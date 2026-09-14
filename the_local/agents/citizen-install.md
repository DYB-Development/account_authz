---
name: citizen-install
description: Use to hook citizen into a project — adding the gem, installing its migrations, including Citizen::Member in the role-holding model, including Citizen::Authorization in controllers, and setting Citizen::Current.account_id per request.
tools: Bash, Read, Edit
scope: authorization — capability catalog, roles, and Pundit enforcement in multi-tenant Rails apps
---

You follow the steps below exactly, in order, and invent none. Where a step says to ask the developer, ask and wait for the answer.

## What citizen is
A Rails engine for capability-based authorization in multi-tenant apps, hooked in when a host needs account-scoped roles enforced through Pundit.

## Interface
- `gem "citizen"` — adds the engine to the host's Gemfile, and brings in `pundit` as a dependency.
- `bin/rails citizen:install:migrations` — copies the engine's two migrations into the host's `db/migrate/`.
- `Citizen::Member` — a model concern included in the host model that holds roles, giving it role assignments.
- `Citizen::Authorization` — a controller concern that includes `Pundit::Authorization` and adds a `can?(capability)` helper to controllers and views.
- `Citizen::Current.account_id` — the per-request account that the `can?` helper scopes its answer to.

## How to use it
1. Confirm the host runs Ruby 3.2 or later and Rails 7.1 or later.
2. Ask the developer which source to install citizen from.
   - RubyGems: `gem "citizen"`
   - Git: `gem "citizen", github: "tylercschneider/citizen", branch: "main"`

   Add the chosen line to `Gemfile`, then run `bundle install`. This updates `Gemfile.lock`.
3. Run `bin/rails citizen:install:migrations`. It copies two files into `db/migrate/`, named `<timestamp>_create_citizen_roles.citizen.rb` and `<timestamp>_create_citizen_assignments.citizen.rb`.
   - `citizen_roles` has `account_id` (bigint, required, indexed), `name` (string, required), and `capabilities` (json, default empty array).
   - `citizen_assignments` has a polymorphic `member` reference, a `role` reference, and a unique index on member and role together.
   - Neither table has a foreign key to an accounts table, so the host needs no account model for the migration to run.
4. Open both copied files. They declare `ActiveRecord::Migration[8.1]`. If the host runs a Rails version older than 8.1, change `[8.1]` in both files to the host's Rails version, such as `[7.2]`.
5. Run `bin/rails db:migrate`. This updates `db/schema.rb` or `db/structure.sql`.
6. Ask the developer which model holds roles, such as `User` or `Membership`. Add `include Citizen::Member` to that model's file in `app/models/`. Any Active Record model works, because the assignment is polymorphic. Destroying a member record destroys its role assignments.
7. Add `include Citizen::Authorization` to `app/controllers/application_controller.rb`. If the controller already includes `Pundit::Authorization`, leave that line in place.
8. `Citizen::Authorization` calls `current_member` on the controller, and its `can?` helper returns `false` when that returns `nil`. Check whether `ApplicationController` already defines `current_member`. If it does not, ask the developer how the member record for the signed-in request is found, and define `current_member` in `ApplicationController` to return that record.
9. Pundit passes `pundit_user` to every policy, and `pundit_user` returns `current_user` unless the host overrides it. If the model from step 6 is not the model `current_user` returns, define `pundit_user` in `ApplicationController` to return `current_member`.
10. Ask the developer how the current account is found for a request, such as from the subdomain, the signed-in user, or a URL parameter. Add a `before_action` to `ApplicationController` that sets `Citizen::Current.account_id` to that account's integer id. Rails resets it at the end of every request.

## Conventions
- After step 5, confirm the schema file contains both `citizen_roles` and `citizen_assignments`.
- After step 10, confirm the host boots with `bin/rails runner 'puts Citizen::Current.account_id.inspect'`, which prints `nil` outside a request.
- The engine adds no routes, so there is nothing to mount in `config/routes.rb`.
- After updating the citizen gem, run `bin/rails citizen:install:migrations` again, then `bin/rails db:migrate`. The task copies only migrations the host does not already have.
- Declaring capabilities, creating roles and templates, seeding roles for a new account, and writing policies are out of scope for this local. Hand that work to the citizen-develop local.
- Citizen adds no UI. Screens for assigning roles belong to the host.
