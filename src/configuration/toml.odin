package configuration

foreign import "lib/libtoml.a"

TomlDatum :: struct {
	ok: bool,
	u: struct #raw_union {
		s: cstring,
		b: bool,
		i: i64,
		d: f64,
	}
}

TomlKeyval :: struct {
	key: cstring,
	val: cstring,
}

TomlArritem :: struct {
	valtype: i32,
	val: cstring,
	arr: ^TomlArray,
	tab: ^TomlTable,
}

TomlArray :: struct {
	key: cstring,
	kind: i32,
	type: i32,
	nitem: i32,
	item: [^]TomlArritem,
}

TomlTable :: struct {
	key: cstring,
	implicit: bool,
	readonly: bool,
	nkval: i32,
	kval: [^]^TomlKeyval,
	narr: i32,
	arr: [^]^TomlArray,
	ntab: i32,
	tab: [^]^TomlTable,
}

foreign libtoml {
	toml_parse :: proc(conf: cstring, errbuf: [^]rune, errbufsz: i32) -> (^TomlTable) ---
	toml_free :: proc(tab: ^TomlTable) ---
	toml_key_exists :: proc(tab: ^TomlTable, key: cstring) -> (bool) ---
	toml_table_in :: proc(tab: ^TomlTable, key: cstring) -> (^TomlTable) ---
	toml_string_in :: proc(tab: ^TomlTable, key: cstring) -> (TomlDatum) ---
	toml_bool_in :: proc(tab: ^TomlTable, key: cstring) -> (TomlDatum) ---
	toml_int_in :: proc(tab: ^TomlTable, key: cstring) -> (TomlDatum) ---
}
