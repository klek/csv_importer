@tool
extends EditorImportPlugin

const PLUGIN_NAME : String = "CSV Importer"
const PLUGIN_UNIQUE_NAME : String = "csv_importer"


# 
enum Presets {
    DEFAULT,
}

# Supported delimiters
enum Delimiters {
    COMMA,
    TAB,
    SEMICOLON,
}

func _get_importer_name() -> String:
    return PLUGIN_UNIQUE_NAME


func _get_visible_name() -> String:
    return PLUGIN_NAME


func _get_priority() -> float:
    return 2.0


func _get_import_order() -> int:
    return 0


func _get_recognized_extensions() -> PackedStringArray:
    return ["csv", "tsv"]


func _get_save_extension() -> String:
    return "res"


func _get_resource_type() -> String:
    # TODO(klek): What resource type should we return
    return "Resource"


func _get_preset_count() -> int:
    return Presets.size()


func _get_preset_name(preset_index: int) -> String:
    match preset_index:
        Presets.DEFAULT:
            return "Comma separated value with headers"
        _:
            return "Unknown"


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
    var delim : int = Delimiters.COMMA
    var headers : bool = false
    match preset_index:
        # NOTE(klek): We don't handle regular CSV, because it is the defaults
        Presets.DEFAULT:
            delim = Delimiters.COMMA
            headers = true
    return [
        { name="delimiter", default_value=delim, property_hint=PROPERTY_HINT_ENUM, hint_string="Comma,Tab,Semicolon" },
        { name="headers", default_value=headers, usage=PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED },
    ]


func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
    return true


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
    return OK
