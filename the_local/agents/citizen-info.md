---
name: citizen-info
description: Use to learn what citizen offers — capability-based authorization for multi-tenant Rails apps, with a capability catalog, account roles, role templates, role ranks that limit who may manage whom, limits on which roles an editor may create or change, a rule that every account keeps a member manager, pages for managing roles and for inviting, removing, and giving and taking roles from members, messages that tell a manager why a change was refused, and Pundit enforcement.
tools: Read
scope: authorization — capability catalog, roles, and Pundit enforcement in multi-tenant Rails apps
---

You explain what citizen is and when to reach for it, and route the reader to the local that does the work. You make no changes and give no steps.

## What citizen is

Citizen is authorization for a Rails app where many accounts share one
installation and each account decides who may do what. The app's code declares
the fixed list of things the software can gate. Each account then builds its own
roles out of that list, ranks them, and assigns them to its people. Citizen
answers five questions about a person in an account: may they do this, which
metrics may they see, which members and roles may they manage, which
capabilities and ranks may they put on a role, and would a change leave the
account with nobody able to manage its members.

Reach for it when the set of gated actions is decided by the developers but the
bundling of those actions into roles is decided by each account. It is a Rails
engine that stores roles and role assignments in its own tables, and it enforces
through Pundit. It ships two sets of pages, drawn with keystone_ui inside the
host's own layout. The role pages let a manager list, create and edit the
account's roles, including each role's rank, limited to capabilities the manager
holds, ranks up to their own, and roles ranked below them. The members page lets
a manager invite a person, remove a member, and give a member a role or take one
away, with removing and role changes limited to the members and roles ranked
below the manager. Both sets of pages refuse any change that would leave the
account with no member able to manage members, and tell the manager why a change
was refused. The host app signs people in, sets which account a request belongs
to, and supplies the members the members page lists, sends the invitations, and
carries out the removals.

## Interface

This local declares no commands. Citizen's surface is split between the other
two locals:

- **citizen-install** owns adding the gem to a Rails app, installing its
  migrations, connecting the host's member model and controllers, setting the
  per-request account, and mounting the engine.
- **citizen-develop** owns everything written against citizen after that:
  declaring the catalog, defining and seeding roles, assigning roles to members,
  checking capabilities, asking whether a manager's rank reaches a member or a
  role, asking whether an editor may put a set of capabilities or a rank on a
  role, asking whether a change would remove the account's last member manager,
  writing policies, configuring the members page, including how it invites and
  removes, and the role pages, and rewording the refusal messages.

## How to use it

Decide which of the two you need, then go there.

- Citizen is not yet in the app, a model or controller is not yet connected to
  it, the engine is not yet mounted, or the migration that adds ranks has not
  been installed after an update: use **citizen-install**.
- Citizen is connected and you are adding a capability, a role, a template, a
  check on an action, a check on who may manage whom in the host's own screens,
  a check on which capabilities and ranks an editor may set in the host's own
  screens, a check that the host's own screens keep a member manager, setting up
  the members page, its invitations and removals, or the role pages, or changing
  the wording of a refusal message: use **citizen-develop**.

## Conventions

- **Capability** — one key the software can gate. Capabilities come in two
  kinds: a **permission** gates an action, and a **metric** gates a figure the
  person may see.
- **Catalog** — the complete list of capabilities, declared in the app's code.
  Capabilities are never created as data.
- **Role** — a named set of capabilities belonging to one account, stored as
  data. A role with no name, or naming a capability the catalog does not
  contain, fails validation.
- **Rank** — a whole number on each role, 0 unless set, where a higher number
  ranks higher. Ranks compare only within one account.
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
- **Highest role** — the member's role in the account with the greatest rank. A
  member with no roles in the account ranks below every role.
- **Reach** — the members, roles, capabilities and ranks a manager may act on. A
  manager reaches a role ranked below their highest role, and a member whose
  highest role ranks below it. A manager reaches the capabilities in their own
  grants, and every rank up to and including their highest role's rank.
- **Top rank** — the greatest rank among the account's roles. A manager whose
  highest role is at the top rank reaches every member and every role in the
  account, including members at that rank and themselves. The top rank does not
  widen which capabilities or ranks they may put on a role. While every role
  keeps the default rank of 0, every manager holding a role is at the top rank,
  so ranks limit no member or role until an account sets them.
- **Member manager** — a member who holds a role in the account that includes
  the members capability.
