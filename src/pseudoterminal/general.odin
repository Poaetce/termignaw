package pseudoterminal

import "core:os"
import "core:os/os2"
import "core:strings"
import "core:sys/linux"
import "core:unicode/utf8"

//---------
// general pseudoterminal procedures
//---------

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
start_shell :: proc(pty: Pty, shell_name: string) -> (process_id: linux.Pid, error: Error) {
	// fork process
	process_id = linux.fork() or_return

	if process_id == 0 {
		// create new session group
		process_id = linux.setsid() or_return

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
		linux.execve(
			shell_name_cstring,
			raw_data([]cstring{shell_name_cstring, nil}),
			raw_data(environment),
		) or_return
	}

	return process_id, nil
}

// writes a charater to the pseudoterminal
write_character :: proc(character: rune, pty: Pty) {
	// encode the character into bytes
	bytes: [4]u8
	size: int
	bytes, size = utf8.encode_rune(character)

	// write bytes to the master device
	os.write(pty.master_fd, bytes[:size])
}
