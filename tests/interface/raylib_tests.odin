package test_interface

import "core:testing"
import "vendor:raylib"

import "../../src/interface"

@(test)
raylib_tests :: proc(t: ^testing.T) {
	raylib.InitWindow(0, 0, nil)
	defer raylib.CloseWindow()

	test_create_font_info(t)
	test_create_terminal(t)
}

test_create_font_info :: proc(t: ^testing.T) {
	font_name: string = "tests/assets/CascadiaCode.ttf"
	text_size: u16 = 12

	success: bool
	font_info: ^interface.Font_Info
	font_info, success = interface.create_font_info(font_name, text_size)
	defer interface.destroy_font_info(font_info)

	testing.expect(t, success)
	testing.expect_value(t, font_info.name, "tests/assets/CascadiaCode.ttf")
	testing.expect_value(t, font_info.size, 12)
	testing.expect_value(t, len(font_info.loaded_characters), 0)
}

test_create_terminal :: proc(t: ^testing.T) {
	title: string = "Termignaw"
	dimensions := [2]u32{1280, 720}
	font_name: string = "tests/assets/CascadiaCode.ttf"
	text_size: u16 = 12
	padding := [2]u32{10, 10}

	success: bool
	terminal: ^interface.Terminal
	terminal, success = interface.create_terminal(title, dimensions, font_name, text_size, padding)
	defer interface.destroy_terminal(terminal)

	testing.expect(t, success)

	testing.expect_value(t, terminal.window.title, "Termignaw")
	testing.expect_value(t, terminal.window.dimensions, [2]u32{1280, 720})
	testing.expect_value(t, terminal.window.padding, [2]u32{10, 10})

	testing.expect_value(t, terminal.grid.dimensions, [2]u16{210, 58})
	testing.expect_value(t, len(terminal.grid.contents), 0)
	testing.expect_value(t, terminal.grid.cursor_position, [2]u16{0, 0})
	testing.expect_value(t, terminal.grid.screen_position, 0)

	testing.expect_value(t, terminal.font_info.name, "tests/assets/CascadiaCode.ttf")
	testing.expect_value(t, terminal.font_info.size, 12)
	testing.expect_value(t, len(terminal.font_info.loaded_characters), 0)
}
