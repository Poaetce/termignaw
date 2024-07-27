package main

import "core:fmt"
import "core:os"
import "core:sys/linux"
import "vendor:raylib"

import "pseudoterminal"
import "interface"

BUFFER_SIZE: u16 : 1024

main :: proc() {
	success: bool
	terminal: ^interface.Terminal
	terminal, success = interface.create_terminal(
		"Termignaw",
		[2]u32{1280, 720},
		"tests/assets/CascadiaCode.ttf",
		12,
		[2]u32{10, 10},
	)
	if !success {return}

	interface.open_window(terminal)
	defer raylib.CloseWindow()
	defer interface.destroy_terminal(terminal)

	pty: pseudoterminal.Pty
	pty, success = pseudoterminal.set_up_pty()
	if !success {return}
	defer pseudoterminal.close_pty(pty)

	process_id: linux.Pid
	process_id, success = pseudoterminal.start_shell(pty, "/bin/sh")
	if !success {return}
	if process_id < 0 {return}

	if !pseudoterminal.set_non_blocking(pty) {return}

	buffer: [BUFFER_SIZE]u8

	for !raylib.WindowShouldClose() {
		{
			raylib.BeginDrawing()
				raylib.ClearBackground(raylib.RAYWHITE)
			raylib.EndDrawing()
		}

		{
			bytes_read: int
			error: os.Errno
			bytes_read, error = os.read(pty.master_fd, buffer[:])
			if error == 11 {continue}
			if error != 0 {break}
		}
	}
}
