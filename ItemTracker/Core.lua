ItemTracker = ItemTracker or {}

local ADDON_NAME = "ItemTracker"

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("BANKFRAME_CLOSED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    ItemTrackerDB = ItemTracker.Logic.MergeDefaults(ItemTrackerDB or {}, ItemTracker.Logic.DEFAULT_DB)
    self:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_ENTERING_WORLD" then
    ItemTracker.Bar.Create()
    ItemTracker.Bar.Refresh()
  elseif event == "BAG_UPDATE" or event == "BANKFRAME_OPENED" or event == "BANKFRAME_CLOSED" or event == "PLAYERBANKSLOTS_CHANGED" then
    ItemTracker.Bar.Refresh()
  end
end)

SLASH_ITEMTRACKER1 = "/itemtracker"
SLASH_ITEMTRACKER2 = "/itr"
SlashCmdList["ITEMTRACKER"] = function()
  ItemTracker.Config.Toggle()
end
