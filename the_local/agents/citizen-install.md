---
name: citizen-install
description: Use to hook citizen into a project — adding the gem, installing its migrations, including Citizen::Member in the role-holding model, including Citizen::Authorization in controllers, setting Citizen::Current.account_id per request, and mounting Citizen::Engine for the members and role pages.
tools: Bash, Read, Edit
scope: authorization — capability catalog, roles, and Pundit enforcement in multi-tenant Rails apps
---

You follow the steps below exactly, in order, and invent none. Where a step says to ask the developer, ask and wait for the answer.

## What citizen is
A Rails engine for capability-based authorization in multi-tenant apps, hooked in when a host needs account-scoped roles enforced through Pundit.

## Interface
- `gem "citizen"` — adds the engine to the host's Gemfile, and brings in `pundit` and `keystone_ui` as dependencies.
- `bin/rails citizen:install:migrations` — copies the engine's two migrations into the host's `db/migrate/`.
- `Citizen::Member` — a model concern included in the host model that holds roles, giving it role assignments.
- `Citizen::Authorization` — a controller concern that includes `Pundit::Authorization` and adds a `can?(capability)` helper to controllers and views.
- `Citizen::Current.account_id` — the per-request account that the `can?` helper scopes its answer to.
- `mount Citizen::Engine` — a line in the host's `config/routes.rb` that serves two sets of pages for the current account. The members page lists each member with their name, email and roles, and gives or takes away the account's roles. The role pages list the account's roles, create a role, add a role from a default template, and rename a role or change its capabilities. All of them are built from keystone_ui components and shown inside the host's own layout.

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
11. Ask the developer whether they want citizen's pages. The one mount serves both the members page and the role pages, so the host gets both or neither. If they do not want them, skip this step. If they do, ask which path to serve them under, offering `/citizen`, and add `mount Citizen::Engine => "/citizen"` with that path to `config/routes.rb`. The members page is then at that path followed by `/members`, and the roles page at that path followed by `/roles`.
   - The engine's controllers inherit the host's `ApplicationController`, so the sign-in, `current_member`, current account and CSRF protection from the host apply to every page and every form on them.
   - The pages render inside the layout the host's `ApplicationController` uses, such as `app/views/layouts/application.html.erb`. Route helpers in that layout, such as `root_path`, reach the host's own routes on the pages without a `main_app.` prefix, so the layout needs no change for them.
   - The pages are built from keystone_ui components and ship no stylesheet of their own, so that layout must load keystone_ui's styles. Check whether the host already loads them. If it does not and the host has a keystone_ui install local, hand that step to it. Otherwise ask the developer how the host loads keystone_ui's styles before continuing.
   - Neither page links to the other. If the developer wants links to them in the host's navigation, ask where to put them.
   - A request with no current account gets a 403 response on every page and every form.
12. Check the members page against these facts, and tell the developer about any that the host does not meet.
   - Each listed member has a `Give <role>` button for every role in the current account the member does not hold, and a `Take <role>` button for every role they hold. Each button submits a form and then returns to the members page.
   - A member who does not hold the members capability in the current account gets a 403 response, whether they load the page or give or take a role. The capability is `manage_members` unless the develop local changes it.
   - Giving or taking a role finds the member only among the current account's members and the role only among the current account's roles, so a member or role from another account raises a not-found error, which Rails answers with a 404 response outside development.
   - Every record the page lists must respond to `name` and `email` and include `Citizen::Member`. If the model from step 6 lacks `name` or `email`, tell the developer before continuing.
   - The page does not know which records to list until the develop local configures that. Until then, a request from a member who holds the members capability raises an error on the page and on both buttons.
13. Check the role pages against these facts, and tell the developer about any that the host does not meet.
   - The roles page lists each role in the current account by name with its number of capabilities, and each name links to that role's edit form. A `New role` link opens the form for a new role.
   - The new and edit forms take a name and a checkbox for each capability in the catalog, and saving returns to the roles page. Until the develop local declares the catalog, the forms show no checkboxes.
   - The roles page shows an `Add <template>` button for each default template, which creates that role in the current account. The section is left out until the develop local declares a default template.
   - A member who does not hold the roles capability in the current account gets a 403 response on every role page and form. The capability is `manage_roles` unless the develop local changes it.
   - Editing a role finds it only among the current account's roles, so a role from another account raises a not-found error, which Rails answers with a 404 response outside development.
   - Saving a role with a blank name raises a validation error, which Rails answers with a 422 response outside development.

## Conventions
- After step 5, confirm the schema file contains both `citizen_roles` and `citizen_assignments`.
- After step 10, confirm the host boots with `bin/rails runner 'puts Citizen::Current.account_id.inspect'`, which prints `nil` outside a request.
- After step 11, confirm `bin/rails routes` lists the mount and, under the routes for `Citizen::Engine`, a `GET` route for `members`, a `POST` route for `members/:member_id/roles`, a `DELETE` route for `members/:member_id/roles/:id`, `GET` routes for `roles`, `roles/new` and `roles/:id/edit`, a `POST` route for `roles`, and `PATCH` and `PUT` routes for `roles/:id`.
- After step 12, once the develop local has configured which members the page lists, load the members page as a member who holds the members capability and confirm it shows inside the host's layout with keystone_ui's styles applied.
- After step 13, load the roles page as a member who holds the roles capability and confirm it shows inside the host's layout with keystone_ui's styles applied.
- After updating the citizen gem, run `bin/rails citizen:install:migrations` again, then `bin/rails db:migrate`. The task copies only migrations the host does not already have.
- Declaring capabilities, declaring templates, seeding roles for a new account, giving the first member the members or roles capability, writing policies, and configuring which members the members page lists and which capabilities open the pages are out of scope for this local. Hand that work to the citizen-develop local.
- The members page and the role pages are the only screens citizen adds. Deleting a role is not offered on them, and a screen for it belongs to the host.
