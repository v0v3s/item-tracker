dofile("ItemTracker/Defaults.lua")

local result = ItemTracker.Logic.MergeDefaults({}, ItemTracker.Logic.DEFAULT_DB)
assert(#result.bars == 1, "expected exactly one default bar")
assert(result.bars[1].name == "Bar 1", "expected default bar name 'Bar 1'")
assert(result.bars[1].iconSize == 36, "expected default iconSize 36, got " .. tostring(result.bars[1].iconSize))
assert(result.bars[1].growth == "RIGHT", "expected default growth RIGHT")
assert(type(result.bars[1].items) == "table" and #result.bars[1].items == 0, "expected empty items array")
assert(result.config.selectedBar == 1, "expected default selectedBar 1")

local partial = { bars = { { iconSize = 50 } } }
local merged = ItemTracker.Logic.MergeDefaults(partial, ItemTracker.Logic.DEFAULT_DB)
assert(merged.bars[1].iconSize == 50, "existing iconSize should not be overwritten")
assert(merged.bars[1].columns == 8, "missing columns should be filled from defaults")

merged.bars[1].iconSize = 999
assert(ItemTracker.Logic.DEFAULT_DB.bars[1].iconSize == 36, "mutating result must not mutate DEFAULT_DB")

-- MigrateLegacyBar: legacy single-bar shape converts to the bars array shape
local legacy = {
  items = { { itemID = 6948, threshold = 1 } },
  bar = {
    point = "CENTER", relPoint = "CENTER", x = 10, y = 20,
    iconSize = 40, columns = 6, spacing = 2, growth = "LEFT",
    scale = 1.2, locked = true, showTooltip = false,
  },
}
local migrated = ItemTracker.Logic.MigrateLegacyBar(legacy)
assert(migrated.items == nil and migrated.bar == nil, "legacy top-level items/bar keys should be removed after migration")
assert(type(migrated.bars) == "table" and #migrated.bars == 1, "migration should produce exactly one bar")
assert(migrated.bars[1].name == "Bar 1", "migrated bar should be named 'Bar 1'")
assert(migrated.bars[1].iconSize == 40 and migrated.bars[1].growth == "LEFT" and migrated.bars[1].locked == true, "migrated bar should keep the legacy bar settings")
assert(#migrated.bars[1].items == 1 and migrated.bars[1].items[1].itemID == 6948, "migrated bar should keep the legacy items list")

-- MigrateLegacyBar: already-migrated data (bars already present) is untouched
local alreadyMigrated = { bars = { { name = "Custom", items = {} } } }
local unchanged = ItemTracker.Logic.MigrateLegacyBar(alreadyMigrated)
assert(#unchanged.bars == 1 and unchanged.bars[1].name == "Custom", "already-migrated data should pass through unchanged")

-- MigrateLegacyBar: fresh install (no legacy data at all) is a no-op
local fresh = {}
local stillFresh = ItemTracker.Logic.MigrateLegacyBar(fresh)
assert(stillFresh.bars == nil, "fresh install with no legacy data should not gain a bars key from migration alone")

-- MigrateLegacyBar: an empty bars array (corrupted or hand-edited data)
-- is cleared so MergeDefaults can fill in a fresh default bar afterward
local corrupted = { bars = {} }
local fixedUp = ItemTracker.Logic.MigrateLegacyBar(corrupted)
assert(fixedUp.bars == nil, "an empty bars array should be cleared so MergeDefaults can repopulate it")
local recovered = ItemTracker.Logic.MergeDefaults(fixedUp, ItemTracker.Logic.DEFAULT_DB)
assert(#recovered.bars == 1 and recovered.bars[1].name == "Bar 1", "recovered data should have exactly one default bar")

-- MergeAllBarDefaults: every bar gets missing keys filled from the
-- template, not just the first one (simulates a future new per-bar key)
local multiBar = { { name = "Bar 1", iconSize = 36 }, { name = "Bar 2" } }
ItemTracker.Logic.MergeAllBarDefaults(multiBar, { iconSize = 99, columns = 8 })
assert(multiBar[1].iconSize == 36, "existing bar 1 value should not be overwritten")
assert(multiBar[2].iconSize == 99 and multiBar[2].columns == 8, "bar 2 missing keys should be filled from the template too")

-- Category Filters: a fresh bar defaults to manual mode (filter == nil)
-- with a filterThreshold ready for when a filter is turned on
local freshFilterCheck = ItemTracker.Logic.MergeDefaults({}, ItemTracker.Logic.DEFAULT_DB)
assert(freshFilterCheck.bars[1].filterThreshold == 1, "expected default filterThreshold 1")
assert(freshFilterCheck.bars[1].filter == nil, "a fresh bar should default to manual mode (filter == nil)")

-- MergeAllBarDefaults backfills filterThreshold onto a bar saved before
-- Category Filters existed, without inventing a filter for it
local preFilterBar = { { name = "Bar 1", iconSize = 36 } }
ItemTracker.Logic.MergeAllBarDefaults(preFilterBar, ItemTracker.Logic.DEFAULT_DB.bars[1])
assert(preFilterBar[1].filterThreshold == 1, "a bar saved before Category Filters existed should be backfilled with filterThreshold 1")
assert(preFilterBar[1].filter == nil, "backfilling must not invent a filter for a pre-existing manual bar")

-- Bar Title: a fresh bar defaults to the title hidden, with sensible
-- position/offset/font-size values ready for when it's turned on
local freshTitleCheck = ItemTracker.Logic.MergeDefaults({}, ItemTracker.Logic.DEFAULT_DB)
assert(freshTitleCheck.bars[1].showTitle == false, "expected title hidden by default")
assert(freshTitleCheck.bars[1].titlePosition == "TOP", "expected default titlePosition TOP")
assert(freshTitleCheck.bars[1].titleOffsetX == 0 and freshTitleCheck.bars[1].titleOffsetY == 0, "expected zero default title offsets")
assert(freshTitleCheck.bars[1].titleFontSize == 12, "expected default titleFontSize 12")

-- MergeAllBarDefaults backfills the title fields onto a bar saved before
-- the Bar Title feature existed
local preTitleBar = { { name = "Bar 1", iconSize = 36 } }
ItemTracker.Logic.MergeAllBarDefaults(preTitleBar, ItemTracker.Logic.DEFAULT_DB.bars[1])
assert(preTitleBar[1].showTitle == false, "a bar saved before Bar Title existed should be backfilled with showTitle false")
assert(preTitleBar[1].titlePosition == "TOP" and preTitleBar[1].titleFontSize == 12, "a bar saved before Bar Title existed should be backfilled with the default position/font size")

print("defaults_test: all assertions passed")
