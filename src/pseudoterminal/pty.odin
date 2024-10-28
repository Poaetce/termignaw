package pseudoterminal

import "core:os"
import "core:os/os2"
import "core:strings"
import "core:sys/linux"
import "core:unicode/utf8"

foreign import "system:c"
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

// sets the master device to non-blocking
set_non_blocking :: proc(pty: Pty) -> (success: bool) {
	if linux.fcntl_setfl(
		linux.Fd(pty.master_fd),
		linux.F_SETFL,
		{linux.Open_Flags_Bits.NONBLOCK},
	) != nil {return false}

	return true
}

// starts and attaches a child process (shell) to the slave device
start_shell :: proc(pty: Pty, shell_name: string) -> (process_id: linux.Pid, success: bool) {
	// fork process
	error: linux.Errno
	process_id, error = linux.fork()
	if error != nil {return 0, false}

	if process_id == 0 {
		// create new session group
		error: linux.Errno
		process_id, error = linux.setsid()
		if error != nil {return 0, false}

		// redirect the standard streams to the slave device
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdin))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdout))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stderr))

		// retrieve the environment as cstrings
		environment_strings: []string = os2.environ(context.allocator)
		defer delete(environment_strings)
		environment: []cstring = make([]cstring, len(environment_strings))
		defer delete(environment)
		for element, index in environment_strings {
			element_cstring: cstring = strings.clone_to_cstring(element)
			environment[index] = element_cstring
		}

		// clone the shell name as a cstring
		shell_name_cstring: cstring = strings.clone_to_cstring(shell_name)
		defer delete(shell_name_cstring)

		// execute the shell
		if linux.execve(
			shell_name_cstring,
			raw_data([]cstring{shell_name_cstring, nil}),
			raw_data(environment),
		) != nil {return 0, false}
	}

	return process_id, true
}

// writes a charater to the pseudoterminal
write_character :: proc(character: rune, pty: Pty) {
	// encode the character into bytes
	bytes: [4]u8
	size: int
	bytes, size = utf8.encode_rune(character)

	// writes bytes to the master device
	os.write(pty.master_fd, bytes[:size])
}
