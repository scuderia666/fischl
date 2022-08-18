module log

import term
import math

pub fn info(str string) {
	info_print('$str\n')
}

pub fn info_print(str string) {
	print(term.rgb(128, 0, 0, str))
}

pub fn info_lol(s string) {
	println(lol_string(s))
}

pub fn lol_string(s string) string {
	mut output := ""
	mut freq := f32(0.1)
	sl := s.split('')
	for c in sl {
		output += normal_color(freq, c)
		freq += 0.1
	}
	return output
}

fn normal_color(freq f32, s string) string {
    red   := int(math.sin(freq + 0) * 127 + 128)
    green := int(math.sin(freq + 2) * 127 + 128)
    blue  := int(math.sin(freq + 4) * 127 + 128)
	return term.rgb(red, green, blue, s)
}
