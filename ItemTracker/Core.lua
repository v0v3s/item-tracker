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
    ItemTrackerDB = ItemTracker.Logic.MigrateLegacyBar(ItemTrackerDB or {})
    ItemTrackerDB = ItemTracker.Logic.MergeDefaults(ItemTrackerDB, ItemTracker.Logic.DEFAULT_DB)
    ItemTracker.Logic.MergeAllBarDefaults(ItemTrackerDB.bars, ItemTracker.Logic.DEFAULT_DB.bars[1])
    self:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_ENTERING_WORLD" then
    ItemTracker.Bar.RebuildAll()
  elseif event == "BANKFRAME_OPENED" then
    ItemTracker.BagScan.SetBankOpen(true)
    ItemTracker.Bar.RefreshAll()
  elseif event == "BANKFRAME_CLOSED" then
    ItemTracker.BagScan.SetBankOpen(false)
    ItemTracker.Bar.RefreshAll()
  elseif event == "BAG_UPDATE" or event == "PLAYERBANKSLOTS_CHANGED" then
    ItemTracker.Bar.RefreshAll()
  end
end)

SLASH_ITEMTRACKER1 = "/itemtracker"
SLASH_ITEMTRACKER2 = "/itr"
SlashCmdList["ITEMTRACKER"] = function()
  ItemTracker.Config.Toggle()
end
