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
