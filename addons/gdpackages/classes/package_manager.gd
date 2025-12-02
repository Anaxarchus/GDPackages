class_name PackageManager extends Node


## Global manager for package loading, grouping, and message propagation.
## [br][br]
## The PackageManager class serves as the central authority for discovering,
## loading, unloading, and coordinating packages within the project. It maintains
## a global registry of active packages, tracks package groups, and provides an
## interface for broadcasting messages, warnings, and errors across packages or
## to specific groups.
## [br][br]
## This class is designed to enforce project wide consistency in how packages are
## initialized, isolated, and interconnected. By delegating all high level
## orchestration to this singleton style API, packages remain modular and self
## contained while still being able to respond to events and errors emitted by the system.
## [br][br]
## All operations are static to make manager functionality globally accessible
## and consistent regardless of scene tree context. The manager does not execute
## package logic directly; it only manages lifecycle and communication channels.


## Global package registry in load order.
static var packages: Dictionary[String, Package]

## Package grouping system. Defaults to grouped by directory.
static var package_groups: Dictionary[String, PackedStringArray]

## Loads and parses the config file for the package in the given directory.
static func _get_package_config(directory: String) -> Dictionary:
    var path: String = directory.path_join("package.json")
    var text: String = FileAccess.get_file_as_string(path)
    if text.is_empty():
        return {}
    var parsed = JSON.parse_string(text)
    if parsed is Dictionary:
        return parsed
    else:
        return {}

## Loads and instantiates the entry script for the package.
static func _get_package_root(directory: String, config: Dictionary) -> Package:
    var path: String = directory.path_join(config.get("script", ""))
    var result = load(path).new()
    if result is Package:
        return result
    else:
        return null

## Returns whether or not a package by the given name exists.
static func has_package(package_name: String) -> bool:
    return package_name in packages

## Returns whether or not a group by the given name exists.
static func has_group(group_name: String) -> bool:
    return group_name in package_groups

## Returns all groups a given package is a member of.
static func get_groups_with_package(package_name: String) -> PackedStringArray:
    var result: PackedStringArray
    for group in package_groups.keys():
        if package_name in package_groups[group]:
            result.append(group)
    return result

## Adds the package with the given name to a group. Creates the group if it doesn't exist.
static func add_package_to_group(package_name: String, group: String) -> void:
    package_groups.get_or_add(group, PackedStringArray()).append(package_name)

## Removes the package with the given name from a group. Deletes the group if its member count reaches 0.
static func remove_package_from_group(package_name: String, group: String) -> void:
    if group in package_groups:
        var idx: int = package_groups[group].find(package_name)
        if idx > -1:
            package_groups[group].remove_at(idx)
            if package_groups[group].is_empty():
                package_groups.erase(group)

## Initializes the package at the given path.
static func load_package(directory: String, group: String = "") -> void:
    # load and validate config file.
    var config := _get_package_config(directory)
    if config.is_empty():
        push_error("error, package has no config.")
        return
    if !config.has("script"):
        push_error("error, package config is missing script.")
        return
    if !config.has("name"):
        push_error("error, package config is missing name.")
        return

    # load entry script.
    var root := _get_package_root(directory, config)
    if root == null:
        push_error("error, failed to load package script.")
        return

    # book keeping.
    var package_name: String = config.get("name", "")
    packages[package_name] = root
    if !group.is_empty():
        package_groups.get_or_add(group, PackedStringArray()).append(package_name)

    # life cycle stuff.
    root._config = config
    root._loaded()

## Initializes all packages in the given directory.
static func load_packages_in_directory(directory_path: String, group: String = directory_path) -> void:
    var dirs := DirAccess.get_directories_at(directory_path)
    for dir in dirs:
        load_package(directory_path.path_join(dir), group)

## Unloads the package with the given name.
static func unload_package(package_name: String) -> void:
    if package_name in packages:
        for group in get_groups_with_package(package_name):
            remove_package_from_group(package_name, group)
        packages[package_name]._unloaded()
        packages.erase(package_name)

## Unloads all the packages in the given group.
## By default, this will be the directory containing the package directories.
static func unload_packages_in_group(group: String) -> void:
    if group in package_groups:
        var names: PackedStringArray = package_groups[group].duplicate()
        for package_name in names:
            unload_package(package_name)

## Unloads all packages.
static func unload_all_packages() -> void:
    for package in packages.values():
        package._unloaded()
    packages.clear()
    package_groups.clear()

## Propagates a message to all packages
static func emit_message(identity: String, message: String) -> void:
    for package in packages.values():
        package._message(identity, message)
    PackageLogger.log_message(identity, message)

## Propagates a message to a specific group of packages.
static func emit_message_to_group(identity: String, message: String, group: String) -> void:
    for package in package_groups.get(group, []):
        packages[package]._message(identity, message)
    PackageLogger.log_message(identity + "@" + group, message)

## Propagates a warning to all packages.
static func emit_warning(identity: String, message: String) -> void:
    for package in packages.values():
        package._warning(identity, message)
    PackageLogger.log_warning(identity, message)

## Propagates a warning to a specific group of packages.
static func emit_warning_to_group(identity: String, message: String, group: String) -> void:
    for package in package_groups.get(group, []):
        packages[package]._warning(identity, message)
    PackageLogger.log_warning(identity + "@" + group, message)

## Propagates a handled error to all packages.
static func emit_handled_error(identity: String, message: String) -> void:
    for package in packages.values():
        package._handled_error(identity, message)
    PackageLogger.log_handled_error(identity, message)

## Propagates a handled error to a specific group of packages.
static func emit_handled_error_to_group(identity: String, message: String, group: String) -> void:
    for package in package_groups.get(group, []):
        packages[package]._handled_error(identity, message)
    PackageLogger.log_handled_error(identity + "@" + group, message)

## Propagates an unhandled error to all packages.
static func emit_unhandled_error(identity: String, message: String) -> void:
    for package in packages.values():
        package._unhandled_error(identity, message)
    PackageLogger.log_error(identity, message)

## Propagates an unhandled error to a specific group of packages.
static func emit_unhandled_error_to_group(identity: String, message: String, group: String) -> void:
    for package in package_groups.get(group, []):
        packages[package]._unhandled_error(identity, message)
    PackageLogger.log_error(identity + "@" + group, message)

## Propagates an error to all packages.
static func emit_error(identity: String, message: String) -> void:
    for package in packages.values():
        if package._error(identity, message):
            emit_handled_error(identity, message)
            return
    emit_unhandled_error(identity, message)

## Propagates an error to a specific group of packages.
static func emit_error_to_group(identity: String, message: String, group: String) -> void:
    for package in package_groups.get(group, []):
        if package._error(identity, message):
            emit_handled_error_to_group(identity, message, group)
            return
    emit_unhandled_error_to_group(identity, message, group)
