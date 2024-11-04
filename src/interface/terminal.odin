package interface

//---------
// <Window> - terminal window information
//---------

Window :: struct {
	title: string,
	dimensions: Window_Vector,
	padding: Window_Vector,
}

//---------
// <Terminal> - main terminal structure
//---------

Terminal :: struct {
	window: Window,
	grid: ^Grid,
	font_group: Font_Group,
}

create_terminal :: proc(
	title: string,
	dimensions: Window_Vector,
	font_names: struct {
		normal: string,
		bold: string,
		italic: string,
		bold_italic: string,
	},
	text_size: u16,
	padding: Window_Vector,
) -> (terminal: ^Terminal, success: bool) {
	terminal = new(Terminal)

	terminal.window.title = title
	terminal.window.dimensions = dimensions
	terminal.window.padding = padding

	terminal.font_group, success = create_font_group(font_names, text_size)
	if !success {
		free(terminal)
		return nil, false
	}

	terminal.grid = create_grid(dimensions, text_size, padding)

	return terminal, true
}

destroy_terminal :: proc(terminal: ^Terminal) {
	destroy_grid(terminal.grid)

	clear_font_group(terminal.font_group)

	free(terminal)
}
