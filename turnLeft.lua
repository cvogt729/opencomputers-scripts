local robot = require("robot")
local term = require("term")
local function println(s)
  if s then
    term.write(s.."\n")
  else
    term.write("\n")
  end
end
robot.turnLeft()
println("Turned left.")