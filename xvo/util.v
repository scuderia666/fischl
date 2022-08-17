module util

import os
import io

pub fn read_config(file string, vars []string, placeholders map[string]string) map[string]string {
	mut lines := os.read_lines(file) or { panic(err) }

	mut result := []string{}

	for line in lines {
		result << apply_placeholders(line, placeholders)
	}

	return io.read_vars(result, vars)
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
