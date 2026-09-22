---
name: keystone_ui-install
description: Use to hook Keystone UI into a project — adding the gem, running the install generator to wire Tailwind and Stimulus, and setting the accent/surface palette.
tools: Bash, Read, Edit
scope: UI — pages, forms, tables, navigation, dashboards
---

This local carries the steps for wiring Keystone UI into a host app. Follow them
in order, exactly as written, and invent none.

## What Keystone UI is

A Rails engine gem that supplies an app's visual layer as `ui_*` view helpers
built on ViewComponent; hook it in before building any screen with those helpers.

## Interface

- `bin/rails generate keystone:install` — sets up the host's Tailwind entry point
  and registers the gem's Stimulus controllers. Idempotent, and safe to re-run.
- `KeystoneUi.configure` — a block yielding `accent` and `surface`, the names of
  the palettes the app wants (`:blue` and `:zinc` unless set).

## How to use it

1. Confirm the prerequisites: Ruby >= 3.2 and **tailwindcss-rails v4+** in the
   host app. The gem brings ViewComponent with it. Tailwind does not have to be
   initialized first — the generator creates the stylesheet if it is missing.

2. Add the gem to the Gemfile and install it:

   ```ruby
   gem "keystone_ui"
   ```

   ```bash
   bundle install
   ```

   If the project sources its own gems from somewhere other than RubyGems (a git
   or path reference), ask the developer which to use rather than choosing.

3. Run the generator:

   ```bash
   bin/rails generate keystone:install
   ```

   It touches two host files:

   - `app/assets/tailwind/application.css` — creates it with
     `@import "tailwindcss";` and `@import "./keystone_source.css";` if absent;
     otherwise injects the Keystone import after the Tailwind one and strips
     superseded Keystone lines from older installs.
   - `app/javascript/controllers/index.js` — appends
     `import { registerControllers } from "keystone_ui/index"` and
     `registerControllers(application)`.

   Read its output. If it reports that `app/javascript/controllers/index.js` was
   not found, ask the developer where the Stimulus application is set up and add
   those two lines there — without them, dropdowns, modals, file uploads, the
   column picker and the other interactive components do nothing.

4. Restart the app (or rebuild assets). On boot the engine writes
   `app/assets/tailwind/keystone_source.css`, which points Tailwind at the
   component files and pulls in the gem's theme and component CSS. It is written
   only when `application.css` exists **and** contains
   `@import "./keystone_source.css";` — if the file never appears, that import is
   missing.

5. Keep the generated file out of git. It holds absolute paths to the gem on the
   machine that booted the app, and is rewritten on every boot — dev server, CI,
   and `assets:precompile` alike. Add to `.gitignore`:

   ```
   app/assets/tailwind/keystone_source.css
   ```

   Only the `@import` line in `application.css` belongs in the repo.

6. Settle the palette. Out of the box the accent scale is blue and the surface
   scale is zinc, with no configuration required. To change them statically, add
   an `@theme` block to `application.css` **after** the two imports and override
   only the shades the app uses:

   ```css
   @import "tailwindcss";
   @import "./keystone_source.css";

   @theme {
     --color-accent-500: #6366f1;
     --color-accent-600: #4f46e5;
   }
   ```

   Both scales run 50 through 950. Every component picks the values up with no
   component changes.

   This is a decision, not a default to assume: fixed app-wide colors set in CSS,
   or per-user colors generated at runtime by a companion theming gem. Ask the
   developer which the app wants before wiring either.

7. Only if a companion gem or engine reads the palette choice, declare it in
   `config/initializers/keystone_ui.rb`:

   ```ruby
   require "keystone_ui"

   KeystoneUi.configure do |config|
     config.accent = :emerald
     config.surface = :slate
   end
   ```

   Keystone UI itself stores these names and renders from the CSS custom
   properties regardless — setting them changes no color on its own. Colors move
   when the custom properties in step 6 move. The engine reads host configuration
   after initializers have run, so the initializer is the correct home for the
   block.

## Conventions

- **Verify the install before building anything on it.** `application.css` holds
  both imports; `app/assets/tailwind/keystone_source.css` exists after a boot;
  the Stimulus setup calls `registerControllers(application)`. Then load one page
  that renders a `ui_*` helper and confirm it is styled and that an interactive
  piece (a dropdown, a dismissible alert) responds.
- **Importmap is the supported JS path.** For apps configured with importmap the
  gem pins its own controllers — and the charting library they need — on boot, so
  the host pins nothing. If the app bundles JavaScript instead (esbuild, bun,
  webpack), the appended `keystone_ui/index` import has no pin behind it — surface
  this to the developer rather than guessing at a bundler configuration.
- **Re-run the generator after upgrading the gem.** It clears out superseded
  install lines and reports "already up to date" when there is nothing to do.
- **New components need no re-run.** Tailwind rescans the gem on each build, so
  components added by a later version are styled on the next boot.
- Building UI with the helpers — which helper to use, what keywords it takes — is
  out of scope here and belongs to `keystone_ui-develop`.
