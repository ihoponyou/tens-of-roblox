
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local InventoryService = Knit.CreateService({
    Name = "InventoryService",
    Client = {
        InventoryChanged = Knit.CreateSignal(),
    },

    Inventories = {},
    _folders = {}
})

function InventoryService:_onPlayerAdded(player: Player)
    -- core backpack is destroyed on death
    local inventory = Instance.new("Folder")
    inventory.Name = "Inventory"
    inventory.Parent = player

    self.Inventories[player.UserId] = {}
    self._folders[player.UserId] = inventory
end

function InventoryService:KnitInit()
    for _, v in Players:GetPlayers() do
        self:_onPlayerAdded(v)
    end
    Players.PlayerAdded:Connect(function(player) 
        self:_onPlayerAdded(player)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        self.Inventories[player.UserId] = nil
        -- folder instance will be destroyed on its own
        self._folders[player.UserId] = nil
    end)
end

function InventoryService:AddEquipment(player, equipment): boolean
    local inventory = self.Inventories[player.UserId]
    local slotType = equipment.SlotType

    if inventory[slotType] ~= nil then
        warn("slot is occupied by "..inventory[slotType].Name)
        return false
    end

    equipment.Instance.Parent = self._folders[player.UserId]
    inventory[slotType] = equipment.Instance

    self.Client.InventoryChanged:Fire(player, inventory)
    return true
end

function InventoryService:RemoveEquipment(player, equipment): boolean
    local inventory = self.Inventories[player.UserId]
    if inventory == nil then
        warn(player.UserId.." has no inventory table; may have left")
        return false
    end

    local slotType = equipment.SlotType

    if inventory[slotType] == nil then
        warn(equipment.Instance.Name.." not found for "..player.Name)
        return false
    end

    -- equipment may have been destroyed
    if equipment.Instance.Parent ~= nil then
        equipment.Instance.Parent = workspace
    end
    inventory[slotType] = nil

    self.Client.InventoryChanged:Fire(player, inventory)
    return true
end

return InventoryService
