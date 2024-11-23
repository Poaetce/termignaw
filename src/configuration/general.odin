package configuration

import "core:encoding/hex"
import "core:os"
import "core:strings"

//---------
// reading related procedures
//---------

@(private)
read_theme :: proc(theme_name: string) -> (theme: Theme, error: Error) {
	data: []u8;
	success: bool;
	data, success = os.read_entire_file(theme_name)
	if !success {return Theme{}, General_Error.Unable_To_Read_File}

	data_cstring: cstring = strings.clone_to_cstring(string(data))

	table: ^TomlTable = toml_parse(data_cstring, nil, 0)
	if table == nil {return Theme{}, Parsing_Error.Cannot_Parse_Table}

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
		if !toml_key_exists(table, option) {
			return {}, Config_Error.Option_Nonexistent
		}

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
