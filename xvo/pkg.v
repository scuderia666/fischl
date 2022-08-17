module pkg

import os
import util

pub struct Package {
pub mut:
	name string [required]
	cfgdata util.Data [required]
	data map[string][]string
	vars map[string]string

	dl string
	bl string
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
}

pub fn (mut p Package) download() {
	os.mkdir(p.dl) or { }

	for src in p.data['src'] {
		if ! os.exists(p.dl + '/' + os.base(src)) {
			os.system('bash ' + p.cfgdata.stuff + '/download.sh ' + src + ' ' + p.dl + '/' + os.base(src))
		}
	}
}

pub fn (mut p Package) extract() {
	os.mkdir(p.bl) or { }

	for src in p.data['src'] {
		os.system('bash ' + p.cfgdata.stuff + '/extract.sh ' + p.dl + '/' + os.base(src) + ' ' + p.bl)
	}
}

pub fn (mut p Package) start_build() {

}

pub fn (mut p Package) build() {
	p.read(p.cfgdata.pkgdir + '/$p.name')
	p.download()
	p.extract()
}
