import os
import util
import xvo { Program }

const (
	version = '0.1'
)

fn usage() {
	println("xvo build|install <pkg>")
	exit(1)
}

fn main() {
	mut args := util.new(os.args, 1)
	args.alias('W', 'with')
	args.parse()

	mut p := Program{}
	p.start()

	if args.command.len == 0 {
		exit(1)
	}

	mut action := ''

	match args.command {
		'build' {
			action = 'build'
		}

		'install' {
			action = 'install'
		}

		else { usage() }
	}

	if args.unknown.len > 0 {
		for pkg in args.unknown {
			p.do_action(action, pkg)
		}
	}

	if args.options.len > 0 {
		for a in args.options['with'].split(',') {
			println(a)
		}

		println('with? ' + args.options['with'])
	}
}
