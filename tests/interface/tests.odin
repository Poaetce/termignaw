package test_interface

import "core:testing"

import "../../src/interface"

@(test)
test_calculate_grid_dimensions :: proc(t: ^testing.T) {
	window_dimensions := [2]u32{1280, 720}
	window_padding := [2]u32{10, 10}
	cell_height: f32 = 12

	grid_dimensions: [2]u16 = interface.calculate_grid_dimensions(window_dimensions, window_padding, cell_height)

	testing.expect_value(t, grid_dimensions, [2]u16{210, 58})
}

@(test)
test_calculate_window_position :: proc(t: ^testing.T) {
	grid_position := [2]u16{69, 42}
	window_padding := [2]u32{10, 10}
	cell_height: f32 = 12

	window_position: [2]u32 = interface.calculate_window_position(grid_position, window_padding, cell_height)

	testing.expect_value(t, window_position, [2]u32{424, 514})
}

@(test)
test_create_grid :: proc(t: ^testing.T) {
	dimensions := [2]u32{1280, 720}
	text_size: u16 = 12
	padding := [2]u32{10, 10}


	grid: ^interface.Grid = interface.create_grid(dimensions, text_size, padding)
	defer interface.destroy_grid(grid)

	testing.expect_value(t, grid.dimensions, [2]u16{210, 58})
	testing.expect_value(t, len(grid.contents), 58)
	testing.expect_value(t, len(grid.contents[0].cells), 210)
	testing.expect_value(t, grid.cursor_position, [2]u16{0, 0})
	testing.expect_value(t, grid.screen_position, 0)
}

@(test)
test_create_font_info :: proc(t: ^testing.T) {
	font_name: string = "tests/assets/CascadiaCode.ttf"
	text_size: u16 = 12

	success: bool
	font_info: ^interface.Font_Info
	font_info, success = interface.create_font_info(font_name, text_size)

	testing.expect(t, success)

	if !success {return}
	defer interface.destroy_font_info(font_info)

	testing.expect_value(t, font_info.name, "tests/assets/CascadiaCode.ttf")
	testing.expect_value(t, font_info.size, 12)
	testing.expect_value(t, len(font_info.loaded_characters), 0)
}

@(test)
test_create_terminal :: proc(t: ^testing.T) {
	title: string = "Termignaw"
	dimensions := [2]u32{1280, 720}
	font_name: string = "tests/assets/CascadiaCode.ttf"
	text_size: u16 = 12
	padding := [2]u32{10, 10}

	success: bool
	terminal: ^interface.Terminal
	terminal, success = interface.create_terminal(title, dimensions, font_name, text_size, padding)

	testing.expect(t, success)

	if !success {return}
	defer interface.destroy_terminal(terminal)

	testing.expect_value(t, terminal.window.title, "Termignaw")
	testing.expect_value(t, terminal.window.dimensions, [2]u32{1280, 720})
	testing.expect_value(t, terminal.window.padding, [2]u32{10, 10})

	testing.expect_value(t, terminal.grid.dimensions, [2]u16{210, 58})
	testing.expect_value(t, len(terminal.grid.contents), 58)
	testing.expect_value(t, len(terminal.grid.contents[0].cells), 210)
	testing.expect_value(t, terminal.grid.cursor_position, [2]u16{0, 0})
	testing.expect_value(t, terminal.grid.screen_position, 0)

	testing.expect_value(t, terminal.font_info.name, "tests/assets/CascadiaCode.ttf")
	testing.expect_value(t, terminal.font_info.size, 12)
	testing.expect_value(t, len(terminal.font_info.loaded_characters), 0)
}
