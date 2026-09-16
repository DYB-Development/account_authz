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
- `gem "citizen"` — adds the engine to the host's Gemfile, and brings in `rails`, `pundit` and `keystone_ui` as dependencies.
- `bin/rails citizen:install:migrations` — copies the engine's three migrations into the host's `db/migrate/`.
- `Citizen::Member` — a model concern included in the host model that holds roles, giving it role assignments.
- `Citizen::Authorization` — a controller concern that includes `Pundit::Authorization` and adds a `can?(capability)` helper to controllers and views.
- `Citizen::Current.account_id` — the per-request account that the `can?` helper scopes its answer to.
- `mount Citizen::Engine` — a line in the host's `config/routes.rb` that serves two sets of pages for the current account. The members page lists each member with their name, email and roles, gives or takes away roles ranked below the viewer's own, invites a person by name and email, lists the invitations still waiting with a button to send each again and one to cancel it, and removes a member from the account. The role pages list the account's roles, create a role, add a role from a default template, and change a role's name, rank or capabilities, limited to roles ranked below the viewer unless the viewer holds the top rank, ranks up to the viewer's own and capabilities the viewer holds. The members page links to the roles page for a viewer who holds the roles capability, and the roles page links back to the members page. All of them are built from keystone_ui components and shown inside the host's own layout.

## How to use it
1. Confirm the host runs Ruby 3.2 or later and Rails 7.1 or later.
2. Ask the developer which source to install citizen from.
   - RubyGems: `gem "citizen"`
   - Git: `gem "citizen", github: "tylercschneider/citizen", branch: "main"`

   Add the chosen line to `Gemfile`, then run `bundle install`. This updates `Gemfile.lock`.
3. Run `bin/rails citizen:install:migrations`. It copies three files into `db/migrate/`, named `<timestamp>_create_citizen_roles.citizen.rb`, `<timestamp>_create_citizen_assignments.citizen.rb` and `<timestamp>_add_rank_to_citizen_roles.citizen.rb`.
   - `citizen_roles` has `account_id` (bigint, required, indexed), `name` (string, required), `capabilities` (json, default empty array), and `rank` (integer, required, default 0).
   - `citizen_assignments` has a polymorphic `member` reference, a `role` reference, and a unique index on member and role together.
   - Neither table has a foreign key to an accounts table, so the host needs no account model for the migrations to run.
   - Citizen stores no invitations of its own, so no table is copied for them.
4. Open the three copied files. They declare `ActiveRecord::Migration[8.1]`. If the host runs a Rails version older than 8.1, change `[8.1]` in all three files to the host's Rails version, such as `[7.2]`.
5. Run `bin/rails db:migrate`. This updates `db/schema.rb` or `db/structure.sql`.
6. Ask the developer which model holds roles, such as `User` or `Membership`. Add `include Citizen::Member` to that model's file in `app/models/`. Any Active Record model works, because the assignment is polymorphic. Destroying a member record destroys its role assignments.
7. Add `include Citizen::Authorization` to `app/controllers/application_controller.rb`. If the controller already includes `Pundit::Authorization`, leave that line in place.
8. `Citizen::Authorization` calls `current_member` on the controller, and its `can?` helper returns `false` when that returns `nil`. Check whether `ApplicationController` already defines `current_member`. If it does not, ask the developer how the member record for the signed-in request is found, and define `current_member` in `ApplicationController` to return that record.
9. Pundit passes `pundit_user` to every policy, and `pundit_user` returns `current_user` unless the host overrides it. If the model from step 6 is not the model `current_user` returns, define `pundit_user` in `ApplicationController` to return `current_member`.
10. Ask the developer how the current account is found for a request, such as from the subdomain, the signed-in user, or a URL parameter. Add a `before_action` to `ApplicationController` that sets `Citizen::Current.account_id` to that account's integer id. Rails resets it at the end of every request.
11. Ask the developer whether they want citizen's pages. The one mount serves both the members page and the role pages, so the host gets both or neither. If they do not want them, skip this step and steps 12 and 13. If they do, ask which path to serve them under, offering `/citizen`, and add `mount Citizen::Engine => "/citizen"` with that path to `config/routes.rb`. The members page is then at that path followed by `/members`, and the roles page at that path followed by `/roles`.
    - The engine's controllers inherit the host's `ApplicationController`, so the sign-in, `current_member`, current account and CSRF protection from the host apply to every page and every form on them.
    - The pages render inside the layout the host's `ApplicationController` uses, such as `app/views/layouts/application.html.erb`. Route helpers in that layout, such as `root_path`, reach the host's own routes on the pages without a `main_app.` prefix, so the layout needs no change for them.
    - The pages are built from keystone_ui components and ship no stylesheet of their own, so that layout must load keystone_ui's styles. Check whether the host already loads them. If it does not and the host has a keystone_ui install local, hand that step to it. Otherwise ask the developer how the host loads keystone_ui's styles before continuing.
    - A change a manager may not make sends them back to a page with a flash alert saying why, and the engine's pages do not show flash messages themselves. Check whether that layout renders `flash[:alert]`. If it does not, tell the developer that refused changes will return to the page with no message, and ask where in the layout to render the alert.
    - The members page shows a `Roles` link only to a viewer who holds the roles capability in the current account, and the roles page shows a `Members` link to every viewer. A member who holds the roles capability but not the members capability gets a 403 response on the members page, so that member reaches the roles page only through a link straight to it. Ask the developer whether the host's navigation should link to the members page, the roles page, or both, and where to put each link.
    - A request with no current account gets a 403 response on every page and every form.
