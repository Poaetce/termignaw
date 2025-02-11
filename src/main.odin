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
	error: union #shared_nil {configuration.Error, pseudoterminal.Error}
	config: configuration.Config
	config, error = configuration.read_config()
	if error != nil {return}

	success: bool
	terminal: ^interface.Terminal
	terminal, success = interface.create_terminal(
		config.window.title,
		config.window.dimensions,
		{
			config.font.normal,
			config.font.bold,
			config.font.italic,
			config.font.bold_italic,
		},
		config.font.size,
		config.window.padding,
		&config.appearance.theme,
	)
	if !success {return}

	raylib.SetConfigFlags({
		.WINDOW_RESIZABLE,
	})

	interface.open_window(terminal)
	defer raylib.CloseWindow()
	defer interface.destroy_terminal(terminal)

	pty: pseudoterminal.Pty
	pty, error = pseudoterminal.set_up_pty()
	if error != nil {return}
	defer pseudoterminal.close_pty(pty)

	process_id: linux.Pid
	process_id, error = pseudoterminal.start_shell(pty, config.general.shell)
	if error != nil {return}
	if process_id < 0 {return}

	if !pseudoterminal.set_non_blocking(pty) {return}

	buffer: [BUFFER_SIZE]u8

	for !raylib.WindowShouldClose() {
		{
			raylib.BeginDrawing()
			defer raylib.EndDrawing()

			raylib.ClearBackground(raylib.Color(config.appearance.theme.background))

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
