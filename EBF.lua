-- КОД НЕ ВЛЕЗЕТ В КОНТРОЛЛЕР. ВОСПОЛЬЗУЙСЯ УМЕНЬШИТЕЛЕМ!!! https://goonlinetools.com/lua-minifier/

local trs = component.proxy(component.list("transposer")())

-- Bottom (bottom) (down), Number: 0
-- Top (top) (up), Number: 1
-- Back (back) (north), Number: 2
-- Front (front) (south), Number: 3
-- Right (right) (west), Number: 4
-- Left (left) (east), Number: 5

-- 0 - Ожидание работы (Пока во входном сундуке не появится что-либо)
-- 1 - Раздача товара (пока не опустеет входной сундук)
-- 2 - Ожидание опустошения выходного сундука (либо остаётся только одна схема)
-- 3 - Выкидывание схемы (если есть)
local mode = 0

-- Состояние входного сундука
local inputChest = {}

local tanks = {"gregtech:gt.Volumetric_Flask"}
local circuit = "gregtech:gt.integrated_circuit"
local catalizator = "bartworks:gt.bwMetaGenerateddust"

local sideTrash = 4
local sodeOuputItems = 3
local sideInput = 1
local sideOuputTank = 5

local function isEmpty(table)
  for i = 0, #table do
    if table[i] ~= nill then		
      if table[i].label ~= nil then
        return false
      end
    end
  end
  
  return true
end

local function isItemCircuit(item)
  if circuit == item.name then
    return true
  end
  if catalizator == item.name then
    return true
  end
  return false
end

local function isOnlyCircuit(table)
  local findedCircuit = false
  
  for i = 0, #table do
    if table[i] ~= nill then		
      if table[i].label ~= nil then
        if isItemCircuit(table[i]) == true then
          if findedCircuit == false then
            findedCircuit = true
          else
            return false
          end
        else
          return false
        end
      end
    end
  end
  
  return findedCircuit
end

local function isTank(item)
  for i = 0, #tanks do
    if tanks[i] == item.name then
      return true
    end
  end
  return false
end

local function waitForWork(args)
  inputChest = {}

  inputChest = trs.getAllStacks(sideInput).getAll()
  if isEmpty(inputChest) == false then
    -- ПЕРЕДЕЛАТЬ! После начала складирования нужно подождать того что в сундук перестали подкладываться предметы!!!
    computer.pullSignal(1)
    inputChest = trs.getAllStacks(sideInput).getAll()
    return 1
  end
  
  return 0
end

local function sendIngridients(args)   
  for i, item in pairs(inputChest) do
    if item.name ~= nil then
      local transfer = 0
        
      if isTank(item) == true then
        transfer = trs.transferItem(sideInput, sideOuputTank, item.size, i + 1, 1)
      else
        transfer = trs.transferItem(sideInput, sodeOuputItems, item.size, i + 1, i + 1)
      end
        
    	if (item.size - transfer) == 0 then
        inputChest[i] = nil
      else
        inputChest[i].size = item.size - transfer 
      end
    end
  end

  if isEmpty(inputChest) == true then
    return 2
  end  
  
  return 1
end

local function waitTakeItemsTank(args)
  local topChest = trs.getAllStacks(sodeOuputItems).getAll()
  if isEmpty(topChest) == true then
    return 0
  elseif isOnlyCircuit(topChest) == true then
    return 3
  end
  
  return 2
end

local function finishing(args)
  local topChest = trs.getAllStacks(sodeOuputItems).getAll()
  
  for i, item in pairs(topChest) do
    if item.name ~= nil then
      local transfer = trs.transferItem(sodeOuputItems, sideTrash, item.size, i + 1, i + 1)
        
    	if (item.size - transfer) == 0 then
        topChest[i] = nil
      else
        topChest[i].size = item.size - transfer 
      end
    end
  end
  
  if isEmpty(topChest) == true then
    return 0
  end  
  
  return 3
end

while true do
  if mode == 0 then
    mode = waitForWork()
  end
  if mode == 1 then
    mode = sendIngridients()
  end
  if mode == 2 then
    mode = waitTakeItemsTank()
  end
  if mode == 3 then
    mode = finishing()
  end  

  computer.pullSignal(1)
end
