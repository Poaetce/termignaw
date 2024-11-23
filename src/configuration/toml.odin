package configuration

foreign import "lib/libtoml.a"

Toml_Datum :: struct {
	ok: bool,
	u: struct #raw_union {
		s: cstring,
		b: bool,
		i: i64,
		d: f64,
	}
}

Toml_Keyval :: struct {
	key: cstring,
	val: cstring,
}

Toml_Arritem :: struct {
	valtype: i32,
	val: cstring,
	arr: ^Toml_Array,
	tab: ^Toml_Table,
}

Toml_Array :: struct {
	key: cstring,
	kind: i32,
	type: i32,
	nitem: i32,
	item: [^]Toml_Arritem,
}

Toml_Table :: struct {
	key: cstring,
	implicit: bool,
	readonly: bool,
	nkval: i32,
	kval: [^]^Toml_Keyval,
	narr: i32,
	arr: [^]^Toml_Array,
	ntab: i32,
	tab: [^]^Toml_Table,
}

foreign libtoml {
	toml_parse :: proc(conf: cstring, errbuf: [^]rune, errbufsz: i32) -> (^Toml_Table) ---
	toml_free :: proc(tab: ^Toml_Table) ---
	toml_key_exists :: proc(tab: ^Toml_Table, key: cstring) -> (bool) ---
	toml_table_in :: proc(tab: ^Toml_Table, key: cstring) -> (^Toml_Table) ---
	toml_string_in :: proc(tab: ^Toml_Table, key: cstring) -> (Toml_Datum) ---
	toml_bool_in :: proc(tab: ^Toml_Table, key: cstring) -> (Toml_Datum) ---
	toml_int_in :: proc(tab: ^Toml_Table, key: cstring) -> (Toml_Datum) ---
}
