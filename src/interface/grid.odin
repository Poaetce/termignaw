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
	theme: ^Theme,
) -> (grid: ^Grid) {
	grid = new(Grid)
	grid.dimensions = calculate_grid_dimensions(dimensions, padding, f32(text_size))

	// fill grid with empty cells
	for index in 0..<grid.dimensions.y {
		new_row(grid)
	}

	grid.cursor = create_cursor(theme)

	return grid
}

destroy_grid :: proc(grid: ^Grid) {
	for row in grid.contents {delete(row.cells)}

	delete(grid.contents)

	free(grid.cursor)

	free(grid)
}

//---------
// general grid related procedures
//---------

// resizes the grid
@(private)
resize_grid :: proc(target_dimensions: Grid_Vector, grid: ^Grid) {
	// update the grid dimensions
	grid.dimensions = target_dimensions

	// resize the grid
	resize_grid_contents_cut(grid)

	// create new empty rows if needed
	row_increase: int = int(target_dimensions.y) - len(grid.contents)
	if row_increase > 0 {
		for index in 0..=row_increase {
			new_row(grid)
		}
	}
}

// resize the grid contents without wrapping or unwrapping
@(private)
resize_grid_contents_cut :: proc(grid: ^Grid) {
	// check if the row's width is increased
	increased_width: bool = grid.dimensions.x > u16(len(grid.contents[0].cells))

	// for each row in the grid
	for &row in grid.contents {
		// create new slice for the row's cells
		new_cells: []Cell = make([]Cell, int(grid.dimensions.x))

		if increased_width {
			// copy all cells of the current row to the new slice
			for cell, index in row.cells {
				new_cells[index] = cell
			}
		}
		else {
			// update all cells of the new slice from the current row
			for &new_cell, index in new_cells {
				new_cell = row.cells[index]
			}
		}

		// replace the old row slice with the new one
		delete(row.cells)
		row.cells = new_cells
	}
}

// moves the screen_scroll by an amount
@(private)
scroll_screen :: proc(amount: i32 , grid: ^Grid) {
	// calulate the target position
	target_scroll: i32 = i32(grid.screen_scroll) + amount

	// calculate the maximum screen scroll
	maximum_scroll: u16 = calculate_maximum_screen_scroll(grid.dimensions, u16(len(grid.contents)))

	// clamps the scroll between 0 and the grid's maximum
	switch {
	case target_scroll < 0:
		grid.screen_scroll = 0
	case target_scroll > i32(maximum_scroll):
		grid.screen_scroll = maximum_scroll
	case:
		grid.screen_scroll = u16(target_scroll)
	}
}

// creates and appends a new row to the grid
@(private)
new_row :: proc(grid: ^Grid) {
	append(&grid.contents, create_row(grid.dimensions.x))
}
