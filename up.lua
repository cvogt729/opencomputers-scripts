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
    name = "up"
  end
  println("Usage:")
  println(name.." <d>")
  println("d: Number of spaces to move up")
  os.exit()
end
local d
if #args==0 then
  d = 1
else
  if #args~=1 then
    println("Incorrect number of arguments.")
    printUsage()
  end
  d = tonumber(args[1])
  if d==nil then
    println("Failed to convert argument to number.")
    printUsage()
  elseif d<=0 then
    println("Please provide a positive argument.")
    printUsage()
  end
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
local function placeBlock()
  local key
  for i=1,invSize,1 do
    if robot.count(i)>0 then
      key = inv.getStackInInternalSlot(i).label:match("%w+$")
      if key and placementBlocks[key] and select(i) and robot.place() then
        return true
      end
    end
  end
  return false
end
local function up()
  local s,t
  for i=1,60,1 do
    if robot.detectUp() then
      robot.swingUp()
    end
    s,t = robot.up()
    if s then
      return true
    elseif t=="impossible move" then
      placeBlock()
    end
    os.sleep(0.5)
  end
  return false
end
local x = 0
while x<d and up() do
  x = x+1
end
println("Moved up "..x.." block(s).")