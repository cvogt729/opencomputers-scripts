local args = {...}
local term = require("term")
local robot = require("robot")
local sh = require("shell")
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
    name = "left"
  end
  println("Usage:")
  println(name.." <d>")
  println("d: Number of spaces to move left")
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
robot.turnLeft()
println("Turned left.")
sh.execute(debug.getinfo(2,"S").short_src:gsub("[^/]*.lua$","").."forward.lua "..d)
robot.turnRight()
println("Turned right.")