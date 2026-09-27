ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

-- Returns the 1-based index of itemID in items, or nil if not present.
function ItemTracker.Logic.FindItemIndex(items, itemID)
  for index, entry in ipairs(items) do
    if entry.itemID == itemID then
      return index
    end
  end
  return nil
end

-- Appends {itemID, threshold} to items if itemID isn't already tracked.
-- Returns true, nil on success or false, errorMessage if it's a duplicate.
function ItemTracker.Logic.AddItem(items, itemID, threshold)
  if ItemTracker.Logic.FindItemIndex(items, itemID) then
    return false, "item already tracked"
  end
  table.insert(items, { itemID = itemID, threshold = threshold or 1 })
  return true, nil
end

-- Removes itemID from items if present. Returns true if something was
-- removed, false otherwise.
function ItemTracker.Logic.RemoveItem(items, itemID)
  local index = ItemTracker.Logic.FindItemIndex(items, itemID)
  if not index then
    return false
  end
  table.remove(items, index)
  return true
end

-- Updates the threshold of an already-tracked item. Returns true if
-- found and updated, false if itemID isn't tracked.
function ItemTracker.Logic.SetThreshold(items, itemID, threshold)
  local index = ItemTracker.Logic.FindItemIndex(items, itemID)
  if not index then
    return false
  end
  items[index].threshold = threshold
  return true
end
