
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
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
	self.Config = EquipmentConfig[self.Instance.Name].TypeDependent
	self._trove = Trove.new()

	self.ReloadEvent = self.Instance:WaitForChild("ReloadEvent")
	self.UpdateCurrentAmmo = self.Instance:WaitForChild("UpdateCurrentAmmo")
	self.UpdateReserveAmmo = self.Instance:WaitForChild("UpdateReserveAmmo")

    self._boltHeldOpen = false
    self._triggerDown = false
	self._firing = false
	self._reloading = false
	self._lastShotFired = 0

	self._castParams = RaycastParams.new()
	self._castParams.CollisionGroup = "Character"
	self._castParams.FilterType = Enum.RaycastFilterType.Exclude

    self.AimPercent = self._trove:Add(Instance.new("NumberValue"))
end

function GunClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
        InputController = Knit.GetController("InputController")
        CameraController = Knit.GetController("CameraController")
    end):catch(warn)

	self.Equipment = self:GetComponent(EquipmentClient)
	
	self._fireDelay = 1/(self.Config.RoundsPerMinute/60)
    self.CasingModel = Find.path(self.Equipment.Folder, "Casing")
	self.Magazine = self.Equipment.WorldModel:WaitForChild("Magazine")
	
	self.CurrentAmmo = self.Config.MagazineCapacity
	self.ReserveAmmo = self.CurrentAmmo * self.Config.ReserveMagazines

    -- self._trove:Connect(self.Equipment.UseEvent.OnClientEvent, function(...: any)
    --     self:_doRecoil(...)
    -- end)

    self._trove:Connect(self.Equipment.Equipped, function(equipped: boolean)
        if equipped then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end)

	self._trove:Connect(self.ReloadEvent.OnClientEvent, function()
		self:_reload()
	end)

	self._trove:Connect(self.UpdateCurrentAmmo.OnClientEvent, function(ammo: number)
		self.CurrentAmmo = ammo
	end)
	self._trove:Connect(self.UpdateReserveAmmo.OnClientEvent, function(ammo: number)
		self.ReserveAmmo = ammo
	end)
end

function GunClient:Stop()
    self._trove:Destroy()
end

function GunClient:_fire()
	if self._firing then return end
	if self._reloading then return end
	if self.CurrentAmmo < 1 then return end

    self._firing = true

	-- local now = time()
	-- print("actual time between shots:", (now-self._lastShotFired), "("..tostring(self._timeBetweenShots)..")")
	-- self._lastShotFired = now

	local origin: Vector3, direction: Vector3
	if CameraController.InFirstPerson then
		local cameraCFrame = workspace.CurrentCamera.CFrame
		origin = cameraCFrame.Position
		direction = cameraCFrame.LookVector
	else
		local head = Find.path(Players.LocalPlayer.Character, "Head")
		local mouse = Players.LocalPlayer:GetMouse()
		origin = head.Position
		direction = (mouse.Hit.Position - origin).Unit
	end
	direction *= self.Config.BulletMaxDistance

	local cast = workspace:Raycast(origin, direction, self._castParams)
	local hits = if cast then { cast.Instance } else nil -- eventually add piercing
	self.Equipment:Use(hits)
	self:_doRecoil()

	if not self.Config.FullyAutomatic then
		self._triggerDown = false
	end

    task.delay(self._fireDelay, function()
		self._firing = false
	end)
end

function GunClient:HeartbeatUpdate()
    if not self.Equipment.IsEquipped then return end
	if not self._triggerDown then return end

	self:_fire()
end

function GunClient:_updateOffsets()
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

function GunClient:Aim(bool: boolean)
	-- print("aiming:", self.Aiming)
	if self.Aiming == bool then return end
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

function GunClient:_handleFireInput(_, userInputState: Enum.UserInputState, _)
	self._triggerDown = userInputState == Enum.UserInputState.Begin

	return Enum.ContextActionResult.Sink
end

function GunClient:_handleReloadInput(_, userInputState: Enum.UserInputState, _)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	if not self._reloading then
		self:Aim(false)
		self.ReloadEvent:FireServer()
	end

	return Enum.ContextActionResult.Sink
end

function GunClient:_onEquipped()
	self._equipTrove = self._trove:Extend()
	self._castParams.FilterDescendantsInstances = { Players.LocalPlayer.Character }

    self.RecoilSpring = Spring.new(Vector3.new(0, 0, 0)) -- x: horizontal recoil, y: vertical recoil, z: "forwards" recoil
	self.RecoilSpring.Speed = 10
	self.RecoilSpring.Damper = 1

    CameraController.OffsetManager:AddOffset("Recoil", CFrame.new(), 1)
    ViewmodelController.Viewmodel.OffsetManager:AddOffset("Recoil", CFrame.new(), 1)
    ViewmodelController.Viewmodel.OffsetManager:AddOffset("Aim", CFrame.new(), 0)

    ContextActionService:BindActionAtPriority("AimGun", function(...)
        self:_handleAimInput(...)
    end, true, Enum.ContextActionPriority.High.Value, InputController:GetKeybind("AltUse"))
    ContextActionService:BindActionAtPriority("FireGun", function(...)
        self:_handleFireInput(...)
    end, true, Enum.ContextActionPriority.High.Value, InputController:GetKeybind("Use"))
	ContextActionService:BindActionAtPriority("ReloadGun", function(...)
        self:_handleReloadInput(...)
    end, true, Enum.ContextActionPriority.High.Value, InputController:GetKeybind("Reload"))

    self._equipTrove:BindToRenderStep("UpdateAimAndRecoilOffsets", Enum.RenderPriority.Camera.Value, function(_)
        self:_updateOffsets()
    end)

	self._equipTrove:Add(function()
		ContextActionService:UnbindAction("FireGun")
		ContextActionService:UnbindAction("AimGun")
		ContextActionService:UnbindAction("ReloadGun")
		CameraController.OffsetManager:RemoveOffset("Recoil")
    	CameraController.OffsetManager:RemoveOffset("Aim")
	end)
end

function GunClient:_onUnequipped()
    self._equipTrove:Clean()
end

function GunClient:_ejectCasing()
    local ejectionPort = Find.path(self.Equipment.WorldModel.PrimaryPart, "EjectionPort")
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
	local xRotation = -2*math.pi * rotationMultiplier
	local yRotation = -4*math.pi * rotationMultiplier
	casingClone.AssemblyAngularVelocity = Vector3.new(xRotation, yRotation, 0)

	-- for debugging
	-- task.wait(.1)
	-- casingClone.Anchored = true

	Debris:AddItem(casingClone, 3)
end

function GunClient:_doRecoil()
	ViewmodelController.Viewmodel.AnimationManager:PlayAnimation("Fire")

	-- TODO: make recoil patterns
	local verticalKick = 25
	local horizontalKick = math.random(-10, 10)
    self.RecoilSpring:Impulse(Vector3.new(horizontalKick, verticalKick, verticalKick))

    self:_ejectCasing()
end

function GunClient:_reload()
	self._reloading = true

	local animationManager = ViewmodelController.Viewmodel.AnimationManager
	local reloadTrack: AnimationTrack
	if self.Aiming then
		reloadTrack = animationManager:GetAnimation("AimReload")
	else
		reloadTrack = animationManager:GetAnimation("Reload")
	end

	if reloadTrack ~= nil then
		reloadTrack:Play()
		reloadTrack.Stopped:Wait()
	end

	self._reloading = false
end

return GunClient
