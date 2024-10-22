package configuration

import "vendor:raylib"

CONFIG_FILE_PATH: string : "***REMOVED***"

Theme :: struct {
	foreground: raylib.Color,
	background: raylib.Color,
	default: raylib.Color,
	black: raylib.Color,
	red: raylib.Color,
	green: raylib.Color,
	yellow: raylib.Color,
	blue: raylib.Color,
	magenta: raylib.Color,
	cyan: raylib.Color,
	light_gray: raylib.Color,
	dark_gray: raylib.Color,
	light_red: raylib.Color,
	light_green: raylib.Color,
	light_yellow: raylib.Color,
	light_blue: raylib.Color,
	light_magenta: raylib.Color,
	light_cyan: raylib.Color,
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
