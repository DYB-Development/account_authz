# Changelog

All notable changes to this project are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-09-22

### Fixed
- The assignments index on the member columns is renamed to match the gem's new
  name. The first rename migration left it under the old name, because Rails
  renames an index with a table only when the index still carries the name Rails
  would generate for it.

## [0.1.0] - 2026-09-22

### Added
- Capability-based authorization (`AccountAuthz`) — the app declares a catalog of
  capabilities in code, an account manages roles as data that bundle them, and
  Pundit enforces the decision.
