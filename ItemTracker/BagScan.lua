ItemTracker = ItemTracker or {}
ItemTracker.BagScan = ItemTracker.BagScan or {}

local BANK_CONTAINER = -1
local BANK_BAG_IDS = { 5, 6, 7, 8, 9, 10, 11 }
local bankOpen = false

-- Tracks whether the bank is open via the BANKFRAME_OPENED/BANKFRAME_CLOSED
-- events (set by Core.lua), rather than BankFrame:IsShown() -- a
-- replacement bag/bank UI (ElvUI's bag module, Bagnon, AdiBags, etc.) may
-- hide or never show Blizzard's own BankFrame widget while still handling
-- a genuinely open bank, but the underlying game events fire regardless
-- of which UI (if any) visually responds to them.
function ItemTracker.BagScan.SetBankOpen(isOpen)
  bankOpen = isOpen
end

-- Container IDs to scan: bags 0-4 always, plus the bank's main slots and
-- bank bags while the bank is open -- bank contents are only populated
-- client-side while it's open (same limitation ItemData.GetTrackedCount
-- already documents for bank-inclusive counts).
local function GetScanContainers()
  local containers = { 0, 1, 2, 3, 4 }
  if bankOpen then
    table.insert(containers, BANK_CONTAINER)
    for _, bagID in ipairs(BANK_BAG_IDS) do
      table.insert(containers, bagID)
    end
  end
  return containers
end

-- Returns a set (itemID -> true) of every distinct itemID currently
-- present across the containers GetScanContainers() returns. itemID is
-- parsed out of each slot's item link, since the 3.3.5a-era
-- GetContainerItemInfo signature (texture, itemCount, locked, quality,
-- readable, lootable, itemLink) does not return an itemID directly.
local function CollectOwnedItemIDs()
  local seen = {}
  for _, bagID in ipairs(GetScanContainers()) do
    local numSlots = GetContainerNumSlots(bagID)
    for slot = 1, numSlots do
      local _, _, _, _, _, _, itemLink = GetContainerItemInfo(bagID, slot)
      if itemLink then
        local itemID = tonumber(itemLink:match("item:(%d+)"))
        if itemID then
          seen[itemID] = true
        end
      end
    end
  end
  return seen
end

local pendingRescanTicker

-- Starts a short one-shot poll that re-runs RefreshAll once, used when a
-- scan skipped an item whose type/subtype the client hadn't cached yet
-- (GetItemInfo returned nil) -- 3.3.5a has no "item info ready" event
-- (ItemData.ResolveItemName works around the same gap for item names), so
-- without this, a freshly-acquired item could stay invisible on a
-- filtered bar until an unrelated bag event happens to trigger a rescan.
-- Coalesces multiple skips in the same pass into a single pending retry,
-- and re-arms itself harmlessly (at most once per second) for as long as
-- some owned item's type genuinely never resolves.
local function ScheduleRescan()
  if pendingRescanTicker then
    return
  end
  pendingRescanTicker = CreateFrame("Frame")
  local elapsed = 0
  pendingRescanTicker:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed < 1 then
      return
    end
    self:SetScript("OnUpdate", nil)
    pendingRescanTicker = nil
    ItemTracker.Bar.RefreshAll()
  end)
end

-- Returns an array of itemIDs (sorted ascending, for stable ordering)
-- currently owned (per CollectOwnedItemIDs) whose GetItemInfo type/subtype
-- matches `filter` (see ItemTracker.Logic.MatchesFilter). An item whose
-- info the client hasn't cached yet (GetItemInfo returns nil) is skipped
-- this pass and triggers ScheduleRescan so it's picked up shortly after.
function ItemTracker.BagScan.FindMatchingItemIDs(filter)
  local matches = {}
  for itemID in pairs(CollectOwnedItemIDs()) do
    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
    if itemType then
      if ItemTracker.Logic.MatchesFilter(itemType, itemSubType, filter) then
        table.insert(matches, itemID)
      end
    else
      ScheduleRescan()
    end
  end
  table.sort(matches)
  return matches
end

-- Returns { order = { itemType1, itemType2, ... }, subTypes = { [itemType]
-- = { subType1, subType2, ... } } }, built from the client's own
-- item-class data (GetAuctionItemClasses / GetAuctionItemSubClasses) --
-- static client-side data, not a live Auction House query, safe to call
-- anytime. `order` preserves the client's own category ordering so the
-- config window's dropdown lists them the same way the Auction House
-- does. Computed once and cached, since this data never changes within a
-- session.
local categoriesCache
function ItemTracker.BagScan.GetCategories()
  if categoriesCache then
    return categoriesCache
  end
  local order = { GetAuctionItemClasses() }
  local subTypes = {}
  for classIndex, className in ipairs(order) do
    subTypes[className] = { GetAuctionItemSubClasses(classIndex) }
  end
  categoriesCache = { order = order, subTypes = subTypes }
  return categoriesCache
end
