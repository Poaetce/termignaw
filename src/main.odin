package main

foreign import "system:c"

foreign c {
	posix_openpt :: proc(flags: int) -> int ---
	grantpt :: proc(file_descriptor: int) -> int ---
	unlockpt :: proc(file_descriptor: int) -> int ---
	ptsname :: proc(file_descriptor: int) -> cstring ---
}

main :: proc() {
}
