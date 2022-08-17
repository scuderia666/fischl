import os
import vargs
//import lol
import xvo { Xvo }

const (
	version = '0.1'
)

fn usage() {
	println("xvo build|install <pkg>")
	exit(1)
}

fn main() {
	mut args := vargs.new(os.args, 1)
	args.alias('W', 'with')
	args.parse()

	mut x := Xvo{}
	x.start()

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
			x.prog.read_package(pkg)
			x.prog.do_action(action, pkg)
		}
	}

	if args.options.len > 0 {
		for a in args.options['with'].split(',') {
			println(a)
		}

		println('with? ' + args.options['with'])
	}

    /*lold := lol.Lol{lol.Config{
    	style: lol.Style.normal
    }}

    lold.print('xvo v${version}')*/
}
