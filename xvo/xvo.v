module xvo

import os
import util
import prog { Program }

pub struct Xvo {
pub mut:
	prog Program
	cfg map[string]string
	cfgdata util.Data
}

pub fn (mut x Xvo) start() {
	cwd := os.getwd()

	mut placeholders := map[string]string

	placeholders['pwd'] = cwd

	vars := ['root', 'src', 'work']

	x.cfg = util.read_config(cwd + '/config', vars, placeholders)

	x.cfgdata.rootdir = x.cfg['root']
	x.cfgdata.srcdir = x.cfg['src']
	x.cfgdata.pkgdir = x.cfgdata.srcdir + '/pkg'
	x.cfgdata.stuff = x.cfgdata.srcdir + '/stuff'
	x.cfgdata.dldir = x.cfg['work'] + '/dl'
	x.cfgdata.bldir = x.cfg['work'] + '/build'

	os.mkdir(x.cfg['work']) or { }
	os.mkdir(x.cfgdata.dldir) or { }
	os.mkdir(x.cfgdata.bldir) or { }

	x.prog = Program{cfgdata: x.cfgdata}
}
