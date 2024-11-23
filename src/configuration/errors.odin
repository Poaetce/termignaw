package configuration

//---------
// configuration error types
//---------

Error :: union #shared_nil {
	General_Error,
	Parsing_Error,
	Config_Error,
}

General_Error :: enum {
	None = 0,
	Unable_To_Read_File,
}

Parsing_Error :: enum {
	None = 0,
	Cannot_Parse_Table,
	Cannot_Decode_Color,
}

Config_Error :: enum {
	None = 0,
	Option_Nonexistent,
}
