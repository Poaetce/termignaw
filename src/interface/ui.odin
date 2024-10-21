package interface

import "core:slice"
import "core:strings"
import "vendor:raylib"

// checks if cursor is at or over the end of the row
is_cursor_at_edge :: proc(grid: ^Grid) -> (bool) {
	return grid.cursor.position.x + 1 >= grid.dimensions.x
}

// checks if cursor is at the last row
is_cursor_at_last_row :: proc(grid: ^Grid) -> (bool) {
	return grid.cursor.position.y + 1 >= u16(len(grid.contents))
}

// creates and appends a new row to the grid
new_row :: proc(grid: ^Grid) {
	append(&grid.contents, create_row(grid.dimensions.x))
}

// loads all font variants
load_font_group :: proc(font_group: Font_Group) {
	for variant in font_group.variants {
		load_font(variant, font_group.size)
	}
}

// loads font using the font data
load_font :: proc(font_info: ^Font_Info, font_size: u16) {
	font_info.font = raylib.LoadFontFromMemory(
		raylib.GetFileExtension(font_info.name),
		raw_data(font_info.data),
		i32(len(font_info.data)),
		i32(font_size),
		raw_data(font_info.loaded_characters),
		i32(len(font_info.loaded_characters)),
	)
}

// reloads the font with the updated details
reload_font :: proc(font_info: ^Font_Info, font_size: u16) {
	raylib.UnloadFont(font_info.font)
	load_font(font_info, font_size)
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

	load_font_group(terminal.font_group)
}

// draws an individual character cell
draw_cell :: proc(cell: Cell, position: Grid_Vector, terminal: ^Terminal) {
	font_info: ^Font_Info = terminal.font_group.variants[cell.font_variant]

	// exit procedure if the character isn't loaded
	if !slice.contains(
		font_info.loaded_characters[:],
		cell.character,
	) {return}

	// calculate the pixel position
	window_position: Window_Vector = calculate_window_position(
		position,
		terminal.window.padding,
		f32(terminal.font_group.size),
	)

	// draw cell background as a rectangle
	if cell.background_color != {} {
		raylib.DrawRectangle(
			i32(window_position.x),
			i32(window_position.y),
			i32(terminal.font_group.size) / 2,
			i32(terminal.font_group.size),
			cell.background_color,
		)
	}

	// draw cell character
	raylib.DrawTextCodepoint(
		font_info.font,
		cell.character,
		[2]f32{f32(window_position.x), f32(window_position.y)},
		f32(terminal.font_group.size),
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
		grid.contents[grid.cursor.position.y].wrapping = true
		grid.cursor.position.y += 1
		grid.cursor.position.x = 0
	} else {
		// increment cursor
		grid.cursor.position.x += 1
	}
}

// maps a strand of text onto the grid
map_strand :: proc(strand: string, terminal: ^Terminal) {
	font_info: ^Font_Info = terminal.font_group.variants[Font_Variant.Normal]

	contains_new_character: bool = false

	for character in strand {
		map_character(character, terminal.grid)

		// add new characters to font_info.loaded_characters
		if !slice.contains(font_info.loaded_characters[:], character) {
			contains_new_character = true

			append(&font_info.loaded_characters, character)
		}
	}

	// reloads font if the strand contains new characters
	if contains_new_character {reload_font(font_info, terminal.font_group.size)}
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

		grid.cursor.position.y += 1
		grid.cursor.position.x = 0
	case '\r':
		grid.cursor.position.x = 0
	case '\t':
		grid.cursor.position.x = round_to_next_multiple(grid.cursor.position.x, 4)
	case:
		// create a cell
		cell: Cell
		cell.character = character
		cell.foreground_color = grid.cursor.foreground_color
		cell.background_color = grid.cursor.background_color

		// set current cell to the new cell
		grid.contents[grid.cursor.position.y].cells[grid.cursor.position.x] = cell

		// update cursor position
		increment_cursor(grid)
	}
}

// renders all cells in the terminal grid
render_grid :: proc(terminal: ^Terminal) {
	for row, y in terminal.grid.contents[terminal.grid.screen_scroll:][:terminal.grid.dimensions.y] {
		for cell, x in row.cells {
			draw_cell(cell, Grid_Vector{u16(x), u16(y)}, terminal)
		}
	}
}

// moves the screen_scroll by an amount
scroll_screen :: proc(amount: i32 , grid: ^Grid) {
	// calulate the target position
	target_scroll: i32 = i32(grid.screen_scroll) + amount

	// clamps the scroll between 0 and the grid's maximum
	switch {
	case target_scroll < 0:
		grid.screen_scroll = 0
	case target_scroll > i32(calculate_maximum_screen_scroll(grid.dimensions, u16(len(grid.contents)))):
		grid.screen_scroll = calculate_maximum_screen_scroll(grid.dimensions, u16(len(grid.contents)))
	case:
		grid.screen_scroll = u16(target_scroll)
	}
}

// resizes the terminal
resize_terminal :: proc(target_dimensions: Window_Vector, terminal: ^Terminal) {
	// update the window dimensions to the new dimensions
	terminal.window.dimensions = target_dimensions

	// calculate the new target dimensions for the grid
	target_grid_dimensions: Grid_Vector = calculate_grid_dimensions(
		target_dimensions,
		terminal.window.padding,
		f32(terminal.font_group.size),
	)

	// resize the grid to the new dimensions
	resize_grid(target_grid_dimensions, terminal.grid)
}

// resizes the grid
resize_grid :: proc(target_dimensions: Grid_Vector, grid: ^Grid) {
	// update the grid dimensio
	grid.dimensions = target_dimensions

	// for each row of the grid
	for &row in grid.contents {
		// matche if the row's width is increased or decreased
		switch {
		case target_dimensions.x > u16(len(row.cells)):
			// create new slice for the row's cells
			new_cells: []Cell = make([]Cell, int(grid.dimensions.x))

			// copy each cell of the row to the new slice
			for cell, index in row.cells {
				new_cells[index] = cell
			}

			// replace the old row slice with the new one
			delete(row.cells)
			row.cells = new_cells
		case target_dimensions.x < u16(len(row.cells)):
			// create new slice for the row's cells
			new_cells: []Cell = make([]Cell, int(grid.dimensions.x))

			// copy the cell of the row to the new slice
			for &new_cell, index in new_cells {
				new_cell = row.cells[index]
			}

			// replace the old row slice with the new one
			delete(row.cells)
			row.cells = new_cells
		}
	}

	// create new empty rows if needed
	row_increase: int = int(target_dimensions.y) - len(grid.contents)
	if row_increase > 0 {
		for index in 0..=row_increase {
			new_row(grid)
		}
	}
}
