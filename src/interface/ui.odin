package interface

import "core:slice"
import "core:strings"
import "vendor:raylib"

// creates and appends a new row to the grid
new_row :: proc(grid: ^Grid) {
	append(&grid.contents, create_row(grid.dimensions.x))
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
