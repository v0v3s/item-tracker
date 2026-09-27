ItemTracker = ItemTracker or {}
ItemTracker.Config = ItemTracker.Config or {}

local ROW_HEIGHT = 36
local NUM_VISIBLE_ROWS = 6

local frame
local addEditBox
local addError
local rows = {}
local scrollFrame

local function RefreshList()
  local items = ItemTrackerDB.items
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
      row.thresholdBox:SetText(tostring(entry.threshold))
      row:Show()
    else
      row.itemID = nil
      row:Hide()
    end
  end
end

local function CreateRow(index)
  local row = CreateFrame("Frame", "ItemTrackerConfigRow" .. index, frame)
  row:SetSize(236, ROW_HEIGHT)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(28, 28)
  row.icon:SetPoint("LEFT", 4, 0)

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
    ItemTracker.Logic.SetThreshold(ItemTrackerDB.items, row.itemID, threshold)
    self:ClearFocus()
    ItemTracker.Bar.Refresh()
  end)

  row.removeButton = CreateFrame("Button", "ItemTrackerConfigRowRemove" .. index, row, "UIPanelCloseButton")
  row.removeButton:SetSize(20, 20)
  row.removeButton:SetPoint("RIGHT", -4, 0)
  row.removeButton:SetScript("OnClick", function()
    ItemTracker.Logic.RemoveItem(ItemTrackerDB.items, row.itemID)
    RefreshList()
    ItemTracker.Bar.Refresh()
  end)

  return row
end

local function ShowAddError(message)
  addError:SetText(message or "")
end

local function TryAddItemID(itemID)
  if not itemID then
    ShowAddError("item not found")
    return
  end
  local ok, err = ItemTracker.Logic.AddItem(ItemTrackerDB.items, itemID, 1)
  if not ok then
    ShowAddError(err)
    return
  end
  ShowAddError(nil)
  RefreshList()
  ItemTracker.Bar.Refresh()
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

local function CreateBarOptions(parent, anchorTo)
  local lockCheck = CreateFrame("CheckButton", "ItemTrackerConfigLockCheck", parent, "UICheckButtonTemplate")
  lockCheck:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -16)
  _G[lockCheck:GetName() .. "Text"]:SetText("Lock bar")
  lockCheck:SetChecked(ItemTrackerDB.bar.locked)
  lockCheck:SetScript("OnClick", function(self)
    ItemTracker.Bar.SetLocked(self:GetChecked() and true or false)
  end)

  local function CreateSlider(name, label, anchor, minVal, maxVal, step, getter, setter)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -24)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetWidth(160)
    _G[name .. "Text"]:SetText(label)
    _G[name .. "Low"]:SetText(tostring(minVal))
    _G[name .. "High"]:SetText(tostring(maxVal))
    slider:SetValue(getter())
    slider:SetScript("OnValueChanged", function(self, value)
      setter(value)
      ItemTracker.Bar.Refresh()
    end)
    return slider
  end

  local iconSizeSlider = CreateSlider("ItemTrackerConfigIconSize", "Icon Size", lockCheck, 16, 64, 1,
    function() return ItemTrackerDB.bar.iconSize end,
    function(value) ItemTrackerDB.bar.iconSize = value end)

  local columnsSlider = CreateSlider("ItemTrackerConfigColumns", "Columns", iconSizeSlider, 1, 20, 1,
    function() return ItemTrackerDB.bar.columns end,
    function(value) ItemTrackerDB.bar.columns = value end)

  local scaleSlider = CreateSlider("ItemTrackerConfigScale", "Scale", columnsSlider, 0.5, 2, 0.05,
    function() return ItemTrackerDB.bar.scale end,
    function(value) ItemTrackerDB.bar.scale = value end)

  local growthDropdown = CreateFrame("Frame", "ItemTrackerConfigGrowthDropdown", parent, "UIDropDownMenuTemplate")
  growthDropdown:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", -16, -24)
  UIDropDownMenu_SetWidth(growthDropdown, 100)
  UIDropDownMenu_Initialize(growthDropdown, function(self, level)
    for _, direction in ipairs({ "RIGHT", "LEFT", "DOWN", "UP" }) do
      local option = UIDropDownMenu_CreateInfo()
      option.text = direction
      option.value = direction
      option.func = function(self)
        ItemTrackerDB.bar.growth = self.value
        UIDropDownMenu_SetSelectedValue(growthDropdown, self.value)
        ItemTracker.Bar.Refresh()
      end
      UIDropDownMenu_AddButton(option, level)
    end
  end)
  UIDropDownMenu_SetSelectedValue(growthDropdown, ItemTrackerDB.bar.growth)

  return {
    lockCheck = lockCheck,
    sliders = { iconSizeSlider, columnsSlider, scaleSlider },
    growthDropdown = growthDropdown,
  }
end

function ItemTracker.Config.Create()
  if frame then
    return
  end
  frame = CreateFrame("Frame", "ItemTrackerConfig", UIParent)
  frame:SetSize(300, 600)
  frame:SetPoint(ItemTrackerDB.config.point, UIParent, ItemTrackerDB.config.relPoint, ItemTrackerDB.config.x, ItemTrackerDB.config.y)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:SetMovable(true)
  frame:EnableMouse(true)
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

  local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  instructions:SetPoint("TOP", title, "BOTTOM", 0, -8)
  instructions:SetWidth(260)
  instructions:SetJustifyH("CENTER")
  instructions:SetText("Type an item name, link, or ID and press Enter, or drag an item onto the slot below.")

  local closeButton = CreateFrame("Button", "ItemTrackerConfigCloseButton", frame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", -4, -4)
  closeButton:SetScript("OnClick", function() frame:Hide() end)

  addEditBox = CreateFrame("EditBox", "ItemTrackerConfigAddBox", frame, "InputBoxTemplate")
  addEditBox:SetSize(180, 24)
  addEditBox:SetPoint("TOPLEFT", 40, -70)
  addEditBox:SetAutoFocus(false)
  addEditBox:SetScript("OnEnterPressed", function(self)
    HandleAddInput(self:GetText())
    self:SetText("")
    self:ClearFocus()
  end)

  local addHint = addEditBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  addHint:SetPoint("LEFT", addEditBox, "LEFT", 6, 0)
  addHint:SetText("Item ID")
  addEditBox:SetScript("OnTextChanged", function(self)
    addHint:SetShown(self:GetText() == "")
  end)
  addEditBox:SetScript("OnEditFocusGained", function(self)
    addHint:Hide()
  end)
  addEditBox:SetScript("OnEditFocusLost", function(self)
    addHint:SetShown(self:GetText() == "")
  end)

  local dragSlot = CreateFrame("Button", "ItemTrackerConfigDragSlot", frame)
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

  local barOptions = CreateBarOptions(frame, scrollFrame)

  frame:Hide()

  local removeButtons = {}
  local thresholdBoxes = {}
  for _, row in ipairs(rows) do
    table.insert(removeButtons, row.removeButton)
    table.insert(thresholdBoxes, row.thresholdBox)
  end

  ItemTracker.Skins.ApplyElvUIToConfig(frame, {
    closeButtons = { closeButton, unpack(removeButtons) },
    checkboxes = { barOptions.lockCheck },
    editboxes = { addEditBox, unpack(thresholdBoxes) },
    sliders = barOptions.sliders,
    dropdowns = { { frame = barOptions.growthDropdown, width = 100 } },
    plainFrames = { dragSlot },
  })
end

function ItemTracker.Config.Toggle()
  ItemTracker.Config.Create()
  if frame:IsShown() then
    frame:Hide()
  else
    RefreshList()
    frame:Show()
  end
end
