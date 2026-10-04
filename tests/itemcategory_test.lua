dofile("ItemTracker/ItemCategory.lua")

assert(ItemTracker.Logic.MatchesFilter("Trade Goods", "Enchanting", { itemType = "Trade Goods" }) == true,
  "nil filter subtype should match any subtype under the right type")
assert(ItemTracker.Logic.MatchesFilter("Trade Goods", "Enchanting", { itemType = "Trade Goods", itemSubType = "Enchanting" }) == true,
  "matching type and subtype should match")
assert(ItemTracker.Logic.MatchesFilter("Trade Goods", "Elemental", { itemType = "Trade Goods", itemSubType = "Enchanting" }) == false,
  "mismatched subtype should not match")
assert(ItemTracker.Logic.MatchesFilter("Consumable", "Enchanting", { itemType = "Trade Goods", itemSubType = "Enchanting" }) == false,
  "mismatched type should not match regardless of subtype")
assert(ItemTracker.Logic.MatchesFilter("Trade Goods", "", { itemType = "Trade Goods", itemSubType = "Enchanting" }) == false,
  "an item with no subtype should not match a filter that requires a specific one")
assert(ItemTracker.Logic.MatchesFilter("Trade Goods", "", { itemType = "Trade Goods" }) == true,
  "an item with no subtype should still match a type-only (nil subtype) filter")

print("itemcategory_test: all assertions passed")
