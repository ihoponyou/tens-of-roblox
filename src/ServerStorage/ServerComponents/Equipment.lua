local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Comm = require(ReplicatedStorage.Packages.Comm)

local InventoryService = Knit.GetService("InventoryService")

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local AnimationManager = require(ReplicatedStorage.Source.Modules.AnimationManager)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local ModelUtil = require(ReplicatedStorage.Source.Modules.ModelUtil)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local DEBUG = false

-- handles picking up, dropping, equipping and unequipping (including animations and viewmodel)
local Equipment = Component.new({
	Tag = "Equipment",
	Extensions = {
		Logger,
	},
})

function Equipment:Construct()
    self._trove = Trove.new()
    self._serverComm = Comm.ServerComm.new(self.Instance)

	self.Config = EquipmentConfig[self.Instance.Name]
	self.Folder = ReplicatedStorage.Equipment:FindFirstChild(self.Instance.Name)

	-- equip & idle animations are required
	Find.path(self.Folder, "Animations/3P/Equip")
	Find.path(self.Folder, "Animations/3P/Idle")
	
    if not self.Config.Type then
        error(self.Instance.Name..": nil equipment type")
    end
    CollectionService:AddTag(self.Instance, self.Config.Type)

	if not self.Config.SlotType then
		error(self.Instance.Name..": nil slot type")
	end
	local worldScale = self.Config.Scales.World
	if not worldScale then
		error(self.Instance.Name .. ": nil world scale")
	end

	self.WorldModel = self._trove:Clone(self.Folder.WorldModel) :: Model
	if not self.WorldModel.PrimaryPart then
		error(self.Instance.Name .. ": nil WorldModel.PrimaryPart")
	end
	self.WorldModel.PrimaryPart.CanCollide = true
	ModelUtil.SetModelCollisionGroup(self.WorldModel, "Equipment")
	self.WorldModel:ScaleTo(worldScale)
	self.WorldModel.Parent = self.Instance

	self.IsEquipped = false
	self.Equipped = Signal.new()
	self.EquipRequest = self._serverComm:CreateSignal("EquipRequest")
	self.EquipRequest:Connect(function(player, equipping)
		if equipping then
			self:Equip(player)
		else
			self:Unequip(player)
		end
	end)

	self.IsPickedUp = false
	self.PickedUp = Signal.new()
	self.PickUpRequest = self._serverComm:CreateSignal("PickUpRequest")
	self.PickUpRequest:Connect(function(player, pickingUp)
		local success = InventoryService:PickUp(player, self, pickingUp)
		if not success then
			return
		end
		if pickingUp then
			self:_onPickUp(player)
		else
			self:_onDrop(player)
		end
	end)

	self.UseRequest = self._serverComm:CreateSignal("UseRequest")
	self.UseRequest:Connect(function(player, ...)
		self:_handleUse(player, ...)
	end)
end

-- returns true if successful, otherwise false
function Equipment:_onPickUp(player: Player): boolean
	if self.Owner ~= nil then
		warn(player.Name .. " tried to pick up already picked up equipment")
		return false
	end

	local character = player.Character
	if not character then
		error("Cannot rig equipment to owner; no character")
	end

	local holsterLimb = character:FindFirstChild(self.Config.HolsterLimb)
	if not holsterLimb then
		error("Cannot rig equipment to character; character missing holster's limb")
	end

	local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
	if not modelRootJoint then
		error("Cannot rig equipment to character; model missing RootJoint")
	end

	ModelUtil.SetModelCanCollide(self.WorldModel, false)

	-- rig equipment to character
	self.WorldModel.Parent = character
	modelRootJoint.Part0 = holsterLimb
	modelRootJoint.C0 = modelRootJoint:GetAttribute("HolsterC0")

	self.Owner = player
	self.Character = character
	self.Instance:SetAttribute("OwnerID", player.UserId)
	self.Instance.Parent = player:WaitForChild("Inventory")

    self._deathConn = self._trove:Connect(self.Owner.CharacterRemoving, function(_)
		self:_onDeath()
	end)
    
    -- print(player.Name .. " picked up " .. self.Instance.Name)

	self.IsPickedUp = true
	self.PickedUp:Fire(true)
    self.PickUpRequest:Fire(self.Owner, true)
	return true
end

