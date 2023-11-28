
local DEBUG = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(script.Parent.Extensions.Logger)

local Equippable = Component.new({
	Tag = "Equippable",
	Extensions = {
		Logger,
	},
})

function Equippable:Construct()
    self._trove = Trove.new()

    self.Equipped = false
    self.Owner = nil

    self.EquipRequest = Instance.new("RemoteFunction")
    self.EquipRequest.Name = "EquipRequest"
    self.EquipRequest.Parent = self.Instance

    self.EquipEvent = Instance.new("BindableEvent")
end

function Equippable:_onEquipRequested(player: Player)
    local character = player.Character
    if not character then return end

    if DEBUG then print(player.Name .. " equipped " .. self.Instance.Name) end

    self.Owner = player
    self.Instance:SetAttribute("OwnerID", player.UserId)

    self.EquipEvent:Fire(self.Owner, true)
end

function Equippable:_onUnequipRequested(player: Player)
    if player ~= self.Owner then return end

    if DEBUG then print(player.Name .. " unequipped " .. self.Instance.Name) end

    self.EquipEvent:Fire(self.Owner, false)
    self.Owner = nil
end

function Equippable:Start()
    self.EquipRequest.OnServerInvoke = function(player: Player, wantsToEquip: boolean)
        if wantsToEquip then
            self:_onEquipRequested(player)
        else
            self:_onUnequipRequested(player)
        end
    end
end

function Equippable:Stop()
    self._trove:Clean()
end

return Equippable
