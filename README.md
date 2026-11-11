# AccountAuthz

Capability-based authorization for multi-tenant apps. **Capabilities are code;
roles are data.**

- The app declares a fixed **catalog** of capabilities (permission + metric keys)
  in code — what the software *can* do.
- Accounts manage **roles** (data) that bundle those capabilities.
- AccountAuthz resolves what a member may do (`can?`) and which metrics they may see
  (`approved_metrics`) from the roles they hold, and plugs into **Pundit** for
  enforcement.

AccountAuthz owns **no role storage** — hosts bring their own (rolify, Jumpstart
`AccountUser` roles, …) via an injectable resolver. It stays a thin, reusable
layer over Pundit + your existing roles.

## Why not just Pundit?

Pundit enforces a decision but has no capability *catalog*, no role *records*,
and no "which metrics may this member see" *list*. AccountAuthz adds exactly those —
the parts you'd otherwise hand-roll in every app — and nothing else.

## Usage (sketch)

```ruby
AccountAuthz.catalog do
  permission :view_fulfillment
  metric :revenue
  metric :deals
end

# roles -> capabilities comes from the host (data); AccountAuthz resolves:
AccountAuthz.can?(grants, :view_fulfillment)   # => true/false
AccountAuthz.approved_metrics(grants)          # => [:revenue, :deals]
```

## A permission for every action

A controller that includes `AccountAuthz::Authorization` can refuse every
action that does not name the permission it needs:

```ruby
class LedgersController < ApplicationController
  include AccountAuthz::Authorization

  refuse_actions_without_a_permission
  requires_permission :revenue, only: :show
  open_to_every_member only: :index, reason: "Every member reads the list of ledgers."
end
```

- `refuse_actions_without_a_permission` refuses every action of the controller
  and its subclasses unless the action names a permission and the current
  member holds it in the current account.
- `requires_permission :capability, only: [:actions]` names the permission
  those actions need.
- `open_to_every_member only: [:actions], reason: "..."` lets any signed-in
  member open those actions, whatever permissions they hold.
- A refused action answers 403 Forbidden. A controller answers differently by
  overriding the private method `refuse_the_action`:

```ruby
class HiddenLedgersController < LedgersController
  private

  def refuse_the_action
    head :not_found
  end
end
```

## Installation

```ruby
gem "account_authz"
```

## License

[MIT](https://opensource.org/licenses/MIT).
