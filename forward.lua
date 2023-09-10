local args = {...}
local term = require("term")
local robot = require("robot")
local inv = component.getPrimary("inventory_controller")
local function println(s)
  if s then
    term.write(s.."\n")
  else
    term.write("\n")
  end
end
local function printUsage()
  local name = debug.getinfo(2,"S").short_src:match("[^/]+.lua$")
  if name then
    name = name:sub(0,-5)
  else
    name = "forward"
  end
  println("Usage:")
  println(name.." <d>")
  println("d: Number of spaces to move forward")
  os.exit()
end
if #args~=1 then
  if #args>0 then
    println("Incorrect number of arguments.")
  end
  printUsage()
end
local d = tonumber(args[1])
if d==nil then
  println("Failed to convert argument to number.")
  printUsage()
elseif d<=0 then
  println("Please provide a positive argument.")
  printUsage()
end
local function arrayToSet(arr)
  for i=#arr,1,-1 do
    arr[arr[i]], arr[i] = true, nil
  end
end
local placementBlocks = {
  "Cobblestone",
  "Dirt"
}
arrayToSet(placementBlocks)
local invSize = robot.inventorySize()
local selectedSlot = robot.select(1)
local function select(slot)
  if slot<0 then
    slot = invSize
  elseif slot>invSize then
    slot = 0
  end
  if slot~=selectedSlot then
    selectedSlot = robot.select(slot)
  end
  return true
end
local function placeBlockDown()
  local key
  for i=1,invSize,1 do
    if robot.count(i)>0 then
      key = inv.getStackInInternalSlot(i).label:match("%w+$")
      if key and placementBlocks[key] and select(i) and robot.placeDown() then
        return true
      end
    end
  end
  return false
end
local function forward()
  local s,t
  for i=1,120,1 do
    if robot.detect() then
      robot.swing()
    end
    s,t = robot.forward()
    if s then
      return true
    elseif t=="impossible move" then
      placeBlockDown()
    end
    os.sleep(0.5)
  end
  return false
end
local x = 0
while x<d and forward() do
  x = x+1
end
println("Moved forward "..x.." blocks.")