local args = {...}
local term = require("term")
local robot = require("robot")
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
    name = "select"
  end
  println("Usage:")
  println(name.." <slot>")
  println("slot: Index of slot to select")
  os.exit()
end
if #args~=1 then
  if #args>0 then
    println("Incorrect number of arguments.")
  end
  printUsage()
end
local slot = tonumber(args[1])
local invSize = robot.inventorySize()
if slot==nil then
  println("Failed to convert argument to number.")
  printUsage()
elseif slot<1 or slot>invSize then
  println("Slot index out of bounds.")
  println("Allowed: [1,"..invSize.."]")
  printUsage()
end
robot.select(slot)