function Equipment:Equip(player: Player)
	if player ~= self.Owner then
		error("Non-owner requested equip")
		return
	end
	if self.IsEquipped then
		error("already equipped")
		return
	end

	local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
	if not modelRootJoint then
		error("Cannot rig equipment to character; model missing RootJoint")
	end

	local equipLimb = self.Character:FindFirstChild("Right Arm")
	if not equipLimb then
		error("Cannot rig equipment to character; character missing limb to equip")
	end

	-- rig equipment to character
	modelRootJoint.C0 = modelRootJoint:GetAttribute("WorldEquippedC0")
	modelRootJoint.Part0 = equipLimb

	self.AnimationManager = AnimationManager.new(Find.path(self.Character, "Humanoid/Animator"))
	self.AnimationManager:LoadAnimations(Find.path(self.Folder, "Animations/3P"):GetChildren())
	self.AnimationManager:PlayAnimation("Idle", 0)
	self.AnimationManager:PlayAnimation("Equip", 0)

	self.IsEquipped = true
	self.Equipped:Fire(true)
	self.EquipRequest:Fire(self.Owner, true)
	return
end

function Equipment:Unequip(player: Player)
	if self.Owner ~= player then
		error("Non-owner requested unequip")
        return
	end

    if not self.IsEquipped then
        error("already unequipped")
        return
    end

	local holsterLimb = self.Character:FindFirstChild(self.Config.HolsterLimb)
	if not holsterLimb then
		error("Cannot rig equipment to character; character missing holster's limb")
	end

	local modelRootJoint: Motor6D = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
	if not modelRootJoint then
		error("Cannot unrig equipment from character; equipment missing RootJoint")
	end

	self.AnimationManager:StopPlayingAnimations(0)
	modelRootJoint.C0 = modelRootJoint:GetAttribute("HolsterC0")
	modelRootJoint.Part0 = holsterLimb

	self.IsEquipped = false
	self.Equipped:Fire(false)
	self.EquipRequest:Fire(self.Owner, false)
	return
end

function Equipment:_onDeath()
	if self.Owner.Character:GetPivot().Position.Y < workspace.FallenPartsDestroyHeight then
		InventoryService:PickUp(self.Owner, self, false)
		self.Instance:Destroy()
	else
		InventoryService:PickUp(self.Owner, self, false)
		self:_onDrop(self.Owner)
	end
end

function Equipment:_onDrop(player: Player)
	if self.Owner ~= player then
		error("Non-owner requested drop")
        return
	end

	if self.IsEquipped then
		self:Unequip(self.Owner)
	end

	-- print(self.Owner.Name .. " dropped " .. self.Instance.Name)

	local oldOwner = self.Owner
	self.Owner = nil
	self.Character = nil
	self.Instance:SetAttribute("OwnerID", nil)
    
    self._trove:Remove(self._deathConn)
    self._deathConn:Disconnect()
	self._deathConn = nil

	self.Instance.Parent = workspace
	self.WorldModel.Parent = self.Instance

	ModelUtil.SetModelCanCollide(self.WorldModel, true)

	local modelRoot: BasePart = self.WorldModel.PrimaryPart
	local modelRootJoint: Motor6D = Find.path(modelRoot, "RootJoint")
	modelRootJoint.Part0 = nil

	-- task.spawn(function()
	-- 	modelRoot:SetNetworkOwner(oldOwner)
	-- 	repeat
	-- 		task.wait(5)
	-- 	until modelRoot:FindFirstAncestorOfClass("Workspace") ~= nil and not modelRoot:CanSetNetworkOwnership()
	-- 	modelRoot:SetNetworkOwnershipAuto()
	-- end)

	self.IsPickedUp = false
    self.PickUpRequest:Fire(oldOwner, false)
	self.PickedUp:Fire(false)
	return true
end

function Equipment.Use()
	warn("equipment use not overriden")
end

function Equipment:_handleUse(player, ...: any)
	if self.Owner ~= player then
		warn("Non-owner attempted use")
		return
	end
	if not self.IsEquipped then
		warn("Cannot use unless equipped")
		return
	end

	-- print(player, ...)

	self.Use(player, ...)

	-- print(self.Instance.Name, "was used")
end

function Equipment:Stop()
    self.Owner = nil
	self._trove:Clean()
end

return Equipment
