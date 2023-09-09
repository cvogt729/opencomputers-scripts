local args = {...}
local term = require("term")
local sh = require("shell")
local rep = "https://raw.githubusercontent.com/cvogt729/opencomputers-scripts/main/"
local path = debug.getinfo(2,"S").short_src
local dir = path:gsub("[^/]*.lua$","")
if #args==0 then
  local ret = sh.execute("wget -f "..rep.."update.lua "..path)
  if ret then
    sh.execute(path.." -x")
  end
  os.exit()
end
local files = {
  "mine.lua"
}
for i=#files,1,-1 do
  sh.execute("wget -f "..rep..files[i].." "..dir..files[i])
end