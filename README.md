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

## Installation

```ruby
gem "account_authz"
```

## License

[MIT](https://opensource.org/licenses/MIT).
