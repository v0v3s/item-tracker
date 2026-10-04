# Changelog

All notable changes to ItemTracker are documented here. Versions are
semver (MAJOR.MINOR.PATCH), tagged `<WoW patch>-v<semver>` (e.g.
`3.3.5-v1.2.0`) — each patch this addon targets (3.3.5a today, possibly
others later) tracks its own version history independently. The addon's
own `.toc` shows just the bare semver (e.g. `1.2.0`). The very first
release predates both schemes and is just `v1`.

## [Unreleased]

## [3.3.5-v1.2.0] - 2026-10-04

### Added

- **Category filters** — a bar can auto-populate from the game's own item
  type/subtype classification (e.g. "Trade Goods > Enchanting") instead
  of a manually curated list, live-updating as matching items are
  acquired or lost.
- **Bar title** — optionally show a bar's own name next to its icons,
  with a choice of side (top/bottom/left/right), a position nudge, and
  an adjustable font size.
- **Maximum Rows** — cap how many rows of items a bar displays at once
  (0 = show all, however many rows that takes).

### Changed

- The config window's bar-options section is now two columns
  (parameters on the left, items on the right) instead of one long
  stacked list.
- The "Columns" slider is now labeled "Items per Row" (same setting,
  clearer name).

## [3.3.5-v1.1.0] - 2026-10-04

### Added

- **Multiple bars** — create, rename, and delete any number of independent
  tracker bars from one config window with a bar selector. Each bar has
  its own tracked items, position, lock state, icon size, columns,
  growth direction, and scale.

### Changed

- Existing single-bar saved data is migrated automatically into a bar
  named "Bar 1" the first time you log in after updating — no data loss,
  no action needed.

## [v1] - 2026-09-27

### Added

- Initial release: configurable, movable, action-bar-style item tracker.
- Add tracked items by name, item link, numeric ID, or drag-and-drop.
- Live bag + bank count updates.
- Per-item low-stock threshold with a red warning color.
- Configurable icon size, columns, growth direction, scale, and
  lock-in-place.
- Optional ElvUI skin support.
