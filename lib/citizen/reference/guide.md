## Citizen

> **DO NOT** explore the citizen gem source code. This reference is the complete
> user-facing API, embedded verbatim into every citizen local so their guidance
> never drifts. Keep it the single source of truth.

Citizen is capability-based authorization for multi-tenant Rails apps:
**capabilities are code, roles are data, Pundit enforces.** The app declares a
fixed catalog of capabilities in code; accounts manage roles (data) that bundle
those capabilities; Citizen resolves what a member may do (`can?`) and which
metrics they may see (`approved_metrics`), and plugs into Pundit for enforcement.
It is a mountable Rails engine.

### What it offers

**Catalog (code).** Declare the fixed set of capabilities — `permission` and
`metric` keys — the software supports:

```ruby
Citizen.catalog do
  permission :view_fulfillment
  metric :revenue
  metric :deals
end

Citizen.catalog.permissions   # => [:view_fulfillment]
Citizen.catalog.metrics       # => [:revenue, :deals]
Citizen.capabilities          # => [:view_fulfillment, :revenue, :deals]
Citizen.reset!                # clears the catalog and templates (mainly for tests)
```

**Resolution.** Decide from a member's granted capabilities:

```ruby
Citizen.can?(grants, :view_fulfillment)   # => true/false (grants.include?)
Citizen.approved_metrics(grants)          # => catalog metrics ∩ grants
```

**Roles (data).** `Citizen::Role` is account-scoped: `account_id`, `name`
(required), and `capabilities` (a JSON array). A role's capabilities must be a
subset of `Citizen.capabilities` — unknown keys fail validation.

```ruby
Citizen::Role.in_account(account_id)                              # scope
Citizen::Role.create!(account_id:, name:, capabilities: %w[...])  # blank add
Citizen::Role.from_template(account_id:, template: :sales)        # one-click add
```

**Templates + seeding.** Templates are seed *data* for roles; capabilities stay
code:

```ruby
Citizen.templates do
  template :sales, capabilities: %w[view_fulfillment revenue], default: true
end

Citizen.templates.find(:sales)          # => the Template
Citizen.templates.defaults              # => templates flagged default: true
Citizen.seed_default_roles(account_id)  # one role per default template (idempotent)
```

**Members.** Include `Citizen::Member` in the record that represents a person
*inside one account* — an account membership, not the person. A role belongs to
one account, so holding it on the membership means it can only apply where the
person belongs and it goes when the membership goes. Where an app has no such
record, the person can hold roles and every check passes `account_id:`, which
scopes resolution to one account (nil = all roles):

```ruby
member.assign_role(role)
member.revoke_role(role)
member.citizen_roles
member.capabilities(account_id: 1)        # union of role capabilities (symbols)
member.can?(:view_fulfillment, account_id: 1)
member.approved_metrics(account_id: 1)
```

**Pundit bridge.** Policies inherit `Citizen::ApplicationPolicy` —
`initialize(member, record)` with `#can?(capability)` delegating to
`member.can?` within `Citizen::Current.account_id`, and denying when no current
account is set. Controllers include `Citizen::Authorization` (which mixes in
`Pundit::Authorization` and exposes a `can?` helper). `Citizen::Current.account_id`
scopes per-request resolution.

**Members page (engine).** Mount the engine and a member who holds the members
capability in the current account sees each member's name, email and roles in
that account, with a button to give each of the account's roles the member does
not hold and to take away each one they do. It lists the account's invitations
still waiting for an answer, each with a button to send it again and one to
cancel it. The page also invites a person by name and email, and removes a member from the account, which first takes away
every role they held in it. Anyone else, or a request with no current account,
gets 403. Only the current account's members and roles can be changed.

```ruby
mount Citizen::Engine => "/citizen"   # members page at /citizen/members

Citizen.members_source = AccountMembers
Citizen.members_capability = :manage_team   # default :manage_members

class AccountMembers
  def self.members(account_id) = Membership.where(account_id: account_id)
  def self.invite(account_id:, name:, email:, invited_by:) = Invitation.send_to(account_id, name, email, invited_by)
  def self.invitations(account_id) = Invitation.where(account_id: account_id)
  def self.resend_invitation(invitation) = invitation.send_again
  def self.cancel_invitation(invitation) = invitation.destroy!
  def self.removable?(member) = !member.owner?
  def self.remove(member) = member.destroy!
end
```

The source's `members(account_id)` returns the account's members as a relation that responds to `find`, `invite` sends the app's own invitation, `invitations(account_id)` returns the ones still waiting as a relation that responds to `find`, `resend_invitation` sends one again, `cancel_invitation` withdraws one, `removable?` says whether a member may be removed at all (such as the account owner), and `remove` takes the member off the account; each responds to `name` and `email`
and includes `Citizen::Member`. Engine controllers inherit the host's
`ApplicationController`, so the host's sign-in, `current_member` and
`Citizen::Current.account_id` apply. The page renders with keystone_ui inside the
layout the host's `ApplicationController` uses, so the host loads keystone_ui's
styles. Route helpers in that layout, such as `root_path`, reach the host's own
routes without a `main_app.` prefix.

