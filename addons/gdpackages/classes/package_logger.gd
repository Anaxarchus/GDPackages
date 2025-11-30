class_name PackageLogger extends RefCounted

## Centralized logging system for package messages, warnings, and errors.
## [br][br]
## The PackageLogger class implements a lightweight, circular buffer logging
## system used throughout the package framework. It records messages emitted
## by packages and by the manager, categorizing them by severity and
## optionally printing them to the console in real time.
## [br][br]
## Logging behavior is fully configurable through verbosity settings,
## stack trace depth, and console output modes. The logger stores a fixed
## size history of entries, automatically overwriting older data as new
## events arrive. Each entry includes timestamp, entry type, identity tag,
## message text, a trimmed stack trace when applicable.
## [br][br]
## This class is used internally by the package manager system to maintain detailed
## diagnostics without requiring external tooling. It is designed to be globally
## accessible, and lightweight, making it suitable for in editor debugging as well
## as runtime monitoring. It is fully in memory to be as WASM friendly as possible.


enum Verbosity {Silent, UnhandledErrors, Errors, ErrorsAndWarnings, All}
enum EntryType {None, UnhandledError, HandledError, Warning, Message}

## Change this to adjust log window.
const LOG_SIZE: int = 200
## Change this to adjust max stack depth when tracing. Set to -1 for no limit.
const STACK_TRACE_DEPTH: int = 5

static var verbosity_level: Verbosity = Verbosity.All

## The actual log itself. This behaves as a circular buffer, so log[0] is not guaranteed to be the first entry at all times.
static var log: Array[Dictionary]
## The current log position.
static var log_position: int = 0
## How much of the log is currently in use. Will increment over LOG_SIZE.
static var log_count: int = 0

## If true, the log immediately prints to console when a new line is added.
static var console_mode: bool = true

## clears the current log.
static func clear_log() -> void:
    for i in log.size():
        log[i].time = ""
        log[i].type = EntryType.None
        log[i].identity = ""
        log[i].message = ""
        log[i].stack.clear()
    log_position = 0
    log_count = 0

## Time stamp implementation.
static func get_timestamp() -> String:
    return Time.get_time_string_from_system()

## Returns a Godot stack item formatted to String.
static func get_stack_item_as_text(stack_item: Dictionary) -> String:
    return "\n\t" + stack_item.source + ":" + str(stack_item.line) + "::" + stack_item.function + "."

## Returns a given log entry, formatted to String.
static func get_log_entry_as_text(entry: Dictionary) -> String:
    var result: String = entry.time + " [Package::" + entry.identity + "] " + EntryType.keys()[entry.type] + " - " + entry.message
    for stack_item in entry.stack:
        result += "\n" + get_stack_item_as_text(stack_item)
    return result

## Returns the log formatted to String.
static func get_log_as_text() -> String:
    var result: String
    for i in log.size():
        if i < log_count:
            result += "\n" + get_log_entry_as_text(log[i])
    return result

## prints the given entry to the console.
static func print_entry(entry: Dictionary) -> void:
    match entry.type:
        EntryType.Warning, EntryType.HandledError:
            push_warning(entry.time + " [Package::" + entry.identity + "] " + entry.message)
        EntryType.UnhandledError:
            push_error(entry.time + " [Package::" + entry.identity + "] " + entry.message)
        _:
            print(get_log_entry_as_text(entry))

## prints the entire log to the console.
static func print_log() -> void:
    for entry in log:
        print_entry(entry)

## Adds a log entry.
static func log_entry(type: EntryType, identity: String, message: String, stack: Array[Dictionary] = []) -> void:
    log[log_position].time = get_timestamp()
    log[log_position].type = type
    log[log_position].identity = identity
    log[log_position].message = message
    log[log_position].stack = stack
    if console_mode:
        print_entry(log[log_position])
    log_position = wrapi(log_position + 1, 0, LOG_SIZE)
    log_count += 1

## Default implementation for logging an error.
static func log_error(identity: String, message: String) -> void:
    if verbosity_level >= Verbosity.UnhandledErrors:
        var stack := get_stack()
        if STACK_TRACE_DEPTH > -1:
            stack.resize(mini(stack.size(), STACK_TRACE_DEPTH))
        log_entry(EntryType.UnhandledError, identity, message, stack)

## Default implementation for logging a handled error.
static func log_handled_error(identity: String, message: String) -> void:
    if verbosity_level >= Verbosity.Errors:
        log_entry(EntryType.HandledError, identity, message)

## Default implementation for logging a warning.
static func log_warning(identity: String, message: String) -> void:
    if verbosity_level >= Verbosity.ErrorsAndWarnings:
        log_entry(EntryType.Warning, identity, message)

## Default implementation for logging a message.
static func log_message(identity: String, message: String) -> void:
    if verbosity_level == Verbosity.All:
        log_entry(EntryType.Message, identity, message)

## saves the log to text at the given path.
static func save_log(file_path: String) -> Error:
    var file := FileAccess.open(file_path, FileAccess.WRITE)
    if FileAccess.get_open_error() == OK:
        file.store_string(get_log_as_text())
        file.close()
    return FileAccess.get_open_error()

static func _static_init() -> void:
    log.resize(LOG_SIZE)
    for i in LOG_SIZE:
        var stack: Array[Dictionary] = []
        log[i]["time"] = ""
        log[i]["type"] = EntryType.None
        log[i]["identity"] = ""
        log[i]["message"] = ""
        log[i]["stack"] = stack
