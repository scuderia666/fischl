import os
import vargs
import lol
import pkg { Package }

const (
	version = '0.1'
)

struct Packages {
	packages map[string]int
}

fn usage() {
	println("xvo build|install <pkg>")
	exit(1)
}

fn do_build() {

}

fn do_install() {

}

fn do_action(action string, pkg string) {
	println('$action: $pkg')

	match action {
		'build' {
			do_build()
		}

		'install' {
			do_install()
		}

		else { }
	}
}

fn read_package(name string) {
	pkg := Package{name}

	packages[name] = pkg
}

fn main() {
	mut args := vargs.new(os.args, 1)

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

		else { usage() }
	}

	if args.unknown.len > 0 {
		for _, pkg in args.unknown {
			read_package(pkg)
			do_action(action, pkg)
		}
	}

	if args.options.len > 0 {
		for _, a in args.options['with'].split(',') {
			println(a)
		}

		println('with? ' + args.options['with'])
	}

    lold := lol.Lol{lol.Config{
    	style: lol.Style.normal
    }}

    lold.print('xvo v${version}')
}
