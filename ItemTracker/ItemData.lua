ItemTracker = ItemTracker or {}
ItemTracker.ItemData = ItemTracker.ItemData or {}

-- Returns the current character's count of itemID across bags + bank.
-- Bank portion is only guaranteed live-accurate while the bank frame is
-- open this session (3.3.5 client limitation: bank slot data goes stale
-- once BANKFRAME_CLOSED fires).
function ItemTracker.ItemData.GetTrackedCount(itemID)
  return GetItemCount(itemID, true) or 0
end

-- Returns the item's icon texture path synchronously (works even for
-- items never seen this session; reads the local client item database,
-- no server round-trip -- unlike GetItemInfo).
function ItemTracker.ItemData.GetItemIcon(itemID)
  return GetItemIcon(itemID)
end

-- Resolves itemID's display name, retrying if the client hasn't cached
-- the item yet (GetItemInfo returns nil on first call for unseen items;
-- 3.3.5 has no GET_ITEM_INFO_RECEIVED event, so we poll instead).
-- Calls callback(name) once resolved -- synchronously if already cached.
function ItemTracker.ItemData.ResolveItemName(itemID, callback)
  local name = GetItemInfo(itemID)
  if name then
    callback(name)
    return
  end
  local ticker = CreateFrame("Frame")
  local elapsed = 0
  local totalElapsed = 0
  ticker:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    totalElapsed = totalElapsed + delta
    if elapsed < 0.2 then
      return
    end
    elapsed = 0
    local resolvedName = GetItemInfo(itemID)
    if resolvedName then
      self:SetScript("OnUpdate", nil)
      callback(resolvedName)
    elseif totalElapsed > 5 then
      self:SetScript("OnUpdate", nil)
    end
  end)
end
