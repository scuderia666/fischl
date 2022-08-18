module pkg

import os
import util

pub struct Package {
pub mut:
	name string [required]
	cfgdata util.Data [required]
	data map[string][]string
	vars map[string]string

	is_read bool

	util util.Util

	dl string
	bl string
	dest string
	files string

	sources map[string]string
	archives map[string]string
}

pub fn (mut p Package) read(pkgfile string) {
	if p.is_read {
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

	p.dl = p.cfgdata.dldir + '/$p.name'
	p.bl = p.cfgdata.bldir + '/$p.name'
	p.dest = p.bl + '/out'
	p.files = p.cfgdata.stuff + '/$p.name'

	p.util.init()

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

pub fn (mut p Package) get_sources() {
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

	for src, filename in p.sources {
		if src.contains('git') {
			os.system('bash ' + p.cfgdata.stuff + '/clone.sh ' + src + ' ' + p.bl + '/' + filename)

			if ! os.exists(p.bl + '/' + filename) {
				return
			}
		} else {
			if ! os.exists(p.dl + '/' + filename) {
				os.system('bash ' + p.cfgdata.stuff + '/download.sh ' + src + ' ' + p.dl + '/' + filename)

				if ! os.exists(p.dl + '/' + filename) {
					return
				}
			}
		}
	}
}

pub fn (mut p Package) extract_sources() {
	for src, filename in p.archives {
		os.mkdir(p.bl + '/' + filename) or { }

		if ! src.contains('git') {
			os.system('bash ' + p.cfgdata.stuff + '/extract.sh ' + p.dl + '/' + src + ' ' + p.bl + '/' + filename)
		}
	}
}

pub fn (p Package) placeholders(str string) string {
	mut result := str

	mut placeholders := p.vars.clone()

	placeholders['stuff'] = p.cfgdata.stuff
	placeholders['files'] = p.files
	placeholders['root'] = p.cfgdata.rootdir
	placeholders['dest'] = p.dest
	placeholders['make'] = 'make -j2'
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
		os.chdir(p.dest) or { }
		os.system('bash ' + p.cfgdata.stuff + '/compress.sh ' + p.cfgdata.built + '/' + p.name + '.pkg')
	}
}

pub fn (mut p Package) build() {
	os.mkdir(p.bl) or { }
	p.get_sources()
	p.extract_sources()
	p.create_script()
	if p.archives.len == 1 {
		os.mkdir(p.dest) or { }
	}
	os.chdir(p.bl) or { }
	os.system('chmod 777 build.sh')
	os.system('sh build.sh')
	p.package()
	os.chdir(p.bl + '/..') or { }
}

pub fn (mut p Package) install() {
	os.mkdir(p.cfgdata.rootdir) or { }
	os.system('bash ' + p.cfgdata.stuff + '/install.sh ' + p.cfgdata.rootdir + ' ' + p.cfgdata.built + '/' + p.name + '.pkg')
}
