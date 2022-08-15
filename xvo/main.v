import os
import vargs
import lol

const (
	version = '0.1'
)

fn main() {
	mut args := vargs.new(os.args, 1)

	args.alias('W', 'with')

	args.parse()

	if args.command.len > 0 {
		println(args.command)
	}

	if args.unknown.len > 0 {
		println(args.unknown[0])
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
