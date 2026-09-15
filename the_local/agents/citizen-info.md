---
name: citizen-info
description: Use to learn what citizen offers — capability-based authorization for multi-tenant Rails apps, with a capability catalog, account roles, role templates, pages for managing roles and for giving and taking them from members, and Pundit enforcement.
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
through Pundit. It ships two sets of pages, drawn with keystone_ui inside the
host's own layout. The role pages let a manager list, create and edit the
account's roles. The members page lets a manager give a member a role or take
one away. The host app signs people in, sets which account a request belongs
to, and supplies the members the members page lists.

## Interface

This local declares no commands. Citizen's surface is split between the other
two locals:

- **citizen-install** owns adding the gem to a Rails app, installing its
  migrations, connecting the host's member model and controllers, setting the
  per-request account, and mounting the engine.
- **citizen-develop** owns everything written against citizen after that:
  declaring the catalog, defining and seeding roles, assigning roles to members,
  checking capabilities, writing policies, and configuring the members page and
  the role pages.

## How to use it

Decide which of the two you need, then go there.

- Citizen is not yet in the app, a model or controller is not yet connected to
  it, or the engine is not yet mounted: use **citizen-install**.
- Citizen is connected and you are adding a capability, a role, a template, a
  check on an action, or setting up the members page or the role pages: use
  **citizen-develop**.

## Conventions

- **Capability** — one key the software can gate. Capabilities come in two
  kinds: a **permission** gates an action, and a **metric** gates a figure the
  person may see.
- **Catalog** — the complete list of capabilities, declared in the app's code.
  Capabilities are never created as data.
- **Role** — a named set of capabilities belonging to one account, stored as
  data. A role with no name, or naming a capability the catalog does not
  contain, fails validation.
- **Template** — a role definition written in code, used to create a role in an
  account. The role's name is the template's key in title case, so a `sales`
  template makes a role named `Sales`.
- **Default template** — a template created in every account that is seeded.
  Seeding skips a default template whose role name already exists in the
  account.
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
- **Role pages** — the engine's pages for the current account's roles. The list
  shows each role's name and how many capabilities it holds, and each name opens
  that role's edit form. The new and edit forms take a name and a checkbox for
  every capability in the catalog.
- **Adding from a template** — the role list shows an Add button for each default
  template, and hides that part of the page when the app has no default
  templates. Unlike seeding, the button does not check whether the account
  already has a role of that name.
- **Members page** — the engine's page for the current account's members. It
  lists each member's name, email and the roles they hold in that account only.
  Beside each member is a Give button for every role of the account they do not
  hold and a Take button for every role they do.
- **Giving and taking** — assigning a role to a member, or removing one, from the
  members page. Only members and roles of the current account can be given or
  taken, and either action returns to the members page.
- **Host layout** — every engine page is built from keystone_ui components and
  shown inside the layout the host's own controllers use, so the host loads
  keystone_ui's styles. Links in that layout to the host's own pages work on the
  engine pages without change.
- **Members source** — what the host supplies to tell the members page which
  members belong to an account.
- **Members capability** — the capability a person needs to open the members
  page and to give or take roles there, `manage_members` unless the app names
  another.
- **Roles capability** — the capability a person needs to open the role pages and
  to create or change roles there, `manage_roles` unless the app names another.
- **Refused** — a person without the page's capability, or a request with no
  current account, gets a forbidden response from any engine page. Another
  account's roles and members cannot be read or changed from these pages.
- The rule the gem follows: capabilities are code, roles are data, and Pundit
  enforces.
