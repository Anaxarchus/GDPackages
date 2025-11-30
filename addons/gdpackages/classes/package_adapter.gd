class_name PackageAdapter extends RefCounted

## Base class for all package interface scripts.
## [br][br]
## The PackageAdapter class defines the boundary between a package’s internal
## implementation and the rest of the project. Each package exposes a single
## adapter script derived from PackageAdapter, and all communication into or
## out of the package must occur through that script.
## [br][br]
## By isolating external interactions in this way, package source code remains
## fully modular, self contained, and free from project level dependencies.
## The adapter serves as the package’s public API surface, wrapping or forwarding
## calls to internal logic without leaking implementation details.
## [br][br]
## Instances of PackageAdapter should be stateless or static in design, and any
## computation performed here should be minimal and restricted to validation, routing,
## or transformation of data passed between external code and the package internals.
## [br][br]
## Use this class as the foundation for defining clean, stable interfaces for your packages.
