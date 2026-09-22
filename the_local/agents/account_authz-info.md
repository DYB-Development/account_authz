---
name: account_authz-info
description: Use to learn what account_authz offers — its capability catalog, account roles and ranks, members as account memberships, reach limits on who may manage whom, the rule that every account keeps a member manager, the members and role pages with their invitations and refusal messages, and Pundit enforcement.
tools: Read
scope: authorization — capability catalog, roles, and Pundit enforcement in multi-tenant Rails apps
---

You explain what account_authz is and when to reach for it, and route the reader to the local that does the work. You make no changes and give no steps.

## What account_authz is

AccountAuthz is authorization for a Rails app where many accounts share one
installation and each account decides who may do what. The app's code declares
the fixed list of things the software can gate. Each account then builds its own
roles out of that list, ranks them, and assigns them to its people. AccountAuthz
answers five questions about a person in an account: may they do this, which
metrics may they see, which members and roles may they manage, which
capabilities and ranks may they put on a role, and would a change leave the
account with nobody able to manage its members.

Reach for it when the set of gated actions is decided by the developers but the
bundling of those actions into roles is decided by each account. It is a Rails
engine that stores roles and role assignments in its own tables, and it enforces
through Pundit.

It ships two sets of pages, drawn with keystone_ui inside the host's own layout.
The role pages let a manager list, create and edit the account's roles, including
each role's rank, limited to capabilities the manager holds, ranks up to their
own, and roles ranked below them. The members page lets a manager invite a
person, remove a member, and give a member a role or take one away, with removing
and role changes limited to the members and roles ranked below the manager. It
also lists the invitations still waiting for an answer, each with a button to
send it again and one to cancel it. The members page links to the role pages and
the role pages link back, so the host's navigation needs one link to reach both.
Both sets of pages refuse any change that would leave the account with no member
able to manage members, and tell the manager why a change was refused. The host
app signs people in, sets which account a request belongs to, supplies the
members and the waiting invitations the members page lists, sends the
invitations, sends them again, cancels them, and carries out the removals.

## Interface

This local declares no commands. AccountAuthz's surface is split between the other
two locals:

- **account_authz-install** owns adding the gem to a Rails app, installing its
  migrations, connecting the host's member model and controllers, setting the
  per-request account, and mounting the engine.
- **account_authz-develop** owns everything written against account_authz after that:
  - declaring the catalog, defining roles and templates, seeding them, and
    assigning roles to members;
  - checking capabilities and approved metrics, and writing policies;
  - asking whether a manager's rank reaches a member or a role, whether an editor
    may put a set of capabilities or a rank on a role, and whether a change would
    remove the account's last member manager;
  - configuring the members page, including how it invites, lists the waiting
    invitations, sends one again, cancels one and removes, and the role pages;
  - rewording the refusal messages.

## How to use it

Decide which of the two you need, then go there.

- AccountAuthz is not yet in the app, a model or controller is not yet connected to
  it, the engine is not yet mounted, or the migration that adds ranks has not
  been installed after an update: use **account_authz-install**.
- You are choosing which of the host's models holds roles: use
  **account_authz-install**.
- AccountAuthz is connected and you are adding a capability, a role, a template, or a
  check on an action: use **account_authz-develop**.
- AccountAuthz is connected and you are setting up the members page, its invitations
  and removals, or the role pages: use **account_authz-develop**.
- AccountAuthz is connected and you are adding a check in the host's own screens on
  who may manage whom, on which capabilities and ranks an editor may set, or on
  keeping a member manager, or changing the wording of a refusal message: use
  **account_authz-develop**.

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
- **Member** — the record roles are assigned to. It is a person's membership in
  one account, not the person, so a person who belongs to three accounts has
  three members. Deleting a member deletes its role assignments with it.
  Assigning the same role twice leaves one assignment.
- **Person as member** — the fallback for an app with no membership record, where
  the person holds roles directly. A check made from a controller, a view or a
  policy still counts only the current account's roles. A check made anywhere
  else must name the account, or it counts the person's roles in every account.
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
  member manager. AccountAuthz refuses three changes that would break it. Taking a
  role from a member is refused when that member holding that role is the only
  way anyone in the account holds the members capability. Removing a member is
  refused when no other member holds a role with the members capability.
  Unticking the members capability on a role is refused when no member holds it
  through any other role. The rule holds whatever the members capability is
  named, and it applies to every manager, including one at the top rank.
- **Role pages** — the engine's pages for the current account's roles. The list
  shows every role's name and how many capabilities it holds, and each name
  opens that role's edit form. Above the list is a Members link back to the
  members page, shown to every viewer, and a viewer without the members
  capability who follows it gets a forbidden response. The new and edit forms
  take a name, a rank of 0 or more, and a checkbox for every capability in the
  catalog. Saving is limited by the editor limits and by the last member manager
  rule.
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
  under a form for inviting a person. Between that form and the members it lists
  the account's invitations still waiting. Beside the page title is a Roles link
  to the role pages, shown only to a viewer who holds the roles capability in the
  current account. Beside each member the viewer reaches is a Give button for
  every role within reach the member does not hold, and a Take button for every
  role within reach they do. It also shows a Remove button when the host says
  that member may be removed. A Take or Remove button that would break the last
  member manager rule is not shown. A member outside the viewer's reach shows no
  buttons.
- **Giving and taking** — assigning a role to a member, or removing one, from the
  members page. Only members and roles of the current account, and within the
  viewer's reach, can be given or taken, and either action returns to the
  members page.
- **Inviting** — sending an invitation from the members page with a name and an
  email, both required. AccountAuthz passes the current account, the name, the email
  and the inviting member to the host. The host sends its own invitation and
  decides when the person becomes a member. Rank does not limit inviting, and the
  action returns to the members page.
- **Waiting invitation** — an invitation the host says is still waiting for an
  answer. Each one shows the name and email it was sent to, an Invited badge, a
  Send again button and a Cancel button. Sending again asks the host to send that
  invitation once more, and cancelling asks the host to withdraw it. Only the
  current account's waiting invitations can be sent again or cancelled, rank does
  not limit either, and both actions return to the members page.
- **Removing** — taking a member off the current account from the members page.
  AccountAuthz first takes away every role the member holds in the current account,
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
  which members belong to an account, sends an invitation, lists the invitations
  still waiting, sends one again, cancels one, says whether a member may be
  removed, and removes a member.
- **Members capability** — the capability a person needs to open the members
  page and to invite, send an invitation again, cancel one, remove, give or take
  roles there, `manage_members` unless the app names another.
- **Roles capability** — the capability a person needs to open the role pages and
  to create or change roles there, `manage_roles` unless the app names another.
- **Forbidden** — a person without the page's capability, or a request with no
  current account, gets a forbidden response from any engine page. Another
  account's roles, members and waiting invitations cannot be read or changed from
  these pages.
- **Refusal message** — what a manager sees when they may use the page but not
  make a particular change. AccountAuthz changes nothing and sends them back with a
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