**Role pages (engine).** The members page links to them with a Roles link
shown only to people who hold the roles capability, and the roles page links
back to the members page, so an app needs one navigation entry for both. At `/citizen/roles`, a member who holds the roles
capability in the current account lists that account's roles, creates a role
with a name and chosen capabilities, adds a role from each default template,
and renames a role or changes its capabilities. Anyone else, or a request with
no current account, gets 403, and another account's roles cannot be changed.

```ruby
Citizen.roles_capability = :manage_team   # default :manage_roles
```

**Ranks (who may manage whom).** Each role has an integer `rank` (default 0),
set on the role form. A manager gives or takes only roles ranked below their
highest role in the account, and changes only members whose highest role ranks
below it. A manager holding a role at the account's top rank reaches every
member and role. The members page shows only the changes the viewer may make,
and a refused change sent directly gets 403. `Citizen::Reach` answers the same
questions for host code:

```ruby
reach = Citizen::Reach.new(current_member, account_id: account.id)
reach.includes_member?(member)   # => true/false
reach.includes_role?(role)       # => true/false
```

**Keeping a member manager.** An account always keeps at least one member who
holds the members capability. Taking away that member's last members role,
removing that member, or unticking the members capability on the only role
anyone holds it through is refused with 403, and the members page hides those
buttons. `Citizen::LastManager` answers the same questions for host code:

```ruby
last_manager = Citizen::LastManager.new(account_id: account.id)
last_manager.lost_by_taking?(member, role)          # => true/false
last_manager.lost_by_removing?(member)              # => true/false
last_manager.lost_by_changing?(role, capabilities)  # => true/false
```

**Editor limits.** On the role pages an editor can only create or add roles
with capabilities they hold themselves, including roles added from a template,
can only set a rank up to their own highest role, and can only change roles
ranked below their own unless they hold the account's top rank.
`reach.includes_capabilities?(capabilities)` and `reach.includes_rank?(rank)`
answer the same questions for host code.

**Refused changes.** When a manager tries a change their rank or the last
manager rule does not allow, citizen sends them back to the page they came from
with a flash alert saying why, and changes nothing. The host's layout shows the
flash. Reword a message under `citizen.refusals` in the app's locale files:

```yaml
en:
  citizen:
    refusals:
      role_out_of_reach: "You can only give or take roles ranked below your own."
      member_out_of_reach: "You can only change members ranked below you."
      last_manager: "Someone else needs to be able to manage members first."
      not_removable: "This member can't be removed from the account."
      capabilities_out_of_reach: "You can only give a role capabilities you have yourself."
      rank_out_of_reach: "You can only set a rank up to your own."
      role_edit_out_of_reach: "You can only change roles ranked below your own."
```

A request from someone without the page's capability still gets 403.

### Install

Citizen is a Rails engine; install it correctly with the engine flow — not a
plain `gem install`:

1. Add the gem (git source until it is on RubyGems), then `bundle install`:
   ```ruby
   gem "citizen", github: "DYB-Development/citizen", branch: "main"
   ```
2. Install and run the engine's migrations — this creates the `citizen_roles`
   and `citizen_assignments` tables:
   ```bash
   bin/rails citizen:install:migrations
   bin/rails db:migrate
   ```
3. Declare the capability catalog in code (e.g. `config/initializers/citizen.rb`)
   with `Citizen.catalog do … end`.
4. Include `Citizen::Member` in the host's member/role-holding model.
5. Include `Citizen::Authorization` in `ApplicationController`, and set
   `Citizen::Current.account_id` per request (e.g. a `before_action`).
6. Optional: declare templates with `Citizen.templates`, and call
   `Citizen.seed_default_roles(account_id)` when provisioning a new account.

7. Optional: mount `Citizen::Engine` and set `Citizen.members_source` to serve
   the members page.

Citizen owns no role *storage* beyond its own tables. The host signs members in,
sets the current account, and supplies the members the members page lists.

### Citizen conventions

- **A member is a person inside one account.** Include `Citizen::Member` in the
  membership record rather than the person, so roles cannot outlive the
  membership or reach an account the person never joined.
- **Capabilities are code, roles are data.** Define capability keys only in the
  catalog; never persist capability *definitions* as data, and never hardcode
  role *records* in code (seed them from templates instead).
- A role's `capabilities` must be a subset of the catalog — adding an unknown key
  is a validation error, by design.
- Resolution is grant-based: `can?` tests membership in the union of the
  member's role capabilities, optionally scoped by `account_id`.
- Enforce through Pundit policies via `can?(capability)`; don't re-derive
  permissions ad hoc in controllers or views.
