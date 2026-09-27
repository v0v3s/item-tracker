dofile("ItemTracker/Logic/BarLayout.lua")

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

print("barlayout_test: all assertions passed")
