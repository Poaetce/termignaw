package configuration

import "core:encoding/hex"

CONFIG_DIRECTORY: string : "$HOME/.config/termignaw"

Color :: [4]u8

Theme :: struct {
	foreground: Color,
	background: Color,
	black: Color,
	red: Color,
	green: Color,
	yellow: Color,
	blue: Color,
	magenta: Color,
	cyan: Color,
	white: Color,
	bright_black: Color,
	bright_red: Color,
	bright_green: Color,
	bright_yellow: Color,
	bright_blue: Color,
	bright_magenta: Color,
	bright_cyan: Color,
	bright_white: Color,
}

Config :: struct {
	appearance: struct {
		theme: Theme,
		cursor: string,
	},
	font: struct {
		normal: string,
		bold: string,
		italic: string,
		bold_italic: string,
		size: u16,
	},
	window: struct {
		title: string,
		fullscreen: bool,
		dimensions: [2]u32,
		padding: [2]u32,
	},
	general: struct {
		shell: string,
		wrapping: bool,
	},
}

decode_color :: proc(hex_code: string) -> (color: Color, success: bool) {
	return Color{
		hex.decode_sequence(hex_code[1:3]) or_return,
		hex.decode_sequence(hex_code[3:5]) or_return,
		hex.decode_sequence(hex_code[5:7]) or_return,
		0,
	}, true
}
