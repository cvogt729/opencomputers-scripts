
-- Mining Program
local version = "v0.1.0"

-- Requirements:
--   Upgrade: Geolyzer
--   Upgrade: Inventory Controller
--   Upgrade: Generator
--   Upgrade: Angel
--   Equipped Tool: Atomic Disassembler
--   Inventories on both left and right sides of robot
--   Empty space behind robot
--   OpenComputers charger in front of robot
--   Mekanism energy cube on top of charger
--   Some fuel in robot inventory for generator
--   Some placement blocks in robot inventory (e.g, cobblestone)

-- Valuables will be dumped into the left inventory
-- Trash will be dumped into the right inventory
-- If no right inventory, trash will be dumped on the groud
-- Any energized mining tool may be used in place of the atomic disassembler

-- placed when robot movement returns "impossible move"
local placementBlocks = {
  "Cobblestone"
}
-- items which may be burned for energy in the generator
local fuelSources = {
  "Coal",
  "Charcoal",
  "Planks",
  "Fence"
}
-- important items which should not be discarded
local valuables = {
  "Coal",
  "Charcoal",
  "Planks",
  "Fence",
  "Redstone",
  "Quartz",
  "Crystal",
  "Emerald",
  "Diamond",
  "Flint",
  "Rhodochrosite",
  "Lazuli",
  "Silicon",
  "Ore",
  "Dust",
  "Obsidian"
}

--os.sleep(seconds: number)
--os.exit()

local robot = require("robot")

-- all these have Up() and Down() variants
--robot.drop([count: number]): boolean
--robot.suck([count: number]): boolean
--robot.place([side: number[, sneaky: boolean]]): boolean[, string]
--robot.swing([side: number, [sneaky:boolean]]): boolean[, string]
--robot.use([side: number[, sneaky: boolean[, duration: number]]]): boolean[, string]

--robot.select([slot: number]): number
--robot.inventorySize(): number
--robot.count([slot: number]): number
--robot.space([slot: number]): number
--robot.transferTo(slot: number[, count: number]): boolean
--robot.compareTo(slot: number): boolean
--robot.durability(): number

--robot.turnLeft()
--robot.turnRight()
--robot.turnAround()
--robot.forward(): boolean[, string]
--robot.back(): boolean[, string]
--robot.up(): boolean[, string]
--robot.down(): boolean[, string]

local computer = require("computer")
--computer.energy(): number
--computer.maxEnergy(): number
--computer.shutdown([reboot: boolean])

local sides = require("sides")
--sides.bottom: number
--sides.top: number
--sides.back: number
--sides.front: number
--sides.right: number
--sides.left: number

local term = require("term")
--term.clear()
--term.read()
--term.write(value: string[, wrap: boolean])

local inv = component.getPrimary("inventory_controller")
--inv.equip():boolean
--inv.getStackInInternalSlot(slot:number):table
--inv.getInventorySize(side: number): number or nil[, string]

local generator = component.getPrimary("generator")
--generator.count(): number[, string]
--generator.insert([count: number]): boolean[, number]
--generator.remove([count: number]): boolean[, number]

local geo = component.getPrimary("geolyzer")
--geo.detect(side:number):boolean, string
--geo.analyze(side:number):table
--geo.scan(x:number, z:number[, y:number, w:number, d:number, h:number][, ignoreReplaceable:boolean|options:table]):table

-- Hardness of various blocks:
-- Water,Lava = 100
-- Obsidian = 50
-- Iron,Tin,Osmium,Copper,Gold,Uranium,Ferrous,Silver = 3
-- Cobblestone,Wood Planks,Marble,Diorite,Limestone,Andesite = 2
-- Stone = 1.5
-- Dirt,Gravel = 0.6
-- Air,Oil = 0

local i,j,k
local function println(s)
  if s then
    term.write(s.."\n")
  else
    term.write("\n")
  end
end

-- print correct usage when invalid arguments are given
local function printUsage()
  local name = debug.getinfo(2,"S").short_src:match("[^/]+.lua$")
  if name then
    name = name:sub(0,-5)
  else
    name = "mine"
  end
  println("Usage:")
  println(name.." <maxY>")
  println("maxY: Upper bound for mining depth")
  os.exit()
end
local args = {...}
if #args==1 and (args[1]=="--version" or args[1]=="-v") then
  println(version)
  os.exit()
end
if #args~=1 then
  if #args>0 then
    println("Incorrect number of arguments.")
  end
  printUsage()
