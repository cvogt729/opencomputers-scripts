
-- Requires internet card upgrade

local args = {...}
local term = require("term")
local sh = require("shell")
local fs = require("filesystem")
local rep = "https://raw.githubusercontent.com/cvogt729/opencomputers-scripts/main/"
local path = debug.getinfo(2,"S").short_src
local dir = path:gsub("[^/]*.lua$","")
if #args==0 then
  if sh.execute("wget -fq "..rep.."update.lua "..path) then
    term.write(" * update.lua\n")
    sh.execute(path.." -x")
  else
    term.write(" ? update.lua\n")
  end
  os.exit()
end
local files = {
  "mine.lua",
  "turnRight.lua",
  "turnLeft.lua",
  "turnAround.lua",
  "forward.lua",
  "back.lua",
  "up.lua",
  "down.lua",
  "right.lua",
  "left.lua",
  "refuel.lua",
  "unfuel.lua",
  "select.lua",
  "place.lua",
  "placeDown.lua",
  "placeUp.lua"
}
--TODO
--  tunnel <d>
--    basically forward.lua with swingUp() added
--    place block below when detectDown() is false
--    use geolyzer scan to detect lava/water in bad spots
--    when detected, have the robot place blocks to make it safe
--  room <w> <d> <h>
--    dig out a room with the given dimensions
--  boundary <w> <d> <h>
--    place floor, walls, and ceiling for a room of the given dimensions
--    can also be used to replace walls with a specific block for uniformity
local blacklist = {}
local x
for i=1,#files,1 do
  path = dir..files[i]
  if fs.exists(path) then
    x = " * "
  else
    x = " + "
  end
  if not sh.execute("wget -fq "..rep..files[i].." "..path) then
    x = " ? "
  end
  term.write(x..files[i].."\n")
end
for i=1,#blacklist,1 do
  path = dir..blacklist[i]
  if fs.exists(path) then
    if fs.remove(path) then
      x = " - "
    else
      x = " ? "
    end
    term.write(x..blacklist[i].."\n")
  end
end