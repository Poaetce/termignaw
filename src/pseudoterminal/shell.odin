package pseudoterminal

import "core:os"
import "core:os/os2"
import "core:strings"
import "core:sys/linux"

start_shell :: proc(pty: Pty, shell_name: string) -> (process_id: linux.Pid, success: bool) {
	error: linux.Errno
	process_id, error = linux.fork()
	if error != nil {return 0, false}

	if process_id == 0 {
		linux.setsid()

		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdin))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stdout))
		linux.dup2(linux.Fd(pty.slave_fd), linux.Fd(os.stderr))

		environment: [dynamic]cstring
		for element in os2.environ(context.allocator) {
			append(&environment, strings.clone_to_cstring(element))
		}

		shell_name_cstring: cstring = strings.clone_to_cstring(shell_name)

		linux.execve(
			shell_name_cstring,
			raw_data([]cstring{shell_name_cstring, nil}),
			raw_data(environment[:])
		)
	}

	return process_id, true
}