- **Last member manager** — the rule that an account always keeps at least one
  member manager. Citizen refuses three changes that would break it. Taking a
  role from a member is refused when that member holding that role is the only
  way anyone in the account holds the members capability. Removing a member is
  refused when no other member holds a role with the members capability.
  Unticking the members capability on a role is refused when no member holds it
  through any other role. The rule holds whatever the members capability is
  named, and it applies to every manager, including one at the top rank.
- **Role pages** — the engine's pages for the current account's roles. The list
  shows every role's name and how many capabilities it holds, and each name
  opens that role's edit form. The new and edit forms take a name, a rank of 0
  or more, and a checkbox for every capability in the catalog. Saving is limited
  by the editor limits and by the last member manager rule.
- **Editor limits** — the changes the role pages refuse from a person who may
  open them. Creating a role is refused when it sets a rank above the editor's
  highest role, or includes a capability the editor does not hold. Saving an
  edit is refused when the role does not rank below the editor's highest role,
  unless the editor is at the top rank. Saving an edit is also refused when it
  sets a rank above the editor's highest role, or ticks a capability the editor
  does not hold. Capabilities already on the role may stay ticked or be unticked
  whether or not the editor holds them. An editor below the top rank may create
  a role at their own rank, and cannot change it after that. Every role still
  appears in the list and its edit form still opens, and the limits apply only
  when a form is saved.
- **Adding from a template** — the role list shows an Add button for each default
  template, and hides that part of the page when the app has no default
  templates. The button is refused when the template includes a capability the
  editor does not hold. The added role has the default rank of 0. Unlike seeding,
  the button does not check whether the account already has a role of that name.
- **Members page** — the engine's page for the current account's members. It
  lists each member's name, email and the roles they hold in that account only,
  under a form for inviting a person. Beside each member the viewer reaches is a
  Give button for every role within reach the member does not hold, and a Take
  button for every role within reach they do. It also shows a Remove button when
  the host says that member may be removed. A Take or Remove button that would
  break the last member manager rule is not shown. A member outside the viewer's
  reach shows no buttons.
- **Giving and taking** — assigning a role to a member, or removing one, from the
  members page. Only members and roles of the current account, and within the
  viewer's reach, can be given or taken, and either action returns to the
  members page.
- **Inviting** — sending an invitation from the members page with a name and an
  email, both required. Citizen passes the current account, the name, the email
  and the inviting member to the host. The host sends its own invitation and
  decides when the person becomes a member. Rank does not limit inviting, and the
  action returns to the members page.
- **Removing** — taking a member off the current account from the members page.
  Citizen first takes away every role the member holds in the current account,
  then asks the host to remove the member, both in one database transaction.
  Roles the member holds in other accounts are left as they are. The member must
  be within the viewer's reach, and the host decides whether a member may be
  removed at all, such as refusing the account owner. A top-rank manager reaches
  themselves, so they can remove themselves unless the host refuses it or they
  are the last member manager.
- **Host layout** — every engine page is built from keystone_ui components and
  shown inside the layout the host's own controllers use, so the host loads
  keystone_ui's styles. Links in that layout to the host's own pages work on the
  engine pages without change.
- **Members source** — what the host supplies for the members page. It lists
  which members belong to an account, sends an invitation, says whether a member
  may be removed, and removes a member.
- **Members capability** — the capability a person needs to open the members
  page and to invite, remove, give or take roles there, `manage_members` unless
  the app names another.
- **Roles capability** — the capability a person needs to open the role pages and
  to create or change roles there, `manage_roles` unless the app names another.
- **Forbidden** — a person without the page's capability, or a request with no
  current account, gets a forbidden response from any engine page. Another
  account's roles and members cannot be read or changed from these pages.
- **Refusal message** — what a manager sees when they may use the page but not
  make a particular change. Citizen changes nothing and sends them back with a
  flash alert saying why. Seven reasons have a message: a role outside the
  manager's reach to give or take, a member outside the manager's reach, a
  member the host says may not be removed, a change that breaks the last member
  manager rule, a capability the editor does not hold, a rank above the editor's
  own, and a role the editor may not change. A give, take or removal returns to
  the members page. Adding from a template, and saving a role the editor may not
  change, return to the role list. A refused new role returns to an empty new
  role form, and any other refused edit returns to the role's edit form showing
  the role as it was saved. The message shows only when the host's layout renders
  flash alerts, and the app can reword each one in its locale files.
- The rule the gem follows: capabilities are code, roles are data, and Pundit
  enforces.
