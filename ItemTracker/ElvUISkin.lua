ItemTracker = ItemTracker or {}
ItemTracker.Skins = ItemTracker.Skins or {}

local function GetElvUISkinsModule()
  if not IsAddOnLoaded("ElvUI") then
    return nil
  end
  local ok, E = pcall(unpack, ElvUI)
  if not ok or not E then
    return nil
  end
  local ok2, S = pcall(function() return E:GetModule("Skins") end)
  if not ok2 then
    return nil
  end
  return S
end

-- Reskins the config window's frame + the widgets listed in `controls`.
-- All fields optional:
--   buttons      - plain text/label buttons (S:HandleButton)
--   closeButtons - icon-only close-style buttons, e.g. UIPanelCloseButton (S:HandleCloseButton)
--   checkboxes   - CheckButton widgets (S:HandleCheckBox)
--   editboxes    - EditBox widgets (S:HandleEditBox)
--   sliders      - OptionsSliderTemplate-based Slider widgets (S:HandleSliderFrame)
--   dropdowns    - array of { frame = dropdownFrame, width = number } (S:HandleDropDownBox)
--   plainFrames  - custom-textured frames that should just get a flat backdrop,
--                  without touching their own textures (frame:SetTemplate("Default"))
function ItemTracker.Skins.ApplyElvUIToConfig(frame, controls)
  local S = GetElvUISkinsModule()
  if not S then
    return
  end
  controls = controls or {}
  local function try(fn)
    pcall(fn)
  end
  try(function() frame:SetTemplate("Default") end)
  for _, button in ipairs(controls.buttons or {}) do
    try(function() S:HandleButton(button) end)
  end
  for _, button in ipairs(controls.closeButtons or {}) do
    try(function() S:HandleCloseButton(button) end)
  end
  for _, checkbox in ipairs(controls.checkboxes or {}) do
    try(function() S:HandleCheckBox(checkbox) end)
  end
  for _, editbox in ipairs(controls.editboxes or {}) do
    try(function() S:HandleEditBox(editbox) end)
  end
  for _, slider in ipairs(controls.sliders or {}) do
    try(function() S:HandleSliderFrame(slider) end)
  end
  for _, dropdown in ipairs(controls.dropdowns or {}) do
    try(function() S:HandleDropDownBox(dropdown.frame, dropdown.width) end)
  end
  for _, plainFrame in ipairs(controls.plainFrames or {}) do
    try(function() plainFrame:SetTemplate("Default") end)
  end
end
