
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local InventoryService = Knit.CreateService {
    Name = "InventoryService",
    Client = {
        -- fire these with instance as argument to protect server's equipment component
        ItemAdded = Knit.CreateSignal();
        ItemRemoved = Knit.CreateSignal();
    }
}

function InventoryService:OnPlayerAdded(player: Player)
    self.PlayerInventories[player.UserId] = {}
end

function InventoryService:OnPlayerRemoving(player: Player)
    self.PlayerInventories[player.UserId] = nil
end

function InventoryService:KnitInit()
    self.PlayerInventories = {}

    Players.PlayerAdded:Connect(function(player) self:OnPlayerAdded(player) end)
    Players.PlayerRemoving:Connect(function(player) self:OnPlayerRemoving(player) end)
end

function InventoryService:GiveItem(player: Player, item): boolean
    local currentItemAtSlot = self.PlayerInventories[player.UserId][item.Config.SlotType]
    if currentItemAtSlot ~= nil then
        warn(player.Name .. "already has an item @ slot " .. item.Config.SlotType)
        return false
    end

    self.PlayerInventories[player.UserId][item.Config.SlotType] = item
    self.Client.ItemAdded:Fire(player, item.Instance)
    return true
end

function InventoryService:TakeItem(player: Player, item): boolean
    self.PlayerInventories[player.UserId][item.Config.SlotType] = nil
    self.Client.ItemRemoved:Fire(player, item.Instance)
    return true
end

return InventoryService