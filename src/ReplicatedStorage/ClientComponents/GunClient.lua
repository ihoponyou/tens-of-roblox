
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- definition of common ancestor
local Packages = ReplicatedStorage.Packages

-- block of all imported packages
local Component = require(Packages.Component)
local Knit = require(Packages.Knit)
local Spring = require(Packages.Spring)
local Trove = require(Packages.Trove)

-- definitions derived from packages
local InputController, ViewmodelController, CameraController

-- block for modules imported from same project
local Find = require(ReplicatedStorage.Source.Modules.Find)
local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local NumberLerp = require(ReplicatedStorage.Source.Modules.NumberLerp)

-- module level constants
local ADS_SPEED = 0.4
local ADS_IN_DURATION = ADS_SPEED
local ADS_OUT_DURATION = ADS_SPEED * 0.75

local RAND = Random.new(tick())

local GunClient = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

function GunClient:Construct()
	self._trove = Trove.new()
    self._folder = Find.path(ReplicatedStorage, "Equipment/"..self.Instance.Name)

    self.BoltHeldOpen = false
    self._primaryDown = false

    self.AimPercent = self._trove:Add(Instance.new("NumberValue"))

    self.CasingModel = Find.path(self._folder, "Casing")
end

function GunClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
        InputController = Knit.GetController("InputController")
        CameraController = Knit.GetController("CameraController")
    end):catch(warn)

	self.EquipmentClient = self:GetComponent(EquipmentClient)

	self.Magazine = self.EquipmentClient.WorldModel:WaitForChild("Magazine")

    self._trove:Connect(self.EquipmentClient.UseEvent.OnClientEvent, function(...: any)
        self:_doRecoil(...)
    end)

    self._trove:Connect(self.EquipmentClient.Equipped, function(equipped: boolean)
        if equipped then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end)
end

function GunClient:Stop()
    self._trove:Destroy()
end

local db = false
function GunClient:HeartbeatUpdate(_)
    if not self.EquipmentClient.IsEquipped then return end

    if not db and self._primaryDown then
        db = true
        self.EquipmentClient:Use(workspace.CurrentCamera.CFrame.LookVector)
        task.wait(.1)
        db = false
    end
end

function GunClient:_updateOffsets(_)
    local recoilOffset = self.RecoilSpring.Position

	local cameraRecoil = CFrame.Angles(
		math.rad(recoilOffset.Y * 3),
		math.rad(recoilOffset.X * 3),
		0)
	CameraController.OffsetManager:SetOffsetValue("Recoil", cameraRecoil)
	CameraController.OffsetManager:SetOffsetAlpha("Recoil", NumberLerp(1, 0.75, self.AimPercent.Value))

	local viewmodel = ViewmodelController.Viewmodel
	local viewmodelRecoil =
		CFrame.new(0, -recoilOffset.Y/10, recoilOffset.Y/5) *
		CFrame.Angles(recoilOffset.Y/25, recoilOffset.X/25, 0)
	viewmodel.OffsetManager:SetOffsetValue("Recoil", viewmodelRecoil)
	viewmodel.OffsetManager:SetOffsetAlpha("Recoil", NumberLerp(1, 0.25, self.AimPercent.Value))
	viewmodel.OffsetManager:SetOffsetValue("Aim", self._folder.Offsets.Aiming.Value) -- for calibrating/debugging
	viewmodel.OffsetManager:SetOffsetAlpha("Aim", self.AimPercent.Value)

	viewmodel.SwayScale = NumberLerp(1, 0.4, self.AimPercent.Value)
	viewmodel.ViewbobScale = NumberLerp(1, 0.1, self.AimPercent.Value)
	viewmodel.PullScale = NumberLerp(1, 0.1, self.AimPercent.Value)
end

function GunClient:_handleFireInput(_, userInputState: Enum.UserInputState, _)
	self._primaryDown = userInputState == Enum.UserInputState.Begin

	return Enum.ContextActionResult.Sink
end

