package main

import "core:os"
import "core:fmt"
import "core:sys/linux"

import "pseudoterminal"

main :: proc() {
	master_fd: os.Handle
	slave_name: string
	success: bool
	master_fd, slave_name, success = pseudoterminal.set_up_pty()
	if !success {return}

	process_id: linux.Pid
	errno: linux.Errno
	process_id, errno = linux.fork()
	if errno != linux.Errno.NONE {return}

	if process_id == 0 {
	} else if process_id > 0 {
	}
}
