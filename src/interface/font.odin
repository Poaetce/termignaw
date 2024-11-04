package interface

import "core:os"
import "core:strings"
import "vendor:raylib"

//---------
// general font related types
//---------

// variant of a font
Font_Variant :: enum u8 {
	Normal,
	Bold,
	Italic,
	Bold_Italic,
}

//---------
// <Font_Info> - font and text related data and information
//---------

Font_Info :: struct {
	name: cstring,						// filename of the font
	data: []u8,							// raw font data
	font: raylib.Font,					// loaded raylib font data
	loaded_characters: [dynamic]rune,	// currently loaded characters
}

create_font_info :: proc(font_name: string) -> (font_info: ^Font_Info, success: bool) {
	font_info = new(Font_Info)

	// read the data from the font file
	font_info.data, success = os.read_entire_file(font_name)
	if !success {
		free(font_info)
		return nil, false
	}

	// clone the font name as a cstring
	font_info.name = strings.clone_to_cstring(font_name)

	return font_info, true
}

destroy_font_info :: proc(font_info: ^Font_Info) {
	raylib.UnloadFont(font_info.font)
	delete(font_info.name)
	delete(font_info.data)
	delete(font_info.loaded_characters)

	free(font_info)
}

//---------
// <Font_Group> - a group of variants of a font
//---------

Font_Group :: struct {
	size: u16,					// size of the font
	variants: [4]^Font_Info,	// font variants
}

create_font_group :: proc(
	font_names: struct {
		normal: string,
		bold: string,
		italic: string,
		bold_italic: string,
	},
	text_size: u16,
) -> (font_group: Font_Group, success:bool) {
	font_group.size = text_size

	// transmute font_names struct to an array to be indexed
	font_names_array: [4]string = transmute([4]string)font_names

	// create Font_Info for each variant
	for _, index in Font_Variant {
		font_group.variants[index] = create_font_info(font_names_array[index]) or_return
	}

	return font_group, true
}

//---------
// general font related procedures
//---------

// destroys all variants of a font group
clear_font_group :: proc(font_group: Font_Group) {
	for _, index in Font_Variant {
		destroy_font_info(font_group.variants[index])
	}
}
