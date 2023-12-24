
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Configs = require(ReplicatedStorage.Source.EquipmentConfigs)
local AnimationManager = require(ReplicatedStorage.Source.Modules.AnimationManager)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local DEBUG = false

-- handles picking up, dropping, equipping and unequipping (including animations and viewmodel)
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
    self._folder = ReplicatedStorage.Equipment:FindFirstChild(self.Instance.Name)

    -- animations are required
    Find.path(self._folder, "Animations/3P/Equip")
    Find.path(self._folder, "Animations/3P/Idle")

    self._trove = Trove.new()

    self.IsEquipped = false
    self.Owner = nil
    self.Config = Configs[self.Instance.Name]

    if not isValidSlotType(self.Config.SlotType) then error("Invalid slot type") end

    local model = self.Instance:FindFirstChild("WorldModel")
    if model then model:Destroy() end
    self.WorldModel = self._trove:Clone(self._folder.WorldModel)
    self.WorldModel.Parent = self.Instance

    for _, part: BasePart in self.WorldModel:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CollisionGroup = "Equipment"
    end

    if not self.WorldModel.PrimaryPart then
        warn(self.Instance.Name .. " model has nil PrimaryPart")
        self.WorldModel.PrimaryPart = self.WorldModel:FindFirstChild("Handle") or self.WorldModel:GetChildren()[1] -- probably unsafe
    end
    self.WorldModel.PrimaryPart.CanCollide = true
    self.WorldModel.PrimaryPart.CollisionGroup = "Equipment"

    local worldScale = self.WorldModel:GetAttribute("WorldScale")
    if not worldScale then
        warn(self.Instance.Name .. " model does not have a set world scale")
        worldScale = 1
    end
    self.WorldModel:ScaleTo(worldScale)

    -- will only be active when there is an owner
    self.AnimationManager = nil

    self.PickUpRequest = self._trove:Add(Instance.new("RemoteFunction"))
    self.PickUpRequest.Name = "PickUpRequest"
    self.PickUpRequest.Parent = self.Instance

    self.EquipRequest = self._trove:Add(Instance.new("RemoteFunction"))
    self.EquipRequest.Name = "EquipRequest"
    self.EquipRequest.Parent = self.Instance
    self.Equipped = Signal.new()

    self.PickUpPrompt = self._trove:Add(Instance.new("ProximityPrompt"))
    self.PickUpPrompt.Name = "PickUpPrompt"
    self.PickUpPrompt.Parent = self.WorldModel
    self.PickUpPrompt.Style = Enum.ProximityPromptStyle.Custom

    self.UseEvent = self._trove:Add(Instance.new("RemoteEvent"))
    self.UseEvent.Name = "UseEvent"
    self.UseEvent.Parent = self.Instance
end

-- returns true if successful, otherwise false
function Equipment:PickUp(player: Player): boolean
    if self.Owner ~= nil then warn(player.Name .. " tried to pick up already picked up equipment") return false end

    local giveSuccess = InventoryService:GiveItem(player, self)
    if not giveSuccess then return false end

    if DEBUG then print(player.Name .. " picked up " .. self.Instance.Name) end

    local character = player.Character
    if not character then error("Cannot rig equipment to owner; no character") end

    -- TODO: check for proper holster limb
    local holsterLimb = character:FindFirstChild("Torso")
    if not holsterLimb then error("Cannot rig equipment to character; character missing holster's limb") end

    local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot rig equipment to character; model missing RootJoint") end

    for _, part: BasePart in self.WorldModel:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CanCollide = false
    end

    -- rig equipment to character
    self.WorldModel.Parent = character
    modelRootJoint.Part0 = holsterLimb
    modelRootJoint.C0 = modelRootJoint:GetAttribute("HolsterC0")

    self.Owner = player
    self.Character = character
    self.Instance:SetAttribute("OwnerID", player.UserId)
    self.Instance.Parent = player.Backpack

    self.WorldModel.PrimaryPart.CanCollide = false

    self.PickUpPrompt.Enabled = false
    return true
end

