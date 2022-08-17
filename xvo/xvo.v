module xvo

import os
import pkg { Package }
import util

pub struct Program {
pub mut:
	packages map[string]Package
	cfg map[string]string

	rootdir string
	srcdir string
	pkgdir string
	stuff string
	dldir string
	bldir string
}

pub fn (mut p Program) start() {
	cwd := os.getwd()

	mut placeholders := map[string]string

	placeholders['pwd'] = cwd

	vars := ['root', 'src', 'work']

	p.cfg = util.read_config(cwd + '/config', vars, placeholders)

	p.rootdir = p.cfg['root']
	p.srcdir = p.cfg['src']
	p.pkgdir = p.srcdir + '/pkg'
	p.pkgdir = p.srcdir + '/stuff'
	p.dldir = p.cfg['work'] + '/dl'
	p.bldir = p.cfg['work'] + '/build'
}

pub fn (mut p Program) read_package(name string) {
	mut pkg := Package{name: name}

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
