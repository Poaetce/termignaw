package test_interface

import "core:testing"

import "../../src/interface"

@(test)
test_calculate_terminal_dimensions :: proc(t: ^testing.T) {
	window_dimensions: [2]i32 = {1280, 720}
	window_padding: [2]i32 = {10, 10}
	cell_height: f32 = 12

	terminal_dimensions: [2]u16 = interface.calculate_terminal_dimensions(window_dimensions, window_padding, cell_height)

	testing.expect_value(t, terminal_dimensions, [2]u16{210, 58})
}
