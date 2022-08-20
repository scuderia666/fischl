import os
import util
import xvo { Program, Action }
import runtime

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

	mut action := Action{}

	match args.command {
		'build' {
			action = Action.build
		}

		'install' {
			action = Action.install
		}

		'emerge' {
			action = Action.emerge
		}

		'remove' {
			action = Action.remove
		}

		else { usage() }
	}

	mut p := Program{}

	mut options := {
		'rebuild': 'no',
		'debug': 'no',
		'jobs': runtime.nr_cpus().str()
	}

	if args.options.len > 0 {
		for opt, val in options {
			if opt in args.options.keys() {
				if args.options[opt] != '' {
					options[opt] = args.options[opt]
				} else if val == 'no' {
					options[opt] = 'yes'
				}
			}
		}
	}

	if options['jobs'].int() > runtime.nr_cpus() + 1 {
		options['jobs'] = (runtime.nr_cpus() + 1).str()
	} else if options['jobs'].int() < 1 {
		options['jobs'] = '1'
	}

	p.start(options)

	if args.unknown.len > 0 {
		for pkg in args.unknown {
			p.do_action(action, pkg)
		}
	}
}
