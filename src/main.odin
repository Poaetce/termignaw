package main

import "core:os"

foreign import libc "system:c"
foreign libc {
	posix_openpt :: proc(flags: i32) -> i32 ---
	grantpt :: proc(file_descriptor: i32) -> i32 ---
	unlockpt :: proc(file_descriptor: i32) -> i32 ---
	ptsname :: proc(file_descriptor: i32) -> cstring ---
}

set_up_pty :: proc() -> (file_descriptor: i32, slave_name: string, success: bool) {
	file_descriptor = posix_openpt(os.O_RDWR)
	if file_descriptor == -1 {return -1, "", false}

	if grantpt(file_descriptor) == -1 {return -1, "", false}

	if unlockpt(file_descriptor) == -1 {return -1, "", false}

	slave_name = string(ptsname(file_descriptor))
	if slave_name == "" {return -1, "", false}

	return file_descriptor, slave_name, true
}

main :: proc() {
}
