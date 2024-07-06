package interface

import "vendor:raylib"

Character :: struct {
	character: rune,
	color: raylib.Color,
}

Terminal :: struct {
	dimensions: [2]u16,
	content: [][]Character,
	cursor_position: [2]u16,
	screen_position: u16,
}

Text :: struct {
	font: raylib.Font,
	size: i32,
	loaded_characters: []rune,
}

Window :: struct {
	title: string,
	dimensions: [2]i32,
	terminal: Terminal,
	text: Text,
	padding: [2]i32,
}
