package interface

import "vendor:raylib"

//---------
// <Cursor> - cursor information and state
//---------

Cursor :: struct {
	position: Grid_Vector,			// cursor position
	foreground_color: raylib.Color,	// current foreground color
	background_color: raylib.Color,	// current background color
	font_variant: Font_Variant,		// current font variant
}

create_cursor :: proc() -> (cursor: ^Cursor) {
	cursor = new(Cursor)

	// set cursor to default values
	cursor.foreground_color = raylib.BLACK
	cursor.background_color = raylib.WHITE
	cursor.font_variant = Font_Variant.Normal

	return cursor
}

//---------
// general cursor related procedures
//---------

// checks if cursor is at or over the end of the row
@(private)
is_cursor_at_edge :: proc(grid: ^Grid) -> (bool) {
	return grid.cursor.position.x + 1 >= grid.dimensions.x
}

// checks if cursor is at the last row
@(private)
is_cursor_at_last_row :: proc(grid: ^Grid) -> (bool) {
	return grid.cursor.position.y + 1 >= u16(len(grid.contents))
}

// moves cursor to the next cell
@(private)
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
