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
	cells: []Cell,
	wrapping: bool,
}

// terminal contents and state
Grid :: struct {
	dimensions: [2]u16,
	contents: [dynamic]Row,
	cursor_position: [2]u16,
	screen_position: u16,
}

// font and text related data
Font_Info :: struct {
	data: []u8,
	font: raylib.Font,
	size: u16,
	loaded_characters: []rune,
}

Window :: struct {
	title: string,
	dimensions: [2]u32,
	padding: [2]u32,
}

// main terminal structure
Terminal :: struct {
	window: Window,
	grid: ^Grid,
	font_info: ^Font_Info,
}

// calculates the dimensions for the terminal grid
calculate_grid_dimensions :: proc(
	window_dimensions: [2]u32,
	window_padding: [2]u32,
	cell_height: f32,
) -> (grid_dimensions: [2]u16) {
	cell_width: f32 = cell_height / 2

	return [2]u16{
		u16(math.floor(f32(window_dimensions.x - window_padding.x * 2) / cell_width)),
		u16(math.floor(f32(window_dimensions.y - window_padding.y * 2) / cell_height)),
	}
}

create_grid :: proc(dimensions: [2]u32, text_size: u16, padding: [2]u32) -> (grid: ^Grid) {
	grid = new(Grid)
	grid.dimensions = calculate_grid_dimensions(dimensions, padding, f32(text_size))

	return grid
}

destroy_grid :: proc(grid: ^Grid) {
	delete(grid.contents)

	free(grid)
}

create_font_info :: proc(font_name: string, text_size: u16) -> (font_info: ^Font_Info, success: bool) {
	font_info = new(Font_Info)

	// read the data from the font file
	font_info.data, success = os.read_entire_file(font_name)
	if !success {
		free(font_info)
		return nil, false
	}

	// clone the font name as a cstring
	font_name_cstring: cstring = strings.clone_to_cstring(font_name)
	defer delete(font_name_cstring)

	// load font using the font data
	font_info.font = raylib.LoadFontFromMemory(
		raylib.GetFileExtension(font_name_cstring),
		raw_data(font_info.data),
		i32(len(font_info.data)),
		i32(text_size),
		raw_data(font_info.loaded_characters),
		i32(len(font_info.loaded_characters)),
	)

	font_info.size = text_size

	return font_info, true
}

destroy_font_info :: proc(font_info: ^Font_Info) {
	raylib.UnloadFont(font_info.font)
	delete(font_info.data)
	delete(font_info.loaded_characters)

	free(font_info)
}

create_terminal :: proc(
	title: string,
	dimensions: [2]u32,
	font_name: string,
	text_size: u16,
	padding: [2]u32,
) -> (terminal: ^Terminal, success: bool) {
	terminal = new(Terminal)

	terminal.window.title = title
	terminal.window.dimensions = dimensions
	terminal.window.padding = padding

	terminal.font_info, success = create_font_info(font_name, text_size)
	if !success {
		free(terminal)
		return nil, false
	}

	terminal.grid = create_grid(dimensions, text_size, padding)

	return terminal, true
}

destroy_terminal :: proc(terminal: ^Terminal) {
	destroy_grid(terminal.grid)
	destroy_font_info(terminal.font_info)

	free(terminal)
}
