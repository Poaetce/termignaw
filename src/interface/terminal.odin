package interface

import "core:strings"
import "vendor:raylib"

//---------
// <Window> - terminal window information
//---------

Window :: struct {
	title: string,
	dimensions: Window_Vector,
	padding: Window_Vector,
}

//---------
// <Terminal> - main terminal structure
//---------

Terminal :: struct {
	window: Window,
	grid: ^Grid,
	font_group: Font_Group,
}

create_terminal :: proc(
	title: string,
	dimensions: Window_Vector,
	font_names: Font_Names,
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

	clear_font_group(terminal.font_group)

	free(terminal)
}

//---------
// general terminal / window related procedures
//---------

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
