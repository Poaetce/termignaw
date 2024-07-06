package pseudoterminal

import "core:os"
import "core:os/os2"
import "core:strings"
import "core:sys/linux"

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

set_non_blocking :: proc(pty: Pty) -> (success: bool) {
	if linux.fcntl_setfl(
		linux.Fd(pty.master_fd),
		linux.F_SETFL,
		{linux.Open_Flags_Bits.NONBLOCK}
	) != nil {return false}

	return true
}

start_shell :: proc(pty: Pty, shell_name: string) -> (process_id: linux.Pid, success: bool) {
	error: linux.Errno
	process_id, error = linux.fork()
	if error != nil {return 0, false}

	if process_id == 0 {
		error: linux.Errno
		process_id, error = linux.setsid()
		if error != nil {return 0, false}

		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdin))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdout))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stderr))

		environment: [dynamic]cstring
		for element in os2.environ(context.allocator) {
			append(&environment, strings.clone_to_cstring(element))
		}

		shell_name_cstring: cstring = strings.clone_to_cstring(shell_name)

		if linux.execve(
			shell_name_cstring,
			raw_data([]cstring{shell_name_cstring, nil}),
			raw_data(environment[:])
		) != nil {return 0, false}
	}

	return process_id, true
}
