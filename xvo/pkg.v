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
		if ! os.exists(p.dl + '/' + filename) {
			os.system('bash ' + p.cfgdata.stuff + '/download.sh ' + src + ' ' + p.dl + '/' + filename)
		}
	}
}

pub fn (mut p Package) extract() {
	os.mkdir(p.bl) or { }

	for src, filename in p.archives {
		os.mkdir(p.bl + '/' + filename) or { }
		os.system('bash ' + p.cfgdata.stuff + '/extract.sh ' + p.dl + '/' + src + ' ' + p.bl + '/' + filename)
	}
}

pub fn (mut p Package) start_build() {

}

pub fn (mut p Package) build() {
	p.read(p.cfgdata.pkgdir + '/$p.name')
	p.download()
	p.extract()
}
