package main

import "core:fmt"
import "core:os"
import "core:sys/linux"

import "pseudoterminal"

BUFFER_SIZE: u16 : 1024

main :: proc() {
	pty: pseudoterminal.Pty
	success: bool
	pty, success = pseudoterminal.set_up_pty()
	if !success {return}
	defer pseudoterminal.close_pty(pty)

	process_id: linux.Pid
	process_id, success = pseudoterminal.start_shell(pty)
	if !success {return}

	if process_id > 0 {
		buffer: [BUFFER_SIZE]u8

		for {
			bytes_read: int
			error: os.Errno
			bytes_read, error = os.read(pty.master_fd, buffer[:])
			if error != 0 {break}

			if bytes_read <= 0 {break}

			os.write(os.stdout, buffer[:bytes_read])
		}
	}
}
