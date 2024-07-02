package main

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"
import "core:sys/linux"

import "pseudoterminal"

BUFFER_SIZE: u16 : 1024

main :: proc() {
	master_fd: os.Handle
	slave_name: string
	success: bool
	master_fd, slave_name, success = pseudoterminal.set_up_pty()
	if !success {return}

	process_id: linux.Pid
	error: linux.Errno
	process_id, error = linux.fork()
	if error != nil {return}

	if process_id == 0 {
		slave_fd: os.Handle
		error: os.Errno
		slave_fd, error = os.open(slave_name, os.O_RDWR)
		if error != 0 {return}
		defer os.close(slave_fd)

		linux.setsid()

		linux.dup2(linux.Fd(slave_fd), linux.Fd(os.stdin))
		linux.dup2(linux.Fd(slave_fd), linux.Fd(os.stdout))
		linux.dup2(linux.Fd(slave_fd), linux.Fd(os.stderr))

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
			bytes_read, error = os.read(master_fd, buffer[:])
			if error != 0 {break}

			if bytes_read <= 0 {break}

			os.write(os.stdout, buffer[:bytes_read])
		}
	}
}
