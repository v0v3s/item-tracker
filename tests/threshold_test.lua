dofile("ItemTracker/Logic/Threshold.lua")

assert(ItemTracker.Logic.IsLowStock(0, 1) == true, "0 below threshold 1 should warn")
assert(ItemTracker.Logic.IsLowStock(5, 1) == false, "5 above threshold 1 should not warn")
assert(ItemTracker.Logic.IsLowStock(1, 1) == false, "count equal to threshold should not warn")
assert(ItemTracker.Logic.IsLowStock(0, nil) == false, "nil threshold should never warn")
assert(ItemTracker.Logic.IsLowStock(0, 0) == false, "zero threshold should never warn")
assert(ItemTracker.Logic.IsLowStock(nil, 1) == true, "nil count should be treated as 0")

print("threshold_test: all assertions passed")
