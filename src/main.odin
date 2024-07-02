package main

import "core:os"
import "core:fmt"

import "pseudoterminal"

main :: proc() {
	master_fd: os.Handle
	slave_name: string
	success: bool
	master_fd, slave_name, success = pseudoterminal.set_up_pty()
}
