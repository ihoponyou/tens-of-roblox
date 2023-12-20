
local DEBUG = false
local EMPTY_CFRAME = CFrame.new()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

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

    local model = self.Instance:FindFirstChild("WorldModel")
    if model then model:Destroy() end
    self.WorldModel = self._trove:Clone(folder.WorldModel)
    
    local worldScale = self.WorldModel:GetAttribute("WorldScale")
    if not worldScale then
        warn(self.Instance.Name .. " model does not have a set world scale")
        worldScale = 1
    end
    self.WorldModel:ScaleTo(worldScale)

    self.WorldModel.Parent = self.Instance
    if not self.WorldModel.PrimaryPart then
        warn(self.Instance.Name .. " model has nil PrimaryPart")
        self.WorldModel.PrimaryPart = self.WorldModel:FindFirstChild("Handle") or self.WorldModel:GetChildren()[1]
    end
    self.WorldModel.PrimaryPart.CanCollide = true
    self.WorldModel.PrimaryPart.CollisionGroup = "Equipment"

    self.PickUpRequest = self._trove:Add(Instance.new("RemoteEvent"))
    self.PickUpRequest.Name = "PickUp"
    self.PickUpRequest.Parent = self.Instance

    self.EquipRequest = self._trove:Add(Instance.new("RemoteEvent"))
    self.EquipRequest.Name = "Equip"
    self.EquipRequest.Parent = self.Instance

    self.IsUseKeyDown = false

    local defaultUse: (any) -> nil = function(...: any)
        warn("use functionality not overriden")
    end
    -- meant to be overriden, not sure how to properly do this
    self.useFunctioniality = defaultUse

    self.UseRequest = self._trove:Add(Instance.new("RemoteEvent"))
    self.UseRequest.Name = "Use"
    self.UseRequest.Parent = self.Instance

    self.AlternateUseRequest = self._trove:Add(Instance.new("RemoteEvent"))
    self.AlternateUseRequest.Name = "AltUse"
    self.AlternateUseRequest.Parent = self.Instance

    self.PickUpPrompt = self._trove:Add(Instance.new("ProximityPrompt"))
    self.PickUpPrompt.Name = "PickUpPrompt"
    self.PickUpPrompt.Parent = self.WorldModel
    self.PickUpPrompt.Style = Enum.ProximityPromptStyle.Custom

    self.PickedUp = Signal.new()
    self.Equipped = Signal.new()
    self.Used = Signal.new()
    self.AltUsed = Signal.new()
end

function Equipment:PickUp(player: Player)
    if self.Owner ~= nil then warn(player.Name .. " tried to pick up already picked up equipment") end

    local giveSuccess = InventoryService:GiveItem(player, self)
    if not giveSuccess then return end

    if DEBUG then print(player.Name .. " picked up " .. self.Instance.Name) end

    local character = player.Character
    if not character then error("Cannot rig equipment to owner; no character") end

    local torso = character:FindFirstChild("Torso")
    if not torso then error("Cannot rig equipment to character; character missing Torso") end

    local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot rig equipment to character; model missing RootJoint") end

    -- rig equipment to character (holstered)
    self.WorldModel.PrimaryPart.Anchored = false
    self.WorldModel.Parent = character
    modelRootJoint.Part0 = torso
    modelRootJoint.C0 = self.WorldModel.PrimaryPart.HolsterC0.Value
    self.WorldModel.PrimaryPart.CanCollide = false

    self.Owner = player
    self.Instance:SetAttribute("OwnerID", player.UserId)
    self.Instance.Parent = player.Backpack

    self.PickUpPrompt.Enabled = false

    -- "player just picked me up"
    self.PickedUp:Fire(player, true)
    self.PickUpRequest:FireClient(player, true)
end

function Equipment:Equip(player: Player)
    if player ~= self.Owner then error("Non-owner requested equip") end

    -- revert from holstered C0
    self.WorldModel.PrimaryPart.RootJoint.C0 = EMPTY_CFRAME
    -- TODO: play a 3P equip animation
    self.IsEquipped = true -- set this at the end or specified keyframe of animation

    -- "player just picked me up"
    self.Equipped:Fire(player, true)
    self.EquipRequest:FireClient(player, true)
end

function Equipment:Use(player: Player, ...: any): boolean?
    if self.Owner ~= player then error("Non-owner requested use") end

    -- TODO: sanity checks
    -- self.useFunctioniality(...)

    self.Used:Fire()
end

function Equipment:AlternateUse(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested alt. use") end

    -- TODO: sanity checks

    self.AltUsed:Fire()
end

function Equipment:Unequip(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested unequip") end

    self.WorldModel.PrimaryPart.RootJoint.C0 = self.WorldModel.PrimaryPart.HolsterC0.Value
    self.IsEquipped = false

    self.Equipped:Fire(player, false)
    self.EquipRequest:FireClient(player, false)
end

-- returns true if successful, otherwise false
function Equipment:Drop(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested drop") end

    local takeSuccess = InventoryService:TakeItem(self.Owner, self)
    if not takeSuccess then error("InventoryService could not take " .. self.Instance.Name) end

    if DEBUG then print(self.Owner.Name .. " dropped " .. self.Instance.Name) end

    if self.IsEquipped then self:Unequip(self.Owner) end

    local oldOwner = self.Owner
    self.Owner = nil
    self.Instance:SetAttribute("OwnerID", nil)
    self.PickUpPrompt.Enabled = true

    -- unrig from character
    local modelRoot = self.WorldModel.PrimaryPart
    local modelRootJoint = modelRoot:FindFirstChild("RootJoint")
    -- TODO: character:StopPlayingAnimations()
    modelRootJoint.Part0 = nil
    modelRootJoint.C0 = EMPTY_CFRAME
    self.WorldModel.Parent = self.Instance -- instance always stays in owner's backpack

    -- allow model to fall
    modelRoot.CanCollide = true
    self.Instance.Parent = workspace
    self.WorldModel.Parent = self.Instance

    -- modelRoot:SetNetworkOwner(oldOwner)
    -- -- task.delay(5, function()
    --     modelRoot.Anchored = true
    --     if modelRoot:GetNetworkOwner() ~= nil then return end
    --     modelRoot:SetNetworkOwnershipAuto()
    -- -- end)

    self.PickedUp:Fire(player, false)
    self.PickUpRequest:FireClient(player, false)
end

function Equipment:Start()
    Knit.OnStart():andThen(function()
        InventoryService = Knit.GetService("InventoryService")
    end):catch(warn)

    self._trove:Connect(self.PickUpPrompt.Triggered, function(player: Player)
        self:PickUp(player)
    end)
    self._trove:Connect(self.PickUpRequest.OnServerEvent, function(player, pickingUp: boolean)
        if pickingUp then
            self:PickUp(player)
        else
            self:Drop(player)
        end
    end)

    self._trove:Connect(self.UseRequest.OnServerEvent, function(...)
        self:Use(...)
    end)

    self._trove:Connect(self.AlternateUseRequest.OnServerEvent, function(...)
        self:AlternateUse(...)
    end)

    self._trove:Connect(self.EquipRequest.OnServerEvent, function(player, equipping)
        if equipping then
            self:Equip(player)
        else
            self:Unequip(player)
        end
    end)
end

function Equipment:Stop()
    self._trove:Clean()
end

return Equipment
