module xvo

import os
import util
import log
import arrays
import pkg { Package }

pub struct Program {
pub mut:
	packages map[string]Package
	cfg map[string]string
	cfgdata util.Data
	options map[string]string

	dependencies []string
	marked []string
}

pub fn (mut p Program) start(opts map[string]string) {
	mut options := opts.clone()

	cwd := os.getwd()

	mut placeholders := map[string]string

	placeholders['pwd'] = cwd

	vars := arrays.merge(['root', 'src', 'work', 'db'], opts.keys())

	p.cfg = util.read_config(cwd + '/config', vars, placeholders)

	for opt in options.keys() {
		if opt in p.cfg.keys() {
			if p.cfg[opt] == 'yes' {
				options[opt] = 'yes'
			} else {
				options[opt] = p.cfg[opt]
			}
		}
	}

	p.options = options.clone()

	if !('root' in p.cfg) {
		return
	}

	if ! os.exists(p.cfg['root']) {
		os.mkdir(p.cfg['work']) or { }
	}

	if !('src' in p.cfg) {
		p.cfg['src'] = p.cfg['root'] + '/src'
	}

	if !('work' in p.cfg) {
		p.cfg['work'] = p.cfg['src']
	}

	if !('db' in p.cfg) {
		p.cfg['db'] = p.cfg['src'] + '/db'
	}

	p.cfgdata.rootdir = p.cfg['root']
	p.cfgdata.srcdir = p.cfg['src']
	p.cfgdata.dbdir = p.cfg['db']
	p.cfgdata.pkgdir = p.cfg['src'] + '/pkg'
	p.cfgdata.stuff = p.cfg['src'] + '/stuff'
	p.cfgdata.dldir = p.cfg['work'] + '/dl'
	p.cfgdata.bldir = p.cfg['work'] + '/build'
	p.cfgdata.built = p.cfg['work'] + '/built'

	os.mkdir(p.cfg['src']) or { }
	os.mkdir(p.cfg['work']) or { }
	os.mkdir(p.cfgdata.dldir) or { }
	os.mkdir(p.cfgdata.bldir) or { }
	os.mkdir(p.cfgdata.built) or { }
}

pub fn (mut p Program) dependency(pkgname string) {
	p.read_package(pkgname)

	deps := p.packages[pkgname].get_deps()

	for dep in deps {
		if !(dep in p.marked) {
			p. marked << dep
			p.dependency(dep)
		}
	}

	if !(pkgname in p.dependencies) {
		p.dependencies << pkgname
	}
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

pub fn (mut p Program) read_package(name string) {
	if name in p.packages {
		return
	}

	mut pkg := Package{name: name, cfgdata: p.cfgdata, options: p.options}

	pkg.read(p.cfgdata.pkgdir + '/$name')

	p.packages[name] = pkg
}

pub fn (mut p Program) get_depends(pkgname string) string {
	if p.dependencies.len != 0 {
		return ''
	}

	p.dependency(pkgname)

	mut pool := ''

	for dep in p.dependencies {
		pool = pool + '$dep, '
	}

	if pool.len == 0 {
		return ''
	}

	return pool.substr(0, pool.len-2)
}

pub fn (mut p Program) do_build(pkgname string) {
	pool := p.get_depends(pkgname)

	log.info('following packages will be built: ' + pool)

	log.info_print('do you want to continue? (y/n) ')
	value := os.input('')

	if value != 'y' {
		log.info('cancelled.')
		return
	}

	for dep in p.dependencies {
		p.packages[dep].build()
	}
}

pub fn (mut p Program) do_install(pkgname string) {
	pool := p.get_depends(pkgname)

	log.info('following packages will be installed: ' + pool)

	log.info_print('do you want to continue? (y/n) ')
	value := os.input('')

	if value != 'y' {
		log.info('cancelled.')
		return
	}

	for dep in p.dependencies {
		p.packages[dep].install()
	}
}

pub fn (mut p Program) emerge(pkgname string) {
	pool := p.get_depends(pkgname)

	log.info('following packages will be installed: ' + pool)

	log.info_print('do you want to continue? (y/n) ')
	value := os.input('')

	if value != 'y' {
		log.info('cancelled.')
		return
	}

	for dep in p.dependencies {
		p.packages[dep].build()
		p.packages[dep].install()
	}
}

pub fn (mut p Program) do_action(action string, pkg string) {
	match action {
		'emerge' {
			p.emerge(pkg)
		}

		'build' {
			p.do_build(pkg)
		}

		'install' {
			p.do_install(pkg)
		}

		else { }
	}
}
