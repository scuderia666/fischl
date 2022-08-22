module xvo

import os
import util
import log
import runtime
import pkg { Package }

pub enum Action {
	emerge
	build
	install
	remove
}

pub struct Program {
pub mut:
	packages map[string]Package
	cfg map[string]string

	dependencies []string
	marked []string
}

pub fn (mut p Program) start(args map[string]string) bool {
	mut cfg := {
		'rebuild': 'no'
		'debug': 'no'
		'nopackage': 'no'
		'deps': 'yes'
		'arch': 'x86_64'
		'cc': 'gcc'
		'cxx': 'g++'
		'cflags': ''
		'cxxflags': ''
		'ldflags': ''
		'prefix': ''
		'host': ''
		'target': ''
		'db': '%root/src/db'
		'pkg': '%root/src/pkg'
		'stuff': '%root/src/stuff'
		'out': '%root/src/out'
		'bl': '%root/src/build'
		'dl': '%root/src/dl'
		'scripts': '%root/src/scripts'
		'config': '/etc/xvo.conf'
		'jobs': runtime.nr_cpus().str()
	}

	mut result := cfg.clone()
	mut lines := []string{}

	if args.len > 0 {
		for var in args.keys() {
			if args[var] != '' {
				result[var] = args[var].replace('%pwd', os.getwd())
			}
		}
	}

	for var, val in result {
		lines << var + ' ' + val.replace('%pwd', os.getwd())
	}

	cfg = util.read_vars(lines)

	if cfg['config'] != '' && os.exists(cfg['config']) {
		mut placeholders := map[string]string
		placeholders['pwd'] = os.getwd()
		config := util.read_config(cfg['config'], placeholders)

		for key in config.keys() {
			cfg[key] = config[key]
		}
	}

	if cfg['jobs'].int() > runtime.nr_cpus() + 1 {
		cfg['jobs'] = (runtime.nr_cpus() + 1).str()
	} else if cfg['jobs'].int() < 1 {
		cfg['jobs'] = '1'
	}

	if cfg['host'] == '' {
		cfg['host'] = os.execute(cfg['cc'] + ' -dumpmachine').output
	}

	if cfg['target'] == '' {
		cfg['target'] = os.execute(cfg['cc'] + ' -dumpmachine').output
	}

	os.setenv('CC', cfg['cc'], true)
	os.setenv('CXX', cfg['cxx'], true)
	os.setenv('CFLAGS', cfg['cflags'], true)
	os.setenv('CXXFLAGS', cfg['cxxflags'], true)
	os.setenv('LDFLAGS', cfg['ldflags'], true)

	os.mkdir_all(cfg['root']) or { }

	cfg['maindir'] = os.getwd()
	p.cfg = cfg.clone()

	return true
}

pub fn (mut p Program) dependency(pkgname string, install bool) bool {
	p.add_package(pkgname)

	mut res := true

	if install {
		res = p.read_archive(pkgname)
	} else {
		res = p.read_package(pkgname)
	}

	if ! res {
		return false
	}

	deps := p.packages[pkgname].get_deps()

	for dep in deps {
		if !(dep in p.marked) {
			p. marked << dep

			if ! p.dependency(dep, install) {
				return false
			}
		}
	}

	if !(pkgname in p.dependencies) {
		p.dependencies << pkgname
	}

	return true
}

pub fn (p Program) is_yes(val string) bool {
	if val in p.cfg {
		return p.cfg[val] == 'yes'
	}

	return false
}

pub fn (p Program) is_no(val string) bool {
	if val in p.cfg {
		return p.cfg[val] == 'no'
	}

	return false
}

pub fn (mut p Program) add_package(name string) {
	if name in p.packages {
		return
	}

	mut pkg := Package{name: name, cfg: p.cfg}

	pkg.on_add()

	p.packages[name] = pkg
}

pub fn (mut p Program) get_recipe(name string) string {
	files := os.ls(p.cfg['pkg']) or { []string{} }

	for filename in files {
		dir := p.cfg['pkg'] + '/$filename'

		if os.is_dir(dir) {
			pkgs := os.ls(dir) or { []string{} }

			for pkg in pkgs {
				if pkg == name {
					return dir + '/$pkg'
				}
			}
		} else {
			return dir
		}
	}

	return ''
}

pub fn (mut p Program) read_package(name string) bool {
	if !(name in p.packages) {
		return false
	}

	return p.packages[name].read(p.get_recipe(name))
}

pub fn (mut p Program) read_archive(name string) bool {
	if !(name in p.packages) {
		return false
	}

	return p.packages[name].read_archive(p.packages[name].get_archive())
}

pub fn (mut p Program) get_depends(pkgs []string, install bool) string {
	for pkg in pkgs {
		if ! p.dependency(pkg, install) {
			return ''
		}
	}

	return util.create_pool(p.dependencies)
}

pub fn (mut p Program) do_build(pkgs []string) bool {
	pool := p.get_depends(pkgs, false)

	if pool == '' {
		return false
	}

	log.info('following packages will be built: ' + pool)

	log.info_print('do you want to continue? (y/n) ')
	value := os.input('')

	if value != 'y' {
		log.info('cancelled.')
		return false
	}

	for dep in p.dependencies {
		if ! p.packages[dep].build() {
			return false
		}
	}

	return true
}

pub fn (mut p Program) do_install(pkgs []string) bool {
	pool := p.get_depends(pkgs, true)

	if pool == '' {
		return false
	}

	log.info('following packages will be installed: ' + pool)

	log.info_print('do you want to continue? (y/n) ')
	value := os.input('')

	if value != 'y' {
		log.info('cancelled.')
		return false
	}

	for dep in p.dependencies {
		if ! p.packages[dep].install() {
			return false
		}
	}

	return true
}

pub fn (mut p Program) do_uninstall(pkgs []string) bool {
	log.info('following packages will be removed: ' + util.create_pool(pkgs))

	log.info_print('do you want to continue? (y/n) ')
	value := os.input('')

	if value != 'y' {
		log.info('cancelled.')
		return false
	}

	for pkg in pkgs {
		p.add_package(pkg)
		p.packages[pkg].remove()
	}

	return true
}

pub fn (mut p Program) emerge(pkgs []string) bool {
	pool := p.get_depends(pkgs, false)

	if pool == '' {
		return false
	}

	log.info('following packages will be installed: ' + pool)

	log.info_print('do you want to continue? (y/n) ')
	value := os.input('')

	if value != 'y' {
		log.info('cancelled.')
		return false
	}

	for dep in p.dependencies {
		if p.packages[dep].build() {
			if ! p.packages[dep].install() {
				return false
			}
		} else {
			return false
		}
	}

	return true
}

pub fn (mut p Program) do_action(action Action, pkgs []string) {
	match action {
		.emerge {
			p.emerge(pkgs)
		}

		.build {
			if p.cfg['deps'] == 'yes' {
				p.do_build(pkgs)
			} else {
				for pkg in pkgs {
					p.read_package(pkg)
					p.packages[pkg].build()
				}
			}
		}

		.install {
			if p.cfg['deps'] == 'yes' {
				p.do_install(pkgs)
			} else {
				for pkg in pkgs {
					p.read_archive(pkg)
					p.packages[pkg].install()
				}
			}
		}

		.remove {
			p.do_uninstall(pkgs)
		}
	}
}