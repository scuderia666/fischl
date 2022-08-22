module util

import os

pub struct Data {
pub mut:
	rootdir string
	srcdir string
	dbdir string
	pkgdir string
	stuff string
	dldir string
	bldir string
	built string
}

pub struct Util {
pub mut:
	archive_exts []string
}

pub fn (mut u Util) init() {
	u.archive_exts << 'tar.gz'
	u.archive_exts << 'tar.xz'
	u.archive_exts << 'tar.bz2'
	u.archive_exts << 'tar.lz'
	u.archive_exts << 'zip'
}

pub fn (u Util) is_archive(filename string) bool {
	for ext in u.archive_exts {
		if filename.contains('.' + ext) {
			return true
		}
	}

	return false
}

pub fn (u Util) strip_extension(filename string) string {
	for ext in u.archive_exts {
		if filename.contains('.' + ext) {
			return filename.all_before('.' + ext)
		}
	}

	return ''
}

pub fn makedir(dir string) bool {
	if os.exists(dir) && os.is_dir(dir) {
		return false
	}

	os.mkdir(dir) or { }

	return true
}

pub fn read_vars(lines []string) map[string]string {
	mut vars := []string{}
	mut data := map[string]string

	for line in lines {
		if line.len == 0 { continue }
		if line[0].ascii_str() == '#' && line[1].ascii_str() != '!' { continue }
		if line[0].ascii_str() == '[' && line[line.len-1].ascii_str() == ']' { break }

		sep := line.split(" ")
        data[sep[0]] = sep[1..].join(" ")
        if sep[0] in vars {
            println("error same variable can't be declared more than once!")
            continue
        }

        vars << sep[0]
	}

	vars.sort(a > b)

	for c in vars {
		for x, y in data {
			if c == x {
				continue
			}

			data[x] = y.replace("%"+c, data[c])
		}
	}

	return data
}

pub fn read_file(file string) []string {
	mut result := []string{}

	mut lines := os.read_lines(file) or { panic(err) }

	for line in lines {
		if line.len == 0 { continue }
		if line[0].ascii_str() == '#' && line[1].ascii_str() != '!' { continue }

		result << line
	}

	return result
}

pub fn read_sect(lines []string, sect string) []string {
	mut result := []string{}

	mut in_sect := false

	for line in lines {
		if line.len == 0 { continue }
		if line[0].ascii_str() == '#' && line[1].ascii_str() != '!' { continue }
		if in_sect && line[0].ascii_str() == '[' && line[line.len-1].ascii_str() == ']' { break }

		if line == '[$sect]' {
			in_sect = true
		} else if in_sect {
			result << line
		}
	}

	return result
}

pub fn read_config(file string, placeholders map[string]string) map[string]string {
	mut lines := os.read_lines(file) or { panic(err) }

	mut result := []string{}

	for line in lines {
		result << apply_placeholders(line, placeholders)
	}

	return read_vars(result)
}

pub fn apply_placeholders(str string, vars map[string]string) string {
	mut result := str

	for var, val in vars {
		if result.contains('%$var') {
			result = result.replace('%$var', val)
		}
	}

	return result
}

pub struct Args {
    orig []string
    start int
pub mut:
    command string
    options map[string]string = map[string]string
    aliases map[string]string = map[string]string
    unknown []string = []string{}
}

fn parse_option(v string) []string {
    delimitter := if v.starts_with('--') { '--' } else { '-' }
    val := v.replace(delimitter, '')

    return val.split('=')
}

fn starts_with_hypen(v string) bool {
    return v.starts_with('-') || v.starts_with('--')
}

fn (mut v Args) insert_option(name string, val string) {
    insert_name := if name in v.aliases { v.aliases[name] } else { name }

    v.options[insert_name] = if insert_name in v.options {
        v.options[insert_name] + ',' + val
    } else {
        val
    }
}

pub fn new(a []string, start_at int) Args {
    return Args{ orig: a, start: start_at }
}

pub fn (mut v Args) parse() Args {
    args := v.orig[v.start..v.orig.len]

    for i, curr in args {
        next := if i+1 > args.len-1 { '' } else { args[i+1] }
        prev := if i-1 <= 0 { '' } else { args[i-1] }

        if i == 0 && !starts_with_hypen(curr) {
            v.command = curr
        }

        if (starts_with_hypen(prev) && parse_option(prev).len == 1) && !starts_with_hypen(curr) {
            prev_opt := parse_option(prev)
            v.insert_option(prev_opt[0], curr)
        }

        if starts_with_hypen(curr) {
            opt := parse_option(curr)
            match opt.len {
                1 { if next.len == 0 { v.options[opt[0]] = '' } }
                2 { v.insert_option(opt[0], opt[1]) }
                else {}
            }
        }

        if i != 0 && (!starts_with_hypen(prev) || parse_option(prev).len == 2) && !starts_with_hypen(curr) {
            v.unknown << curr
        }
    }

    return v
}

pub fn (v Args) array_option(name string) []string {
    opt_values := v.options[name].split(',')

    return opt_values
}

pub fn (mut v Args) alias(orig string, dest string) {
    v.aliases[orig] = dest
}

pub fn (v Args) str() string {
    mut opts := v.options.str().split_into_lines()
    for i, el in opts { opts[i] = el.trim_space() }
    opts_str := opts.join(' ')

    return '\{ command: "${v.command}", options: ${opts_str}, unknown: ${v.unknown.str()} \}'
}