end
local maxY = tonumber(args[1])
if maxY==nil then
  println("Failed to convert argument to number.")
  printUsage()
end


-- returns the energy level of this robot
local function getEnergy()
  return computer.energy()/computer.maxEnergy()
end
local function arrayToSet(arr)
  for i=#arr,1,-1 do
    arr[arr[i]], arr[i] = true, nil
  end
end
arrayToSet(fuelSources)
arrayToSet(valuables)
arrayToSet(placementBlocks)
local invSize = robot.inventorySize()
local selectedSlot = robot.select(1)
-- safe slot selection function when looping
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
-- drops all valuable items in front of the robot
-- retains at most one slot for fuel when keepFuel is true
local function dropValuables(keepFuel)
  local key
  local hasFuel = false
  for i=1,invSize,1 do
    if robot.count(i)>0 then
      key = inv.getStackInInternalSlot(i).label:match("%w+$")
      if key and valuables[key] then
        if not keepFuel or hasFuel or not fuelSources[key] then
          select(i)
          if not robot.drop() then
            println("Valuables inventory is full.")
            robot.turnRight()
            os.exit()
          end
        else
          hasFuel = true
        end
      end
    end
  end
end
-- drops all trash in front of the robot
-- retains at most one slot for blocks when keepBlock is true
local function dropTrash(keepBlock)
  local key
  local hasBlock = false
  for i=1,invSize,1 do
    if robot.count(i)>0 then
      key = inv.getStackInInternalSlot(i).label:match("%w+$")
      if key and not valuables[key] then
        if not keepBlock or hasBlock or not placementBlocks[key] then
          select(i)
          if not robot.drop() then
            robot.dropUp()
          end
        else
          hasBlock = true
        end
      end
    end
  end
end
-- places a block in front of the robot
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
-- places a block below the robot
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
-- attempts to load the generator with fuel
-- returns boolean value indicating success
local function refuel()
  if generator.count()>0 then
    return true
  end
  local key
  for i=1,invSize,1 do
    if robot.count(i)>0 then
      key = inv.getStackInInternalSlot(i).label:match("%w+$")
      if key and fuelSources[key] then
        select(i)
        if generator.insert() then
          return true
        end
      end
    end
  end
  return false
end
-- attempts to removes all fuel from the generator
-- returns boolean value indicating success
local function removeFuel()
  local count, name = generator.count()
  if count==0 then
    return true
  end
  for i=1,invSize,1 do
    if robot.count(i)==0 or name and robot.space(i)>0 and name==inv.getStackInInternalSlot(i).label then
      select(i)
      generator.remove()
      count, name = generator.count()
      if count==0 then
        return true
      end
    end
  end
  return false
end
-- positive x axis is to left of robot
-- positive z axis is to front of robot
-- positive y axis is above robot
-- w represents relative facing side
-- 0=initial, 1=turnRight(), 2=turnAround(), 3=turnLeft()
local x,y,z,w = 0,0,0,0
local homeY = 0
local function up()
  local s,t
  for i=1,60,1 do
    if geo.detect(sides.up) then
      robot.swingUp()
    end
    s,t = robot.up()
    if s then
      y = y+1
      return true
    elseif t=="impossible move" then
      placeBlock()
    end
    os.sleep(0.5)
  end
  return false
end
local function down()
  for i=1,60,1 do
    if geo.detect(sides.down) then
      robot.swingDown()
    end
    if robot.down() then
      y = y-1
      return true
    end
    os.sleep(0.5)
  end
  return false
end
local function forward()
  local s,t
  for i=1,120,1 do
    if geo.detect(sides.front) then
      robot.swing()
    end
    s,t = robot.forward()
    if s then
      z = z+1
      return true
    elseif t=="impossible move" then
      placeBlockDown()
    end
    os.sleep(0.5)
  end
  return false
end
local function back()
  local s,t = robot.back()
  if s then
    z = z-1
    return true
  elseif t=="impossible move" then
    placeBlockDown()
    if robot.back() then
      z = z-1
      return true
    else
      return false
    end
  else
    return false
  end
end
local function turnRight()
  robot.turnRight()
  x,z = z,-x
  w = (w+1)%4
end
local function turnLeft()
  robot.turnLeft()
  x,z = -z,x
  w = (w+3)%4
end
local function turnAround()
  robot.turnAround()
  x,z = -x,-z
  w = (w+2)%4
end
local function setFace(ww)
  if ww and w~=ww then
    if (w+3)%4==ww then
      turnLeft()
    elseif (w+1)%4==ww then
      turnRight()
    else
      turnAround()
    end
  end
