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

// draws an individual character cell
draw_cell :: proc(cell: Cell, position: Grid_Vector, terminal: ^Terminal) {
	// exit procedure if the character isn't loaded
	if !slice.contains(
		terminal.font_info.loaded_characters[:],
		cell.character,
	) {return}

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

// moves cursor to the next cell
increment_cursor :: proc(grid: ^Grid) {
	if is_cursor_at_edge(grid) {
		// creates a new row if needed
		if is_cursor_at_last_row(grid) {
			new_row(grid)
			scroll_screen(1, grid)
		}

		// wrap cursor to next row
		grid.contents[grid.cursor_position.y].wrapping = true
		grid.cursor_position.y += 1
		grid.cursor_position.x = 0
	} else {
		// increment cursor
		grid.cursor_position.x += 1
	}
}

// maps a strand of text onto the grid
map_strand :: proc(strand: string, terminal: ^Terminal) {
	contains_new_character: bool = false

	for character in strand {
		map_character(character, terminal.grid)

		// add new characters to font_info.loaded_characters
		if !slice.contains(terminal.font_info.loaded_characters[:], character) {
			contains_new_character = true

			append(&terminal.font_info.loaded_characters, character)
		}
	}

	// reloads font if the strand contains new characters
	if contains_new_character {reload_font(terminal.font_info)}
}

// maps a character onto the grid
map_character :: proc(character: rune, grid: ^Grid) {
	// match character for special characters
	switch character {
	case '\n':
		// creates a new row if needed
		if is_cursor_at_last_row(grid) {
			new_row(grid)
			scroll_screen(1, grid)
		}

		grid.cursor_position.y += 1
		grid.cursor_position.x = 0
	case '\t':
		grid.cursor_position.x = round_to_next_multiple(grid.cursor_position.x, 4)
	case:
		// create a cell
		cell: Cell
		cell.character = character
		cell.foreground_color = raylib.BLACK
		cell.background_color = raylib.WHITE

		// set current cell to the new cell
		grid.contents[grid.cursor_position.y].cells[grid.cursor_position.x] = cell

		// update cursor position
		increment_cursor(grid)
	}
}

// renders all cells in the terminal grid
render_grid :: proc(terminal: ^Terminal) {
	for row, y in terminal.grid.contents[terminal.grid.screen_position:][:terminal.grid.dimensions.y] {
		for cell, x in row.cells {
			draw_cell(cell, Grid_Vector{u16(x), u16(y)}, terminal)
		}
	}
}

// moves the screen_position by an amount
scroll_screen :: proc(amount: i32 , grid: ^Grid) {
	// calulate the target position
	target_position: i32 = i32(grid.screen_position) + amount

	// clamps the position between 0 and the grid's maximum
	switch {
	case target_position < 0:
		grid.screen_position = 0
	case target_position > i32(calculate_maximum_screen_position(grid.dimensions, u16(len(grid.contents)))):
		grid.screen_position = calculate_maximum_screen_position(grid.dimensions, u16(len(grid.contents)))
	case:
		grid.screen_position = u16(target_position)
	}
}

resize_terminal :: proc(target_dimensions: Window_Vector, terminal: ^Terminal) {
	terminal.window.dimensions = target_dimensions

	target_grid_dimensions: Grid_Vector = calculate_grid_dimensions(
		target_dimensions,
		terminal.window.padding,
		f32(terminal.font_info.size),
	)
	resize_grid(target_grid_dimensions, terminal.grid)
}

resize_grid :: proc(target_dimensions: Grid_Vector, grid: ^Grid) {
	grid.dimensions = target_dimensions

	for &row in grid.contents {
		switch {
		case target_dimensions.x > u16(len(row.cells)):
			new_cells: []Cell = make([]Cell, int(grid.dimensions.x))

			for cell, index in row.cells {
				new_cells[index] = cell
			}

			delete(row.cells)
			row.cells = new_cells
		case target_dimensions.x < u16(len(row.cells)):
			new_cells: []Cell = make([]Cell, int(grid.dimensions.x))

			for &new_cell, index in new_cells {
				new_cell = row.cells[index]
			}

			delete(row.cells)
			row.cells = new_cells
		}
	}

	row_increase: int = int(target_dimensions.y) - len(grid.contents)
	if row_increase > 0 {
		for index in 0..=row_increase {
			new_row(grid)
		}
	}
}
