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

**Members.** Include `Citizen::Member` in the model that holds roles (User,
Membership, …). `account_id:` scopes resolution to one account (nil = all roles):

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

### Install

Citizen is a Rails engine; install it correctly with the engine flow — not a
plain `gem install`:

1. Add the gem (git source until it is on RubyGems), then `bundle install`:
   ```ruby
   gem "citizen", github: "tylercschneider/citizen", branch: "main"
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

Citizen owns no role *storage* beyond its own tables and no UI — the host drives
assignment and sets the current account.

### Citizen conventions

- **Capabilities are code, roles are data.** Define capability keys only in the
  catalog; never persist capability *definitions* as data, and never hardcode
  role *records* in code (seed them from templates instead).
- A role's `capabilities` must be a subset of the catalog — adding an unknown key
  is a validation error, by design.
- Resolution is grant-based: `can?` tests membership in the union of the
  member's role capabilities, optionally scoped by `account_id`.
- Enforce through Pundit policies via `can?(capability)`; don't re-derive
  permissions ad hoc in controllers or views.
