module pkg

import os
import log
import util

pub struct Package {
pub mut:
	name string [required]
	cfg map[string]string [required]
	data map[string][]string
	vars map[string]string

	fullname string

	is_read bool

	util util.Util

	dl string
	bl string
	db string
	dest string
	files string
	patches string

	sources map[string]string
	archives map[string]string
}

pub fn (mut p Package) on_add() {
	p.db = p.cfg['db'] + '/$p.name'
}

pub fn (mut p Package) read(pkgfile string) bool {
	if p.is_read {
		return true
	}

	if ! os.exists(pkgfile) {
		log.err('package is not found')
		return false
	}

	mut lines := os.read_lines(pkgfile) or { panic(err) }

	sects := ['options', 'src', 'deps', 'build']

	p.vars = util.read_vars(lines)

	if p.vars['name'] == '' {
		p.vars['name'] = p.name
	}

	for var, val in p.vars {
		p.vars[var] = val.replace('%name', p.vars['name'])
	}

	for sect in sects {
		for line in util.read_sect(lines, sect) {
			p.data[sect] << util.apply_placeholders(line, p.vars)
		}
	}

	if p.val('ver') == '' {
		p.vars['ver'] = 'unknown'
	}

	p.fullname = p.name + '-' + p.val('ver')

	p.dl = p.cfg['dl'] + '/$p.name'
	p.bl = p.cfg['bl'] + '/$p.name'
	p.dest = p.bl + '/out'
	p.files = p.cfg['stuff'] + '/$p.name'
	p.patches = p.files + '/patches'

	p.util.init()

	p.is_read = true

	return true
}

pub fn (mut p Package) read_archive(archive string) bool {
	if p.is_read {
		return true
	}

	if ! os.exists(archive) {
		return false
	}

	os.mkdir_all(p.cfg['root']) or { }
	os.chdir(p.cfg['root']) or { }
	p.sys('bash ' + p.cfg['scripts'] + '/read_file.sh ' + archive + ' ./pkginfo')
	os.chdir(p.cfg['maindir']) or { }

	mut lines := os.read_lines(p.cfg['root'] + '/pkginfo') or { panic(err) }

	os.rm(p.cfg['root'] + '/pkginfo') or { }

	sects := ['deps']

	for sect in sects {
		for line in util.read_sect(lines, sect) {
			p.data[sect] << line
		}
	}

	p.vars = util.read_vars(lines)

	p.is_read = true

	return true
}

pub fn (p Package) get_deps() []string {
	mut deps := []string{}

	for dep in p.data['deps'] {
		deps << dep
	}

	return deps
}

pub fn (p Package) is_yes(var string) bool {
	return p.val(var) == 'yes'
}

pub fn (p Package) is_no(var string) bool {
	return p.val(var) == 'no'
}

pub fn (p Package) val(var string) string {
	if var in p.vars.keys() {
		return p.vars[var]
	}

	return ''
}

pub fn (p Package) sys(cmd string) int {
	if p.cfg['debug'] != 'yes' {
		return os.system(cmd + ' &>/dev/null')
	} else {
		return os.system(cmd)
	}
}

pub fn (mut p Package) get_sources() bool {
	for src in p.data['src'] {
		mut source := src
		mut filename := os.base(src)

		if os.base(src).contains(':') {
			filename = os.base(src).all_after(':')
			source = src.all_before(':' + filename)
		}

		if p.util.is_archive(filename) || source.contains('git') {
			p.archives[filename] = p.util.strip_extension(filename)
		}

		p.sources[source] = filename
	}

	if p.sources.len != 0 {
		os.mkdir_all(p.dl) or { }
	}

	mut i := 1

	for src, filename in p.sources {
		if src.contains('git') {
			if ! os.exists(p.bl + '/' + filename) {
				log.info('cloning $filename [$i/$p.sources.len]')

				p.sys('bash ' + p.cfg['scripts'] + '/clone.sh ' + src + ' ' + p.bl + '/' + filename)

				if ! os.exists(p.bl + '/' + filename) {
					log.err('couldnt clone $filename')
					return false
				}
			} else {
				log.info('already cloned: $filename')
			}
		} else {
			if ! os.exists(p.dl + '/' + filename) {
				log.info('downloading $filename [$i/$p.sources.len]')

				p.sys('bash ' + p.cfg['scripts'] + '/download.sh ' + src + ' ' + p.dl + '/' + filename)

				if ! os.exists(p.dl + '/' + filename) {
					log.err('couldnt download $filename')
					return false
				}
			} else {
				log.info('already exists: $filename')
			}
		}

		i = i + 1
	}

	return true
}

pub fn (mut p Package) extract_sources() bool {
	mut i := 1

	for src, filename in p.archives {
		if os.exists(p.bl + '/' + filename) {
			os.rmdir_all(p.bl + '/' + filename) or { }
		}

		os.mkdir_all(p.bl + '/' + filename) or { }

		if ! src.contains('git') {
			log.info('extracting source: $src [$i/$p.archives.len]')

			p.sys('bash ' + p.cfg['scripts'] + '/extract.sh ' + p.dl + '/' + src + ' ' + p.bl + '/' + filename)

			if ! os.exists(p.bl + '/' + filename) {
				log.err('couldnt extract $filename')
				return false
			}
		}

		i = i + 1
	}

	return true
}

