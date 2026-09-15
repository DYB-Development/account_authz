---
name: citizen-info
description: Use to learn what citizen offers — capability-based authorization for multi-tenant Rails apps, with a capability catalog, account roles, role templates, a members page, and Pundit enforcement.
tools: Read
scope: authorization — capability catalog, roles, and Pundit enforcement in multi-tenant Rails apps
---

You explain what citizen is and when to reach for it, and route the reader to the local that does the work. You make no changes and give no steps.

## What citizen is

Citizen is authorization for a Rails app where many accounts share one
installation and each account decides who may do what. The app's code declares
the fixed list of things the software can gate. Each account then builds its own
roles out of that list and assigns them to its people. Citizen answers two
questions about a person in an account: may they do this, and which metrics may
they see.

Reach for it when the set of gated actions is decided by the developers but the
bundling of those actions into roles is decided by each account. It is a Rails
engine that stores roles and role assignments in its own tables, and it enforces
through Pundit. It ships one page, the members page, which lists an account's
members with their name, email and roles. The host app signs people in, sets
which account a request belongs to, supplies the members the page lists, and
builds any screen for managing roles.

## Interface

This local declares no commands. Citizen's surface is split between the other
two locals:

- **citizen-install** owns adding the gem to a Rails app, installing its
  migrations, connecting the host's member model and controllers, setting the
  per-request account, and mounting the engine.
- **citizen-develop** owns everything written against citizen after that:
  declaring the catalog, defining and seeding roles, assigning roles to members,
  checking capabilities, writing policies, and configuring the members page.

## How to use it

Decide which of the two you need, then go there.

- Citizen is not yet in the app, a model or controller is not yet connected to
  it, or the engine is not yet mounted: use **citizen-install**.
- Citizen is connected and you are adding a capability, a role, a template, a
  check on an action, or setting up the members page: use **citizen-develop**.

## Conventions

- **Capability** — one key the software can gate. Capabilities come in two
  kinds: a **permission** gates an action, and a **metric** gates a figure the
  person may see.
- **Catalog** — the complete list of capabilities, declared in the app's code.
  Capabilities are never created as data.
- **Role** — a named set of capabilities belonging to one account, stored as
  data. A role naming a capability the catalog does not contain fails
  validation.
- **Template** — a role definition written in code, used to create a role in an
  account. A template marked **default** is created in every account that is
  seeded, and seeding skips a template whose role name already exists there. The
  role's name is the template's key in title case, so a `sales` template makes a
  role named `Sales`.
- **Member** — the record roles are assigned to, such as a user or a membership.
  Assigning the same role twice leaves one assignment.
- **Grants** — the capabilities a member holds: every capability of every role
  assigned to them, with duplicates removed.
- **Approved metrics** — the metrics in the catalog that appear in a member's
  grants.
- **Current account** — the account a request is acting in, set by the host.
  Checks made from a controller, a view or a policy count only the member's roles
  in the current account, and every check is denied when no current account is
  set.
- **Members page** — the engine's one page, listing each member of the current
  account with the roles they hold in that account only.
- **Members source** — what the host supplies to tell the members page which
  members belong to an account.
- **Members capability** — the capability a member needs to open the members
  page, `manage_members` unless the app names another. Anyone without it, or a
  request with no current account, is refused.
- The rule the gem follows: capabilities are code, roles are data, and Pundit
  enforces.
