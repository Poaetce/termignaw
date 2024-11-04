package interface

import "vendor:raylib"

//---------
// <Cell> - a character cell on the terminal grid
//---------

Cell :: struct {
	character: rune,				// cell character
	foreground_color: raylib.Color,	// foreground color of the cell
	background_color: raylib.Color, // background color of the cell
	font_variant: Font_Variant,		// font variant of the cell
}

//---------
// <Row> - a row of cells
//---------

Row :: struct {
	cells: []Cell,	// cells in the row
	wrapping: bool,	// whether or not the row wraps to the next
}

create_row :: proc(length: u16) -> (row: Row) {
	row.cells = make([]Cell, int(length))
	return row
}

//---------
// <Grid> - terminal grid contents and state
//---------

Grid :: struct {
	dimensions: Grid_Vector,	// dimensions of the grid
	contents: [dynamic]Row,		// contents of the grid
	cursor: ^Cursor,			// the cursor
	screen_scroll: u16,			// scroll position of the screen
}

create_grid :: proc(
	dimensions: Window_Vector,
	text_size: u16,
	padding: Window_Vector,
) -> (grid: ^Grid) {
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
