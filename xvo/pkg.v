module pkg

import os
import util

pub struct Package {
pub mut:
	name string [required]
	cfgdata util.Data [required]
	data map[string][]string
	vars map[string]string

	util util.Util

	dl string
	bl string
	files string

	sources map[string]string
	archives map[string]string
}

pub fn (mut p Package) read(pkgfile string) {
	mut lines := os.read_lines(pkgfile) or { panic(err) }

	vars := ['ver']
	sects := ['src', 'build']

	p.vars = util.read_vars(lines, vars)
	p.vars['name'] = p.name

	for sect in sects {
		for line in util.read_sect(lines, sect) {
			p.data[sect] << util.apply_placeholders(line, p.vars)
		}
	}

	p.dl = p.cfgdata.dldir + '/$p.name'
	p.bl = p.cfgdata.bldir + '/$p.name'
	p.files = p.cfgdata.stuff + '/$p.name'

	p.util.init()
}

pub fn (mut p Package) download() {
	os.mkdir(p.dl) or { }

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

	for src, filename in p.sources {
		if src.contains('git') {
			os.system('git clone ' + src + ' ' + p.bl + '/' + filename)
		} else {
			if ! os.exists(p.dl + '/' + filename) {
				os.system('bash ' + p.cfgdata.stuff + '/download.sh ' + src + ' ' + p.dl + '/' + filename)
			}
		}
	}
}

pub fn (mut p Package) extract() {
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

	placeholders['files'] = p.files

	result = util.apply_placeholders(result, placeholders)

	return result
}

pub fn (mut p Package) start_build() {
	script := p.bl + '/build.sh'

	if os.exists(script) {
		os.rm(script) or { }
	}

	mut f := os.create(script) or { panic(err) }

	f.write_string('#!/bin/sh' + '\r\n') or { }
	f.write_string('source common.sh' + '\r\n') or { }

	if p.archives.len == 1 {
		f.write_string('cd ' + p.archives.values()[0] + '\r\n') or { }
	}

	common := p.bl + '/common.sh'

	if os.exists(common) {
		os.rm(common) or { }
	}

	mut common_f := os.create(common) or { panic(err) }

	mut lines := os.read_lines(p.cfgdata.stuff + '/common.sh') or { panic(err) }

	for line in lines {
		common_f.write_string(p.placeholders(line) + '\r\n') or { }
	}
}

pub fn (mut p Package) build() {
	p.read(p.cfgdata.pkgdir + '/$p.name')
	os.mkdir(p.bl) or { }
	p.download()
	p.extract()
	p.start_build()
}