end
local function transformXZ(xx, zz, wOld, wNew)
  if not wNew then
    wNew = w
  end
  if wOld==wNew then
    return xx,zz
  elseif (wOld+1)%4==wNew then
    return zz,-xx
  elseif (wOld+2)%4==wNew then
    return -xx,-zz
  elseif (wOld+3)%4==wNew then
    return -zz,xx
  end
end
local homeCheckIndex = 0
local function needsHome()
  homeCheckIndex = homeCheckIndex+1
  if homeCheckIndex>=5 then
    homeCheckIndex = 0
    local e = getEnergy()
    if e>0.95 then
      removeFuel()
    elseif e<0.85 then
      if refuel() and e<0.2 then
        while true do
          os.sleep(10)
          if getEnergy()>0.3 or not refuel() then
            break
          end
        end
      end
      if e<0.25 then
        return true
      end
    end
    if robot.durability()<0.2 then
      return true
    end
    local count = 0
    for i=1,invSize,1 do
      if robot.count(i)==0 then
        count = count+1
        if count>=4 then
          break
        end
      end
    end
    return count<4
  end
  return false
end
-- Empties inventory, charges robot, and charges tool
local function chargeAndDrop()
  if geo.analyze(sides.front).name~="OpenComputers:charger" then
    println("Please place an OpenComputers charger in front of the robot.")
    os.exit()
  end
  up()
  if geo.analyze(sides.front).name~="Mekanism:EnergyCube" then
    println("Please place a Mekanism energy cube above the charger.")
    down()
    os.exit()
  end
  i=0
  while robot.durability()<0.98 do
    i = i+1
    if i==36 then
      println("Energy cube appears to have run out of power.")
      os.exit()
    end
    inv.equip()
    inv.dropIntoSlot(sides.front,1)
    os.sleep(5)
    inv.suckFromSlot(sides.front,1)
    inv.equip()
  end
  down()
  robot.turnRight()
  dropTrash(true)
  removeFuel()
  robot.turnAround()
  dropValuables(true)
  robot.turnRight()
  i=0
  while getEnergy()<0.98 do
    i = i+1
    if i==60 then
      println("Energy cube appears to have run out of power.")
      os.exit()
    end
    os.sleep(5)
  end
end
local function goXZ(xd,zd)
  while zd>0 do
    forward()
    zd = zd-1
  end
  while zd<0 and back() do
    zd = zd+1
  end
  local flag = 0
  if xd>0 then
    turnLeft()
    flag = 1
  elseif xd<0 then
    turnRight()
    xd = -xd
    flag = -1
  end
  while xd>0 do
    forward()
    xd = xd-1
  end
  if zd<0 then
    if flag==1 then
      turnLeft()
    elseif flag==-1 then
      turnRight()
    else
      turnAround()
    end
    while zd<0 do
      forward()
      zd = zd+1
    end
  end
end
local function go(xx,yy,zz,ww,ignoreCheck)
  if not ignoreCheck and needsHome() then
    local www = w
    go(0,homeY,0,0,true)
    chargeAndDrop()
    local yd = yy-y
    while yd>0 do
      up()
      yd = yd-1
    end
    while yd<0 do
      down()
      yd = yd+1
    end
    xx,zz = transformXZ(xx,zz,www)
    goXZ(xx-x,zz-z)
    setFace(ww)
  else
    goXZ(xx-x,zz-z)
    setFace(ww)
    local yd = yy-y
    while yd>0 do
      up()
      yd = yd-1
    end
    while yd<0 do
      down()
      yd = yd+1
    end
  end
end
local function kill(xx,yy,zz)
  if needsHome() then
    local ww = w
    go(0,homeY,0,0,true)
    chargeAndDrop()
    local yd = yy-y
    while yd>0 do
      up()
      yd = yd-1
    end
    while yd<0 do
      down()
      yd = yd+1
    end
    xx,zz = transformXZ(xx,zz,ww)
  end
  if y==yy then
    local zd = zz-z
    if xx==x then
      if zz~=z then
        if zd<0 then
          zd = -zd
          turnAround()
        end
        while zd>1 do
          forward()
          zd = zd-1
        end
        robot.swing()
      end
    elseif zd>=0 then
      while zd>0 do
        forward()
        zd = zd-1
      end
      local xd = xx-x
      if xd>0 then
        turnLeft()
      else
        turnRight()
        xd = -xd
      end
      while xd>1 do
        forward()
        xd = xd-1
      end
      robot.swing()
    else
      local flag = false
      local xd = xx-x
      if xd>0 then
        turnLeft()
        flag = true
      else
        turnRight()
        xd = -xd
      end
      while xd>0 do
        forward()
        xd = xd-1
      end
      if flag then
        turnLeft()
      else
        turnRight()
      end
      while zd<1 do
        forward()
        zd = zd+1
      end
      robot.swing()
    end
  else
    goXZ(xx-x,zz-z)
    local yd = yy-y
    if yd>0 then
      while yd>1 do
        up()
        yd = yd-1
      end
      robot.swingUp()
    else
      while yd<-1 do
        down()
        yd = yd+1
      end
      robot.swingDown()
    end
  end
