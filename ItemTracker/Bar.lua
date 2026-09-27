ItemTracker = ItemTracker or {}
ItemTracker.Bar = ItemTracker.Bar or {}

local frame
local buttons = {}

local function ApplyButtonAppearance(button, itemID, count, threshold)
  button.itemID = itemID
  button.icon:SetTexture(ItemTracker.ItemData.GetItemIcon(itemID))
  button.count:SetText(count)
  if ItemTracker.Logic.IsLowStock(count, threshold) then
    button.count:SetTextColor(1, 0.15, 0.15)
    button:SetBackdropBorderColor(1, 0, 0)
  else
    button.count:SetTextColor(1, 1, 1)
    button:SetBackdropBorderColor(0, 0, 0)
  end
end

local function CreateButton(index)
  local button = CreateFrame("Button", "ItemTrackerBarButton" .. index, frame)
  button:SetSize(36, 36)
  button:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })
  button:SetBackdropBorderColor(0, 0, 0)

  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetAllPoints(button)

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
  for index, entry in ipairs(items) do
    local button = GetButton(index)
    local x, y = ItemTracker.Logic.ComputeSlotPosition(index, barOpts.columns, barOpts.iconSize, barOpts.spacing, barOpts.growth)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    button:SetSize(barOpts.iconSize, barOpts.iconSize)
    ApplyButtonAppearance(button, entry.itemID, ItemTracker.ItemData.GetTrackedCount(entry.itemID), entry.threshold)
    button:Show()
  end
  for index = #items + 1, #buttons do
    buttons[index]:Hide()
  end
end

function ItemTracker.Bar.Create()
  if frame then
    return
  end
  frame = CreateFrame("Frame", "ItemTrackerBar", UIParent)
  frame:SetSize(200, 40)
  frame:SetPoint(ItemTrackerDB.bar.point, UIParent, ItemTrackerDB.bar.relPoint, ItemTrackerDB.bar.x, ItemTrackerDB.bar.y)
  frame:SetScale(ItemTrackerDB.bar.scale)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if not ItemTrackerDB.bar.locked then
      self:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    ItemTrackerDB.bar.point = point
    ItemTrackerDB.bar.relPoint = relPoint
    ItemTrackerDB.bar.x = x
    ItemTrackerDB.bar.y = y
  end)

  ItemTracker.Skins.ApplyElvUIToBar(frame)
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
