@tool
extends ConfirmationDialog

signal create(pkg_path: String, pkg_name: String, pkg_version: String, pkg_desc: String)

func clear() -> void:
    %PackagePathEdit.text = ""
    %PackageNameEdit.text = ""
    %PackageVersion.text = "v1.0"
    %PackageDescription.text = ""
    %ErrorMessage.text = ""
    %ErrorMessage.hide()

func set_package_path(path: String) -> void:
    %PackagePathEdit.text = path

func set_error_message(message: String) -> void:
    %ErrorMessage.text = "[color=red]" + message + "[/color]"
    %ErrorMessage.show()

func _ready() -> void:
    confirmed.connect(_on_create_button_pressed)
    canceled.connect(_on_cancel_button_pressed)

func _on_cancel_button_pressed() -> void:
    clear()
    self.hide()

func _on_create_button_pressed() -> void:
    var pkg_name: String = %PackageNameEdit.text.strip_edges().to_snake_case()

    if pkg_name.is_empty():
        set_error_message("Invalid package name.")
        return

    var pkg_path: String = %PackagePathEdit.text.strip_edges()

    var exists: bool = DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(pkg_path.path_join(pkg_name)))
    if exists:
        set_error_message("Package cannot overwrite existing directory.")
        return

    var vers: String = %PackageVersion.text.strip_edges()
    var desc: String = %PackageDescription.text.strip_edges()
    create.emit(pkg_path, pkg_name, vers, desc)
    clear()
    self.hide()
