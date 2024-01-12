
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local InventoryService = Knit.CreateService({
    Name = "InventoryService",
    Client = {
        InventoryChanged = Knit.CreateSignal(),
        ActiveSlotChanged = Knit.CreateSignal()
    },

    PlayerInventories = {}
})

function InventoryService:_onPlayerAdded(player: Player)
    local inventory = Instance.new("Folder")
    inventory.Name = "Inventory"
    inventory.Parent = player

    self.PlayerInventories[player.UserId] = {}
end

function InventoryService:KnitInit()
    for _, v in Players:GetPlayers() do
        self:_onPlayerAdded(v)
    end
    Players.PlayerAdded:Connect(function(player) 
        self:_onPlayerAdded(player)
    end)
    Players.PlayerRemoving:Connect(function(player: Player) 
        self.PlayerInventories[player.UserId] = nil
    end)
end

function InventoryService:PickUp(player: Player, equipment, pickingUp: boolean): boolean
    if pickingUp and equipment.Owner ~= nil then return false end

    local inventory = self.PlayerInventories[player.UserId]
    if not pickingUp and inventory == nil then
        -- warn("player has no inventory")
        return true
    end
    local slotType = equipment.Config.SlotType

    if pickingUp then
        if inventory[slotType] ~= nil then return false end
        
        inventory[slotType] = equipment
    else
        if inventory[slotType] == nil then return false end
        
        inventory[slotType] = nil
    end

    -- print(inventory)

    return true
end

return InventoryService
