package interface

import "vendor:raylib"

//---------
// <Cursor> - cursor information and state
//---------

Cursor :: struct {
	position: Grid_Vector,			// cursor position
	foreground_color: raylib.Color,	// current foreground color
	background_color: raylib.Color,	// current background color
	font_variant: Font_Variant,		// current font variant
}

create_cursor :: proc() -> (cursor: ^Cursor) {
	cursor = new(Cursor)

	// set cursor to default values
	cursor.foreground_color = raylib.BLACK
	cursor.background_color = raylib.WHITE
	cursor.font_variant = Font_Variant.Normal

	return cursor
}
