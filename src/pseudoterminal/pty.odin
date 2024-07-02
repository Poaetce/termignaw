package pseudoterminal

import "core:os"

foreign import libc "system:c"
foreign libc {
	posix_openpt :: proc(flags: i32) -> i32 ---
	grantpt :: proc(fd: i32) -> i32 ---
	unlockpt :: proc(fd: i32) -> i32 ---
	ptsname :: proc(fd: i32) -> cstring ---
}

Pty :: struct {
	master_fd: os.Handle,
	slave_fd: os.Handle,
}

set_up_pty :: proc() -> (pty: Pty, success: bool) {
	master_fd_i32: i32 = posix_openpt(os.O_RDWR)
	if master_fd_i32 == -1 {return Pty{}, false}

	master_fd := os.Handle(master_fd_i32)

	if grantpt(master_fd_i32) == -1 {
		os.close(master_fd)
		return Pty{}, false
	}

	if unlockpt(master_fd_i32) == -1 {
		os.close(master_fd)
		return Pty{}, false
	}

	slave_name := string(ptsname(master_fd_i32))
	if slave_name == "" {
		os.close(master_fd)
		return Pty{}, false
	}

	slave_fd: os.Handle
	error: os.Errno
	slave_fd, error = os.open(slave_name, os.O_RDWR)
	if error != 0 {
		os.close(master_fd)
		return Pty{}, false
	}

	return Pty{master_fd, slave_fd}, true
}

close_pty :: proc(pty: Pty) {
	os.close(pty.master_fd)
	os.close(pty.slave_fd)
}
