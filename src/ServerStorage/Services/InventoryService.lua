
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local InventoryService = Knit.CreateService {
    Name = "InventoryService",
    Client = {
        -- fire these with instance as argument to protect server's equipment component
        ItemAdded = Knit.CreateSignal();
        ItemRemoved = Knit.CreateSignal();
    },

    PlayerInventories = {},
    _playerConnections = {}
}

function InventoryService:OnPlayerAdded(player: Player)
    local inventoryFolder = Instance.new("Folder")
    inventoryFolder.Name = "Inventory"
    inventoryFolder.Parent = player

    self.PlayerInventories[player.UserId] = {}
    self._playerConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
        self:ClearInventory(player)
    end)
end

function InventoryService:OnPlayerRemoving(player: Player)
    self.PlayerInventories[player.UserId] = nil
    self._playerConnections[player.UserId]:Disconnect()
    self._playerConnections[player.UserId] = nil
end

function InventoryService:KnitInit()
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

function InventoryService:ClearInventory(player: Player)
    for slot, item in self.PlayerInventories[player.UserId] do
        self:TakeItem(player, item)
    end
end

return InventoryService