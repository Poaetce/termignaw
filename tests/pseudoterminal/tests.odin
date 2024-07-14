package test_pseudoterminal

import "core:testing"

import "../../src/pseudoterminal"

@(test)
test_set_up_pty :: proc(t: ^testing.T) {
	pty: pseudoterminal.Pty
	success: bool
	pty, success = pseudoterminal.set_up_pty()

	testing.expect(t, success)

	if !success {return}
	pseudoterminal.close_pty(pty)
}

@(test)
test_set_non_blocking :: proc(t: ^testing.T) {
	pty: pseudoterminal.Pty
	success: bool
	pty, success = pseudoterminal.set_up_pty()
	if !success {return}
	defer pseudoterminal.close_pty(pty)

	success = pseudoterminal.set_non_blocking(pty)
	testing.expect(t, success)
}

@(test)
test_start_shell :: proc(t: ^testing.T) {
	pty: pseudoterminal.Pty
	success: bool
	pty, success = pseudoterminal.set_up_pty()
	if !success {return}
	defer pseudoterminal.close_pty(pty)

	_, success = pseudoterminal.start_shell(pty, "/bin/sh")
	testing.expect(t, success)
}
