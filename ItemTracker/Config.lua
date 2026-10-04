ItemTracker = ItemTracker or {}
ItemTracker.Config = ItemTracker.Config or {}

local ROW_HEIGHT = 36
local NUM_VISIBLE_ROWS = 6

-- Two-column layout below the bar selector row: parameters (category
-- filter, lock, sliders, growth) on the left, items (the add-row plus the
-- item list -- manually-curated or, while filtered, read-only and
-- live-scanned) on the right, separated by a vertical divider line.
local LEFT_COLUMN_X = 24
local RIGHT_COLUMN_X = 300
local DIVIDER_X = 280
local CONTENT_TOP_Y = -90

local frame
local addEditBox
local addError
local rows = {}
local scrollFrame
local selectedBar = 1
local barDropdown
local barNameBox
local newBarButton
local deleteBarButton
local lockCheck
local titleCheck
local titlePositionDropdown
local titleOffsetXSlider
local titleOffsetYSlider
local titleFontSizeSlider
local iconSizeSlider
local columnsSlider
local maxRowsSlider
local scaleSlider
local growthDropdown
local instructions
local dragSlot
local filterStatus
local filterTypeDropdown
local filterSubTypeDropdown
local filterThresholdSlider

-- The left (parameters) column's rows, top to bottom, populated by
-- CreateBarOptions once every widget exists. Declared here (not just
-- inside CreateBarOptions) so RelayoutLeftColumn -- assigned by
-- CreateBarOptions too, same forward-declared-upvalue pattern used
-- throughout this file for every widget local -- can read it from
-- RefreshBarOptions and the Show Title checkbox, both defined earlier in
-- this file than CreateBarOptions runs.
local leftColumnRows
local RelayoutLeftColumn

local function FormatSliderValue(value, step)
  if step >= 1 then
    return tostring(math.floor(value + 0.5))
  end
  return string.format("%.2f", value)
end

-- Toggles the config window's add-row vs. category-filter-only controls
-- in the ITEMS (right) column. The item list itself (scrollFrame/rows) is
-- always shown -- see RefreshList. The PARAMETERS (left) column's own
-- conditional rows (filter subtype, title options, low-stock threshold)
-- are handled by RelayoutLeftColumn instead, since hiding one of those
-- must also close the gap it would otherwise leave behind. Never mixed --
-- see the plan's Global Constraints.
local function SetManualUIShown(shown)
  if shown then
    instructions:Show()
    addEditBox:Show()
    dragSlot:Show()
    addError:Show()
    filterStatus:Hide()
  else
    instructions:Hide()
    addEditBox:Hide()
    dragSlot:Hide()
    addError:Hide()
    filterStatus:Show()
  end
end

