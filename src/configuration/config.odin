package configuration

CONFIG_FILE_PATH: string : "***REMOVED***"

Color :: [4]u8

Theme :: struct {
	foreground: Color,
	background: Color,
	default: Color,
	black: Color,
	red: Color,
	green: Color,
	yellow: Color,
	blue: Color,
	magenta: Color,
	cyan: Color,
	light_gray: Color,
	dark_gray: Color,
	light_red: Color,
	light_green: Color,
	light_yellow: Color,
	light_blue: Color,
	light_magenta: Color,
	light_cyan: Color,
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
