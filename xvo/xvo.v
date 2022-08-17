module xvo

import os
import pkg { Package }
import util

pub struct Program {
pub mut:
	packages map[string]Package
	cfg map[string]string
	cfgdata util.Data
}

pub fn (mut p Program) start() {
	cwd := os.getwd()

	mut placeholders := map[string]string

	placeholders['pwd'] = cwd

	vars := ['root', 'src', 'work']

	p.cfg = util.read_config(cwd + '/config', vars, placeholders)

	p.cfgdata.rootdir = p.cfg['root']
	p.cfgdata.srcdir = p.cfg['src']
	p.cfgdata.pkgdir = p.cfgdata.srcdir + '/pkg'
	p.cfgdata.stuff = p.cfgdata.srcdir + '/stuff'
	p.cfgdata.dldir = p.cfg['work'] + '/dl'
	p.cfgdata.bldir = p.cfg['work'] + '/build'

	os.mkdir(p.cfg['work']) or { }
	os.mkdir(p.cfgdata.dldir) or { }
	os.mkdir(p.cfgdata.bldir) or { }
}

pub fn (mut p Program) read_package(name string) {
	mut pkg := Package{name: name, cfgdata: p.cfgdata}

	p.packages[name] = pkg
}

pub fn (p Program) do_build(pkgname string) {
	mut pkg := p.packages[pkgname]

	pkg.build()
}

pub fn (p Program) do_install(pkg string) {

}

pub fn (p Program) do_action(action string, pkg string) {
	match action {
		'build' {
			p.do_build(pkg)
		}

		'install' {
			p.do_install(pkg)
		}

		else { }
	}
}
