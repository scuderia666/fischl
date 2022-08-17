module pkg

import os
import io
import util

pub struct Package {
pub mut:
	name string [required]
	//prog Program [required]
	data map[string][]string
	vars map[string]string
}

pub fn (mut p Package) read(pkgfile string) {
	mut lines := os.read_lines(pkgfile) or { panic(err) }

	vars := ['ver']
	sects := ['src', 'build']

	p.vars = io.read_vars(lines, vars)

	for sect in sects {
		for line in io.read_sect(lines, sect) {
			p.data[sect] << util.apply_placeholders(line, p.vars)
		}
	}
}

pub fn (mut p Package) download() {
	//os.mkdir(p.prog.dldir + '/$name')

	for src in p.data['src'] {

	}
}

pub fn (mut p Package) build() {
	//p.read(p.prog.cfg['pkg'] + '/$p.name')
	p.download()
}
