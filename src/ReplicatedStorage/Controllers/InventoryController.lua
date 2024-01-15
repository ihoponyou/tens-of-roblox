
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local InventoryService
local CameraController

local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)

local InventoryController = Knit.CreateController({
    Name = "InventoryController",

    Inventory = {},

    ActiveSlot = nil,
    ActiveSlotChanged = Signal.new()
})

function InventoryController:_tryEquip(newSlot: string)
    local oldSlot = self.ActiveSlot
    local currentItem = self.Inventory[oldSlot]
    if currentItem ~= nil then
        local equipment = EquipmentClient:FromInstance(currentItem)
        equipment:Unequip()

        self:SetActiveSlot(nil)
        if newSlot == oldSlot then return end
    end

    local newItem = self.Inventory[newSlot]
    if not newItem then return end
    local equipment = EquipmentClient:FromInstance(newItem)
    equipment:Equip()

    if equipment.Config.ThirdPersonOnly then
        CameraController:SetAllowFirstPerson(false)
    end

    self:SetActiveSlot(equipment.Config.SlotType)
end

function InventoryController:_tryDrop()
    local currentItem = self.Inventory[self.ActiveSlot]
    if currentItem ~= nil then
        local equipment = EquipmentClient:FromInstance(currentItem)
        equipment:Drop()

        self:SetActiveSlot(nil)
    end
end

function InventoryController:KnitInit()
    Knit.Player.CharacterRemoving:Connect(function(_character)
        self:SetActiveSlot(nil)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.KeyCode == Enum.KeyCode.One then
            self:_tryEquip("Primary")
        elseif input.KeyCode == Enum.KeyCode.Two then
            self:_tryEquip("Secondary")
        elseif input.KeyCode == Enum.KeyCode.Three then
            self:_tryEquip("Tertiary")
        elseif input.KeyCode == Enum.KeyCode.G then
            self:_tryDrop()
        end
    end)
end

function InventoryController:KnitStart()
    InventoryService = Knit.GetService("InventoryService")
    CameraController = Knit.GetController("CameraController")

    InventoryService.InventoryChanged:Connect(function(...)
        self.Inventory = ...
    end)

    self.ActiveSlotChanged:Connect(function()
        if self.ActiveSlot == nil then
            CameraController:SetAllowFirstPerson(true)
        end
    end)
end

function InventoryController:SetActiveSlot(slot: string)
    -- print(self.ActiveSlot, "->", slot)
    self.ActiveSlot = slot
    self.ActiveSlotChanged:Fire(slot)
end

return InventoryController