-- Populates the item list: bar.items (manually-curated, editable) when
-- bar.filter is nil, or a fresh live scan (read-only -- no per-item
-- threshold or remove control, since a filtered bar's membership and
-- threshold aren't edited per-item) when a filter is active.
local function RefreshList()
  local bar = ItemTrackerDB.bars[selectedBar]
  local items
  if bar.filter then
    items = {}
    for _, itemID in ipairs(ItemTracker.BagScan.FindMatchingItemIDs(bar.filter)) do
      table.insert(items, { itemID = itemID })
    end
    filterStatus:SetText("Showing " .. #items .. " items")
  else
    items = bar.items
  end
  FauxScrollFrame_Update(scrollFrame, #items, NUM_VISIBLE_ROWS, ROW_HEIGHT)
  local offset = FauxScrollFrame_GetOffset(scrollFrame)
  for rowIndex = 1, NUM_VISIBLE_ROWS do
    local dataIndex = rowIndex + offset
    local row = rows[rowIndex]
    local entry = items[dataIndex]
    if entry then
      row.itemID = entry.itemID
      row.icon:SetTexture(ItemTracker.ItemData.GetItemIcon(entry.itemID))
      row.nameText:SetText("Item " .. entry.itemID)
      ItemTracker.ItemData.ResolveItemName(entry.itemID, function(name)
        if row.itemID == entry.itemID then
          row.nameText:SetText(name)
        end
      end)
      if bar.filter then
        row.thresholdBox:Hide()
        row.removeButton:Hide()
      else
        row.thresholdBox:SetText(tostring(entry.threshold))
        row.thresholdBox:Show()
        row.removeButton:Show()
      end
      row:Show()
    else
      row.itemID = nil
      row:Hide()
    end
  end
end

local function RefreshBarOptions()
  local bar = ItemTrackerDB.bars[selectedBar]
  lockCheck:SetChecked(bar.locked)

  titleCheck:SetChecked(bar.showTitle)
  if bar.showTitle then
    UIDropDownMenu_SetSelectedValue(titlePositionDropdown, bar.titlePosition)
    UIDropDownMenu_SetText(titlePositionDropdown, bar.titlePosition)
    titleOffsetXSlider:SetValue(bar.titleOffsetX)
    titleOffsetXSlider.valueBox:SetText(FormatSliderValue(bar.titleOffsetX, 1))
    titleOffsetYSlider:SetValue(bar.titleOffsetY)
    titleOffsetYSlider.valueBox:SetText(FormatSliderValue(bar.titleOffsetY, 1))
    titleFontSizeSlider:SetValue(bar.titleFontSize)
    titleFontSizeSlider.valueBox:SetText(FormatSliderValue(bar.titleFontSize, 1))
  end

  iconSizeSlider:SetValue(bar.iconSize)
  iconSizeSlider.valueBox:SetText(FormatSliderValue(bar.iconSize, 1))
  columnsSlider:SetValue(bar.columns)
  columnsSlider.valueBox:SetText(FormatSliderValue(bar.columns, 1))
  maxRowsSlider:SetValue(bar.maxRows)
  maxRowsSlider.valueBox:SetText(FormatSliderValue(bar.maxRows, 1))
  scaleSlider:SetValue(bar.scale)
  scaleSlider.valueBox:SetText(FormatSliderValue(bar.scale, 0.05))
  UIDropDownMenu_SetSelectedValue(growthDropdown, bar.growth)
  UIDropDownMenu_SetText(growthDropdown, bar.growth)

  if bar.filter then
    UIDropDownMenu_SetSelectedValue(filterTypeDropdown, bar.filter.itemType)
    UIDropDownMenu_SetText(filterTypeDropdown, bar.filter.itemType)
    UIDropDownMenu_SetSelectedValue(filterSubTypeDropdown, bar.filter.itemSubType)
    UIDropDownMenu_SetText(filterSubTypeDropdown, bar.filter.itemSubType or "All")
    filterThresholdSlider:SetValue(bar.filterThreshold)
    filterThresholdSlider.valueBox:SetText(FormatSliderValue(bar.filterThreshold, 1))
  else
    UIDropDownMenu_SetSelectedValue(filterTypeDropdown, nil)
    UIDropDownMenu_SetText(filterTypeDropdown, "None (manual)")
  end

  RelayoutLeftColumn()
end

local function RefreshBarUI()
  local bar = ItemTrackerDB.bars[selectedBar]
  UIDropDownMenu_SetSelectedValue(barDropdown, selectedBar)
  UIDropDownMenu_SetText(barDropdown, bar.name)
  barNameBox:SetText(bar.name)
  if #ItemTrackerDB.bars > 1 then
    deleteBarButton:Enable()
  else
    deleteBarButton:Disable()
  end
  SetManualUIShown(bar.filter == nil)
  RefreshList()
  RefreshBarOptions()
end

local function CreateRow(index)
  local row = CreateFrame("Frame", "ItemTrackerConfigRow" .. index, frame)
  row:SetSize(236, ROW_HEIGHT)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(28, 28)
  row.icon:SetPoint("LEFT", 4, 0)
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
  row.nameText:SetWidth(120)
  row.nameText:SetJustifyH("LEFT")

  row.thresholdBox = CreateFrame("EditBox", "ItemTrackerConfigRowThreshold" .. index, row, "InputBoxTemplate")
  row.thresholdBox:SetSize(40, 20)
  row.thresholdBox:SetPoint("LEFT", row.nameText, "RIGHT", 8, 0)
  row.thresholdBox:SetAutoFocus(false)
  row.thresholdBox:SetNumeric(true)
  row.thresholdBox:SetScript("OnEnterPressed", function(self)
    local threshold = tonumber(self:GetText()) or 1
    ItemTracker.Logic.SetThreshold(ItemTrackerDB.bars[selectedBar].items, row.itemID, threshold)
    self:ClearFocus()
    ItemTracker.Bar.RefreshAll()
  end)
  row.thresholdBox:SetScript("OnEditFocusLost", function(self)
    local threshold = tonumber(self:GetText()) or 1
    ItemTracker.Logic.SetThreshold(ItemTrackerDB.bars[selectedBar].items, row.itemID, threshold)
    ItemTracker.Bar.RefreshAll()
  end)
  row.thresholdBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    RefreshList()
  end)

  row.removeButton = CreateFrame("Button", "ItemTrackerConfigRowRemove" .. index, row, "UIPanelCloseButton")
  row.removeButton:SetSize(20, 20)
  row.removeButton:SetPoint("RIGHT", -4, 0)
  row.removeButton:SetScript("OnClick", function()
    ItemTracker.Logic.RemoveItem(ItemTrackerDB.bars[selectedBar].items, row.itemID)
    RefreshList()
    ItemTracker.Bar.RefreshAll()
  end)

  return row
end

local function ShowAddError(message)
  addError:SetText(message or "")
end

local function TryAddItemID(itemID)
  if not itemID or not ItemTracker.ItemData.GetItemIcon(itemID) then
    ShowAddError("item not found")
    return
  end
  local ok, err = ItemTracker.Logic.AddItem(ItemTrackerDB.bars[selectedBar].items, itemID, 1)
  if not ok then
    ShowAddError(err)
    return
  end
  ShowAddError(nil)
  RefreshList()
  ItemTracker.Bar.RefreshAll()
end

local function HandleAddInput(text)
  local itemID, err = ItemTracker.Logic.ParseItemInput(text)
  if itemID then
    TryAddItemID(itemID)
    return
  end
  -- ParseItemInput only handles numeric IDs and item links; fall back to
  -- resolving a plain typed item name via the WoW API for everything else.
  local name, link = GetItemInfo(text)
  if link then
    TryAddItemID(tonumber(link:match("item:(%d+)")))
  else
    ShowAddError(err or "item not found")
  end
end

local function HandleCursorDrop()
  local infoType, itemID = GetCursorInfo()
  ClearCursor()
  if infoType == "item" then
    TryAddItemID(itemID)
  end
end

local function CreateBarSelector(parent)
  barDropdown = CreateFrame("Frame", "ItemTrackerConfigBarDropdown", parent, "UIDropDownMenuTemplate")
  barDropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -50)
  UIDropDownMenu_SetWidth(barDropdown, 110)
  UIDropDownMenu_Initialize(barDropdown, function(self, level)
    for index, bar in ipairs(ItemTrackerDB.bars) do
      local option = UIDropDownMenu_CreateInfo()
      option.text = bar.name
      option.value = index
      option.func = function(self)
        selectedBar = self.value
        ItemTrackerDB.config.selectedBar = selectedBar
        RefreshBarUI()
      end
      UIDropDownMenu_AddButton(option, level)
    end
  end)

  barNameBox = CreateFrame("EditBox", "ItemTrackerConfigBarNameBox", parent, "InputBoxTemplate")
  barNameBox:SetSize(90, 20)
  barNameBox:SetPoint("LEFT", barDropdown, "RIGHT", 10, 2)
  barNameBox:SetAutoFocus(false)
  local function CommitBarName(self)
    ItemTracker.Logic.RenameBar(ItemTrackerDB.bars, selectedBar, self:GetText())
    RefreshBarUI()
  end
  barNameBox:SetScript("OnEnterPressed", function(self)
    CommitBarName(self)
    self:ClearFocus()
  end)
  barNameBox:SetScript("OnEditFocusLost", CommitBarName)

  newBarButton = CreateFrame("Button", "ItemTrackerConfigNewBarButton", parent, "UIPanelButtonTemplate")
  newBarButton:SetSize(50, 20)
  newBarButton:SetText("New")
  newBarButton:SetPoint("LEFT", barNameBox, "RIGHT", 6, 0)
  newBarButton:SetScript("OnClick", function()
    local newIndex = ItemTracker.Logic.AddBar(ItemTrackerDB.bars, "Bar " .. (#ItemTrackerDB.bars + 1), ItemTracker.Logic.DEFAULT_DB.bars[1])
    ItemTrackerDB.bars[newIndex].y = -(newIndex - 1) * 50
    selectedBar = newIndex
    ItemTrackerDB.config.selectedBar = selectedBar
    ItemTracker.Bar.RebuildAll()
    RefreshBarUI()
  end)

  deleteBarButton = CreateFrame("Button", "ItemTrackerConfigDeleteBarButton", parent, "UIPanelButtonTemplate")
  deleteBarButton:SetSize(24, 20)
  deleteBarButton:SetText("X")
  deleteBarButton:SetPoint("LEFT", newBarButton, "RIGHT", 4, 0)
  deleteBarButton:SetScript("OnClick", function()
    if #ItemTrackerDB.bars <= 1 then
      return
    end
    local bar = ItemTrackerDB.bars[selectedBar]
    StaticPopup_Show("ITEMTRACKER_DELETE_BAR", bar.name, #bar.items, { index = selectedBar })
  end)
end

local function CreateBarOptions(parent)
  -- None of these widgets set their own position at creation time anymore
  -- -- every left-column row's TOPLEFT is computed by RelayoutLeftColumn
  -- (defined at the end of this function, once every row exists), which
  -- walks the rows top to bottom and only advances past the ones that are
  -- actually visible, so a hidden row never leaves a gap behind it.

  -- Category Filter comes first: it's the one control that decides
  -- whether the rest of the window's manual item list is even usable.
  filterTypeDropdown = CreateFrame("Frame", "ItemTrackerConfigFilterTypeDropdown", parent, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(filterTypeDropdown, 190)
  UIDropDownMenu_Initialize(filterTypeDropdown, function(self, level)
    local noneOption = UIDropDownMenu_CreateInfo()
    noneOption.text = "None (manual)"
    noneOption.value = nil
    noneOption.func = function()
      ItemTrackerDB.bars[selectedBar].filter = nil
      ItemTracker.Bar.RefreshAll()
      RefreshBarUI()
    end
    UIDropDownMenu_AddButton(noneOption, level)

    for _, itemType in ipairs(ItemTracker.BagScan.GetCategories().order) do
      local option = UIDropDownMenu_CreateInfo()
      option.text = itemType
      option.value = itemType
      option.func = function(self)
        ItemTrackerDB.bars[selectedBar].filter = { itemType = self.value, itemSubType = nil }
        ItemTracker.Bar.RefreshAll()
        RefreshBarUI()
      end
      UIDropDownMenu_AddButton(option, level)
    end
  end)

  filterSubTypeDropdown = CreateFrame("Frame", "ItemTrackerConfigFilterSubTypeDropdown", parent, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(filterSubTypeDropdown, 190)
  UIDropDownMenu_Initialize(filterSubTypeDropdown, function(self, level)
    local bar = ItemTrackerDB.bars[selectedBar]
    if not bar.filter then
      return
    end
    local allOption = UIDropDownMenu_CreateInfo()
    allOption.text = "All"
    allOption.value = nil
    allOption.func = function()
      bar.filter.itemSubType = nil
      ItemTracker.Bar.RefreshAll()
      RefreshBarOptions()
      RefreshList()
    end
    UIDropDownMenu_AddButton(allOption, level)

    local subTypes = ItemTracker.BagScan.GetCategories().subTypes[bar.filter.itemType] or {}
    for _, subType in ipairs(subTypes) do
      local option = UIDropDownMenu_CreateInfo()
      option.text = subType
      option.value = subType
      option.func = function(self)
        bar.filter.itemSubType = self.value
        ItemTracker.Bar.RefreshAll()
        RefreshBarOptions()
        RefreshList()
      end
      UIDropDownMenu_AddButton(option, level)
    end
  end)

  lockCheck = CreateFrame("CheckButton", "ItemTrackerConfigLockCheck", parent, "UICheckButtonTemplate")
  _G[lockCheck:GetName() .. "Text"]:SetText("Lock bar")
  lockCheck:SetScript("OnClick", function(self)
    ItemTracker.Bar.SetLocked(selectedBar, self:GetChecked() and true or false)
  end)

  titleCheck = CreateFrame("CheckButton", "ItemTrackerConfigTitleCheck", parent, "UICheckButtonTemplate")
  _G[titleCheck:GetName() .. "Text"]:SetText("Show Title")
  titleCheck:SetScript("OnClick", function(self)
    ItemTrackerDB.bars[selectedBar].showTitle = self:GetChecked() and true or false
    ItemTracker.Bar.RefreshAll()
    RefreshBarOptions()
  end)

  titlePositionDropdown = CreateFrame("Frame", "ItemTrackerConfigTitlePositionDropdown", parent, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(titlePositionDropdown, 150)
  UIDropDownMenu_Initialize(titlePositionDropdown, function(self, level)
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
      local option = UIDropDownMenu_CreateInfo()
      option.text = side
      option.value = side
      option.func = function(self)
        ItemTrackerDB.bars[selectedBar].titlePosition = self.value
        UIDropDownMenu_SetSelectedValue(titlePositionDropdown, self.value)
        UIDropDownMenu_SetText(titlePositionDropdown, self.value)
        ItemTracker.Bar.RefreshAll()
      end
      UIDropDownMenu_AddButton(option, level)
    end
  end)

  local function CreateSlider(name, label, minVal, maxVal, step, setter)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetWidth(160)
    _G[name .. "Text"]:SetText(label)
    _G[name .. "Low"]:SetText(tostring(minVal))
    _G[name .. "High"]:SetText(tostring(maxVal))

    local valueBox = CreateFrame("EditBox", name .. "ValueBox", parent, "InputBoxTemplate")
    valueBox:SetSize(40, 18)
    valueBox:SetAutoFocus(false)
    valueBox:SetPoint("LEFT", slider, "RIGHT", 12, 0)

    local function CommitValueBox()
      local value = tonumber(valueBox:GetText())
      if value then
        value = math.floor(value / step + 0.5) * step
        slider:SetValue(math.max(minVal, math.min(maxVal, value)))
      end
      valueBox:SetText(FormatSliderValue(slider:GetValue(), step))
      valueBox:ClearFocus()
    end
    valueBox:SetScript("OnEnterPressed", CommitValueBox)
    valueBox:SetScript("OnEscapePressed", function(self)
      self:SetText(FormatSliderValue(slider:GetValue(), step))
      self:ClearFocus()
    end)
    valueBox:SetScript("OnEditFocusLost", CommitValueBox)

    slider:SetScript("OnValueChanged", function(self, value)
      setter(value)
      valueBox:SetText(FormatSliderValue(value, step))
      ItemTracker.Bar.RefreshAll()
    end)

    slider.valueBox = valueBox
    return slider
  end

  -- Title offsets are sliders too (draggable, with a type-in value box),
  -- same as every other numeric bar setting -- they nudge the title on
  -- top of whichever preset side titlePositionDropdown picks.
  titleOffsetXSlider = CreateSlider("ItemTrackerConfigTitleOffsetX", "Title Offset X", -100, 100, 1,
    function(value) ItemTrackerDB.bars[selectedBar].titleOffsetX = value end)

  titleOffsetYSlider = CreateSlider("ItemTrackerConfigTitleOffsetY", "Title Offset Y", -100, 100, 1,
    function(value) ItemTrackerDB.bars[selectedBar].titleOffsetY = value end)

  titleFontSizeSlider = CreateSlider("ItemTrackerConfigTitleFontSize", "Title Font Size", 8, 24, 1,
    function(value) ItemTrackerDB.bars[selectedBar].titleFontSize = value end)

  iconSizeSlider = CreateSlider("ItemTrackerConfigIconSize", "Icon Size", 16, 64, 1,
    function(value) ItemTrackerDB.bars[selectedBar].iconSize = value end)

  -- Same field as always (bar.columns) -- just labeled for what it does.
  columnsSlider = CreateSlider("ItemTrackerConfigColumns", "Items per Row", 1, 20, 1,
    function(value) ItemTrackerDB.bars[selectedBar].columns = value end)

  -- 0 means unlimited (show every item, however many rows that takes).
  maxRowsSlider = CreateSlider("ItemTrackerConfigMaxRows", "Maximum Rows (0 = All)", 0, 20, 1,
    function(value) ItemTrackerDB.bars[selectedBar].maxRows = value end)

  scaleSlider = CreateSlider("ItemTrackerConfigScale", "Scale", 0.5, 2, 0.05,
    function(value) ItemTrackerDB.bars[selectedBar].scale = value end)

  growthDropdown = CreateFrame("Frame", "ItemTrackerConfigGrowthDropdown", parent, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(growthDropdown, 150)
  UIDropDownMenu_Initialize(growthDropdown, function(self, level)
    for _, direction in ipairs({ "RIGHT", "LEFT", "DOWN", "UP" }) do
      local option = UIDropDownMenu_CreateInfo()
      option.text = direction
      option.value = direction
      option.func = function(self)
        ItemTrackerDB.bars[selectedBar].growth = self.value
        UIDropDownMenu_SetSelectedValue(growthDropdown, self.value)
        UIDropDownMenu_SetText(growthDropdown, self.value)
        ItemTracker.Bar.RefreshAll()
      end
      UIDropDownMenu_AddButton(option, level)
    end
  end)

  filterThresholdSlider = CreateSlider("ItemTrackerConfigFilterThreshold", "Low Stock Threshold", 0, 50, 1,
    function(value) ItemTrackerDB.bars[selectedBar].filterThreshold = value end)

  -- Declared top to bottom. `isDropdown` widgets need their TOPLEFT
  -- shifted 16px left of the column's true left edge to visually align --
  -- UIDropDownMenuTemplate's internal padding offsets its clickable box
  -- that far right of its own anchor point, a quirk plain widgets (
  -- checkboxes, sliders) don't share.
  leftColumnRows = {
    { frame = filterTypeDropdown, isDropdown = true, isVisible = function() return true end },
    { frame = filterSubTypeDropdown, isDropdown = true, isVisible = function(bar) return bar.filter ~= nil end },
    { frame = lockCheck, isDropdown = false, isVisible = function() return true end },
    { frame = titleCheck, isDropdown = false, isVisible = function() return true end },
    { frame = titlePositionDropdown, isDropdown = true, isVisible = function(bar) return bar.showTitle end },
    { frame = titleOffsetXSlider, isDropdown = false, isVisible = function(bar) return bar.showTitle end },
    { frame = titleOffsetYSlider, isDropdown = false, isVisible = function(bar) return bar.showTitle end },
    { frame = titleFontSizeSlider, isDropdown = false, isVisible = function(bar) return bar.showTitle end },
    { frame = iconSizeSlider, isDropdown = false, isVisible = function() return true end },
    { frame = columnsSlider, isDropdown = false, isVisible = function() return true end },
    { frame = maxRowsSlider, isDropdown = false, isVisible = function() return true end },
    { frame = scaleSlider, isDropdown = false, isVisible = function() return true end },
    { frame = growthDropdown, isDropdown = true, isVisible = function() return true end },
    { frame = filterThresholdSlider, isDropdown = false, isVisible = function(bar) return bar.filter ~= nil end },
  }

  local LEFT_COLUMN_ROW_GAP = 10

  -- Repositions (and shows/hides) every left-column row from scratch,
  -- top to bottom, so a row that isn't currently visible is skipped
  -- entirely rather than leaving the gap its reserved space would
  -- otherwise leave behind. Safe to call anytime a row's visibility or
  -- the set of rows above it may have changed.
  RelayoutLeftColumn = function()
    local bar = ItemTrackerDB.bars[selectedBar]
    local cursorY = CONTENT_TOP_Y
    for _, row in ipairs(leftColumnRows) do
      if row.isVisible(bar) then
        row.frame:Show()
        local x = row.isDropdown and (LEFT_COLUMN_X - 16) or LEFT_COLUMN_X
        row.frame:ClearAllPoints()
        row.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, cursorY)
        cursorY = cursorY - row.frame:GetHeight() - LEFT_COLUMN_ROW_GAP
      else
        row.frame:Hide()
      end
    end
  end
end

StaticPopupDialogs["ITEMTRACKER_DELETE_BAR"] = {
  text = "Delete '%s'? This removes its %d tracked items.",
  button1 = YES,
  button2 = NO,
  OnAccept = function(self, data)
    local ok = ItemTracker.Logic.RemoveBar(ItemTrackerDB.bars, data.index)
    if ok then
      if data.index < selectedBar then
        selectedBar = selectedBar - 1
      end
      if selectedBar > #ItemTrackerDB.bars then
        selectedBar = #ItemTrackerDB.bars
      end
      ItemTrackerDB.config.selectedBar = selectedBar
      ItemTracker.Bar.RebuildAll()
      RefreshBarUI()
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

function ItemTracker.Config.Create()
  if frame then
    return
  end
  selectedBar = ItemTrackerDB.config.selectedBar or 1
  if selectedBar > #ItemTrackerDB.bars then
    selectedBar = #ItemTrackerDB.bars
  end

  frame = CreateFrame("Frame", "ItemTrackerConfig", UIParent)
  frame:SetSize(600, 780)
  frame:SetPoint(ItemTrackerDB.config.point, UIParent, ItemTrackerDB.config.relPoint, ItemTrackerDB.config.x, ItemTrackerDB.config.y)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    ItemTrackerDB.config.point = point
    ItemTrackerDB.config.relPoint = relPoint
    ItemTrackerDB.config.x = x
    ItemTrackerDB.config.y = y
  end)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  title:SetText("Item Tracker")

  local closeButton = CreateFrame("Button", "ItemTrackerConfigCloseButton", frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -4, -4)
  closeButton:SetScript("OnClick", function() frame:Hide() end)

  CreateBarSelector(frame)

  local divider = frame:CreateTexture(nil, "ARTWORK")
  divider:SetTexture(1, 1, 1)
  divider:SetVertexColor(1, 1, 1, 0.2)
  divider:SetWidth(2)
  divider:SetPoint("TOP", frame, "TOPLEFT", DIVIDER_X, CONTENT_TOP_Y + 10)
  divider:SetPoint("BOTTOM", frame, "BOTTOMLEFT", DIVIDER_X, 20)

  instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  instructions:SetPoint("TOPLEFT", frame, "TOPLEFT", RIGHT_COLUMN_X, CONTENT_TOP_Y)
  instructions:SetWidth(260)
  instructions:SetJustifyH("LEFT")
  instructions:SetText("Type an item name, link, or ID and press Enter, or drag an item onto the slot below.")

  addEditBox = CreateFrame("EditBox", "ItemTrackerConfigAddBox", frame, "InputBoxTemplate")
  addEditBox:SetSize(180, 24)
  addEditBox:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 20, -10)
  addEditBox:SetAutoFocus(false)
  addEditBox:SetScript("OnEnterPressed", function(self)
    HandleAddInput(self:GetText())
    self:SetText("")
    self:ClearFocus()
  end)

  local addHint = addEditBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  addHint:SetPoint("LEFT", addEditBox, "LEFT", 6, 0)
  addHint:SetText("Item ID")
  local function UpdateAddHint()
    if addEditBox:GetText() == "" then
      addHint:Show()
    else
      addHint:Hide()
    end
  end
  addEditBox:SetScript("OnTextChanged", UpdateAddHint)
  addEditBox:SetScript("OnEditFocusGained", function() addHint:Hide() end)
  addEditBox:SetScript("OnEditFocusLost", UpdateAddHint)

  dragSlot = CreateFrame("Button", "ItemTrackerConfigDragSlot", frame)
  dragSlot:SetSize(28, 28)
  dragSlot:SetPoint("LEFT", addEditBox, "RIGHT", 10, 0)
  dragSlot:SetNormalTexture("Interface\\Buttons\\UI-EmptySlot")
  dragSlot:RegisterForDrag("LeftButton")
  dragSlot:SetScript("OnReceiveDrag", HandleCursorDrop)
  dragSlot:SetScript("OnClick", function()
    if CursorHasItem() then
      HandleCursorDrop()
    end
  end)
  dragSlot:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Drag an item here to track it")
    GameTooltip:Show()
  end)
  dragSlot:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  addError = frame:CreateFontString(nil, "OVERLAY", "GameFontRed")
  addError:SetPoint("TOPLEFT", addEditBox, "BOTTOMLEFT", 0, -4)

  scrollFrame = CreateFrame("ScrollFrame", "ItemTrackerConfigScrollFrame", frame, "FauxScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", addEditBox, "BOTTOMLEFT", 0, -24)
  scrollFrame:SetSize(236, ROW_HEIGHT * NUM_VISIBLE_ROWS)
  scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, RefreshList)
  end)

  for index = 1, NUM_VISIBLE_ROWS do
    local row = CreateRow(index)
    row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    rows[index] = row
  end

  filterStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  filterStatus:SetPoint("TOPLEFT", frame, "TOPLEFT", RIGHT_COLUMN_X, CONTENT_TOP_Y)
  filterStatus:SetWidth(260)
  filterStatus:SetJustifyH("LEFT")
  filterStatus:Hide()

  CreateBarOptions(frame)

  frame:Hide()
  table.insert(UISpecialFrames, "ItemTrackerConfig")

  local removeButtons = {}
  local thresholdBoxes = {}
  for _, row in ipairs(rows) do
    table.insert(removeButtons, row.removeButton)
    table.insert(thresholdBoxes, row.thresholdBox)
  end

  ItemTracker.Skins.ApplyElvUIToConfig(frame, {
    buttons = { newBarButton, deleteBarButton },
    closeButtons = { closeButton, unpack(removeButtons) },
    checkboxes = { lockCheck, titleCheck },
    editboxes = { addEditBox, barNameBox, iconSizeSlider.valueBox, columnsSlider.valueBox, maxRowsSlider.valueBox, scaleSlider.valueBox, filterThresholdSlider.valueBox, titleFontSizeSlider.valueBox, titleOffsetXSlider.valueBox, titleOffsetYSlider.valueBox, unpack(thresholdBoxes) },
    sliders = { iconSizeSlider, columnsSlider, maxRowsSlider, scaleSlider, filterThresholdSlider, titleFontSizeSlider, titleOffsetXSlider, titleOffsetYSlider },
    dropdowns = { { frame = barDropdown, width = 110 }, { frame = growthDropdown, width = 150 }, { frame = filterTypeDropdown, width = 190 }, { frame = filterSubTypeDropdown, width = 190 }, { frame = titlePositionDropdown, width = 150 } },
    plainFrames = { dragSlot },
  })

  RefreshBarUI()
end

function ItemTracker.Config.Toggle()
  ItemTracker.Config.Create()
  if frame:IsShown() then
    frame:Hide()
  else
    RefreshBarUI()
    frame:Show()
  end
end
