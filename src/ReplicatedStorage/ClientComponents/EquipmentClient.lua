
-- allows clients to request interaction with equipment (server)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local CameraController, ViewmodelController

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local ModelUtil = require(ReplicatedStorage.Source.Modules.ModelUtil)

local EquipmentClient = Component.new({
    Tag = "Equipment";
    Extensions = {
        LocalPlayerExclusive,
        Logger
    }
})

function EquipmentClient:Construct()
    self._trove = Trove.new()
    self._clientComm = self._trove:Construct(Comm.ClientComm, self.Instance, true, "Equipment")

    for k, v in EquipmentConfig[self.Instance.Name] do
        self[k] = v
    end

    self.Folder = ReplicatedStorage.Equipment[self.Instance.Name]

    self.WorldModel = self.Instance:WaitForChild("WorldModel")

    self.IsPickedUp = self._clientComm:GetProperty("IsPickedUp")
    self.DropRequest = self._clientComm:GetSignal("DropRequest")

    self.IsEquipped = self._clientComm:GetProperty("IsEquipped")
    self.EquipRequest = self._clientComm:GetSignal("EquipRequest")
    self.UnequipRequest = self._clientComm:GetSignal("UnequipRequest")
end

function EquipmentClient:Start()
    Knit.OnStart():andThen(function()
        CameraController = Knit.GetController("CameraController")
        ViewmodelController = Knit.GetController("ViewmodelController")
    end, warn):await()
end

function EquipmentClient:_setupForLocalPlayer()
    self._localPlayerTrove = self._trove:Extend()

    self._localPlayerTrove:Add(self.IsEquipped:Observe(function(value)
        if value then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end))

    self._localPlayerTrove:Connect(CameraController.PointOfViewChanged, function(inFirstPerson: boolean)
        if not self.IsEquipped:Get() then return end
        ViewmodelController.Viewmodel:ToggleVisibility(inFirstPerson)
        if inFirstPerson then
            self:_rigToViewmodel()
        else
            self:_rigToCharacter(false)
        end
    end)
end

function EquipmentClient:_cleanUpForLocalPlayer()
    CameraController:SetAllowFirstPerson(true)

    if self._localPlayerTrove then
        self._localPlayerTrove:Destroy()
    end
end

function EquipmentClient:_getRootJoint(): Motor6D
    local rootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
	if not rootJoint then error(self.Instance.Name..": RootJoint has been found dead") end
    return rootJoint
end

function EquipmentClient:RigTo(character: Model, limb: string, c0: CFrame?)
	if not character then error("nil character") end

	local rootJoint = self:_getRootJoint()

	local limbPart = character:FindFirstChild(limb)
	if not limbPart then error("nil " .. limb) end

	self.WorldModel.Parent = character
	rootJoint.Part0 = limbPart
    if c0 ~= nil then
		rootJoint.C0 = c0
	end
end

function EquipmentClient:_rigToCharacter(holstered: boolean)
    ModelUtil.SetPartProperty(self.WorldModel, "CastShadow", true)
    if holstered then
        self:RigTo(Players.LocalPlayer.Character, self.HolsterLimb, self.RootJoint.C0.Holstered)
    else
        self:RigTo(Players.LocalPlayer.Character, "Right Arm", self.RootJoint.C0.Equipped.World)
    end
end

function EquipmentClient:_rigToViewmodel()
    ModelUtil.SetPartProperty(self.WorldModel, "CastShadow", false)
    self:RigTo(ViewmodelController.Viewmodel.Instance, "Right Arm", self.RootJoint.C0.Equipped.Viewmodel)
end

function EquipmentClient:_loadViewmodelAnimations()
    local viewmodel = ViewmodelController.Viewmodel
    local animationManager = viewmodel.AnimationManager
    animationManager:LoadAnimations(self.Folder.Animations["1P"]:GetChildren())
    animationManager:PlayAnimation("Idle", 0)
    animationManager:PlayAnimation("Equip", 0)
end

-- pickup is handled via proximity prompt

function EquipmentClient:Equip()
    if self.IsPickedUp:Get() then
        self.EquipRequest:Fire()
    end
end

function EquipmentClient:_onEquipped()
    CameraController:SetAllowFirstPerson(self.AllowFirstPerson)

    UserInputService.MouseIconEnabled = false

    if not self.AllowFirstPerson then return end

    self:_loadViewmodelAnimations()
    if CameraController.InFirstPerson then
        self:_rigToViewmodel()
        ViewmodelController.Viewmodel:ToggleVisibility(true)
    end
end

function EquipmentClient:Unequip()
    if self.IsPickedUp:Get() then
        self.UnequipRequest:Fire()
    end
end

function EquipmentClient:_onUnequipped()
    if self.IsPickedUp:Get() then
        self:_rigToCharacter(true)
    end

    ViewmodelController.Viewmodel:ToggleVisibility(false)
    CameraController:SetAllowFirstPerson(true)

    UserInputService.MouseIconEnabled = true
end

function EquipmentClient:Drop()
    if self.IsPickedUp:Get() then
        self.DropRequest:Fire()
    end
end

return EquipmentClient
