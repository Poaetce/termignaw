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
set_up_pty :: proc() -> (pty: Pty, error: Error) {
	// open the master device
	master_fd_i32: i32 = posix_openpt(os.O_RDWR)
	if master_fd_i32 == -1 {return Pty{}, Setup_Error.Unable_To_Open_Pseudoterminal}

	master_fd := os.Handle(master_fd_i32)

	// grant access to the slave device
	if grantpt(master_fd_i32) == -1 {
		os.close(master_fd)
		return Pty{}, Setup_Error.Unable_To_Grant_Slave_Access
	}

	// unlock the slave device
	if unlockpt(master_fd_i32) == -1 {
		os.close(master_fd)
		return Pty{}, Setup_Error.Unable_To_Unlock_Slave
	}

	// get the name of the slave device
	slave_name := string(ptsname(master_fd_i32))
	if slave_name == "" {
		os.close(master_fd)
		return Pty{}, Setup_Error.No_Slave_Name
	}

	// open the slave device
	slave_fd: os.Handle
	os_error: os.Error
	slave_fd, os_error = os.open(slave_name, os.O_RDWR)
	if os_error != nil {
		os.close(master_fd)
		return Pty{}, os_error
	}

	return Pty{master_fd, slave_fd}, nil
}

// closes both pseudoterminal devices
close_pty :: proc(pty: Pty) {
	os.close(pty.master_fd)
	os.close(pty.slave_fd)
}
