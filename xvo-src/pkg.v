module pkg

import os
import log
import util

pub struct Package {
pub mut:
	name string [required]
	cfgdata util.Data [required]
	options map[string]string [required]
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

	sources map[string]string
	archives map[string]string
}

pub fn (mut p Package) read(pkgfile string) {
	if p.is_read {
		return
	}

	if ! os.exists(pkgfile) {
		return
	}

	mut lines := os.read_lines(pkgfile) or { panic(err) }

	vars := ['ver', 'workdir']
	sects := ['src', 'deps', 'build']

	p.vars = util.read_vars(lines, vars)
	p.vars['name'] = p.name

	for sect in sects {
		for line in util.read_sect(lines, sect) {
			p.data[sect] << util.apply_placeholders(line, p.vars)
		}
	}

	p.fullname = p.name + '-' + p.vars['ver']

	p.dl = p.cfgdata.dldir + '/$p.name'
	p.bl = p.cfgdata.bldir + '/$p.name'
	p.db = p.cfgdata.dbdir + '/$p.name'
	p.dest = p.bl + '/out'
	p.files = p.cfgdata.stuff + '/$p.name'

	p.util.init()

	p.is_read = true
}

pub fn (mut p Package) read_archive(archive string) {
	if p.is_read {
		return
	}

	os.mkdir(p.cfgdata.rootdir) or { }
	os.chdir(p.cfgdata.rootdir) or { }
	p.sys('bash ' + p.cfgdata.stuff + '/read_file.sh ' + archive + ' ./pkginfo')
	os.chdir(p.cfgdata.srcdir) or { }

	mut lines := os.read_lines(p.cfgdata.rootdir + '/pkginfo') or { panic(err) }

	os.rm(p.cfgdata.rootdir + '/pkginfo') or { }

	sects := ['deps']

	for sect in sects {
		for line in util.read_sect(lines, sect) {
			p.data[sect] << line
		}
	}

	vars := ['ver']
	p.vars = util.read_vars(lines, vars)

	p.db = p.cfgdata.dbdir + '/$p.name'

	p.is_read = true
}

pub fn (p Package) get_deps() []string {
	mut deps := []string{}

	for dep in p.data['deps'] {
		deps << dep
	}

	return deps
}

pub fn (p Package) is_yes(val string) bool {
	if val in p.vars {
		return p.vars[val] == 'yes'
	}

	return false
}

pub fn (p Package) is_no(val string) bool {
	if val in p.vars {
		return p.vars[val] == 'no'
	}

	return false
}

pub fn (p Package) sys(cmd string) {
	if p.options['debug'] != 'yes' {
		os.system(cmd + ' &>/dev/null')
	} else {
		os.system(cmd)
	}
}

pub fn (mut p Package) get_sources() bool {
	for src in p.data['src'] {
		mut source := src
		mut filename := os.base(src)

		if src.contains('::') {
			source = src.all_before('::')
			filename = src.all_after('::')
		}

		if p.util.is_archive(filename) || source.contains('git') {
			p.archives[filename] = p.util.strip_extension(filename)
		}

		p.sources[source] = filename
	}

	if p.sources.len != 0 {
		os.mkdir(p.dl) or { }
	}

	mut i := 1

	for src, filename in p.sources {
		if src.contains('git') {
			if ! os.exists(p.bl + '/' + filename) {
				log.info('cloning $filename [$i/$p.sources.len]')

				p.sys('bash ' + p.cfgdata.stuff + '/clone.sh ' + src + ' ' + p.bl + '/' + filename)

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

				p.sys('bash ' + p.cfgdata.stuff + '/download.sh ' + src + ' ' + p.dl + '/' + filename)

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

		os.mkdir(p.bl + '/' + filename) or { }

		if ! src.contains('git') {
			log.info('extracting source: $src [$i/$p.archives.len]')

			p.sys('bash ' + p.cfgdata.stuff + '/extract.sh ' + p.dl + '/' + src + ' ' + p.bl + '/' + filename)

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

	placeholders['stuff'] = p.cfgdata.stuff
	placeholders['files'] = p.files
	placeholders['root'] = p.cfgdata.rootdir
	placeholders['dest'] = p.dest
	placeholders['make'] = 'make -j' + p.options['jobs']
	placeholders['prefix'] = ''

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
	} else if 'workdir' in p.vars {
		f.write_string('cd ' + p.vars['workdir'] + '\n') or { }
	}

	for line in p.data['build'] {
		f.write_string(p.placeholders(line) + '\n') or { }
	}

	f.close()
}

pub fn (mut p Package) package() {
	if os.exists(p.dest) {
		log.info('packaging')

		mut f := os.create(p.dest + '/pkginfo') or { panic(err) }

		f.write_string('ver ' + p.vars['ver'] + '\n') or { }

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

		p.sys('bash ' + p.cfgdata.stuff + '/compress.sh ' + p.get_archive())

		log.info('$p.name built successfully')
	}
}

pub fn (mut p Package) get_archive() string {
	return p.cfgdata.built + '/' + p.name + '.pkg'
}

pub fn (mut p Package) build() bool {
	if os.exists(p.get_archive()) {
		if p.options['rebuild'] != 'yes' {
			log.err('package is already built, pass -rebuild to rebuild it')
			return false
		} else {
			println('rebuilding $p.name')
		}
	} else {
		println('building $p.name')
	}

	os.mkdir(p.bl) or { }

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
			os.mkdir(p.dest) or { }
		}

		println('building')

		os.chdir(p.bl) or { }
		os.system('chmod 777 build.sh')
		p.sys('sh build.sh')
		p.package()
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

	os.mkdir(p.cfgdata.rootdir) or { }
	os.mkdir(p.cfgdata.dbdir) or { }
	os.system('bash ' + p.cfgdata.stuff + '/install.sh ' + p.cfgdata.rootdir + ' ' + p.get_archive() + ' &>/dev/null')
	os.mkdir(p.db) or { }
	os.mv(p.cfgdata.rootdir + '/pkginfo', p.db) or { }
	p.sys('bash ' + p.cfgdata.stuff + '/create_filelist.sh ' + p.get_archive() + ' ' + p.db + '/files')

	log.info('$p.name is installed successfully')

	return true
}

pub fn (p Package) remove() bool {
	if ! os.exists(p.db) {
		log.err('package is not installed')
		return false
	}

	p.sys('bash ' + p.cfgdata.stuff + '/list_uninstall.sh ' + p.db + '/files ' + p.cfgdata.rootdir)
	os.rmdir_all(p.db) or { }

	log.info('$p.name is removed successfully')

	return true
}
