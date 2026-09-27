dofile("ItemTracker/Logic/ItemInput.lua")

local id, err = ItemTracker.Logic.ParseItemInput("6948")
assert(id == 6948 and err == nil, "plain numeric ID should parse")

id, err = ItemTracker.Logic.ParseItemInput("  6948  ")
assert(id == 6948, "should trim whitespace")

id, err = ItemTracker.Logic.ParseItemInput("|cffffffff|Hitem:6948:0:0:0:0:0:0:0:0|h[Hearthstone]|h|r")
assert(id == 6948, "should extract itemID from a full item link, got " .. tostring(id))

id, err = ItemTracker.Logic.ParseItemInput("item:6948")
assert(id == 6948, "should extract itemID from a bare item:<id> string")

id, err = ItemTracker.Logic.ParseItemInput("Hearthstone")
assert(id == nil and err ~= nil, "plain item name should fail to parse (not resolvable as pure logic)")

id, err = ItemTracker.Logic.ParseItemInput("")
assert(id == nil and err ~= nil, "empty input should fail to parse")

print("iteminput_test: all assertions passed")
