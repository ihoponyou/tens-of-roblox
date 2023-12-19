
local DEBUG = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local Equipment = Component.new({
	Tag = "Equipment",
	Extensions = {
		Logger,
	},
})

local InventoryService

function Equipment:Construct()
    self._trove = Trove.new()

    self.IsEquipped = false
    self.Owner = nil
    self.Config = ReplicatedStorage.Equipment:FindFirstChild(self.Instance.Name, true).Configuration:GetAttributes()

    self.WorldModel = self.Instance:WaitForChild("WorldModel")
    self.WorldModel.PrimaryPart.CollisionGroup = "Equipment"

    self.PickUpRequest = self._trove:Add(Instance.new("RemoteFunction"))
    self.PickUpRequest.Name = "PickUpRequest"
    self.PickUpRequest.Parent = self.Instance

    self.EquipRequest = self._trove:Add(Instance.new("RemoteFunction"))
    self.EquipRequest.Name = "EquipRequest"
    self.EquipRequest.Parent = self.Instance

    self.PickUpPrompt = self._trove:Add(Instance.new("ProximityPrompt"))
    self.PickUpPrompt.Name = "PickUpPrompt"
    self.PickUpPrompt.Parent = self.WorldModel
    self.PickUpPrompt.Style = Enum.ProximityPromptStyle.Custom
end

-- returns true if successful, otherwise false
function Equipment:PickUp(player: Player): boolean
    if self.Owner ~= nil then warn(player.Name .. " tried to pick up already picked up equipment") return false end

    local character = player.Character
    if not character then return false end

    local giveSuccess = InventoryService:GiveItem(player, self)
    if not giveSuccess then return false end

    if DEBUG then print(player.Name .. " picked up " .. self.Instance.Name) end

    self.Owner = player
    self.Instance:SetAttribute("OwnerID", player.UserId)
    self.Instance.Parent = player.Backpack

    self.WorldModel.PrimaryPart.CanCollide = false

    self.PickUpPrompt.Enabled = false
    return true
end

function Equipment:Equip(player: Player): boolean?
    if player ~= self.Owner then error("Non-owner requested equip") end

    local character = self.Owner.Character
    if not character then error("Cannot rig equipment to owner; no character") end

    local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot rig equipment to character; model missing RootJoint") end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then error("Cannot rig equipment to character; character missing HumanoidRootPart") end

    -- set this at the end of animation
    self.IsEquipped = true

    -- rig equipment to character
    self.WorldModel.Parent = character
    modelRootJoint.Part0 = hrp

    return true
end

function Equipment:Unequip(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested unequip") end

    local character = player.character
    if not character then error("Cannot unrig equipment from character; no character") end

    local modelRootJoint: Motor6D = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot unrig equipment from character; equipment missing RootJoint") end

    -- TODO: character:StopPlayingAnimations()
    modelRootJoint.Part0 = nil
    self.WorldModel.Parent = self.Instance -- instance always stays in owner's backpack

    return true
end

-- returns true if successful, otherwise false
function Equipment:Drop(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested drop") end

    local takeSuccess = InventoryService:TakeItem(self.Owner, self)
    if not takeSuccess then warn("InventoryService could not take " .. self.Instance.Name) return false end

    if DEBUG then print(self.Owner.Name .. " dropped " .. self.Instance.Name) end

    if self.IsEquipped then self:Unequip(self.Owner) end

    local oldOwner = self.Owner
    self.Owner = nil
    self.Instance:SetAttribute("OwnerID", nil)
    self.PickUpPrompt.Enabled = true

    local modelRoot = self.WorldModel.PrimaryPart
    modelRoot.CanCollide = true
    self.Instance.Parent = workspace
    self.WorldModel.Parent = self.Instance

    modelRoot:SetNetworkOwner(oldOwner)
    task.delay(5, function()
        if modelRoot:GetNetworkOwner() ~= nil then return end
        modelRoot:SetNetworkOwnershipAuto()
    end)

    return true
end

function Equipment:OnPickUpRequested(player: Player, pickingUp: boolean)
    return if pickingUp then
        self:PickUp(player)
    else
        self:Drop(player)
end

function Equipment:OnEquipRequested(player: Player, equipping: boolean)
    return if equipping then
        self:Equip(player)
    else
        self:Unequip(player)
end

function Equipment:Start()
    self.PickUpRequest.OnServerInvoke = function(...)
        return self:OnPickUpRequested(...)
    end

    self.EquipRequest.OnServerInvoke = function(...)
        return self:OnEquipRequested(...)
    end

    Knit.OnStart():andThen(function()
        InventoryService = Knit.GetService("InventoryService")
    end):catch(warn)
end

function Equipment:Stop()
    self._trove:Clean()
end

return Equipment
