package interface

import "vendor:raylib"

// a character cell on the terminal grid
Cell :: struct {
	character: rune,
	foreground_color: raylib.Color,
	background_color: raylib.Color,
	font_variant: Font_Variant,
}

// a row of cells
Row :: struct {
	cells: []Cell,
	wrapping: bool,
}

create_row :: proc(length: u16) -> (row: Row) {
	row.cells = make([]Cell, int(length))
	return row
}

// terminal contents and state
Grid :: struct {
	dimensions: Grid_Vector,
	contents: [dynamic]Row,
	cursor: ^Cursor,
	screen_scroll: u16,
}

create_grid :: proc(dimensions: Window_Vector, text_size: u16, padding: Window_Vector) -> (grid: ^Grid) {
	grid = new(Grid)
	grid.dimensions = calculate_grid_dimensions(dimensions, padding, f32(text_size))

	// fill grid with empty cells
	for index in 0..<grid.dimensions.y {
		new_row(grid)
	}

	grid.cursor = create_cursor()

	return grid
}

destroy_grid :: proc(grid: ^Grid) {
	for row in grid.contents {delete(row.cells)}

	delete(grid.contents)

	free(grid.cursor)

	free(grid)
}
