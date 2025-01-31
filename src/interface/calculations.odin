package interface

import "core:math"

//---------
// general calculations
//---------

// calculates the dimensions for the terminal grid
@(private)
calculate_grid_dimensions :: proc(
	window_dimensions: Window_Vector,
	window_padding: Window_Vector,
	cell_height: f32,
) -> (grid_dimensions: Grid_Vector) {
	cell_width: f32 = cell_height / 2

	return Grid_Vector{
		u16(math.floor(f32(window_dimensions.x - window_padding.x * 2) / cell_width)),
		u16(math.floor(f32(window_dimensions.y - window_padding.y * 2) / cell_height)),
	}
}

// converts grid position into pixel position
@(private)
calculate_window_position :: proc(
	grid_position: Grid_Vector,
	window_padding: Window_Vector,
	cell_height: f32,
) -> (window_position: Window_Vector){
	cell_width: f32 = cell_height / 2

	return Window_Vector{
		u32(f32(grid_position.x) * cell_width) + window_padding.x,
		u32(f32(grid_position.y) * cell_height) + window_padding.y,
	}
}

// calculates the maximum possible screen scroll
@(private)
calculate_maximum_screen_scroll :: proc(
	grid_dimensions: Grid_Vector,
	row_count: u16,
) -> (screen_scroll: u16) {
	return row_count - grid_dimensions.y
}

// calculates the next multiple of a number
@(private)
round_to_next_multiple :: proc(number: u16, multiple: u16) -> (result: u16) {
	return number + (multiple - number % multiple)
}
