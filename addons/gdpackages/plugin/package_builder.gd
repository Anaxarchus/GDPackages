@tool
extends EditorPlugin

const PackageCreateDialog = preload("package_create_dialog.tscn")
const PackageContextMenuPlugin = preload("package_context_menu_plugin.gd")

var dialog: ConfirmationDialog
var ctx: EditorContextMenuPlugin
var last_file_path: String

func _enter_tree():
    dialog = PackageCreateDialog.instantiate()
    dialog.create.connect(_on_package_created)
    ctx = PackageContextMenuPlugin.new()
    ctx.pressed.connect(_on_create_package_pressed)
    add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM_CREATE, ctx)

func _exit_tree() -> void:
    remove_context_menu_plugin(ctx)

func _new_package_config(pkg_name: String, pkg_vers: String, pkg_desc: String) -> Dictionary:
    return {
        "name": pkg_name,
        "version": pkg_vers,
        "description": pkg_desc,
        "script": pkg_name + ".gd"
    }

func _new_package_script(pkg_name: String, pkg_desc: String) -> String:
    var result: String = "extends Package # " + pkg_name
    result += "\n\n## " + pkg_desc

    result += "\n\n## This packages adapter."
    result += "\nconst Adapter = preload(\"" + pkg_name + "_adapter.gd\")"

    result += "\n\n## Called when the package is loaded, after the entire scene tree has initialized."
    result += "\nfunc _loaded() -> void:"
    result += "\n\temit_message(\"loaded successfully.\")"

    result += "\n\n## Called if the package is ever unloaded at runtime."
    result += "\nfunc _unloaded() -> void:"
    result += "\n\temit_message(\"unloaded successfully.\")"

    result += "\n\n## Message propagation hook."
    result += "\nfunc _message(_identity: String, _msg: String) -> void:\n\tpass"

    result += "\n\n## Warning propagation hook."
    result += "\nfunc _warning(_identity: String, _msg: String) -> void:\n\tpass"

    result += "\n\n## Error propagation hook, return true if the error is handled."
    result += "\nfunc _error(_identity: String, _msg: String) -> bool:\n\treturn false"

    result += "\n\n## Unhandled Error propagation hook, gets called if an error passes through all packages unhandled."
    result += "\nfunc _unhandled_error(_identity: String, _msg: String) -> void:\n\tpass"

    result += "\n\n## Handled Error propagation hook, gets called if an error gets handled by a package."
    result += "\nfunc _handled_error(_identity: String, _msg: String) -> void:\n\tpass"
    return result

func _on_create_package_pressed(option: PackedStringArray):
    if option.is_empty():
        return
    var parent = dialog.get_parent()
    if parent:
        parent.remove_child(dialog)
    EditorInterface.popup_dialog_centered(dialog,Vector2i(500, 300))
    dialog.set_package_path(option[0])

func _on_package_created(package_path: String, package_name: String, package_version: String, package_desc: String) -> void:
    print("creating package: ", package_name)
    print("at path: ", package_path)

    var dir := DirAccess.open(package_path)
    if dir.get_open_error() == OK:
        dir.make_dir(package_name)

    var path: String = package_path.path_join(package_name)
    var config: Dictionary = _new_package_config(package_name, package_version, package_desc)
    var config_string: String = JSON.stringify(config, "    ")

    var file := FileAccess.open(path.path_join("package.json"), FileAccess.WRITE)
    if FileAccess.get_open_error() == OK:
        file.store_string(config_string)
        file.close()
    else:
        push_error("[PackageBuilderPlugin] failed to create package config file, open error: ", FileAccess.get_open_error())

    file = FileAccess.open(path.path_join(package_name + ".gd"), FileAccess.WRITE)
    if FileAccess.get_open_error() == OK:
        file.store_string(_new_package_script(package_name, package_desc))
        file.close()
    else:
        push_error("[PackageBuilderPlugin] failed to create package main script, open error: ", FileAccess.get_open_error())

    file = FileAccess.open(path.path_join(package_name + "_adapter.gd"), FileAccess.WRITE)
    if FileAccess.get_open_error() == OK:
        file.store_string("extends PackageAdapter")
        file.close()
    else:
        push_error("[PackageBuilderPlugin] failed to create package adapter script, open error: ", FileAccess.get_open_error())

    dir.make_dir(path.path_join("src"))

    get_editor_interface().get_resource_filesystem().scan()
