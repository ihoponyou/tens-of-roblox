
local DEBUG = false
local EMPTY_CFRAME = CFrame.new()

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

local function isValidSlotType(slot: string)
    return type(slot) == "string" and (slot == "Primary" or slot == "Secondary" or slot == "Tertiary") 
end

function Equipment:Construct()
    self._trove = Trove.new()

    self.IsEquipped = false
    self.Owner = nil
    local folder = ReplicatedStorage.Equipment:FindFirstChild(self.Instance.Name, true)
    self.Config = folder.Configuration:GetAttributes()
    if not isValidSlotType(self.Config.SlotType) then error("Invalid slot type") end 

    self.WorldModel = self.Instance:WaitForChild("WorldModel", 5) or self._trove:Clone(folder.WorldModel)
    self.WorldModel:ScaleTo(self.WorldModel:GetAttribute("WorldScale"))
    print("scaled", self.Instance)
    self.WorldModel.Parent = self.Instance
    self.WorldModel.PrimaryPart.CanCollide = true
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

    local giveSuccess = InventoryService:GiveItem(player, self)
    if not giveSuccess then return false end

    if DEBUG then print(player.Name .. " picked up " .. self.Instance.Name) end

    local character = player.Character
    if not character then error("Cannot rig equipment to owner; no character") end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then error("Cannot rig equipment to character; character missing HumanoidRootPart") end

    local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot rig equipment to character; model missing RootJoint") end

    -- rig equipment to character
    self.WorldModel.Parent = character
    modelRootJoint.Part0 = hrp

    self.Owner = player
    self.Instance:SetAttribute("OwnerID", player.UserId)
    self.Instance.Parent = player.Backpack

    self.WorldModel.PrimaryPart.CanCollide = false

    self.WorldModel.PrimaryPart.RootJoint.C0 = self.WorldModel.PrimaryPart.HolsterC0.Value

    self.PickUpPrompt.Enabled = false
    return true
end

function Equipment:Equip(player: Player): boolean?
    if player ~= self.Owner then error("Non-owner requested equip") end

    self.WorldModel.PrimaryPart.RootJoint.C0 = EMPTY_CFRAME
    -- TODO: play an equip animation
    self.IsEquipped = true -- set this at the end or specified keyframe of animation

    return true
end

function Equipment:Unequip(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested unequip") end

    self.WorldModel.PrimaryPart.RootJoint.C0 = self.WorldModel.PrimaryPart.HolsterC0.Value
    self.IsEquipped = false

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
    local modelRootJoint = modelRoot:FindFirstChild("RootJoint")
    -- TODO: character:StopPlayingAnimations()
    modelRootJoint.Part0 = nil
    self.WorldModel.Parent = self.Instance -- instance always stays in owner's backpack

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
    Knit.OnStart():andThen(function()
        InventoryService = Knit.GetService("InventoryService")
    end):catch(warn)

    self.PickUpRequest.OnServerInvoke = function(...)
        return self:OnPickUpRequested(...)
    end

    self.EquipRequest.OnServerInvoke = function(...)
        return self:OnEquipRequested(...)
    end
end

function Equipment:Stop()
    self._trove:Clean()
end

return Equipment
