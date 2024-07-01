package main

import "core:os"

foreign import "system:c"

foreign c {
	posix_openpt :: proc(flags: int) -> int ---
	grantpt :: proc(file_descriptor: int) -> int ---
	unlockpt :: proc(file_descriptor: int) -> int ---
	ptsname :: proc(file_descriptor: int) -> cstring ---
}

set_up_pty :: proc() -> (file_descriptor: int, slave_name: string, success: bool) {
	file_descriptor = posix_openpt(os.O_RDWR)
	if file_descriptor == -1 {
		return -1, "", false
	}

	if grantpt(file_descriptor) == -1 {
		return -1, "", false
	}

	if unlockpt(file_descriptor) == -1 {
		return -1, "", false
	}

	slave_name = string(ptsname(file_descriptor))
	if slave_name == "" {
		return -1, "", false
	}

	return file_descriptor, slave_name, true
}

main :: proc() {
}
