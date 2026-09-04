@tool
extends EditorPlugin

var import_plugin = null

func _enable_plugin() -> void:
    # Add autoloads here.
    pass


func _disable_plugin() -> void:
    # Remove autoloads here.
    pass


func _enter_tree() -> void:
    # Initialization of the plugin goes here.
    import_plugin = preload("csv_import.gd").new()
    add_import_plugin( import_plugin )


func _exit_tree() -> void:
    # Clean-up of the plugin goes here.
    remove_import_plugin( import_plugin )
    import_plugin = null
