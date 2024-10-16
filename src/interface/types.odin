package interface

import "core:os"
import "core:strings"
import "vendor:raylib"

Grid_Vector :: [2]u16
Window_Vector :: [2]u32

// variant of a font
Font_Variant :: enum {
	Normal,
	Bold,
	Italic,
	Bold_Italic,
}

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
	dimensions: Grid_Vector,
	contents: [dynamic]Row,
	cursor_position: Grid_Vector,
	screen_position: u16,
}

// font and text related data
Font_Info :: struct {
	name: cstring,
	data: []u8,
	font: raylib.Font,
	loaded_characters: [dynamic]rune,
}

// data for a group of font
Font_Group :: struct {
	size: u16,
	variants: [4]^Font_Info,
}

Window :: struct {
	title: string,
	dimensions: Window_Vector,
	padding: Window_Vector,
}

// main terminal structure
Terminal :: struct {
	window: Window,
	grid: ^Grid,
	font_group: Font_Group,
}

create_row :: proc(length: u16) -> (row: Row) {
	row.cells = make([]Cell, int(length))
	return row
}

create_grid :: proc(dimensions: Window_Vector, text_size: u16, padding: Window_Vector) -> (grid: ^Grid) {
	grid = new(Grid)
	grid.dimensions = calculate_grid_dimensions(dimensions, padding, f32(text_size))

	// fill grid with empty cells
	for index in 0..<grid.dimensions.y {
		new_row(grid)
	}

	return grid
}

destroy_grid :: proc(grid: ^Grid) {
	for row in grid.contents {delete(row.cells)}

	delete(grid.contents)

	free(grid)
}

create_font_info :: proc(font_name: string) -> (font_info: ^Font_Info, success: bool) {
	font_info = new(Font_Info)

	// read the data from the font file
	font_info.data, success = os.read_entire_file(font_name)
	if !success {
		free(font_info)
		return nil, false
	}

	// clone the font name as a cstring
	font_info.name = strings.clone_to_cstring(font_name)

	return font_info, true
}

destroy_font_info :: proc(font_info: ^Font_Info) {
	raylib.UnloadFont(font_info.font)
	delete(font_info.name)
	delete(font_info.data)
	delete(font_info.loaded_characters)

	free(font_info)
}

create_font_group :: proc(
	font_names: struct {
		normal: string,
		bold: string,
		italic: string,
		bold_italic: string,
	},
	text_size: u16,
) -> (font_group: Font_Group, success:bool)
{
	font_group.size = text_size

	// transmute font_names struct to an array to be indexed
	font_names_array: [4]string = transmute([4]string)font_names

	// create Font_Info for each variant
	for _, index in Font_Variant {
		font_group.variants[index] = create_font_info(font_names_array[index]) or_return
	}

	return font_group, true
}

create_terminal :: proc(
	title: string,
	dimensions: Window_Vector,
	font_names: struct {
		normal: string,
		bold: string,
		italic: string,
		bold_italic: string,
	},
	text_size: u16,
	padding: Window_Vector,
) -> (terminal: ^Terminal, success: bool) {
	terminal = new(Terminal)

	terminal.window.title = title
	terminal.window.dimensions = dimensions
	terminal.window.padding = padding

	terminal.font_group, success = create_font_group(font_names, text_size)
	if !success {
		free(terminal)
		return nil, false
	}

	terminal.grid = create_grid(dimensions, text_size, padding)

	return terminal, true
}

destroy_terminal :: proc(terminal: ^Terminal) {
	destroy_grid(terminal.grid)

	for _, index in Font_Variant {
		destroy_font_info(terminal.font_group.variants[index])
	}

	free(terminal)
}
