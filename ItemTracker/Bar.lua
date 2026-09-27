ItemTracker = ItemTracker or {}
ItemTracker.Bar = ItemTracker.Bar or {}

local frame
local buttons = {}

local function StartBarDrag()
  if not ItemTrackerDB.bar.locked then
    frame:StartMoving()
  end
end

local function StopBarDrag()
  frame:StopMovingOrSizing()
  local point, _, relPoint, x, y = frame:GetPoint()
  ItemTrackerDB.bar.point = point
  ItemTrackerDB.bar.relPoint = relPoint
  ItemTrackerDB.bar.x = x
  ItemTrackerDB.bar.y = y
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

local function CreateButton(index)
  local button = CreateFrame("Button", "ItemTrackerBarButton" .. index, frame)
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
    if not (ItemTrackerDB.bar.showTooltip and self.itemID) then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. self.itemID)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  button:RegisterForDrag("LeftButton")
  button:SetScript("OnDragStart", StartBarDrag)
  button:SetScript("OnDragStop", StopBarDrag)

  return button
end

local function GetButton(index)
  local button = buttons[index]
  if not button then
    button = CreateButton(index)
    buttons[index] = button
  end
  return button
end

local function LayoutButtons()
  local barOpts = ItemTrackerDB.bar
  local items = ItemTrackerDB.items
  local originX, originY = ItemTracker.Logic.ComputeGridOrigin(#items, barOpts.columns, barOpts.iconSize, barOpts.spacing, barOpts.growth)
  for index, entry in ipairs(items) do
    local button = GetButton(index)
    local x, y = ItemTracker.Logic.ComputeSlotPosition(index, barOpts.columns, barOpts.iconSize, barOpts.spacing, barOpts.growth)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", x + originX, y + originY)
    button:SetSize(barOpts.iconSize, barOpts.iconSize)
    ApplyButtonAppearance(button, entry.itemID, ItemTracker.ItemData.GetTrackedCount(entry.itemID), entry.threshold)
    button:Show()
  end
  for index = #items + 1, #buttons do
    buttons[index]:Hide()
  end
  frame:SetSize(ItemTracker.Logic.ComputeFrameSize(#items, barOpts))
end

function ItemTracker.Bar.Create()
  if frame then
    return
  end
  frame = CreateFrame("Frame", "ItemTrackerBar", UIParent)
  frame:SetSize(ItemTracker.Logic.ComputeFrameSize(#ItemTrackerDB.items, ItemTrackerDB.bar))
  frame:SetPoint(ItemTrackerDB.bar.point, UIParent, ItemTrackerDB.bar.relPoint, ItemTrackerDB.bar.x, ItemTrackerDB.bar.y)
  frame:SetScale(ItemTrackerDB.bar.scale)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", StartBarDrag)
  frame:SetScript("OnDragStop", StopBarDrag)
end

function ItemTracker.Bar.Refresh()
  if not frame then
    return
  end
  frame:SetScale(ItemTrackerDB.bar.scale)
  LayoutButtons()
end

function ItemTracker.Bar.SetLocked(locked)
  ItemTrackerDB.bar.locked = locked
end
