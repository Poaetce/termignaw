package main

import "core:fmt"
import "core:os"
import "core:sys/linux"
import "vendor:raylib"

import "pseudoterminal"
import "interface"
import "configuration"

BUFFER_SIZE: u16 : 1024

main :: proc() {
	success: bool
	terminal: ^interface.Terminal
	terminal, success = interface.create_terminal(
		"Termignaw",
		[2]u32{1280, 720},
		{
			"test-assets/fonts/CascadiaCodeNF-Regular.ttf",
			"test-assets/fonts/CascadiaCodeNF-Bold.ttf",
			"test-assets/fonts/CascadiaCodeNF-Italic.ttf",
			"test-assets/fonts/CascadiaCodeNF-BoldItalic.ttf",
		},
		50,
		[2]u32{10, 10},
	)
	if !success {return}

	raylib.SetConfigFlags({
		.WINDOW_RESIZABLE,
	})

	interface.open_window(terminal)
	defer raylib.CloseWindow()
	defer interface.destroy_terminal(terminal)

	pty: pseudoterminal.Pty
	error: pseudoterminal.Error
	pty, error = pseudoterminal.set_up_pty()
	if error != nil {return}
	defer pseudoterminal.close_pty(pty)

	process_id: linux.Pid
	process_id, error = pseudoterminal.start_shell(pty, "/bin/sh")
	if error != nil {return}
	if process_id < 0 {return}

	if !pseudoterminal.set_non_blocking(pty) {return}

	buffer: [BUFFER_SIZE]u8

	for !raylib.WindowShouldClose() {
		{
			raylib.BeginDrawing()
			defer raylib.EndDrawing()

			raylib.ClearBackground(raylib.WHITE)

			interface.render_grid(terminal)
		}

		{
			if raylib.IsWindowResized() {
				dimensions := [2]u32{
					u32(raylib.GetScreenWidth()),
					u32(raylib.GetScreenHeight()),
				}
				interface.resize_terminal(dimensions, terminal)
			}

			for
				character: rune = raylib.GetCharPressed();
				character > 0;
				character = raylib.GetCharPressed()
			{
				pseudoterminal.write_character(character, pty)
			}

			for
				key: raylib.KeyboardKey = raylib.GetKeyPressed();
				key != .KEY_NULL;
				key = raylib.GetKeyPressed()
			{
				#partial switch key {
				case .ENTER:
					pseudoterminal.write_character('\n', pty)
				case .BACKSPACE:
					pseudoterminal.write_character('\b', pty)
				}
			}

			bytes_read: int
			error: os.Error
			bytes_read, error = os.read(pty.master_fd, buffer[:])
			if error == .EAGAIN {continue}
			if error != nil {break}

			buffer_strand := string(buffer[:bytes_read])
			interface.map_strand(buffer_strand, terminal)
		}
	}
}
