---
name: keystone_ui-info
description: Use to learn what Keystone UI offers — what the component system covers, its layout and color model, and the vocabulary the install and develop locals assume.
tools: Read
scope: UI — pages, forms, tables, navigation, dashboards
---

This local explains Keystone UI and hands you off to the local that does the
work. It changes nothing and gives no steps.

## What Keystone UI is

Keystone UI is a Rails engine gem that supplies a host app's entire visual
layer as a library of view helpers built on ViewComponent. Screens are composed
out of named pieces — page shells, sections, panels, grids, form fields, data
tables, navigation bars, cards, charts, banners — instead of hand-written ERB
and Tailwind. Every class the UI renders lives inside the gem, in frozen
constants, so the look is owned in one place.

Reach for it whenever you are building or changing a screen in an app that has
it installed. The point is to stop UI drift: two pages built from the same
helpers cannot disagree about spacing, color, or dark-mode treatment, and a
change to a component updates every page at once. It is mobile-first by
construction — components ship distinct mobile and desktop treatments (a bottom
tab bar and mobile header on small screens, a full navigation bar above the
`lg:` breakpoint), which matters because these apps are often viewed in a native
webview.

## Interface

This local declares no commands. The two working surfaces belong elsewhere:

- **Getting the gem into a host app** — adding it, wiring Tailwind and Stimulus,
  setting the palette, refreshing the generated reference → **`keystone_ui-install`**.
- **Building UI with it** — which helper renders what, what keywords it takes,
  how helpers nest → **`keystone_ui-develop`**.

## How to use it

One decision: is the app already wearing Keystone UI?

- No, or it is out of date → **`keystone_ui-install`**.
- Yes, and you have a screen to build or edit → **`keystone_ui-develop`**. Do not
  hand-write ERB or Tailwind for UI it covers.

Questions about which piece fits a scenario are also answered by the develop
local — it owns the catalog.

## Conventions

- **Helpers, not classes.** Every entry point is a view helper prefixed `ui_`,
  called from ERB. Components live under the `Keystone::Ui` namespace, but a
  host app should not name a component class directly.
- **Containers take blocks; leaves take keywords.** Helpers that wrap content
  (page shells, sections, panels, grids, forms, tables) yield a block; helpers
  that render one thing (a button, a badge, a field, a stat) are configured
  entirely by keyword arguments. Composite pieces such as the navigation bar
  expose named slots rather than a single block.
- **Options are symbols, and the accepted set is per-component.** Appearance is
  chosen by name — `variant:`, `size:`, `type:`, `padding:`, `spacing:`,
  `max_width:`, `radius:` — on a small t-shirt scale (`:sm` … `:xl`) or a short
  semantic list. Do not assume one global vocabulary: a button's `variant:` and
  a badge's `variant:` accept different symbols, and `padding:` means different
  things on a page shell than on a panel. The develop local carries the real
  values. An unrecognized symbol raises rather than degrading silently, so a
  wrong guess fails loudly at render time.
- **Semantic color, not literal color.** The themed hue is `accent-*` and the
  themed neutral family is `surface-*` — Tailwind v4 CSS custom properties
  defaulting to blue and zinc, so retheming an app is a token change, not a
  component change. Older components still reach for Tailwind's stock
  `gray-*`/`zinc-*` neutrals directly; the accent hue is themed throughout.
  Dark-mode variants are already built into every component. Changing the
  defaults is install-local territory.
- **Tailwind classes are static strings.** Class names are never interpolated,
  so Tailwind's scanner can see them; the host needs tailwindcss-rails v4+ and
  the engine tells Tailwind where to look.
- **Interactivity is Stimulus.** Dropdowns, modals, dismissible alerts, file
  uploads, tab switchers, column pickers, clipboard copy and similar behavior
  ship with the gem as Stimulus controllers registered in one call at install —
  a host writes no JavaScript to use them.
- Ruby >= 3.2. ViewComponent >= 2.0.
