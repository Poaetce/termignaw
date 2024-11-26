package configuration

//---------
// config related constants
//---------

CONFIG_DIRECTORY: string : "test-assets/config" when ODIN_DEBUG else "$HOME/.config/termignaw"

//---------
// config related types
//---------

Color :: [3]u8

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

Appearance_Table :: struct {
	theme: Theme,
	// cursor: string,
}

Font_Table :: struct {
	normal: string,
	bold: string,
	italic: string,
	bold_italic: string,
	size: u16,
}

Window_Table :: struct {
	title: string,
	// fullscreen: bool,
	dimensions: [2]u32,
	padding: [2]u32,
}

General_Table :: struct {
	shell: string,
	// wrapping: bool,
}

Config :: struct {
	appearance: Appearance_Table,
	font: Font_Table,
	window: Window_Table,
	general: General_Table,
}
