module util

pub fn apply_placeholders(str string, vars map[string]string) string {
	mut result := str

	for var, val in vars {
		if result.contains('%$var') {
			result = result.replace('%$var', val)
		}
	}

	return result
}
