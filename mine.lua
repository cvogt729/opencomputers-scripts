
-- when energy < this, fuel the generator
local generatorThreshold = 0.7
-- when energy < this, recharge at home
local rechargeThreshold = 0.15
-- when energy > this, considered to have full charge
local maxChargeThreshold = 0.98
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

-- positive x axis is to left of robot
-- positive z axis is to front of robot
-- positive y axis is above robot

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
  term.write(s.."\n")
end

-- print correct usage when invalid arguments are given
local function printUsage()
  local name = debug.getinfo(2,"S").short_src:match("[^/]+.lua$")
  if name then
    name = name:sub(0,-5)
  else
    name = "Mine"
  end
  println("Usage:")
  println(name.." <radius> <maxY>")
  println(name.." 40 30")
  println("radius: Max lateral distance from x,z origin")
  println("maxY: Upper bound for mining depth")
  os.exit()
end
local args = {...}
if #args~=2 then
  if #args>0 then
    println("Incorrect number of arguments.")
  end
  printUsage()
end
local radius = tonumber(args[1])
local maxY = tonumber(args[2])
if radius==nil or maxY==nil then
  println("Failed to convert arguments to numbers.")
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
local function dropTrash()
  local key
  for i=1,invSize,1 do
    if robot.count(i)>0 then
      key = inv.getStackInInternalSlot(i).label:match("%w+$")
      if key and not valuables[key] then
        select(i)
        if not robot.drop() then
          robot.dropUp()
        end
      end
    end
  end
end
-- attempts to load the generator with fuel
-- returns boolean value indicating success
local function refuel()
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
local x,y,z = 0,0,0
local function up()
  for i=1,60,1 do
    if geo.detect(sides.up) then
      robot.swingUp()
    end
    if robot.up() then
      y = y+1
      return true
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
  for i=1,120,1 do
    if geo.detect(sides.front) then
      robot.swing()
    end
    if robot.forward() then
      z = z+1
      return true
    end
    os.sleep(0.5)
  end
  return false
end
local function back()
  if robot.back() then
    z = z-1
    return true
  else
    return false
  end
end
local function turnRight()
  robot.turnRight()
  x,z = z,-x
end
local function turnLeft()
  robot.turnLeft()
  x,z = -z,x
end
local function turnAround()
  robot.turnAround()
  x,z = -x,-z
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
  while robot.durability()<maxChargeThreshold do
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
  dropTrash()
  removeFuel()
  robot.turnAround()
  dropValuables(true)
  robot.turnRight()
  i=0
  while getEnergy()<maxChargeThreshold do
    i = i+1
    if i==60 then
      println("Energy cube appears to have run out of power.")
      os.exit()
    end
    os.sleep(5)
  end
end
chargeAndDrop()
local homeY = 1
while true do
  if geo.detect(sides.down) then
    robot.swingDown()
  end
  if robot.down() then
    homeY = homeY+1
  else
    break
  end
end
x,y,z = 0,1,0
while y<homeY do
  up()
end
chargeAndDrop()