12. Check the members page against these facts, and tell the developer about any that the host does not meet.
    - A member who does not hold the members capability in the current account gets a 403 response, whether they load the page, give or take a role, invite a person, send an invitation again, cancel one, or remove a member. The capability is `manage_members` unless the develop local changes it.
    - Every member record the page lists must respond to `name` and `email` and include `Citizen::Member`. If the model from step 6 lacks `name` or `email`, tell the developer before continuing.
    - Every waiting invitation the page lists must respond to `name` and `email`, and must be findable by its id among the current account's invitations. It needs no citizen concern and no citizen table.
    - The engine sends no email and stores no invitation. Inviting a person, sending an invitation again, and cancelling one each call the host's own code, and accepting an invitation is the host's own flow.
    - The invite form has a required `Name` field, a required `Email` field and an `Invite` button, and the engine does not validate either value, so the host's invite decides what to do with one it rejects.
    - Giving or taking a role, removing a member, sending an invitation again and cancelling one find the record only among the current account's members, roles or invitations, so a record from another account raises a not-found error, which Rails answers with a 404 response outside development.
    - A refused give, take or removal changes nothing and returns to the members page with a flash alert naming the reason, drawn from these four: `You can only give or take roles ranked below your own.`, `You can only change members ranked below you.`, `Someone else needs to be able to manage members first.` and `This member can't be removed from the account.`
    - Sending an invitation again and cancelling one are not limited by rank, so every viewer who holds the members capability may do both to every waiting invitation.
    - The account always keeps at least one member who holds the members capability, so a `Take <role>` or `Remove` button is left out when that member is the only way anyone in the current account holds it.
    - Every role starts at rank 0, so until ranks are set, every viewer who holds a role reaches every member and every role. Tell the developer this, and that a role's rank is set on the role form.
    - Removing a member takes away every role they hold in the current account and then calls the host's remove, both in one database transaction.
    - The page does not know which records to list, which invitations are waiting, how to invite a person, how to send an invitation again, how to cancel one, which members cannot be removed, or how to remove one until the develop local configures that. Until then, a request from a member who holds the members capability raises an error on the page, on every button and on the invite form.
13. Check the role pages against these facts, and tell the developer about any that the host does not meet.
    - A member who does not hold the roles capability in the current account gets a 403 response on every role page and form. The capability is `manage_roles` unless the develop local changes it.
    - The roles page lists each role in the current account by name with its number of capabilities, and each name links to that role's edit form. A `New role` link opens the form for a new role.
    - The new and edit forms take a name, a rank as a number field with a minimum of 0, and a checkbox for each capability in the catalog, and saving returns to the roles page. Until the develop local declares the catalog, the forms show no checkboxes.
    - The roles page shows an `Add <template>` button for each default template, which creates that role in the current account at rank 0. The section is left out until the develop local declares a default template.
    - A refused create or save changes nothing and returns to the form or the roles page with a flash alert naming the reason, drawn from these four: `You can only change roles ranked below your own.`, `You can only set a rank up to your own.`, `You can only give a role capabilities you have yourself.` and `Someone else needs to be able to manage members first.`
    - Editing a role finds it only among the current account's roles, so a role from another account raises a not-found error, which Rails answers with a 404 response outside development.
    - Saving a role with a blank name raises a validation error, which Rails answers with a 422 response outside development.

## Conventions
- After step 5, confirm the schema file contains both `citizen_roles` and `citizen_assignments`, and that `citizen_roles` has a `rank` column.
- After step 10, confirm the host boots with `bin/rails runner 'puts Citizen::Current.account_id.inspect'`, which prints `nil` outside a request.
- After step 11, confirm `bin/rails routes` lists the mount and, under the routes for `Citizen::Engine`, a `GET` route for `members`, a `DELETE` route for `members/:id`, a `POST` route for `members/:member_id/roles`, a `DELETE` route for `members/:member_id/roles/:id`, a `POST` route for `invitations`, a `POST` route for `invitations/:id/resend`, a `DELETE` route for `invitations/:id`, `GET` routes for `roles`, `roles/new` and `roles/:id/edit`, a `POST` route for `roles`, and `PATCH` and `PUT` routes for `roles/:id`.
- After step 12, once the develop local has configured the members page, load it as a member who holds the members capability and confirm it shows the invite form and any waiting invitations inside the host's layout with keystone_ui's styles applied.
- After step 13, load the roles page as a member who holds the roles capability and confirm it shows inside the host's layout with keystone_ui's styles applied.
- After updating the citizen gem, run `bin/rails citizen:install:migrations` again, then `bin/rails db:migrate`. The task copies only migrations the host does not already have. A host that installed citizen before ranks existed gets the rank migration this way, and every existing role gets rank 0.
- Declaring capabilities, declaring templates, seeding roles for a new account, giving the first member the members or roles capability, writing policies, checking reach in host code, checking in host code whether a change would leave the account with no member who holds the members capability, configuring which members and which waiting invitations the members page lists, how it invites a person, sends an invitation again and cancels one, which members cannot be removed and how it removes one, configuring which capabilities open the pages, and rewording the refusal messages are out of scope for this local. Hand that work to the citizen-develop local.
- The members page and the role pages are the only screens citizen adds. Deleting a role is not offered on them, and a screen for it belongs to the host. Sending an invitation and accepting one also belong to the host.
