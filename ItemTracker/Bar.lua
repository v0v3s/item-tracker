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
  button.barIndex = barIndex

  if not button.border then
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
      if not (ItemTrackerDB.bars[self.barIndex].showTooltip and self.itemID) then
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
  end

  return button
end

-- Returns the array of { itemID, threshold } this bar should render: its
-- own manually-curated bar.items when bar.filter is nil (today's
-- behavior, unchanged), or a freshly-scanned list of every currently
-- owned item matching bar.filter (each paired with the bar's single
-- shared bar.filterThreshold) when a filter is active. bar.items is never
-- read or modified while filtered, so switching back to manual restores
-- it exactly as it was.
local function GetDisplayItems(bar)
  if bar.filter then
    local displayItems = {}
    for _, itemID in ipairs(ItemTracker.BagScan.FindMatchingItemIDs(bar.filter)) do
      table.insert(displayItems, { itemID = itemID, threshold = bar.filterThreshold })
    end
    return displayItems
  end
  return bar.items
end

-- Truncates displayItems to at most bar.maxRows * bar.columns entries, or
-- returns it unchanged when bar.maxRows is 0 ("show all", no cap).
-- Applies uniformly to manual and filtered bars alike -- a bar's maximum
-- displayed size is a layout concern, independent of where its items come
-- from.
local function CapDisplayItems(displayItems, bar)
  if not bar.maxRows or bar.maxRows <= 0 then
    return displayItems
  end
  local limit = bar.maxRows * bar.columns
  if #displayItems <= limit then
    return displayItems
  end
  local capped = {}
  for i = 1, limit do
    capped[i] = displayItems[i]
  end
  return capped
end

-- Gap (pixels) between the bar's icon grid and its title, before any
-- user-set titleOffsetX/titleOffsetY nudge is added on top.
local TITLE_GAP = 4

-- Anchors entry.title just outside the given side of entry.frame (whose
-- size already reflects this layout pass's item count), nudged by the
-- bar's own titleOffsetX/titleOffsetY on top of the preset side -- the
-- anchor is live, so the title stays correctly placed as the bar's size
-- changes on a later layout pass without needing to be repositioned here
-- again.
local function PositionTitle(entry, bar)
  local title = entry.title
  local offsetX = bar.titleOffsetX or 0
  local offsetY = bar.titleOffsetY or 0
  title:ClearAllPoints()
  if bar.titlePosition == "BOTTOM" then
    title:SetPoint("TOP", entry.frame, "BOTTOM", offsetX, -TITLE_GAP + offsetY)
  elseif bar.titlePosition == "LEFT" then
    title:SetPoint("RIGHT", entry.frame, "LEFT", -TITLE_GAP + offsetX, offsetY)
  elseif bar.titlePosition == "RIGHT" then
    title:SetPoint("LEFT", entry.frame, "RIGHT", TITLE_GAP + offsetX, offsetY)
  else -- "TOP" (default)
    title:SetPoint("BOTTOM", entry.frame, "TOP", offsetX, TITLE_GAP + offsetY)
  end
end

local function LayoutBar(barIndex)
  local entry = barFrames[barIndex]
  local bar = ItemTrackerDB.bars[barIndex]
  local displayItems = CapDisplayItems(GetDisplayItems(bar), bar)
  local originX, originY = ItemTracker.Logic.ComputeGridOrigin(#displayItems, bar.columns, bar.iconSize, bar.spacing, bar.growth)
  for itemIndex, item in ipairs(displayItems) do
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
  for itemIndex = #displayItems + 1, #entry.buttons do
    entry.buttons[itemIndex]:Hide()
  end
  entry.frame:SetSize(ItemTracker.Logic.ComputeFrameSize(#displayItems, bar))

  if bar.showTitle then
    local fontPath, _, fontFlags = entry.title:GetFont()
    entry.title:SetFont(fontPath, bar.titleFontSize, fontFlags)
    entry.title:SetText(bar.name)
    PositionTitle(entry, bar)
    entry.title:Show()
  else
    entry.title:Hide()
  end
end

-- Creates the bar frame for `barIndex` the FIRST time it's needed, and
-- reuses the same frame object on every later call -- WoW's CreateFrame
-- does not reuse an existing same-named frame (it creates a brand-new
-- one and repoints the global, orphaning the old object, which can
-- never be garbage-collected), so calling CreateFrame more than once
-- per barIndex per session would leak an entire frame tree every time.
local function EnsureBarFrame(barIndex, bar)
  local entry = barFrames[barIndex]
  if not entry then
    local frame = CreateFrame("Frame", "ItemTrackerBar" .. barIndex, UIParent)
    entry = { frame = frame, buttons = {} }
    entry.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    barFrames[barIndex] = entry
  end
  local frame = entry.frame
  frame:ClearAllPoints()
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
  return entry
end

-- Reconciles the live bar frames with ItemTrackerDB.bars: reuses each
-- bar's frame (and its pooled buttons, via LayoutBar) across calls
-- instead of recreating them, since WoW frames are never destroyed.
-- Creates a frame only for a barIndex that has never had one before;
-- hides (never discards) any frame whose barIndex no longer exists.
-- Safe to call on every PLAYER_ENTERING_WORLD (every zone change), and
-- whenever a bar is added or removed.
function ItemTracker.Bar.RebuildAll()
  local bars = ItemTrackerDB.bars
  for barIndex, bar in ipairs(bars) do
    EnsureBarFrame(barIndex, bar)
    LayoutBar(barIndex)
  end
  for barIndex = #bars + 1, #barFrames do
    barFrames[barIndex].frame:Hide()
  end
end

-- Re-lays-out and re-colors every existing bar frame from its current
-- ItemTrackerDB.bars entry. Does not recreate frames -- this is the hot
-- path, called on every BAG_UPDATE etc. Iterates ItemTrackerDB.bars (the
-- authoritative count), not barFrames -- since frames are now pooled
-- rather than recreated each RebuildAll, barFrames can hold more entries
-- than there are current bars (hidden, orphaned by a deletion), and
-- indexing ItemTrackerDB.bars by one of those stale trailing indexes
-- would be nil. Also guards against running before the first RebuildAll
-- (e.g. a BAG_UPDATE during the loading screen, before
-- PLAYER_ENTERING_WORLD has created any frame yet).
function ItemTracker.Bar.RefreshAll()
  for barIndex, bar in ipairs(ItemTrackerDB.bars) do
    local entry = barFrames[barIndex]
    if entry then
      entry.frame:SetScale(bar.scale)
      LayoutBar(barIndex)
    end
  end
end

function ItemTracker.Bar.SetLocked(barIndex, locked)
  ItemTrackerDB.bars[barIndex].locked = locked
end
