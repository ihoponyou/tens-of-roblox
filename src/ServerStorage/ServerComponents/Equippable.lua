
local DEBUG = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(script.Parent.Extensions.Logger)
local Roact = require(ReplicatedStorage.Packages.Roact)

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

    self.WorldModel = self.Instance:WaitForChild("WorldModel")

    self.EquipRequest = self._trove:Add(Instance.new("RemoteFunction"))
    self.EquipRequest.Name = "EquipRequest"
    self.EquipRequest.Parent = self.Instance

    self.EquipPrompt = self._trove:Add(Instance.new("ProximityPrompt"))
    self.EquipPrompt.Name = "EquipPrompt"
    self.EquipPrompt.Parent = self.WorldModel
    self.EquipPrompt.Style = Enum.ProximityPromptStyle.Custom

    self.EquipEvent = self._trove:Add(Instance.new("BindableEvent"))
end

function Equippable:_showPrompt()
    Roact.mount(Roact.createElement("BillboardGui"), self.WorldModel.PrimaryPart)
end

function Equippable:_hidePrompt()
    -- Roact.unmount(self.PromptGui)
end

function Equippable:Equip(player: Player)
    local character = player.Character
    if not character then return false end

    if DEBUG then print(player.Name .. " equipped " .. self.Instance.Name) end

    self.Owner = player
    self.Instance:SetAttribute("OwnerID", player.UserId)

    self.EquipEvent:Fire(self.Owner, true)

    self.EquipPrompt.Enabled = false
    return true
end

function Equippable:Unequip(player: Player)
    if player ~= self.Owner then return false end

    if DEBUG then print(player.Name .. " unequipped " .. self.Instance.Name) end

    self.EquipEvent:Fire(self.Owner, false)
    self.Owner = nil

    self.EquipPrompt.Enabled = true
    return true
end

function Equippable:OnServerInvoke(player: Player, wantsToEquip: boolean)
    if wantsToEquip then
        return self:Equip(player)
    else
        return self:Unequip(player)
    end
end

function Equippable:Start()
    self.EquipRequest.OnServerInvoke = function(...) self:OnServerInvoke(...) end
    self._trove:Connect(self.EquipPrompt.Triggered, function(playerWhoTriggered: Player)
        self:Equip(playerWhoTriggered)
    end)
end

function Equippable:Stop()
    self._trove:Clean()
end

return Equippable
