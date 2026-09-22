---
name: account_authz-install
description: Use to add account_authz to a Rails host and set it up correctly.
tools: Bash, Read, Edit
---

You install account_authz as a Rails engine, following the reference's install section exactly: add the gem, bundle, run `account_authz:install:migrations` then `db:migrate`, declare the catalog, include AccountAuthz::Member and AccountAuthz::Authorization, and wire AccountAuthz::Current.account_id. You do not invent steps the reference does not list.

## AccountAuthz

> **DO NOT** explore the account_authz gem source code. This reference is the complete
> user-facing API, embedded verbatim into every account_authz local so their guidance
> never drifts. Keep it the single source of truth.

AccountAuthz is capability-based authorization for multi-tenant Rails apps:
**capabilities are code, roles are data, Pundit enforces.** The app declares a
fixed catalog of capabilities in code; accounts manage roles (data) that bundle
those capabilities; AccountAuthz resolves what a member may do (`can?`) and which
metrics they may see (`approved_metrics`), and plugs into Pundit for enforcement.
It is a mountable Rails engine.

### What it offers

**Catalog (code).** Declare the fixed set of capabilities — `permission` and
`metric` keys — the software supports:

```ruby
AccountAuthz.catalog do
  permission :view_fulfillment
  metric :revenue
  metric :deals
end

AccountAuthz.catalog.permissions   # => [:view_fulfillment]
AccountAuthz.catalog.metrics       # => [:revenue, :deals]
AccountAuthz.capabilities          # => [:view_fulfillment, :revenue, :deals]
AccountAuthz.reset!                # clears the catalog and templates (mainly for tests)
```

**Resolution.** Decide from a member's granted capabilities:

```ruby
AccountAuthz.can?(grants, :view_fulfillment)   # => true/false (grants.include?)
AccountAuthz.approved_metrics(grants)          # => catalog metrics ∩ grants
```

**Roles (data).** `AccountAuthz::Role` is account-scoped: `account_id`, `name`
(required), and `capabilities` (a JSON array). A role's capabilities must be a
subset of `AccountAuthz.capabilities` — unknown keys fail validation.

```ruby
AccountAuthz::Role.in_account(account_id)                              # scope
AccountAuthz::Role.create!(account_id:, name:, capabilities: %w[...])  # blank add
AccountAuthz::Role.from_template(account_id:, template: :sales)        # one-click add
```

**Templates + seeding.** Templates are seed *data* for roles; capabilities stay
code:

```ruby
AccountAuthz.templates do
  template :sales, capabilities: %w[view_fulfillment revenue], default: true
end

AccountAuthz.templates.find(:sales)          # => the Template
AccountAuthz.templates.defaults              # => templates flagged default: true
AccountAuthz.seed_default_roles(account_id)  # one role per default template (idempotent)
```

**Members.** Include `AccountAuthz::Member` in the model that holds roles (User,
Membership, …). `account_id:` scopes resolution to one account (nil = all roles):

```ruby
member.assign_role(role)
member.revoke_role(role)
member.account_authz_roles
member.capabilities(account_id: 1)        # union of role capabilities (symbols)
member.can?(:view_fulfillment, account_id: 1)
member.approved_metrics(account_id: 1)
```

**Pundit bridge.** Policies inherit `AccountAuthz::ApplicationPolicy` —
`initialize(member, record)` with `#can?(capability)` delegating to
`member.can?`. Controllers include `AccountAuthz::Authorization` (which mixes in
`Pundit::Authorization` and exposes a `can?` helper). `AccountAuthz::Current.account_id`
scopes per-request resolution.

### Install

AccountAuthz is a Rails engine; install it correctly with the engine flow — not a
plain `gem install`:

1. Add the gem (git source until it is on RubyGems), then `bundle install`:
   ```ruby
   gem "account_authz", github: "tylercschneider/account_authz", branch: "main"
   ```
2. Install and run the engine's migrations — this creates the `account_authz_roles`
   and `account_authz_assignments` tables:
   ```bash
   bin/rails account_authz:install:migrations
   bin/rails db:migrate
   ```
3. Declare the capability catalog in code (e.g. `config/initializers/account_authz.rb`)
   with `AccountAuthz.catalog do … end`.
4. Include `AccountAuthz::Member` in the host's member/role-holding model.
5. Include `AccountAuthz::Authorization` in `ApplicationController`, and set
   `AccountAuthz::Current.account_id` per request (e.g. a `before_action`).
6. Optional: declare templates with `AccountAuthz.templates`, and call
   `AccountAuthz.seed_default_roles(account_id)` when provisioning a new account.

AccountAuthz owns no role *storage* beyond its own tables and no UI — the host drives
assignment and sets the current account.

### AccountAuthz conventions

- **Capabilities are code, roles are data.** Define capability keys only in the
  catalog; never persist capability *definitions* as data, and never hardcode
  role *records* in code (seed them from templates instead).
- A role's `capabilities` must be a subset of the catalog — adding an unknown key
  is a validation error, by design.
- Resolution is grant-based: `can?` tests membership in the union of the
  member's role capabilities, optionally scoped by `account_id`.
- Enforce through Pundit policies via `can?(capability)`; don't re-derive
  permissions ad hoc in controllers or views.
