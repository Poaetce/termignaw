package interface

import "core:slice"
import "core:strings"
import "vendor:raylib"

// checks if cursor is at or over the end of the row
is_cursor_at_edge :: proc(grid: ^Grid) -> (bool) {
	return grid.cursor_position.x + 1 >= grid.dimensions.x
}

// checks if cursor is at the last row
is_cursor_at_last_row :: proc(grid: ^Grid) -> (bool) {
	return grid.cursor_position.y + 1 >= u16(len(grid.contents))
}

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
	contains_new_character: bool = false

	// add new characters to font_info.loaded_characters
	for character in strand {
		if !slice.contains(font_info.loaded_characters[:], character) {
			contains_new_character = true

			append(&font_info.loaded_characters, character)
		}
	}

	if contains_new_character {reload_font(font_info)}
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

// maps a strand of text onto the grid
map_strand :: proc(strand: string, grid: ^Grid) {
	for character in strand {
		// create a cell
		cell: Cell
		cell.character = character
		cell.foreground_color = raylib.BLACK
		cell.background_color = raylib.WHITE

		// set current cell to the new cell
		grid.contents[grid.cursor_position.y].cells[grid.cursor_position.x] = cell

		// update cursor position
		if is_cursor_at_edge(grid) {
			// creates a new row if needed
			if is_cursor_at_last_row(grid) {new_row(grid)}

			// wrap cursor to next row
			grid.contents[grid.cursor_position.y].wrapping = true
			grid.cursor_position.y += 1
			grid.cursor_position.x = 0
		} else {
			// increment cursor
			grid.cursor_position.x += 1
		}
	}
}

// renders all cells in the terminal grid
render_grid :: proc(terminal: ^Terminal) {
	for row, y in terminal.grid.contents {
		for cell, x in row.cells {
			draw_cell(cell, Grid_Vector{u16(x), u16(y)}, terminal)
		}
	}
}
