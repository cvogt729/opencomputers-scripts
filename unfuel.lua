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
if removeFuel() then
  println("Fuel removed.")
else
  println("Failed to remove fuel.")
end