extends Package # example

## An example package.

## Packages only interact with the rest of the application via their adapter script.
## Nothing should ever call to the package, but packages may react to messages sent
## via PackageManager.emit_message("Dad", "Are you winning, son?"). I would caution
## AGAINST strong dependence on these messages, as it undermines the entire pattern.
##
## To best use this pattern, partner it with a provider or service layer within your
## application to interface with the scene tree and use Godot's built in servers where applicable.
##
## Packages have a convenience layer for the event busses which automatically handle identity
## insertion. self.emit_message("Hello") -> PackageManager.emit_message(self.config_get_name(), "Hello")
##
## The PackageLogger is configurable. See its documentation for useage.

## This packages adapter.
const Adapter = preload("example_adapter.gd")

## Called when the package is loaded, after the entire scene tree has initialized.
func _loaded() -> void:
    emit_message("loaded successfully.")
    Adapter.say_hello()

## Called if the package is ever unloaded at runtime.
func _unloaded() -> void:
    Adapter.say_goodbye()
    emit_message("unloaded successfully.")

## Message propagation hook.
func _message(_identity: String, _msg: String) -> void:
    pass

## Warning propagation hook.
func _warning(_identity: String, _msg: String) -> void:
    pass

## Error propagation hook, return true if the error is handled.
func _error(_identity: String, _msg: String) -> bool:
    return false

## Unhandled Error propagation hook, gets called if an error passes through all packages unhandled.
func _unhandled_error(_identity: String, _msg: String) -> void:
    pass

## Handled Error propagation hook, gets called if an error gets handled by a package.
func _handled_error(_identity: String, _msg: String) -> void:
    pass
