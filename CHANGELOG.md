# Changelog

All notable changes to ItemTracker are documented here. Versions follow
`<WoW patch>-v<N>` (e.g. `3.3.5-v2`) — each patch this addon targets
(3.3.5a today, possibly others later) has its own independent release
count. The very first release predates that scheme and is just `v1`.

## [3.3.5-v2]

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
