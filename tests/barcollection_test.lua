dofile("ItemTracker/BarCollection.lua")

local template = {
  items = {}, iconSize = 36, columns = 8, spacing = 4, growth = "RIGHT",
  scale = 1.0, locked = false, showTooltip = true,
  point = "CENTER", relPoint = "CENTER", x = 0, y = 0,
}

local bars = {}
local newIndex = ItemTracker.Logic.AddBar(bars, "Bar 1", template)
assert(newIndex == 1, "first AddBar should return index 1")
assert(#bars == 1 and bars[1].name == "Bar 1", "bar should be appended with the given name")
assert(bars[1].iconSize == 36, "new bar should be seeded from the template")

bars[1].items[1] = { itemID = 1, threshold = 1 }
assert(#template.items == 0, "mutating the new bar's items must not mutate the template")

local secondIndex = ItemTracker.Logic.AddBar(bars, "Bar 2", template)
assert(secondIndex == 2 and #bars == 2, "second AddBar should append at index 2")

local removedOk, removedErr = ItemTracker.Logic.RemoveBar(bars, 1)
assert(removedOk == true and removedErr == nil and #bars == 1, "removing a non-last bar should succeed")
assert(bars[1].name == "Bar 2", "remaining bar should shift down to index 1")

local lastOk, lastErr = ItemTracker.Logic.RemoveBar(bars, 1)
assert(lastOk == false and lastErr ~= nil, "removing the last remaining bar should be refused")
assert(#bars == 1, "refused removal should not change the bars array")

local missingOk = ItemTracker.Logic.RemoveBar(bars, 5)
assert(missingOk == false, "removing a nonexistent index should fail safely")

local renamedOk = ItemTracker.Logic.RenameBar(bars, 1, "Flasks")
assert(renamedOk == true and bars[1].name == "Flasks", "renaming an existing bar should update its name")

local emptyNameOk = ItemTracker.Logic.RenameBar(bars, 1, "   ")
assert(emptyNameOk == true and bars[1].name == "Bar 1", "renaming to a blank name should fall back to 'Bar <index>'")

local missingRenameOk = ItemTracker.Logic.RenameBar(bars, 9, "Nope")
assert(missingRenameOk == false, "renaming a nonexistent index should fail safely")

print("barcollection_test: all assertions passed")