pub fn (p Package) placeholders(str string) string {
	mut result := str

	mut placeholders := p.vars.clone()

	for key, val in p.cfg {
		placeholders[key] = val
	}

	placeholders['dest'] = p.dest
	placeholders['files'] = p.files

	placeholders['conf'] = './configure --prefix ' + p.cfg['prefix']
	placeholders['make'] = 'make -j' + p.cfg['jobs']
	placeholders['samu'] = 'samu -j' + p.cfg['jobs']

	result = util.apply_placeholders(result, placeholders)

	return result
}

pub fn (mut p Package) create_script() {
	script := p.bl + '/build.sh'

	if os.exists(script) {
		os.rm(script) or { }
	}

	mut f := os.create(script) or { panic(err) }

	f.write_string('#!/bin/sh' + '\n') or { }

	if p.archives.len == 1 {
		f.write_string('cd ' + p.archives.values()[0] + '\n') or { }
	} else if 'workdir' in p.vars.keys() {
		f.write_string('cd ' + p.val('workdir') + '\n') or { }
	}

	if p.val('nopatch') != 'yes' && (p.archives.len == 1 || p.val('force-patch') == 'yes') {
		if os.exists(p.patches) {
			files := os.ls(p.patches) or { []string{} }

			for filename in files {
				file := p.patches + '/$filename'

				if os.is_file(file) {
					if filename.contains('.patch') || filename.contains('.diff') {
						f.write_string('patch -p1 < ' + file + '\n') or { }
					}
				}
			}
		}
	}

	f.write_string('set -e' + '\n') or { }

	for line in p.data['build'] {
		f.write_string(p.placeholders(line) + '\n') or { }
	}

	f.close()
}

pub fn (mut p Package) package() {
	if os.exists(p.dest) {
		log.info('packaging')

		mut f := os.create(p.dest + '/pkginfo') or { panic(err) }

		f.write_string('ver ' + p.val('ver') + '\n') or { }

		if 'deps' in p.data.keys() {
			f.write_string('\n[deps]' + '\n') or { }

			for dep in p.data['deps'] {
				f.write_string(dep + '\n') or { }
			}
		}

		f.close()

		os.chdir(p.dest) or { }

		if os.exists(p.get_archive()) {
			os.rm(p.get_archive()) or { }
		}

		p.sys('bash ' + p.cfg['scripts'] + '/compress.sh ' + p.get_archive())

		log.info('$p.name built successfully')
	}
}

pub fn (mut p Package) get_archive() string {
	return p.cfg['out'] + '/' + p.name + '.pkg'
}

pub fn (mut p Package) build() bool {
	if os.exists(p.get_archive()) {
		if p.cfg['rebuild'] != 'yes' {
			log.err('package is already built, pass -rebuild to rebuild it')
			return false
		} else {
			println('rebuilding $p.name')
		}
	} else {
		println('building $p.name')
	}

	os.mkdir_all(p.bl) or { }

	if ! p.get_sources() {
		log.err('couldnt get sources')
		return false
	}

	if ! p.extract_sources() {
		log.err('couldnt extract sources')
		return false
	}

	if 'build' in p.data.keys() {
		p.create_script()

		if os.exists(p.dest) {
			os.rmdir_all(p.dest) or { }
		}

		if p.archives.len == 1 {
			os.mkdir_all(p.dest) or { }
		}

		os.chdir(p.bl) or { }
		os.system('chmod 777 build.sh')
		res := p.sys('sh build.sh')
		if res != 0 {
			log.err('build failed')
			return false
		}
		if p.cfg['nopackage'] != 'yes' {
			p.package()
		}
		os.chdir(p.bl + '/..') or { }
	}

	return true
}

pub fn (mut p Package) install() bool {
	if os.exists(p.db) {
		log.err('package is already installed')
		return false
	}

	if ! os.exists(p.get_archive()) {
		log.err('package is not built')
		return false
	}

	os.mkdir_all(p.cfg['root']) or { }
	os.mkdir_all(p.cfg['db']) or { }
	os.system('bash ' + p.cfg['scripts'] + '/install.sh ' + p.cfg['root'] + ' ' + p.get_archive() + ' &>/dev/null')
	os.mkdir_all(p.db) or { }
	os.mv(p.cfg['root'] + '/pkginfo', p.db) or { }
	p.sys('bash ' + p.cfg['scripts'] + '/create_filelist.sh ' + p.get_archive() + ' ' + p.db + '/files')

	log.info('$p.name is installed successfully')

	return true
}

pub fn (p Package) remove() bool {
	if ! os.exists(p.db) {
		log.err('package is not installed')
		return false
	}

	p.sys('bash ' + p.cfg['scripts'] + '/list_uninstall.sh ' + p.db + '/files ' + p.cfg['root'])
	os.rmdir_all(p.db) or { }

	log.info('$p.name is removed successfully')

	return true
}
