ItemTracker = ItemTracker or {}
ItemTracker.Logic = ItemTracker.Logic or {}

-- Returns xOffset, yOffset (pixels) for the Nth (1-based) tracked item's
-- button, relative to the bar's top-left anchor point, given how many
-- items fit per line before wrapping and which direction the bar grows.
-- growth: "RIGHT" | "LEFT" | "DOWN" | "UP" (defaults to "RIGHT" behavior
-- for any other value).
function ItemTracker.Logic.ComputeSlotPosition(index, columns, iconSize, spacing, growth)
  columns = math.max(columns or 1, 1)
  local step = iconSize + spacing
  local withinLine = (index - 1) % columns
  local line = math.floor((index - 1) / columns)

  if growth == "LEFT" then
    return -withinLine * step, -line * step
  elseif growth == "DOWN" then
    return line * step, -withinLine * step
  elseif growth == "UP" then
    return line * step, withinLine * step
  end
  return withinLine * step, -line * step
end

-- Returns the outer bar frame's width/height (pixels) so it fully
-- contains the rendered icon grid for the given item count and bar
-- options, using the same step/columns/growth math as
-- ComputeSlotPosition. Never collapses below a single icon's
-- footprint, so the bar stays draggable even with zero items.
function ItemTracker.Logic.ComputeFrameSize(itemCount, barOpts)
  local columns = math.max(barOpts.columns or 1, 1)
  local step = barOpts.iconSize + barOpts.spacing
  local count = math.max(itemCount, 1)
  local perLine = math.min(count, columns)
  local numLines = math.ceil(count / columns)
  if barOpts.growth == "DOWN" or barOpts.growth == "UP" then
    return numLines * step, perLine * step
  end
  return perLine * step, numLines * step
end

-- Returns the (x, y) offset to add to every ComputeSlotPosition result
-- so the rendered icon grid's bounding box always aligns with the
-- frame's own [0, width] x [-height, 0] rectangle (TOPLEFT-anchored),
-- regardless of growth direction. RIGHT and DOWN already align
-- naturally (offset 0,0); LEFT and UP grow away from the frame's
-- TOPLEFT origin and need a counter-shift so the frame's hit-rect
-- (and drag region) actually covers every icon.
function ItemTracker.Logic.ComputeGridOrigin(itemCount, columns, iconSize, spacing, growth)
  columns = math.max(columns or 1, 1)
  local step = iconSize + spacing
  local count = math.max(itemCount, 1)
  local perLine = math.min(count, columns)
  if growth == "LEFT" then
    return (perLine - 1) * step, 0
  elseif growth == "UP" then
    return 0, -(perLine - 1) * step
  end
  return 0, 0
end
