package pseudoterminal

import "core:os"

foreign import "system:c"

@(private)
foreign c {
	posix_openpt :: proc(flags: i32) -> (i32) ---
	grantpt :: proc(fd: i32) -> (i32) ---
	unlockpt :: proc(fd: i32) -> (i32) ---
	ptsname :: proc(fd: i32) -> (cstring) ---
}

// file descriptors for the opened pseudoterminal devices
Pty :: struct {
	master_fd: os.Handle,
	slave_fd: os.Handle,
}

// opens and sets up the pseudoterminal device pair
set_up_pty :: proc() -> (pty: Pty, success: bool) {
	// open the master device
	master_fd_i32: i32 = posix_openpt(os.O_RDWR)
	if master_fd_i32 == -1 {return Pty{}, false}

	master_fd := os.Handle(master_fd_i32)

	// grant access to the slave device
	if grantpt(master_fd_i32) == -1 {
		os.close(master_fd)
		return Pty{}, false
	}

	// unlock the slave device
	if unlockpt(master_fd_i32) == -1 {
		os.close(master_fd)
		return Pty{}, false
	}

	// get the name of the slave device
	slave_name := string(ptsname(master_fd_i32))
	if slave_name == "" {
		os.close(master_fd)
		return Pty{}, false
	}

	// open the slave device
	slave_fd: os.Handle
	error: os.Errno
	slave_fd, error = os.open(slave_name, os.O_RDWR)
	if error != 0 {
		os.close(master_fd)
		return Pty{}, false
	}

	return Pty{master_fd, slave_fd}, true
}

// closes both pseudoterminal devices
close_pty :: proc(pty: Pty) {
	os.close(pty.master_fd)
	os.close(pty.slave_fd)
}
