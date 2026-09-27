dofile("ItemTracker/BarLayout.lua")

local x, y = ItemTracker.Logic.ComputeSlotPosition(1, 4, 36, 4, "RIGHT")
assert(x == 0 and y == 0, "first slot should be at origin")

x, y = ItemTracker.Logic.ComputeSlotPosition(2, 4, 36, 4, "RIGHT")
assert(x == 40 and y == 0, "second RIGHT slot should be one step right, got x=" .. x)

x, y = ItemTracker.Logic.ComputeSlotPosition(5, 4, 36, 4, "RIGHT")
assert(x == 0 and y == -40, "5th slot (wraps after 4 columns) should start a new row below, got x=" .. x .. ", y=" .. y)

x, y = ItemTracker.Logic.ComputeSlotPosition(2, 4, 36, 4, "LEFT")
assert(x == -40 and y == 0, "second LEFT slot should be one step left")

x, y = ItemTracker.Logic.ComputeSlotPosition(5, 4, 36, 4, "DOWN")
assert(x == 40 and y == 0, "5th DOWN slot (wraps after 4 rows) should start a new column to the right, got x=" .. x .. ", y=" .. y)

x, y = ItemTracker.Logic.ComputeSlotPosition(2, 4, 36, 4, "DOWN")
assert(x == 0 and y == -40, "second DOWN slot should be one step down")

x, y = ItemTracker.Logic.ComputeSlotPosition(2, 4, 36, 4, "UP")
assert(x == 0 and y == 40, "second UP slot should be one step up")

local w, h = ItemTracker.Logic.ComputeFrameSize(2, { columns = 4, iconSize = 36, spacing = 4, growth = "RIGHT" })
assert(w == 80 and h == 40, "RIGHT frame size for 2 items/4 columns should be 2 steps wide, 1 tall, got w=" .. w .. ", h=" .. h)

w, h = ItemTracker.Logic.ComputeFrameSize(9, { columns = 4, iconSize = 36, spacing = 4, growth = "RIGHT" })
assert(w == 160 and h == 120, "RIGHT frame size for 9 items/4 columns should be 4 steps wide, 3 tall, got w=" .. w .. ", h=" .. h)

w, h = ItemTracker.Logic.ComputeFrameSize(0, { columns = 4, iconSize = 36, spacing = 4, growth = "RIGHT" })
assert(w == 40 and h == 40, "0 items should never collapse below one icon's footprint, got w=" .. w .. ", h=" .. h)

w, h = ItemTracker.Logic.ComputeFrameSize(5, { columns = 4, iconSize = 36, spacing = 4, growth = "DOWN" })
assert(w == 80 and h == 160, "DOWN frame size for 5 items/4 columns should swap width/height vs RIGHT, got w=" .. w .. ", h=" .. h)

local ox, oy = ItemTracker.Logic.ComputeGridOrigin(6, 4, 36, 4, "RIGHT")
assert(ox == 0 and oy == 0, "RIGHT needs no origin shift")

ox, oy = ItemTracker.Logic.ComputeGridOrigin(6, 4, 36, 4, "DOWN")
assert(ox == 0 and oy == 0, "DOWN needs no origin shift")

ox, oy = ItemTracker.Logic.ComputeGridOrigin(6, 4, 36, 4, "LEFT")
assert(ox == 120 and oy == 0, "LEFT should shift x by (perLine-1)*step = 3*40 = 120, got ox=" .. ox)

ox, oy = ItemTracker.Logic.ComputeGridOrigin(6, 4, 36, 4, "UP")
assert(ox == 0 and oy == -120, "UP should shift y by -(perLine-1)*step = -120, got oy=" .. oy)

-- Bounding-box containment: for every growth direction, applying the
-- origin shift to every icon's ComputeSlotPosition must make the
-- grid's bounding box exactly match the frame's own rect -- this is
-- the property whose violation (for LEFT/UP) was the actual bug.
local function boundingBox(itemCount, columns, iconSize, spacing, growth)
  local shiftX, shiftY = ItemTracker.Logic.ComputeGridOrigin(itemCount, columns, iconSize, spacing, growth)
  local minX, maxX, minY, maxY
  for i = 1, itemCount do
    local x, y = ItemTracker.Logic.ComputeSlotPosition(i, columns, iconSize, spacing, growth)
    x, y = x + shiftX, y + shiftY
    if not minX or x < minX then minX = x end
    if not maxX or x + iconSize > maxX then maxX = x + iconSize end
    if not minY or y - iconSize < minY then minY = y - iconSize end
    if not maxY or y > maxY then maxY = y end
  end
  return minX, maxX, minY, maxY
end

for _, growth in ipairs({ "RIGHT", "LEFT", "DOWN", "UP" }) do
  local fw, fh = ItemTracker.Logic.ComputeFrameSize(6, { columns = 4, iconSize = 36, spacing = 4, growth = growth })
  local minX, maxX, minY, maxY = boundingBox(6, 4, 36, 4, growth)
  assert(minX == 0, growth .. ": grid should start at x=0 after origin shift, got minX=" .. minX)
  assert(maxX <= fw, growth .. ": grid should not exceed frame width, got maxX=" .. maxX .. " w=" .. fw)
  assert(maxY == 0, growth .. ": grid should start at y=0 after origin shift, got maxY=" .. maxY)
  assert(minY >= -fh, growth .. ": grid should not exceed frame height, got minY=" .. minY .. " h=" .. fh)
end

print("barlayout_test: all assertions passed")
