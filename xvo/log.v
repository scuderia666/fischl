module log

import term
import math

pub fn info(msg string) {
	//info_print('$msg\n')
	println(msg)
}

pub fn err(msg string) {
	println('[!] $msg')
}

pub fn info_print(msg string) {
	print(term.rgb(128, 0, 0, msg))
}

pub fn info_lol(msg string) {
	println(lol_string(msg))
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
