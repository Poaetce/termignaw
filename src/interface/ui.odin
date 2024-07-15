package interface

import "core:math"
import "vendor:raylib"

Cell :: struct {
	character: rune,
	foreground_color: raylib.Color,
	background_color: raylib.Color,
}

Row :: struct {
	content: []Cell,
	wrapping: bool,
}

Terminal :: struct {
	dimensions: [2]u16,
	content: [dynamic]Row,
	cursor_position: [2]u16,
	screen_position: u16,
}

Text :: struct {
	font_data: []u8,
	font: raylib.Font,
	size: u16,
	loaded_characters: []rune,
}

Window :: struct {
	title: string,
	dimensions: [2]u32,
	terminal: ^Terminal,
	text: ^Text,
	padding: [2]u32,
}

calculate_terminal_dimensions :: proc(
	window_dimensions: [2]u32,
	window_padding: [2]u32,
	cell_height: f32
) -> (terminal_dimensions: [2]u16) {
	cell_width: f32 = cell_height / 2

	return [2]u16{
		u16(math.floor(f32(window_dimensions.x - window_padding.x * 2) / cell_width)),
		u16(math.floor(f32(window_dimensions.y - window_padding.y * 2) / cell_height)),
	}
}
