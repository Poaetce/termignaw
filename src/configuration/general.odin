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
	defer toml_free(table)

	ensure_key_exists(table, "appearance") or_return
	config.appearance = read_appearance_table(toml_table_in(table, "appearance")) or_return

	ensure_key_exists(table, "font") or_return
	config.font = read_font_table(toml_table_in(table, "font")) or_return

	ensure_key_exists(table, "window") or_return
	config.window = read_window_table(toml_table_in(table, "window")) or_return

	ensure_key_exists(table, "general") or_return
	config.general = read_general_table(toml_table_in(table, "general")) or_return
	general_table: ^Toml_Table = toml_table_in(table, "general")

	return config, nil
}

@(private)
read_appearance_table :: proc(table: ^Toml_Table) -> (result: Appearance_Table, error: Error) {
	ensure_key_exists(table, "theme") or_return

	theme_name: string = fmt.aprintf(
		"{}/{}",
		CONFIG_DIRECTORY,
		string(toml_string_in(table, "theme").u.s)
	)
	defer delete(theme_name)

	result.theme = read_theme(theme_name) or_return

	return result, nil
}

@(private)
read_font_table :: proc(table: ^Toml_Table) -> (result: Font_Table, error: Error) {
	ensure_key_exists(table, "normal") or_return
	result.normal = string(toml_string_in(table, "normal").u.s)

	if !toml_key_exists(table, "bold") {result.bold = result.normal}
	else {result.bold = string(toml_string_in(table, "bold").u.s)}

	if !toml_key_exists(table, "italic") {result.italic = result.normal}
	else {result.italic = string(toml_string_in(table, "italic").u.s)}

	if !toml_key_exists(table, "bold_italic") {result.bold_italic = result.normal}
	else {result.bold_italic = string(toml_string_in(table, "bold_italic").u.s)}

	ensure_key_exists(table, "size") or_return
	result.size = u16(toml_int_in(table, "size").u.i)

	return result, nil
}

@(private)
read_window_table :: proc(table: ^Toml_Table) -> (result: Window_Table, error: Error) {
	if !toml_key_exists(table, "title") {result.title = "Termignaw"}
	else {result.title = string(toml_string_in(table, "title").u.s)}

	ensure_key_exists(table, "dimensions") or_return
	result.dimensions.x = u32(toml_int_in(
		toml_table_in(table, "dimensions"),
		"x",
	).u.i)
	result.dimensions.y = u32(toml_int_in(
		toml_table_in(table, "dimensions"),
		"y",
	).u.i)

	ensure_key_exists(table, "padding") or_return
	result.padding.x = u32(toml_int_in(
		toml_table_in(table, "padding"),
		"x",
	).u.i)
	result.padding.y = u32(toml_int_in(
		toml_table_in(table, "padding"),
		"y",
	).u.i)

	return result, nil
}

@(private)
read_general_table :: proc(table: ^Toml_Table) -> (result: General_Table, error: Error) {
	ensure_key_exists(table, "shell") or_return
	result.shell = string(toml_string_in(table, "shell").u.s)

	return result, nil
}

@(private)
read_theme :: proc(theme_name: string) -> (theme: Theme, error: Error) {
	table: ^Toml_Table = read_and_parse_toml(theme_name) or_return
	defer toml_free(table)

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
		ensure_key_exists(table, option) or_return

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
		255,
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

@(private)
ensure_key_exists :: proc(table: ^Toml_Table, key: cstring) -> (Config_Error)
{
	if !toml_key_exists(table, key) {return Config_Error.Option_Nonexistent}
	return nil
}
