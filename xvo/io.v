module io

import os

pub fn read_vars(lines []string, vars []string) map[string]string {
	mut result := map[string]string

	for line in lines {
		if line.len == 0 { continue }
		if line[0].ascii_str() == '#' && line[1].ascii_str() != '!' { continue }
		if line[0].ascii_str() == '[' && line[line.len-1].ascii_str() == ']' { break }

		for var in vars {
			if line.contains(var) {
				result[var] = line.after(var).trim(' ')
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
