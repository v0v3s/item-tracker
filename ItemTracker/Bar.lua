ItemTracker = ItemTracker or {}
ItemTracker.Bar = ItemTracker.Bar or {}

local barFrames = {}

-- Shared by both a bar's own frame and every icon button on it (both
-- get `.barIndex` set) -- always moves the BAR frame for that index,
-- never `self` directly, since a button's own StartMoving() would just
-- drag the button.
local function StartBarDrag(self)
  local bar = ItemTrackerDB.bars[self.barIndex]
  if bar and not bar.locked then
    barFrames[self.barIndex].frame:StartMoving()
  end
end

local function StopBarDrag(self)
  local barIndex = self.barIndex
  local frame = barFrames[barIndex].frame
  frame:StopMovingOrSizing()
  local point, _, relPoint, x, y = frame:GetPoint()
  local bar = ItemTrackerDB.bars[barIndex]
  bar.point = point
  bar.relPoint = relPoint
  bar.x = x
  bar.y = y
end

local function ApplyButtonAppearance(button, itemID, count, threshold)
  button.itemID = itemID
  button.icon:SetTexture(ItemTracker.ItemData.GetItemIcon(itemID))
  button.count:SetText(count)
  if ItemTracker.Logic.IsLowStock(count, threshold) then
    button.count:SetTextColor(1, 0.15, 0.15)
    button.border:SetVertexColor(1, 0, 0)
  else
    button.count:SetTextColor(1, 1, 1)
    button.border:SetVertexColor(0, 0, 0)
  end
end

local function CreateButton(parentFrame, barIndex, buttonIndex)
  local button = CreateFrame("Button", "ItemTrackerBarButton" .. barIndex .. "_" .. buttonIndex, parentFrame)
  button:SetSize(36, 36)

  button.border = button:CreateTexture(nil, "BACKGROUND")
  button.border:SetAllPoints(button)
  button.border:SetTexture(1, 1, 1)
  button.border:SetVertexColor(0, 0, 0)

  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
  button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
  button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  button.count:SetPoint("BOTTOMRIGHT", -2, 2)

  button:SetScript("OnEnter", function(self)
    if not (ItemTrackerDB.bars[barIndex].showTooltip and self.itemID) then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. self.itemID)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  button.barIndex = barIndex
  button:RegisterForDrag("LeftButton")
  button:SetScript("OnDragStart", StartBarDrag)
  button:SetScript("OnDragStop", StopBarDrag)

  return button
end

local function LayoutBar(barIndex)
  local entry = barFrames[barIndex]
  local bar = ItemTrackerDB.bars[barIndex]
  local originX, originY = ItemTracker.Logic.ComputeGridOrigin(#bar.items, bar.columns, bar.iconSize, bar.spacing, bar.growth)
  for itemIndex, item in ipairs(bar.items) do
    local button = entry.buttons[itemIndex]
    if not button then
      button = CreateButton(entry.frame, barIndex, itemIndex)
      entry.buttons[itemIndex] = button
    end
    local x, y = ItemTracker.Logic.ComputeSlotPosition(itemIndex, bar.columns, bar.iconSize, bar.spacing, bar.growth)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", entry.frame, "TOPLEFT", x + originX, y + originY)
    button:SetSize(bar.iconSize, bar.iconSize)
    ApplyButtonAppearance(button, item.itemID, ItemTracker.ItemData.GetTrackedCount(item.itemID), item.threshold)
    button:Show()
  end
  for itemIndex = #bar.items + 1, #entry.buttons do
    entry.buttons[itemIndex]:Hide()
  end
  entry.frame:SetSize(ItemTracker.Logic.ComputeFrameSize(#bar.items, bar))
end

-- Hides every existing bar frame and creates one fresh frame per entry
-- in ItemTrackerDB.bars. Called on login, and again whenever a bar is
-- added or removed -- a rare, deliberate action, not the hot path, so
-- recreating everything is simpler than tracking stable bar IDs to
-- patch a single frame. Any leftover frame from a deleted bar (there
-- are now fewer entries than before) stays hidden forever, an
-- accepted, negligible one-time cost -- see the spec's Open Risks.
function ItemTracker.Bar.RebuildAll()
  for _, entry in ipairs(barFrames) do
    entry.frame:Hide()
  end
  barFrames = {}

  for barIndex, bar in ipairs(ItemTrackerDB.bars) do
    local frame = CreateFrame("Frame", "ItemTrackerBar" .. barIndex, UIParent)
    frame:SetPoint(bar.point, UIParent, bar.relPoint, bar.x, bar.y)
    frame:SetScale(bar.scale)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame.barIndex = barIndex
    frame:SetScript("OnDragStart", StartBarDrag)
    frame:SetScript("OnDragStop", StopBarDrag)
    frame:Show()

    barFrames[barIndex] = { frame = frame, buttons = {} }
    LayoutBar(barIndex)
  end
end

-- Re-lays-out and re-colors every existing bar frame from its current
-- ItemTrackerDB.bars entry. Does not recreate frames -- this is the hot
-- path, called on every BAG_UPDATE etc.
function ItemTracker.Bar.RefreshAll()
  for barIndex, entry in ipairs(barFrames) do
    entry.frame:SetScale(ItemTrackerDB.bars[barIndex].scale)
    LayoutBar(barIndex)
  end
end

function ItemTracker.Bar.SetLocked(barIndex, locked)
  ItemTrackerDB.bars[barIndex].locked = locked
end
