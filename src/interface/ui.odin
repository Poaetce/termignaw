package interface

import "core:math"
import "core:os"
import "core:strings"
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
	cell_height: f32,
) -> (terminal_dimensions: [2]u16) {
	cell_width: f32 = cell_height / 2

	return [2]u16{
		u16(math.floor(f32(window_dimensions.x - window_padding.x * 2) / cell_width)),
		u16(math.floor(f32(window_dimensions.y - window_padding.y * 2) / cell_height)),
	}
}

create_terminal :: proc(dimensions: [2]u32, text_size: u16, padding: [2]u32) -> (terminal: ^Terminal) {
	terminal = new(Terminal)
	terminal.dimensions = calculate_terminal_dimensions(dimensions, padding, f32(text_size))

	return terminal
}

create_text :: proc(font_name: string, text_size: u16) -> (text: ^Text, success: bool) {
	text = new(Text)

	text.font_data, success = os.read_entire_file(font_name)
	if !success {
		free(text)
		return nil, false
	}

	font_name_cstring: cstring = strings.clone_to_cstring(font_name)
	defer delete(font_name_cstring)

	text.font = raylib.LoadFontFromMemory(
		raylib.GetFileExtension(font_name_cstring),
		raw_data(text.font_data),
		i32(len(text.font_data)),
		i32(text_size),
		raw_data(text.loaded_characters),
		i32(len(text.loaded_characters)),
	)

	text.size = text_size

	return text, true
}

create_window :: proc(
	title: string,
	dimensions: [2]u32,
	font_name: string,
	text_size: u16,
	padding: [2]u32,
) -> (window: ^Window, success: bool) {
	window = new(Window)

	window.title = title
	window.dimensions = dimensions
	window.padding = padding

	window.text, success = create_text(font_name, text_size)
	if !success {
		free(window)
		return nil, false
	}

	window.terminal = create_terminal(dimensions, text_size, padding)

	return window, true
}