function GunClient:Aim(bool: boolean)
	-- print("aiming:", self.Aiming)
	self.Aiming = bool
	-- self.AimEvent:FireServer(self.Aiming)

	ReplicatedStorage.UIEvents.CrosshairEnabled:Fire(not self.Aiming)

	local tweenInfo = TweenInfo.new(if self.Aiming then ADS_IN_DURATION else ADS_OUT_DURATION, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local properties = { Value = if self.Aiming then 1 else 0 }

	TweenService:Create(self.AimPercent, tweenInfo, properties):Play()
end

function GunClient:_handleAimInput(_, userInputState: Enum.UserInputState, _)
    if userInputState == Enum.UserInputState.Cancel then return Enum.ContextActionResult.Pass end

	self:Aim(userInputState == Enum.UserInputState.Begin)

	return Enum.ContextActionResult.Sink
end

function GunClient:_onEquipped()
    self.RecoilSpring = Spring.new(Vector3.new(0, 0, 0)) -- x: horizontal recoil, y: vertical recoil, z: "forwards" recoil
	self.RecoilSpring.Speed = 10
	self.RecoilSpring.Damper = 1

    CameraController.OffsetManager:AddOffset("Recoil", CFrame.new(), 1)
    ViewmodelController.Viewmodel.OffsetManager:AddOffset("Recoil", CFrame.new(), 1)
    ViewmodelController.Viewmodel.OffsetManager:AddOffset("Aim", CFrame.new(), 0)

    ContextActionService:BindActionAtPriority("FireGun", function(...)
        self:_handleFireInput(...)
    end, true, Enum.ContextActionPriority.High.Value, InputController:GetKeybind("Use"))

    ContextActionService:BindActionAtPriority("AimGun", function(...)
        self:_handleAimInput(...)
    end, true, Enum.ContextActionPriority.High.Value, InputController:GetKeybind("AltUse"))

    self._trove:BindToRenderStep("UpdateAimAndRecoilOffsets", Enum.RenderPriority.Camera.Value, function(_)
        self:_updateOffsets(_)
    end)
end

function GunClient:_onUnequipped()
    ContextActionService:UnbindAction("FireGun")
	ContextActionService:UnbindAction("AimGun")
    RunService:UnbindFromRenderStep("UpdateAimAndRecoilOffsets")

    CameraController.OffsetManager:RemoveOffset("Recoil")
    CameraController.OffsetManager:RemoveOffset("Aim")    
end

function GunClient:_ejectCasing()
    local ejectionPort = Find.path(self.EquipmentClient.WorldModel.PrimaryPart, "EjectionPort")
	local casingClone = self.CasingModel:Clone()
	casingClone.Parent = workspace.GunDebris
	casingClone.CFrame = ejectionPort.WorldCFrame * CFrame.Angles(0, math.pi/2, 0)
	casingClone.CollisionGroup = "GunDebris"

	-- TODO: add a sound when it hits the ground

	local ejectionCFrame = ejectionPort.WorldCFrame
	casingClone.AssemblyLinearVelocity = (
		ejectionCFrame.LookVector * 2 +
		ejectionCFrame.RightVector * 0.2  +
		ejectionCFrame.UpVector
	) * 10

	local rotationMultiplier = 1 + RAND:NextNumber()
	local xRotation = 2*math.pi * rotationMultiplier
	local yRotation = -4*math.pi * rotationMultiplier
	casingClone.AssemblyAngularVelocity = Vector3.new(xRotation, yRotation, 0)

	-- for debugging
	-- task.wait(.1)
	-- casingClone.Anchored = true

	Debris:AddItem(casingClone, 3)
end

function GunClient:_doRecoil(horizontalKick: number, verticalKick: number, ammoLeft: number)
	if CameraController.InFirstPerson then
		ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Fire")		
	end
    self.RecoilSpring:Impulse(Vector3.new(horizontalKick, verticalKick, verticalKick))

    self:_ejectCasing()
    self.Ammo = ammoLeft
end

return GunClient
