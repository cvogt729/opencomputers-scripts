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
    name = "down"
  end
  println("Usage:")
  println(name.." <d>")
  println("d: Number of spaces to move down")
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
local function down()
  for i=1,60,1 do
    if robot.detectDown() then
      robot.swingDown()
    end
    if robot.down() then
      return true
    end
    os.sleep(0.5)
  end
  return false
end
local x = 0
while x<d and down() do
  x = x+1
end
println("Moved down "..x.." blocks.")