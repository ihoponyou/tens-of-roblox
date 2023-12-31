
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local InventoryService

local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)
local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)

local DEBUG = false

local InventoryController = Knit.CreateController({
    Name = "InventoryController";

    Inventory = {};
    InventoryChanged = Signal.new();

    ActiveItem = nil;
    ActiveSlot = nil;
    ActiveSlotChanged = Signal.new();
})

function InventoryController:_onItemAdded(item: Instance)
    if DEBUG then print('added', item) end

    local slotType = EquipmentConfig[item.Name].SlotType
    if not slotType then error("this equipment does not have a slot type") end

    self.Inventory[slotType] = item
    if DEBUG then print(self.Inventory) end
    self.InventoryChanged:Fire(self.Inventory)

    if self.ActiveSlot ~= slotType then return end
    self.ActiveItem = item
    local equipSuccess = EquipmentClient:FromInstance(self.ActiveItem):Equip()
    if not equipSuccess then
        self.ActiveItem = nil
        error("could not auto-equip picked up item")
    end
end

function InventoryController:_onItemRemoved(item: Instance)
    if DEBUG then print('removed', item) end

    local slotType = EquipmentConfig[item.Name].SlotType
    if not slotType then error("this equipment does not have a slot type") end

    local entry = self.Inventory[slotType]
    if not entry or entry ~= item then error("you do not have", item) end

    self.Inventory[slotType] = nil
    if DEBUG then print(self.Inventory) end
    self.InventoryChanged:Fire(self.Inventory)

    if self.ActiveItem == item then self.ActiveItem = nil end
end

function InventoryController:UseActiveItem()
    if not self.ActiveItem then warn("No active item to use") return end
    EquipmentClient:FromInstance(self.ActiveItem):Use()
end

function InventoryController:DropActiveItem()
    if not self.ActiveItem then warn("No active item to drop") return end
    EquipmentClient:FromInstance(self.ActiveItem):Drop()
end

local function isValidSlot(slot: string)
    return type(slot) == "string" and (slot == "Primary" or slot == "Secondary" or slot == "Tertiary") 
end
function InventoryController:SwitchSlot(slot: string)
    if not isValidSlot(slot) then error("invalid slot") end
    -- print("switch from", self.ActiveItem, "to", self.Inventory[slot])

    if self.ActiveItem ~= nil then
        local unequipSuccess = EquipmentClient:FromInstance(self.ActiveItem):Unequip()
        if not unequipSuccess then error("could not unequip old slot") end
    end

    self.ActiveSlot = slot
    self.ActiveSlotChanged:Fire(slot)
    self.ActiveItem = self.Inventory[slot]

    UserInputService.MouseIconEnabled = self.ActiveItem == nil
    if self.ActiveItem == nil then return end

    local equipSuccess = EquipmentClient:FromInstance(self.ActiveItem):Equip()
    -- print(equipSuccess)
    if not equipSuccess then
        self.ActiveItem = nil
        error("could not equip new slot")
    end
end

function InventoryController:KnitStart()
    InventoryService = Knit.GetService("InventoryService")

    InventoryService.ItemAdded:Connect(function(item: Instance)
        self:_onItemAdded(item)
    end)
    InventoryService.ItemRemoved:Connect(function(item: Instance)
        self:_onItemRemoved(item)
    end)
end

return InventoryController
