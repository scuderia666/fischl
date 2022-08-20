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

		'emerge' {
			action = 'emerge'
		}

		else { usage() }
	}

	mut p := Program{}

	mut options := ['rebuild', 'debug']

	mut opts := map[string]string

	for opt in options {
		opts[opt] = 'no'
	}

	if args.options.len > 0 {
		for opt in options {
			if opt in args.options.keys() {
				opts[opt] = 'yes'
			}
		}
	}

	p.start(opts)

	if args.unknown.len > 0 {
		for pkg in args.unknown {
			p.do_action(action, pkg)
		}
	}
}
