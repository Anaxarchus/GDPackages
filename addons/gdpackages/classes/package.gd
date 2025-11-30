@abstract
class_name Package extends Node

## Abstract base class for all loadable packages.
## [br][br]
## The Package class defines the lifecycle, structure, and communication
## hooks for every package in the modular package framework. Each package
## derives from this abstract base class and provides its own configuration,
## internal API, and event-handling logic.
## [br][br]
## A package represents a self contained module, backed by a package.json
## manifest, isolated source code, and an internal adapter script. Although
## the adapter is technically exposed as a public object, it is not part of
## the system’s public API. Instead, it serves solely as the bridge between
## the package’s internal files allowing code inside the package to communicate
## with external systems while keeping the package source strictly isolated.
## [br][br]
## The package lifecycle includes loading, readiness, and unloading, all of
## which can be customized by implementing the abstract callbacks defined here.
## Packages also participate in the system wide event propagation network,
## receiving messages, warnings, and errors distributed by other packages
## or the manager.
## [br][br]
## This abstract class ensures that all packages follow a consistent structural
## pattern while maintaining strict modular boundaries. The package interacts with
## the outside world only through its adapter, and the rest of the system interacts
## with the package only through the message propagation system.


## This packages manifest, found at `package.json`.
@export var _config: Dictionary

## Called if this package is loaded, after the scene tree has already readied.
@abstract func _loaded() -> void

## Called if this package is unloaded.
@abstract func _unloaded() -> void

## Message propagation hook.
@abstract func _message(identity: String, message: String) -> void

## Warning propagation hook.
@abstract func _warning(identity: String, message: String) -> void

## Error propagation hook. Package should return true if it handles the error.
## Handled errors will repropagate as a handled error.
## Unhandled errors will repropagate as an unhandled error.
@abstract func _error(identity: String, message: String) -> bool
@abstract func _unhandled_error(identity: String, message: String) -> void
@abstract func _handled_error(identity: String, message: String) -> void

func config_get_name() -> String:
    return _config.get("name", "")

func config_get_version() -> String:
    return _config.get("version", "0.0")

func config_get_description() -> String:
    return _config.get("description", "")

## Propagates a message to all packages.
func emit_message(message: String, identity: String = config_get_name()) -> void:
    PackageManager.emit_message(identity, message)

## Propagates a message to all packages in the same group.
func emit_group_message(message: String, identity: String = config_get_name()) -> void:
    for group in PackageManager.get_groups_with_package(config_get_name()):
        PackageManager.emit_message_to_group(identity, message, group)

## Propagates a warning message to all packages.
func emit_warning(message: String, identity: String = config_get_name()) -> void:
    PackageManager.emit_warning(identity, message)

## Propagates a warning message to all packages in the same group.
func emit_group_warning(message: String, identity: String = config_get_name()) -> void:
    for group in PackageManager.get_groups_with_package(config_get_name()):
        PackageManager.emit_warning_to_group(identity, message, group)

## Propagates an error message to all packages.
func emit_error(message: String, identity: String = config_get_name()) -> void:
    PackageManager.emit_error(identity, message)

## Propagates an error message to all packages in the same group.
func emit_group_error(message: String, identity: String = config_get_name()) -> void:
    for group in PackageManager.get_groups_with_package(config_get_name()):
        PackageManager.emit_error_to_group(identity, message, group)

## Convenience wrapper for arbitrary logging.
func log_entry(identity: String, message: String, stack: Array[Dictionary] = []) -> void:
    PackageLogger.log_entry(PackageLogger.EntryType.None, identity, message, stack)
