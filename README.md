# Citizen

Capability-based authorization for multi-tenant apps. **Capabilities are code;
roles are data.**

- The app declares a fixed **catalog** of capabilities (permission + metric keys)
  in code — what the software *can* do.
- Accounts manage **roles** (data) that bundle those capabilities.
- Citizen resolves what a member may do (`can?`) and which metrics they may see
  (`approved_metrics`) from the roles they hold, and plugs into **Pundit** for
  enforcement.

Citizen owns **no role storage** — hosts bring their own (rolify, Jumpstart
`AccountUser` roles, …) via an injectable resolver. It stays a thin, reusable
layer over Pundit + your existing roles.

## Why not just Pundit?

Pundit enforces a decision but has no capability *catalog*, no role *records*,
and no "which metrics may this member see" *list*. Citizen adds exactly those —
the parts you'd otherwise hand-roll in every app — and nothing else.

## Usage (sketch)

```ruby
Citizen.catalog do
  permission :view_fulfillment
  metric :revenue
  metric :deals
end

# roles -> capabilities comes from the host (data); Citizen resolves:
Citizen.can?(grants, :view_fulfillment)   # => true/false
Citizen.approved_metrics(grants)          # => [:revenue, :deals]
```

## Installation

```ruby
gem "citizen", github: "DYB-Development/citizen", branch: "main"
```

## License

[MIT](https://opensource.org/licenses/MIT).
