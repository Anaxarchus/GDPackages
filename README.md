# Modular Package Framework for Godot

A lightweight, opinionated framework for creating modular, isolated packages in Godot. This system encourages decoupled development, safe experimentation, and maintainable feature layers.

---

## Pattern

### Package Isolation
- Each package is fully **self-contained**.
- Interaction with external code occurs **only through a package adapter**.
- No package dependencies are allowed within the package source; this limits breakage to the adapter script only.

### Package Adapter
- The adapter acts as the single interface between a package and the outside world.
- Adapters should be used **only by the package itself**.
- Supports stable, incremental development and stub-first workflows.

### Logging System
- Simplistic centralized logging via `PackageLogger`.
- Supports **messages, warnings, handled errors, and unhandled errors with stack trace**.
- Exists in memory using a circular buffer.
- Configurable stack trace depth.
- Congifurable buffer size.
- Configurable verbosity.

### Package Orchestration
- `PackageOrchestrator` manages global package registry, package groups, and lifecycle.
- Supports message propagation to all packages or specific groups.
- Designed to work seamlessly with `.pck` files for modular runtime loading.

---

## Features

- Automatic package lifecycle management (`_loaded`, `_unloaded`)
- Message, warning, and error propagation hooks
- Strict boundaries to enforce modularity
- Ready-to-use editor plugin to **generate package boilerplate**
- Supports both filesystem packages and runtime-loaded `.pck` packages

---

## Philosophy

- **Isolation:** Packages never rely on external code.
- **Stability:** Packages can be added or dropped without breakage.
- **Incremental development:** Stub methods first, implement later, and use TDD-friendly patterns.

---

## Plug-in Useage

1. Right click the FileSystem directory you want to create your package in.
2. Select **Create New -> Package**
3. Complete the form.

---

## Getting Started

1. Create a new package via the Editor plugin or manually.
2. Implement your package logic inside the package source directory, package entry script and adapter.
3. Use the `PackageManager` to load/unload packages and propagate events.
4. Access logging through `PackageLogger`, or convenience wrappers in `Package`.

---

## Example

```gdscript
var pkg = PackageOrchestrator.load_package("res://packages/MyPackage")
PackageManager.unload_package("my_package")
var pkgs = PackageManager.load_packages_in_directory("res://packages")
PackageManager.unload_packages_in_group("res://packages")
```

---
