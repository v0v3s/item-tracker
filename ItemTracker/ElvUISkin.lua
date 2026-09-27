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
  pcall(function()
    frame:SetTemplate("Default")
    for _, button in ipairs(controls.buttons or {}) do
      S:HandleButton(button)
    end
    for _, button in ipairs(controls.closeButtons or {}) do
      S:HandleCloseButton(button)
    end
    for _, checkbox in ipairs(controls.checkboxes or {}) do
      S:HandleCheckBox(checkbox)
    end
    for _, editbox in ipairs(controls.editboxes or {}) do
      S:HandleEditBox(editbox)
    end
    for _, slider in ipairs(controls.sliders or {}) do
      S:HandleSliderFrame(slider)
    end
    for _, dropdown in ipairs(controls.dropdowns or {}) do
      S:HandleDropDownBox(dropdown.frame, dropdown.width)
    end
    for _, plainFrame in ipairs(controls.plainFrames or {}) do
      plainFrame:SetTemplate("Default")
    end
  end)
end
