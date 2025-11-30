extends Control

func _ready() -> void:
    # automatically forms a group under the given directory.
    PackageManager.load_packages_in_directory("res://addons/package_builder/example/packages")

    if PackageManager.has_package("example"):
        # packages can be members of multiple groups
        PackageManager.add_package_to_group("example", "MyGroup")
        PackageManager.emit_message_to_group("Main", "Hello, MyGroup!", "MyGroup")

    PackageManager.unload_packages_in_group("res://addons/package_builder/example/packages")

    # see PackageManager for useage.
