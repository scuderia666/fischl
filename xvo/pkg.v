module pkg

import os
import io
import util

pub struct Package {
pub mut:
	name string [required]
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
			p.data[sect] << line
		}
	}

	for sect, data in p.data {
		for line in data {
			linee := util.apply_placeholders(line, p.vars)
			println('$sect: $linee')
		}
	}

	for var, val in p.vars {
		println('$var: $val')
	}
}

pub fn (mut p Package) build() {
	p.read('test')
}
