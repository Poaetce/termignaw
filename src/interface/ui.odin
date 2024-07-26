package interface

import "core:math"
import "core:os"
import "core:slice"
import "core:strings"
import "vendor:raylib"

Grid_Vector :: [2]u16
Window_Vector :: [2]u32

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
	size: u16,
	loaded_characters: [dynamic]rune,
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
	font_info: ^Font_Info,
}

// calculates the dimensions for the terminal grid
calculate_grid_dimensions :: proc(
	window_dimensions: Window_Vector,
	window_padding: Window_Vector,
	cell_height: f32,
) -> (grid_dimensions: Grid_Vector) {
	cell_width: f32 = cell_height / 2

	return Grid_Vector{
		u16(math.floor(f32(window_dimensions.x - window_padding.x * 2) / cell_width)),
		u16(math.floor(f32(window_dimensions.y - window_padding.y * 2) / cell_height)),
	}
}

// converts grid position into pixel position
calculate_window_position :: proc (
	grid_position: Grid_Vector,
	window_padding: Window_Vector,
	cell_height: f32,
) -> (window_position: Window_Vector){
	cell_width: f32 = cell_height / 2

	return Window_Vector{
		u32(f32(grid_position.x) * cell_width) + window_padding.x,
		u32(f32(grid_position.y) * cell_height) + window_padding.y,
	}
}

// loads font using the font data
load_font :: proc(font_info: ^Font_Info) {
	font_info.font = raylib.LoadFontFromMemory(
		raylib.GetFileExtension(font_info.name),
		raw_data(font_info.data),
		i32(len(font_info.data)),
		i32(font_info.size),
		raw_data(font_info.loaded_characters),
		i32(len(font_info.loaded_characters)),
	)
}

// reloads the font with the updated details
reload_font :: proc(font_info: ^Font_Info) {
	raylib.UnloadFont(font_info.font)
	load_font(font_info)
}

create_grid :: proc(dimensions: Window_Vector, text_size: u16, padding: Window_Vector) -> (grid: ^Grid) {
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
	font_info.name = strings.clone_to_cstring(font_name)

	font_info.size = text_size

	return font_info, true
}

destroy_font_info :: proc(font_info: ^Font_Info) {
	raylib.UnloadFont(font_info.font)
	delete(font_info.name)
	delete(font_info.data)
	delete(font_info.loaded_characters)

	free(font_info)
}

create_terminal :: proc(
	title: string,
	dimensions: Window_Vector,
	font_name: string,
	text_size: u16,
	padding: Window_Vector,
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

// initialises and opens the terminal window
open_window :: proc(terminal: ^Terminal) {
	window_title: cstring = strings.clone_to_cstring(terminal.window.title)
	defer delete(window_title)

	raylib.InitWindow(
		i32(terminal.window.dimensions.x),
		i32(terminal.window.dimensions.y),
		window_title,
	)

	load_font(terminal.font_info)
}

// adds new character and reloads font
update_font_characters :: proc(strand: string, font_info: ^Font_Info) {
	// add new characters to font_info.loaded_characters
	for character in strand {
		if !slice.contains(font_info.loaded_characters[:], character) {
			append(&font_info.loaded_characters, character)
		}
	}

	reload_font(font_info)
}

// draws an individual character cell
draw_cell :: proc(cell: Cell, position: Grid_Vector, terminal: ^Terminal) {
	// calculate the pixel position
	window_position: Window_Vector = calculate_window_position(
		position,
		terminal.window.padding,
		f32(terminal.font_info.size),
	)

	// draw cell background as a rectangle
	if cell.background_color != {} {
		raylib.DrawRectangle(
			i32(window_position.x),
			i32(window_position.y),
			i32(terminal.font_info.size) / 2,
			i32(terminal.font_info.size),
			cell.background_color,
		)
	}

	// draw cell character
	raylib.DrawTextCodepoint(
		terminal.font_info.font,
		cell.character,
		[2]f32{f32(window_position.x), f32(window_position.y)},
		f32(terminal.font_info.size),
		cell.foreground_color,
	)
}
