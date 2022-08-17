module prog

import util
import pkg { Package }

pub struct Program {
pub mut:
	cfgdata util.Data [required]
	packages map[string]Package
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
