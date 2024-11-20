package interface

import "core:slice"
import "vendor:raylib"

//---------
// rendering related procedures
//---------

// renders all cells in the terminal grid
render_grid :: proc(terminal: ^Terminal) {
	for row, y in
		terminal.grid.contents[terminal.grid.screen_scroll:][:terminal.grid.dimensions.y]
	{
		for cell, x in row.cells {
			draw_cell(cell, Grid_Vector{u16(x), u16(y)}, terminal)
		}
	}
}

// draws an individual character cell
@(private)
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

//---------
// mapping related procedures
//---------

// maps a strand of text onto the grid
map_strand :: proc(strand: string, terminal: ^Terminal) {
	variant_contains_new_character: [4]bool

	for character in strand {
		// get the current font variant and respective Font_Info
		font_variant: Font_Variant = terminal.grid.cursor.font_variant
		font_info: ^Font_Info = terminal.font_group.variants[font_variant]

		map_character(character, terminal.grid)

		// add new characters to the respective font_info.loaded_characters
		if !slice.contains(font_info.loaded_characters[:], character) {
			variant_contains_new_character[font_variant] = true

			append(&font_info.loaded_characters, character)
		}
	}

	// for each font variant
	for _, index in Font_Variant {
		// reload font if the strand contains new characters
		if variant_contains_new_character[index] {
			font_info: ^Font_Info = terminal.font_group.variants[index]
			reload_font(font_info, terminal.font_group.size)
		}
	}
}

// maps a character onto the grid
@(private)
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
		cell.font_variant = grid.cursor.font_variant

		// set current cell to the new cell
		grid.contents[grid.cursor.position.y].cells[grid.cursor.position.x] = cell

		// update cursor position
		increment_cursor(grid)
	}
}
