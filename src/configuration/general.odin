package configuration

import "core:encoding/hex"
import "core:os"
import "core:strings"

//---------
// reading related procedures
//---------

@(private)
read_theme :: proc(theme_name: string) -> (theme: Theme, error: Error) {
	table: ^Toml_Table = read_and_parse_toml(theme_name) or_return

	theme_array: [18]Color
	theme_options := [18]cstring{
		"foreground",
		"background",
		"black",
		"red",
		"green",
		"yellow",
		"blue",
		"magenta",
		"cyan",
		"white",
		"bright_black",
		"bright_red",
		"bright_green",
		"bright_yellow",
		"bright_blue",
		"bright_magenta",
		"bright_cyan",
		"bright_white",
	}

	for option, index in theme_options {
		if !toml_key_exists(table, option) {return Theme{}, Config_Error.Option_Nonexistent}

		success: bool
		theme_array[index], success = decode_color(string(toml_string_in(table, option).u.s))
		if !success {return Theme{}, Parsing_Error.Cannot_Decode_Color}
	}

	return transmute(Theme)theme_array, nil
}

//---------
// other general config related procedures
//---------

@(private)
decode_color :: proc(hex_code: string) -> (color: Color, success: bool) {
	return Color{
		hex.decode_sequence(hex_code[1:3]) or_return,
		hex.decode_sequence(hex_code[3:5]) or_return,
		hex.decode_sequence(hex_code[5:7]) or_return,
	}, true
}

@(private)
read_and_parse_toml :: proc(filename: string) -> (table: ^Toml_Table, error: Error) {
	data: []u8
	success: bool
	data, success = os.read_entire_file(filename)
	if !success {return nil, General_Error.Unable_To_Read_File}
	defer delete(data)

	data_cstring: cstring = strings.clone_to_cstring(string(data))
	defer delete(data_cstring)

	table = toml_parse(data_cstring, nil, 0)
	if table == nil {return nil, Parsing_Error.Cannot_Parse_Table}

	return table, nil
}
