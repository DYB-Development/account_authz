# Changelog

All notable changes to this project are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- A controller including `AccountAuthz::Authorization` may call
  `refuse_actions_without_a_permission`, and every action of it and its
  subclasses is then refused unless the action names a permission the current
  member holds.
- `requires_permission :capability, only: [:actions]` names the permission an
  action needs.
- `open_to_every_member only: [:actions], reason: "..."` lets any signed-in
  member open an action.
- A refused action answers 403 Forbidden, and a controller answers differently
  by overriding the private method `refuse_the_action`.

## [0.2.0] - 2026-10-12

### Added
- Every role carries a code from the public_code gem, given by the migration
  `AddPublicCodeToAccountAuthzRoles`, which also gives one to each role made
  before it. Run `bin/rails account_authz:install:migrations` and migrate.
- A members source may answer `member(account_id, address)`, and the members
  pages, the team section and the Give, Take and Remove actions then ask it for
  the member at an address instead of finding one by id.
- A members source may answer `invitation(account_id, address)`, and Send again
  and Cancel then ask it for the invitation at an address instead of finding
  one by id.

### Changed
- The role pages and the Give and Take buttons address a role by its code, and
  a numbered role address is not found.
- The team section links each member, and sends each member, role and
  invitation, by the address the record gives instead of its id.

## [0.1.2] - 2026-09-30

### Fixed
- A member's capabilities in an account are loaded once per request, and every
  later check in the same request answers from them instead of building the
  member's roles again. Assigning or revoking a role, or saving a role, clears
  them, so the next check sees the change.

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
