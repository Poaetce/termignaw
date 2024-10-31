package interface

import "vendor:raylib"

Grid_Vector :: [2]u16
Window_Vector :: [2]u32

Cell :: struct {
	character: rune,
	foreground_color: raylib.Color,
	background_color: raylib.Color,
	font_variant: Font_Variant,
}

Row :: struct {
	cells: []Cell,
	wrapping: bool,
}

// terminal contents and state
Grid :: struct {
	dimensions: Grid_Vector,
	contents: [dynamic]Row,
	cursor: ^Cursor,
	screen_scroll: u16,
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
	font_group: Font_Group,
}

create_row :: proc(length: u16) -> (row: Row) {
	row.cells = make([]Cell, int(length))
	return row
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

create_terminal :: proc(
	title: string,
	dimensions: Window_Vector,
	font_names: struct {
		normal: string,
		bold: string,
		italic: string,
		bold_italic: string,
	},
	text_size: u16,
	padding: Window_Vector,
) -> (terminal: ^Terminal, success: bool) {
	terminal = new(Terminal)

	terminal.window.title = title
	terminal.window.dimensions = dimensions
	terminal.window.padding = padding

	terminal.font_group, success = create_font_group(font_names, text_size)
	if !success {
		free(terminal)
		return nil, false
	}

	terminal.grid = create_grid(dimensions, text_size, padding)

	return terminal, true
}

destroy_terminal :: proc(terminal: ^Terminal) {
	destroy_grid(terminal.grid)

	for _, index in Font_Variant {
		destroy_font_info(terminal.font_group.variants[index])
	}

	free(terminal)
}
