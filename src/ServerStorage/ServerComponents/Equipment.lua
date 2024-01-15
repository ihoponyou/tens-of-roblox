
-- allows an item to be picked up, dropped, equipped, and unequipped

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Comm = require(ReplicatedStorage.Packages.Comm)
local Signal = require(ReplicatedStorage.Packages.Signal)

local InventoryService = Knit.GetService("InventoryService")

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local AnimationManager = require(ReplicatedStorage.Source.Modules.AnimationManager)
local ModelUtil = require(ReplicatedStorage.Source.Modules.ModelUtil)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local Equipment = Component.new({
	Tag = "Equipment",
	Extensions = {
		Logger
	}
})

function Equipment:Construct()
	self._trove = Trove.new()
	self._serverComm = self._trove:Construct(Comm.ServerComm, self.Instance, "Equipment")

	self.Config = EquipmentConfig[self.Instance.Name]
    self.Folder = ReplicatedStorage.Equipment[self.Instance.Name]

	self.WorldModel = self._trove:Clone(ReplicatedStorage.Equipment[self.Instance.Name].WorldModel)
	self.WorldModel.Parent = self.Instance
	-- destroy component if worldmodel is destroyed or drop if character is destroyed
	self._trove:Connect(self.WorldModel.AncestryChanged, function(child, parent)
		-- only consider when things are destroyed
		if parent ~= nil then return end

		if child ~= self.WorldModel then
			-- owner died/left
			self:Drop(self.Owner)
		else
			-- worldmodel DESTROYED!!!!!
			if self.Owner ~= nil then
				InventoryService:RemoveEquipment(self.Owner, self)
			end
			self.Instance:Destroy()
		end
	end)

	-- PICK UP / DROP ----------------------------------------------------
	self.IsPickedUp = self._serverComm:CreateProperty("IsPickedUp", false)

	self.PickUpPrompt = self._trove:Construct(Instance, "ProximityPrompt") :: ProximityPrompt
	self.PickUpPrompt.ClickablePrompt = false
	self.PickUpPrompt.ActionText = "Pick Up"
	self.PickUpPrompt.ObjectText = self.Instance.Name
	self.PickUpPrompt.Parent = self.WorldModel
	self.PickUpPrompt.Triggered:Connect(function(playerWhoTriggered)
		self:PickUp(playerWhoTriggered)
	end)

	self.DropRequest = self._serverComm:CreateSignal("DropRequest")

	self._trove:Connect(self.DropRequest, function(player)
		self:Drop(player)
	end)

	-- EQUIP / UNEQUIP ----------------------------------------------------
	self.IsEquipped = self._serverComm:CreateProperty("IsEquipped", false)
	self.Equipped = Signal.new()

	self.EquipRequest = self._serverComm:CreateSignal("EquipRequest")
	self._trove:Connect(self.EquipRequest, function(player: Player)
		self:Equip(player)
	end)

	self.UnequipRequest = self._serverComm:CreateSignal("UnequipRequest")
	self._trove:Connect(self.UnequipRequest, function(player: Player)
		self:Unequip(player)
	end)
end

function Equipment:Stop()
	self._trove:Destroy()
end

-- MISC ----------------------------------------------------------------

function Equipment:GetRootJoint(): Motor6D
	local rootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
	if not rootJoint then
		warn(self.Instance.Name..": RootJoint has been presumed dead")
		rootJoint = self:_newRootJoint()
	end
	return rootJoint
end

function Equipment:_newRootJoint(): Motor6D
	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Parent = self.WorldModel.PrimaryPart
	rootJoint.Part1 = self.WorldModel.PrimaryPart
	return rootJoint
end

function Equipment:RigTo(character: Model, limb: string, c0: CFrame?)
	if not character then error("nil character") end

	local rootJoint = self:GetRootJoint()

	local limbPart = character:FindFirstChild(limb)
	if not limbPart then error("nil " .. limb) end

	self.WorldModel.Parent = character
	rootJoint.Part0 = limbPart
	if c0 ~= nil then
		rootJoint.C0 = c0
	end
end

function Equipment:Unrig()
	local rootJoint = self:GetRootJoint()

	self.WorldModel.Parent = self.Instance
	rootJoint.Part0 = nil
end

function Equipment:_setEquipped(isEquipped: boolean)
	self.IsEquipped:Set(isEquipped)
	self.Equipped:Fire(isEquipped)
end

-- PICK UP / DROP ----------------------------------------------------

function Equipment:PickUp(player: Player)
	if self.Owner ~= nil then return end

	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local state: Enum.HumanoidStateType = humanoid:GetState()
	if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Dead then
		return
	end

	local success = InventoryService:AddEquipment(player, self)
	if not success then return end

	self.Owner = player
	self.Instance:SetAttribute("OwnerID", player.UserId)

	self._deathConn = self._trove:Connect(humanoid.Died, function()
		self:Drop(self.Owner)
	end)

	ModelUtil.SetPartProperty(self.WorldModel, "CanCollide", false)
	self:RigTo(player.Character, self.Config.HolsterLimb, self.Config.RootJointC0.Holstered)

	self.PickUpPrompt.Enabled = false
	self.IsPickedUp:Set(true)
end

function Equipment:Drop(player: Player)
	if self.Owner ~= player then return end
	local success = InventoryService:RemoveEquipment(self.Owner, self)
	if not success then return end

	if self.IsEquipped:Get() then
		-- print("forced unequip")
		self:Unequip(self.Owner)
	end

	self.Owner = nil
	self.Instance:SetAttribute("OwnerID", nil)

	self._trove:Remove(self._deathConn)
	self._deathConn:Disconnect()
	self._deathConn = nil

	self:Unrig()
	ModelUtil.SetPartProperty(self.WorldModel, "CanCollide", true)

	self.PickUpPrompt.Enabled = true
	self.IsPickedUp:Set(false)
end

-- EQUIP / UNEQUIP ----------------------------------------------------

function Equipment:Equip(player: Player)
	if self.Owner ~= player then return end

	self:RigTo(self.Owner.Character, "Right Arm", self.Config.RootJointC0.Equipped.World)

	local animator = self.Owner.Character:WaitForChild("Humanoid"):WaitForChild("Animator")
    self.AnimationManager = AnimationManager.new(animator)
    self.AnimationManager:LoadAnimations(self.Folder.Animations["3P"]:GetChildren())
    self.AnimationManager:PlayAnimation("Idle", 0)
    self.AnimationManager:PlayAnimation("Equip", 0)

	self:_setEquipped(true)
end

function Equipment:Unequip(player: Player)
	if self.Owner ~= player then return end

	self:RigTo(self.Owner.Character, self.Config.HolsterLimb, self.Config.RootJointC0.Holstered)

	if self.AnimationManager then
        self.AnimationManager:Destroy()
        self.AnimationManager = nil
        -- print("KILL")
    end

	self:_setEquipped(false)
end

return Equipment