end
local geoW = 0
local function orientGeolyzer()
  local t = geo.scan(-1,-1,0,3,3,1)
  if t[2]==0 then
    geoW = 0
  elseif t[4]==0 then
    geoW = 1
  elseif t[6]==0 then
    geoW = 3
  elseif t[8]==0 then
    geoW = 2
  else
    println("Unable to orient geolyzer.")
    println("Please ensure the space behind the robot is empty.")
    os.exit()
  end
end
local function scan()
  local n = 10
  local raw = {}
  local gx,gz,gy -- relative scan anchor coords in geolyzer orientation
  local gw,gd,gh -- width, height, and depth of geolyzer scan
  gy = -1
  gh = 3
  if w==geoW then
    gx,gz,gw,gd = -1,0,3,7
  elseif (w+2)%4==geoW then
    gx,gz,gw,gd = -1,-6,3,7
  elseif (w+1)%4==geoW then
    gx,gz,gw,gd = 0,-1,7,3
  else
    gx,gz,gw,gd = -6,-1,7,3
  end
  for i=1,63,1 do
    raw[i] = 0
  end
  local _raw
  for i=1,n,1 do
    _raw = geo.scan(gx,gz,gy,gw,gd,gh)
    for j=1,63,1 do
      raw[j] = raw[j]+_raw[j]
    end
  end
  _raw = nil
  gw = gw-1
  gd = gd-1
  gh = gh-1
  local ores = {}
  local i = 0
  local j = 0
  for yy=0,gh,1 do
    for zz=0,gd,1 do
      for xx=0,gw,1 do
        i = i+1
        raw[i] = raw[i]/n
        if raw[i]>2.4 and raw[i]<60 then
          j = j+1
          ores[j] = {
            _x = gx+xx,
            _z = gz+zz,
            _y = gy+yy
          }
          ores[j]._x, ores[j]._z = transformXZ(ores[j]._x, ores[j]._z, geoW)
        end
      end
    end
  end
  raw = nil
  table.sort(ores, function (a,b)
    if a._z==b._z then
      if a._y==b._y then
        if a._y%2==0 then
          return a._x<b._x
        else
          return a._x>b._x
        end
      else
        if a._z%2==0 then
          return a._y<b._y
        else
          return a._y>b._y
        end
      end
    else
      return a._z<b._z
    end
  end)
  for i=1,j,1 do
    ores[i]._x = x+ores[i]._x
    ores[i]._y = y+ores[i]._y
    ores[i]._z = z+ores[i]._z
    --println("("..ores[i]._x..", "..ores[i]._z..", "..ores[i]._y..")")
  end
  return ores
end
local function scanAndMine()
  local ww = w
  local ores = scan()
  local len = #ores
  for i=0,len,1 do
    ores[i]._x, ores[i]._z = transformXZ(ores[i]._x, ores[i]._z, ww, w)
    kill(ores[i]._x, ores[i]._y, ores[i]._z)
  end
end

-- This is where the primary logic block begins
orientGeolyzer()
chargeAndDrop()
homeY = 1
z = 0
while true do
  if geo.detect(sides.down) then
    robot.swingDown()
  end
  x,y = robot.down()
  if x then
    homeY = homeY+1
    z = 0
  elseif y and y=="solid" or z==10 then
    break
  else
    z = z+1
    os.sleep(0.5)
  end
end
x,y,z = 0,1,0
maxY = math.min(maxY, homeY-2)
maxY = maxY-(maxY%3)
go(0,2,0)
scanAndMine()
--go(30,maxY-1,-31,0)
--local xl
--local wl = 0
--for yl=maxY-1,2,-3 do
--  for xo=30,-30,-3 do
--    xl = xo*(wl-1)
--    
--  end
--  if wl==0 then
--    wl = 2
--  else
--    wl = 0
--  end
--end
go(0,homeY,0,0,true)
chargeAndDrop()