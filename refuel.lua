local args = {...}
local term = require("term")
local robot = require("robot")
local inv = component.getPrimary("inventory_controller")
local generator = component.getPrimary("generator")
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
    name = "refuel"
  end
  println("Usage:")
  println(name.." <amount>")
  println("amount: Number of fuel items to burn")
  os.exit()
end
if #args~=1 then
  if #args>0 then
    println("Incorrect number of arguments.")
  end
  printUsage()
end
local amount = tonumber(args[1])
if amount==nil then
  println("Failed to convert argument to number.")
  printUsage()
elseif amount<=0 then
  println("Please provide a positive argument.")
  printUsage()
end
local function arrayToSet(arr)
  for i=#arr,1,-1 do
    arr[arr[i]], arr[i] = true, nil
  end
end
local fuelSources = {
  "Coal",
  "Charcoal",
  "Planks",
  "Fence"
}
arrayToSet(fuelSources)
local invSize = robot.inventorySize()
local selectedSlot = robot.select(1)
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
local function refuel(x)
  local name, lbl
  local c,n = generator.count()
  if c>0 then
    name = n
  end
  local total = 0
  local key
  for i=1,invSize,1 do
    if robot.count(i)>0 then
      lbl = inv.getStackInInternalSlot(i).label
      if not name or name==lbl then
        key = lbl:match("%w+$")
        if name==lbl or key and fuelSources[key] then
          select(i)
          c,n = generator.insert(x)
          if c then
            name = lbl
            x = x-n
            total = total+n
            if x<=0 then
              return total
            end
          end
        end
      end
    end
  end
  return total
end
println("Burning "..refuel(amount).." items.")