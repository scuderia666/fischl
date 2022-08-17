module util

import os

pub struct Data {
pub mut:
	rootdir string
	srcdir string
	pkgdir string
	stuff string
	dldir string
	bldir string
}

pub fn makedir(dir string) bool {
	if os.exists(dir) && os.is_dir(dir) {
		return false
	}

	os.mkdir(dir) or { }

	return true
}

pub fn read_vars(lines []string, vars []string) map[string]string {
	mut result := map[string]string

	for line in lines {
		if line.len == 0 { continue }
		if line[0].ascii_str() == '#' && line[1].ascii_str() != '!' { continue }
		if line[0].ascii_str() == '[' && line[line.len-1].ascii_str() == ']' { break }

		for var in vars {
			if line.contains(var) {
				result[var] = line.all_after_first(var).trim(' ')
			}
		}
	}

	return result
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

pub fn read_config(file string, vars []string, placeholders map[string]string) map[string]string {
	mut lines := os.read_lines(file) or { panic(err) }

	mut result := []string{}

	for line in lines {
		result << apply_placeholders(line, placeholders)
	}

	return read_vars(result, vars)
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
