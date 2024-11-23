package configuration

import "core:encoding/hex"
import "core:fmt"
import "core:os"
import "core:strings"

//---------
// reading related procedures
//---------

read_config :: proc() -> (config: Config, error: Error) {
	config_name: string = fmt.aprintf("{}/termignaw.toml", CONFIG_DIRECTORY)
	defer delete(config_name)

	table: ^Toml_Table = read_and_parse_toml(config_name) or_return

	if !toml_key_exists(table, "appearance") {return Config{}, Config_Error.Option_Nonexistent}
	appearance_table: ^Toml_Table = toml_table_in(table, "appearance")

	if !toml_key_exists(appearance_table, "theme") {
		return Config{}, Config_Error.Option_Nonexistent
	}

	theme_name: string = fmt.aprintf(
		"{}/{}",
		CONFIG_DIRECTORY,
		string(toml_string_in(appearance_table, "theme").u.s)
	)
	defer delete(theme_name)

	config.appearance.theme = read_theme(theme_name) or_return

	if !toml_key_exists(table, "font") {return Config{}, Config_Error.Option_Nonexistent}
	font_table: ^Toml_Table = toml_table_in(table, "font")

	if !toml_key_exists(font_table, "normal") {return Config{}, Config_Error.Option_Nonexistent}
	config.font.normal = string(toml_string_in(font_table, "normal").u.s)

	if !toml_key_exists(font_table, "bold") {config.font.bold = config.font.normal}
	else {config.font.bold = string(toml_string_in(font_table, "bold").u.s)}

	if !toml_key_exists(font_table, "italic") {config.font.italic = config.font.normal}
	else {config.font.italic = string(toml_string_in(font_table, "italic").u.s)}

	if !toml_key_exists(font_table, "bold_italic") {config.font.bold_italic = config.font.normal}
	else {config.font.bold_italic = string(toml_string_in(font_table, "bold_italic").u.s)}

	if !toml_key_exists(font_table, "size") {return Config{}, Config_Error.Option_Nonexistent}
	config.font.size = u16(toml_int_in(font_table, "size").u.i)

	if !toml_key_exists(table, "window") {return Config{}, Config_Error.Option_Nonexistent}
	window_table: ^Toml_Table = toml_table_in(table, "window")

	if !toml_key_exists(window_table, "title") {config.window.title = "Termignaw"}
	else {config.window.title = string(toml_string_in(window_table, "title").u.s)}

	if !toml_key_exists(window_table, "dimensions") {
		return Config{}, Config_Error.Option_Nonexistent
	}
	config.window.dimensions.x = u32(toml_int_in(
		toml_table_in(window_table, "dimensions"),
		"x",
	).u.i)
	config.window.dimensions.y = u32(toml_int_in(
		toml_table_in(window_table, "dimensions"),
		"y",
	).u.i)

	if !toml_key_exists(window_table, "padding") {
		return Config{}, Config_Error.Option_Nonexistent
	}
	config.window.padding.x = u32(toml_int_in(
		toml_table_in(window_table, "padding"),
		"x",
	).u.i)
	config.window.padding.y = u32(toml_int_in(
		toml_table_in(window_table, "padding"),
		"y",
	).u.i)

	if !toml_key_exists(table, "general") {return Config{}, Config_Error.Option_Nonexistent}
	general_table: ^Toml_Table = toml_table_in(table, "general")

	if !toml_key_exists(general_table, "shell") {return Config{}, Config_Error.Option_Nonexistent}
	config.general.shell = string(toml_string_in(general_table, "shell").u.s)

	return config, nil
}

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
