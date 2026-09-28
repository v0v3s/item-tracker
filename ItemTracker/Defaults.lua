ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

ItemTracker.Logic.DEFAULT_DB = {
  bars = {
    {
      name = "Bar 1",
      items = {},
      point = "CENTER", relPoint = "CENTER", x = 0, y = 0,
      iconSize = 36, columns = 8, spacing = 4, growth = "RIGHT",
      scale = 1.0, locked = false, showTooltip = true,
    },
  },
  config = {
    point = "CENTER", relPoint = "CENTER", x = 0, y = 100,
    selectedBar = 1,
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

-- Fills in any keys missing from EVERY bar in `bars` using `template`
-- (normally DEFAULT_DB.bars[1]) -- unlike a single top-level
-- MergeDefaults(saved, DEFAULT_DB) call, which only ever reaches
-- bars[1] since DEFAULT_DB.bars has just one template entry, this
-- reaches every bar, so a future per-bar key added to the template
-- also backfills bars created before that key existed.
function ItemTracker.Logic.MergeAllBarDefaults(bars, template)
  for _, bar in ipairs(bars) do
    ItemTracker.Logic.MergeDefaults(bar, template)
  end
  return bars
end

-- One-time migration: converts the old single-bar saved shape
-- (top-level `items` + `bar` keys) into the new `bars` array shape, if
-- present. Also clears an empty `bars` array (corrupted/hand-edited
-- data) back to nil so the caller's subsequent MergeDefaults call can
-- repopulate it with a fresh default bar. No-op if `saved.bars` is
-- already a non-empty array, or if there's no legacy data at all
-- (fresh install). Mutates and returns `saved`.
function ItemTracker.Logic.MigrateLegacyBar(saved)
  saved = saved or {}
  if not saved.bars and saved.items and saved.bar then
    local migratedBar = deepCopy(saved.bar)
    migratedBar.name = "Bar 1"
    migratedBar.items = saved.items
    saved.bars = { migratedBar }
    saved.items = nil
    saved.bar = nil
  end
  if saved.bars and #saved.bars == 0 then
    saved.bars = nil
  end
  return saved
end
