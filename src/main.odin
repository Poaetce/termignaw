package main

import "core:os"
import "core:fmt"
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
