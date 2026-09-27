ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

-- Parses user-typed text into a numeric itemID. Handles a bare numeric
-- ID ("6948") or an item link/hyperlink string containing "item:<id>"
-- (e.g. pasted via shift-click, or "item:6948:0:0:0:0:0:0:0:0").
-- Does NOT resolve plain item names (e.g. "Hearthstone") -- callers
-- should fall back to GetItemInfo(text) for that case, since name
-- resolution needs the WoW API and can't be done as pure logic.
-- Returns itemID, nil on success or nil, errorMessage on failure.
function ItemTracker.Logic.ParseItemInput(text)
  if not text or text:match("^%s*$") then
    return nil, "no input"
  end
  text = text:match("^%s*(.-)%s*$")

  local linkID = text:match("item:(%d+)")
  if linkID then
    return tonumber(linkID), nil
  end

  if text:match("^%d+$") then
    return tonumber(text), nil
  end

  return nil, "not a numeric ID or item link"
end
