local args = {...}
local term = require("term")
local sh = require("shell")
local path = debug.getinfo(2,"S").short_src
local dir = path:gsub("[^/]*.lua$","")
if #args==0 then
  local ret = sh.execute("wget -f https://raw.githubusercontent.com/cvogt729/opencomputers-scripts/main/update.lua "..path)
  if ret then
    term.write("SUCCESS: update.lua\n")
    sh.execute(path)
  else
    term.write("FAILED: update.lua\n")
  end
  os.exit()
end
term.write("Test\n")