dofile("ItemTracker/Logic/Defaults.lua")

local result = ItemTracker.Logic.MergeDefaults({}, ItemTracker.Logic.DEFAULT_DB)
assert(result.bar.iconSize == 36, "expected default iconSize 36, got " .. tostring(result.bar.iconSize))
assert(result.bar.growth == "RIGHT", "expected default growth RIGHT")
assert(type(result.items) == "table" and #result.items == 0, "expected empty items array")

local partial = { bar = { iconSize = 50 } }
local merged = ItemTracker.Logic.MergeDefaults(partial, ItemTracker.Logic.DEFAULT_DB)
assert(merged.bar.iconSize == 50, "existing iconSize should not be overwritten")
assert(merged.bar.columns == 8, "missing columns should be filled from defaults")

merged.bar.iconSize = 999
assert(ItemTracker.Logic.DEFAULT_DB.bar.iconSize == 36, "mutating result must not mutate DEFAULT_DB")

print("defaults_test: all assertions passed")
