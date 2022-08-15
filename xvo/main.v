import os
import vargs
import lol
import pkg { Package }

const (
	version = '0.1'
)

struct Program {
	packages map[string]int
}

fn (p Program) start() {

}

fn (p Program) read_package(name string) {
	pkg := Package{name}
}

fn (p Program) do_build() {

}

fn (p Program) do_install() {

}

fn (p Program) do_action(action string, pkg string) {
	println('$action: $pkg')

	match action {
		'build' {
			p.do_build()
		}

		'install' {
			p.do_install()
		}

		else { }
	}
}

fn usage() {
	println("xvo build|install <pkg>")
	exit(1)
}

fn main() {
	mut args := vargs.new(os.args, 1)

	args.alias('W', 'with')

	args.parse()

	p := Program{}

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
		for _, pkg in args.unknown {
			p.read_package(pkg)
			p.do_action(action, pkg)
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