function Equipment:Equip(player: Player): boolean?
    if player ~= self.Owner then error("Non-owner requested equip") end
    if self.IsEquipped then error("already equipped") end

    local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot rig equipment to character; model missing RootJoint") end

    local equipLimb = self.Character:FindFirstChild("Right Arm")
    if not equipLimb then error("Cannot rig equipment to character; character missing limb to equip") end

    -- rig equipment to character
    modelRootJoint.C0 = modelRootJoint:GetAttribute("WorldEquippedC0")
    modelRootJoint.Part0 = equipLimb

    self.AnimationManager = AnimationManager.new(Find.path(self.Character, "Humanoid/Animator"))
    self.AnimationManager:LoadAnimations(Find.path(self._folder, "Animations/3P"):GetChildren())
    self.AnimationManager:PlayAnimation("Idle", 0)

    local equipAnimation = self.AnimationManager:GetAnimation("Equip")
    equipAnimation:Play(0)
    equipAnimation.Stopped:Connect(function()

    end)
    equipAnimation.Stopped:Wait()

    if equipAnimation.TimePosition ~= equipAnimation.Length then
        print('interrupted')
        return false
    else
        print'completed'
        self.IsEquipped = true
        self.Equipped:Fire(true)
        return true
    end
end

function Equipment:Unequip(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested unequip") end
    if not self.IsEquipped then error("not equipped") end

    local torso = self.Character:FindFirstChild("Torso")
    if not torso then error("Cannot rig equipment to character; character missing torso") end

    local modelRootJoint: Motor6D = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot unrig equipment from character; equipment missing RootJoint") end

    self.AnimationManager:StopPlayingAnimations(0)
    modelRootJoint.C0 = modelRootJoint:GetAttribute("HolsterC0")
    modelRootJoint.Part0 = torso

    self.IsEquipped = false
    self.Equipped:Fire(false)
    return true
end

-- returns true if successful, otherwise false
function Equipment:Drop(player: Player): boolean?
    if self.Owner ~= player then error("Non-owner requested drop") end
    if self.IsEquipped then self:Unequip(self.Owner) end

    local takeSuccess = InventoryService:TakeItem(self.Owner, self)
    if not takeSuccess then warn("InventoryService could not take " .. self.Instance.Name) return false end

    if DEBUG then print(self.Owner.Name .. " dropped " .. self.Instance.Name) end

    self.Owner = nil
    self.Character = nil
    self.Instance:SetAttribute("OwnerID", nil)
    self.PickUpPrompt.Enabled = true

    for _, part: BasePart in self.WorldModel:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CanCollide = true
    end

    local modelRoot: BasePart = self.WorldModel.PrimaryPart
    local modelRootJoint: Motor6D = Find.path(modelRoot, "RootJoint")
    modelRootJoint.Part0 = nil

    self.Instance.Parent = workspace
    self.WorldModel.Parent = self.Instance

    return true
end

-- meant to be overriden; basically an abstract method
function Equipment.Use(_: Player, _: any)
    warn("equipment use not overriden")
end

function Equipment:_handleUse(player, ...: any)
    local verbose = false
    if self.Owner ~= player then
        if verbose then warn("Non-owner attempted use") end
        return
    end
    if not self.IsEquipped then
        if verbose then warn("Cannot use unless equipped") end
        return
    end

    self.Use(player, ...)

    -- print(self.Instance.Name, "was used")
end

function Equipment:Start()
    Knit.OnStart():andThen(function()
        InventoryService = Knit.GetService("InventoryService")
    end):catch(warn)

    self.PickUpRequest.OnServerInvoke = function(player, pickingUp)
        return if pickingUp then
                self:PickUp(player)
            else
                self:Drop(player)
    end

    self.EquipRequest.OnServerInvoke = function(player, equipping)
        return if equipping then
                self:Equip(player)
            else
                self:Unequip(player)
    end

    self._trove:Connect(self.UseEvent.OnServerEvent, function(...: any)
        self:_handleUse(...)
    end)
end

function Equipment:Stop()
    self._trove:Clean()
end

return Equipment
