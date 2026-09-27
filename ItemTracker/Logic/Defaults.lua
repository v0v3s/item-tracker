ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

ItemTracker.Logic.DEFAULT_DB = {
  items = {},
  bar = {
    point = "CENTER", relPoint = "CENTER", x = 0, y = 0,
    iconSize = 36, columns = 8, spacing = 4, growth = "RIGHT",
    scale = 1.0, locked = false, showTooltip = true,
  },
  config = {
    point = "CENTER", relPoint = "CENTER", x = 0, y = 100,
  },
}

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

-- Fills in keys missing from `saved` using `defaults`, recursively.
-- Never overwrites a key already present in `saved`. Values copied from
-- `defaults` are deep-copied so the result never shares table references
-- with `defaults` (mutating the result can't mutate the defaults template).
function ItemTracker.Logic.MergeDefaults(saved, defaults)
  saved = saved or {}
  for key, defaultValue in pairs(defaults) do
    if saved[key] == nil then
      saved[key] = deepCopy(defaultValue)
    elseif type(defaultValue) == "table" and type(saved[key]) == "table" then
      ItemTracker.Logic.MergeDefaults(saved[key], defaultValue)
    end
  end
  return saved
end
