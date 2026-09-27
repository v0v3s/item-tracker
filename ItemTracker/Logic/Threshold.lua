ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

-- Returns true if count is below threshold and threshold is a positive
-- warning value. A nil or non-positive threshold means "no warning".
function ItemTracker.Logic.IsLowStock(count, threshold)
  if not threshold or threshold <= 0 then
    return false
  end
  return (count or 0) < threshold
end
