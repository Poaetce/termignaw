package interface

import "vendor:raylib"

// cursor state
Cursor :: struct {
	position: Grid_Vector,
	foreground_color: raylib.Color,
	background_color: raylib.Color,
	font_variant: Font_Variant,
}

create_cursor :: proc() -> (cursor: ^Cursor) {
	cursor = new(Cursor)

	// set cursor to default values
	cursor.foreground_color = raylib.BLACK
	cursor.background_color = raylib.WHITE
	cursor.font_variant = Font_Variant.Normal

	return cursor
}
