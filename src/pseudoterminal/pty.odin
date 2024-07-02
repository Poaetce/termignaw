package pseudoterminal

import "core:os"

foreign import libc "system:c"
foreign libc {
	posix_openpt :: proc(flags: i32) -> i32 ---
	grantpt :: proc(fd: i32) -> i32 ---
	unlockpt :: proc(fd: i32) -> i32 ---
	ptsname :: proc(fd: i32) -> cstring ---
}

set_up_pty :: proc() -> (master_fd: os.Handle, slave_name: string, success: bool) {
	master_fd_i32: i32 = posix_openpt(os.O_RDWR)
	if master_fd_i32 == -1 {return -1, "", false}

	if grantpt(master_fd_i32) == -1 {return -1, "", false}

	if unlockpt(master_fd_i32) == -1 {return -1, "", false}

	slave_name_cstring: cstring = ptsname(master_fd_i32)
	if slave_name_cstring == "" {return -1, "", false}

	return os.Handle(master_fd_i32), string(slave_name_cstring), true
}
