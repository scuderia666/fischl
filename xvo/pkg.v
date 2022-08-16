module pkg

import os
import io

pub struct Package {
pub mut:
	name string [required]
	data map[string][]string
}

pub fn (mut p Package) read() {
	mut lines := os.read_lines('test') or { panic(err) }

	sects := ['src', 'build']

	for sect in sects {
		for line in io.read_sect(lines, sect) {
			p.data[sect] << line
		}
	}

	for sect in p.data.keys() {
		for line in p.data[sect] {
			println('$sect: $line')
		}
	}
}

pub fn (mut p Package) build() {
	p.read()
}
