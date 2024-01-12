local DEBUG = false

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CameraController
local ViewmodelController

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local PromptGui = require(ReplicatedStorage.Source.UIElements.PromptGui)

local EquipmentClient = Component.new({
	Tag = "Equipment",
	Extensions = {
		Logger,
	},
})

function EquipmentClient:Construct()
    self.Instance:SetAttribute("Log", true)
	self.Config = EquipmentConfig[self.Instance.Name]
	self.Folder = Find.path(ReplicatedStorage, "Equipment/" .. self.Instance.Name)

    self._clientComm = Comm.ClientComm.new(self.Instance, true)

	if not self.Config.ThirdPersonOnly then
		Find.path(self.Folder, "Animations/1P/Equip")
		Find.path(self.Folder, "Animations/1P/Idle")
	end

	self._trove = Trove.new()

	self._isEquipped = false
	self.Equipped = Signal.new()

	self.EquipRequest = self._clientComm:GetSignal("EquipRequest")
	self.PickUpRequest = self._clientComm:GetSignal("PickUpRequest")
	self.UseRequest = self._clientComm:GetSignal("UseRequest")

	self.WorldModel = self.Instance:WaitForChild("WorldModel")
	local container = Instance.new("Folder")
	container.Name = "Interface"
	container.Parent = self.WorldModel
	self._reactRoot = ReactRoblox.createRoot(container)

	self.PickUpPrompt = self._trove:Add(Instance.new("ProximityPrompt")) :: ProximityPrompt
	self.PickUpPrompt.Parent = self.WorldModel
	self.PickUpPrompt.RequiresLineOfSight = false

    -- self._trove:Connect(self.PickUpPrompt.PromptShown, function()
	-- 	print'shown'
	-- 	self._reactRoot:render({
	-- 		EquipPrompt = React.createElement(PromptGui, {
	-- 			equipmentName = self.Instance.Name,
	-- 			adornee = self.WorldModel,
	-- 		}),
	-- 	})
	-- end)
	-- self._trove:Connect(self.PickUpPrompt.PromptHidden, function()
	-- 	print'hidden'
	-- 	self._reactRoot:render({})
	-- end)
    self.PickUpPrompt.Triggered:Connect(function()
		self.PickUpRequest:Fire(true)
	end)

	self._riggedToViewmodel = false
end


function EquipmentClient:Start()
    Knit.OnStart():andThen(function()
        CameraController = Knit.GetController("CameraController")
        ViewmodelController = Knit.GetController("ViewmodelController")
    end):catch(warn):await()

	self._trove:Connect(CameraController.FirstPersonChanged, function(inFirstPerson: boolean)
		if not self.IsEquipped then
			return
		end
		if inFirstPerson then
			self:_rigToViewmodel()
		else
			self:_rigToCharacter()
		end
	end)

    self.EquipRequest:Connect(function(equipped)
		if equipped then
			self:_onEquipped()
		else
			self:_onUnequipped()
		end
    end)
    self.PickUpRequest:Connect(function(pickedUp)
        if pickedUp then
            self:_onPickUp()
        else
            self:_onDrop()
        end
    end)
end

function EquipmentClient:Stop()
	self._trove:Clean()
end

function EquipmentClient:_rigToViewmodel()
	local viewmodel = ViewmodelController.Viewmodel
	if not viewmodel then
		error("Cannot rig equipment to viewmodel; no viewmodel")
	end

	local viewmodelAnimations = Find.path(self.Folder, "Animations/1P")

	-- rig to viewmodel
	viewmodel:HoldModel(self.WorldModel)

	local animationManager = viewmodel.AnimationManager
	animationManager:LoadAnimations(viewmodelAnimations:GetChildren())
	animationManager:PlayAnimation("Idle", 0)
	self._riggedToViewmodel = true
end

function EquipmentClient:_rigToCharacter()
	if not self._riggedToViewmodel then
		return
	end

	self.WorldModel:ScaleTo(self.WorldModel:GetAttribute("WorldScale"))

	local rootJoint = self.WorldModel.PrimaryPart.RootJoint

	ViewmodelController.Viewmodel:ReleaseModel(self.WorldModel, self.Character)
	rootJoint.Part0 = self.Character["Right Arm"]
	rootJoint.C0 = rootJoint:GetAttribute("WorldEquippedC0")
end

function EquipmentClient:_onPickUp()
    print('picked up')
    self.PickUpPrompt.Enabled = false

    ContextActionService:BindAction("equip"..self.Instance.Name, function(_, uis, _)
        if uis ~= Enum.UserInputState.Begin then return end
        self._isEquipped = not self._isEquipped
        self.EquipRequest:Fire(self._isEquipped)
    end, false, Enum.KeyCode.One)

    ContextActionService:BindAction("drop"..self.Instance.Name, function(_, uis, _)
        if uis ~= Enum.UserInputState.Begin then return end
        self.PickUpRequest:Fire(false)
    end, false, Enum.KeyCode.G)
end

function EquipmentClient:_onEquipped()
	self.Character = Players.LocalPlayer.Character

	CameraController.ForceShiftLock = true

	if self.Config.ThirdPersonOnly then
		self:_rigToCharacter()
		-- print("this thing is 3p only!!!")
		CameraController.AllowFirstPerson = false
	elseif CameraController.InFirstPerson then
		self:_rigToViewmodel()
		ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Equip", 0)
	end
	
	ContextActionService:BindAction("use"..self.Instance.Name, function(_, uis, _)
        if uis ~= Enum.UserInputState.Begin then return end
        self.UseRequest:Fire()
    end, false, Enum.UserInputType.MouseButton1)

	self.Equipped:Fire(true)
	self._isEquipped = true
end

function EquipmentClient:_onUnequipped()
	ContextActionService:UnbindAction("use"..self.Instance.Name)

	CameraController.ForceShiftLock = false

	if self.Config.ThirdPersonOnly then
		-- print("that thing was 3p only!!!")
		CameraController.AllowFirstPerson = true
	elseif CameraController.InFirstPerson then
		local viewmodel = ViewmodelController.Viewmodel
		if not viewmodel then
			error("Cannot unrig equipment from viewmodel; no viewmodel")
		end

		viewmodel:ReleaseModel(self.WorldModel, self.Instance) -- instance always stays in owner's backpack
	end

	self.Equipped:Fire(false)
	self._isEquipped = false
end

function EquipmentClient:_onDrop()
    
	ContextActionService:UnbindAction("equip"..self.Instance.Name)
	ContextActionService:UnbindAction("drop"..self.Instance.Name)

	if self._isEquipped then
		self:_onUnequipped()
	end

    self.PickUpPrompt.Enabled = true

	-- unrig from viewmodel and drop it
	self.Instance.Parent = workspace
	self.WorldModel.Parent = self.Instance

	local destinationCFrame
	if CameraController.InFirstPerson then
		destinationCFrame = workspace.CurrentCamera.CFrame
	else
		destinationCFrame = Players.LocalPlayer.Character.PrimaryPart.CFrame -- TODO: fix this
	end
	self.WorldModel:PivotTo(destinationCFrame + destinationCFrame.LookVector)
	self.WorldModel.PrimaryPart.AssemblyLinearVelocity = (workspace.CurrentCamera.CFrame.LookVector * 30)

	-- remove from inventory GUI
end

return EquipmentClient
