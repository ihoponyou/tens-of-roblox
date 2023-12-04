
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Equippable = require(ServerStorage.Source.ServerComponents.Equippable)

local InventoryService = Knit.CreateService {
    Name = "InventoryService",
    Client = {
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

function InventoryService:KnitStart()
    
end

function InventoryService:GiveItem(player: Player, item: Equippable): boolean
    local currentItemAtSlot = self.PlayerInventories[player.UserId][item.SlotType]
    if currentItemAtSlot ~= nil then
        warn(player.Name .. "already has an item @ slot " .. item.SlotType)
        return false
    end

    self.PlayerInventories[player.UserId][item.SlotType] = item
    self.Client.ItemAdded:Fire(player, item)
    return true
end

function InventoryService:TakeItem(player: Player, item)
    self.PlayerInventories[player.UserId][item.SlotType] = item
    self.Client.ItemRemoved:Fire(player, item)
end

return InventoryService