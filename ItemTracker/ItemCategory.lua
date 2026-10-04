ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

-- Returns true if an item with the given itemType/itemSubType (as
-- returned by GetItemInfo) matches `filter` ({ itemType = ..., itemSubType
-- = <string> or nil }). A nil filter.itemSubType matches any subtype
-- (including an item with no subtype of its own, itemSubType == "") under
-- filter.itemType.
function ItemTracker.Logic.MatchesFilter(itemType, itemSubType, filter)
  if itemType ~= filter.itemType then
    return false
  end
  if filter.itemSubType == nil then
    return true
  end
  return itemSubType == filter.itemSubType
end
