dofile("ItemTracker/Logic/ItemList.lua")

local items = {}

local ok, err = ItemTracker.Logic.AddItem(items, 6948, 1)
assert(ok == true and err == nil, "adding a new item should succeed")
assert(#items == 1 and items[1].itemID == 6948 and items[1].threshold == 1, "item should be appended with given threshold")

ok, err = ItemTracker.Logic.AddItem(items, 6948, 2)
assert(ok == false and err ~= nil, "adding a duplicate item should fail")
assert(#items == 1, "duplicate add should not append a second entry")

assert(ItemTracker.Logic.FindItemIndex(items, 6948) == 1, "should find existing item's index")
assert(ItemTracker.Logic.FindItemIndex(items, 12345) == nil, "should return nil for untracked item")

local updated = ItemTracker.Logic.SetThreshold(items, 6948, 5)
assert(updated == true and items[1].threshold == 5, "threshold should update for tracked item")

local updatedMissing = ItemTracker.Logic.SetThreshold(items, 999, 5)
assert(updatedMissing == false, "updating threshold of untracked item should fail")

local removed = ItemTracker.Logic.RemoveItem(items, 6948)
assert(removed == true and #items == 0, "removing a tracked item should succeed and empty the list")

local removedAgain = ItemTracker.Logic.RemoveItem(items, 6948)
assert(removedAgain == false, "removing an already-removed item should return false")

print("itemlist_test: all assertions passed")
