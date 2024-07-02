package main

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"
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
	error: linux.Errno
	process_id, error = linux.fork()
	if error != nil {return}

	if process_id == 0 {
		linux.setsid()

		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdin))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdout))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stderr))

		environment: [dynamic]cstring
		for element in os2.environ(context.allocator) {
			append(&environment, strings.clone_to_cstring(element))
		}

		linux.execve("/bin/sh", raw_data([]cstring{"/bin/sh", nil}), raw_data(environment[:]))
	} else if process_id > 0 {
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
