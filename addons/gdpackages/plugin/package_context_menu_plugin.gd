@tool
extends EditorContextMenuPlugin

signal pressed

func _popup_menu(paths: PackedStringArray) -> void:
    add_context_menu_item("Package", pressed.emit)
