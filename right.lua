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
    name = "right"
  end
  println("Usage:")
  println(name.." <d>")
  println("d: Number of spaces to move right")
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
robot.turnRight()
println("Turned right.")
sh.execute(debug.getinfo(2,"S").short_src:gsub("[^/]*.lua$","").."forward.lua "..d)
robot.turnLeft()
println("Turned left.")