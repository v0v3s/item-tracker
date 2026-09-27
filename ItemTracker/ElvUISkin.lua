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

-- Reskins the tracker bar's outer frame to match ElvUI's flat style.
-- No-op if ElvUI isn't loaded, or if ElvUI's skinning API errors --
-- degrades safely to the addon's own default look either way.
function ItemTracker.Skins.ApplyElvUIToBar(frame)
  if not GetElvUISkinsModule() then
    return
  end
  pcall(function()
    frame:SetTemplate("Transparent")
  end)
end

-- Reskins the config window's frame + the widgets listed in `controls`
-- ({ buttons = {...}, checkboxes = {...}, editboxes = {...} }, all optional).
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
    for _, checkbox in ipairs(controls.checkboxes or {}) do
      S:HandleCheckBox(checkbox)
    end
    for _, editbox in ipairs(controls.editboxes or {}) do
      S:HandleEditBox(editbox)
    end
  end)
end
