import os
import util
import xvo { Program, Action }

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
	p.start(args.options)

	if args.unknown.len > 0 {
		p.do_action(action, args.unknown)
	}
}
