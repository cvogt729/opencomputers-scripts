
-- when energy < this, fuel the generator
local generatorThreshold = 0.5
-- when energy < this, recharge at home
local rechargeThreshold = 0.08
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


-- print correct usage when invalid arguments are given
local function printUsage()
  local name = debug.getinfo(1,"S").source:match("[^/]+.lua")
  if name then
    name = name:sub(0,-5)
  else
    name = "Mine"
  end
  term.write("Usage:\n")
  term.write(name.." <radius> <homeY> <minY> <maxY>\n")
  term.write(name.." 40 60 8 35\n")
  term.write("radius: Max lateral distance from x,z origin\n")
  term.write("homeY: Absolute y coord of origin\n")
  term.write("minY: Lower bound for mining depth\n")
  term.write("maxY: Upper bound for mining depth\n")
  os.exit()
end
local args = {...}
if #args~=4 then
  if #args>0 then
    term.write("Incorrect number of arguments.")
  end
  printUsage()
end
local radius = tonumber(args[1])
local homeY = tonumber(args[2])
local minY = tonumber(args[3])
local maxY = tonumber(args[4])
if radius==nil or homeY==nil or minY==nil or maxY==nil then
  term.write("Failed to convert arguments to numbers.")
  printUsage()
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
          robot.drop()
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
        robot.drop()
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


-- check for chests placed on any side of turtle
-- drop valuables into chests
-- drop trash into chests
-- wait for energy to be > 0.98
-- go to maxY
-- go to a top corner of the mining region
-- process everything in 4x4x4 chunks with geolyzer
-- check energy level, inv space, and tool durability after each chunk
-- if low energy or less than 4 free slots, recharge and dump