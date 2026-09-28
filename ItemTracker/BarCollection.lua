ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

local function deepCopy(value)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for k, v in pairs(value) do
    copy[k] = deepCopy(v)
  end
  return copy
end

-- Appends a new bar to `bars`, seeded from `template` (deep-copied so
-- the new bar never shares table references with it), named `name`.
-- Returns the new bar's 1-based index.
function ItemTracker.Logic.AddBar(bars, name, template)
  local newBar = deepCopy(template)
  newBar.name = name
  table.insert(bars, newBar)
  return #bars
end

-- Removes the bar at `index`. Refuses to remove the last remaining bar
-- (there must always be at least one). Returns true, nil on success or
-- false, errorMessage on failure.
function ItemTracker.Logic.RemoveBar(bars, index)
  if #bars <= 1 then
    return false, "cannot remove the last bar"
  end
  if not bars[index] then
    return false, "no bar at that index"
  end
  table.remove(bars, index)
  return true, nil
end

-- Renames the bar at `index`. An empty/whitespace-only name falls back
-- to "Bar <index>" instead of storing a blank name. Returns true if the
-- bar exists and was renamed, false otherwise.
function ItemTracker.Logic.RenameBar(bars, index, name)
  if not bars[index] then
    return false
  end
  if not name or name:match("^%s*$") then
    name = "Bar " .. index
  end
  bars[index].name = name
  return true
end
