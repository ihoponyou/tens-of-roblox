
local EMPTY_CFRAME = CFrame.new()

local ADS_SPEED = 0.4
local ADS_IN_DURATION = ADS_SPEED
local ADS_OUT_DURATION = ADS_SPEED * 0.75

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)
local NamedInstance = require(ReplicatedStorage.Source.NamedInstance)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Knit = require(ReplicatedStorage.Packages.Knit)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local ViewmodelClient = require(ReplicatedStorage.Source.ClientComponents.ViewmodelClient)
local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)

local CameraController, ViewmodelController, InputController

local GunClient = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
		LocalPlayerExclusive
	},
})

local GUNS = ReplicatedStorage.Equipment.Guns

local Random = Random.new()

function GunClient:Construct()
	self._trove = Trove.new()

	self.Config = GUNS[self.Instance.Name].Configuration:GetAttributes()

	self.BoltHeldOpen = false
	self._primaryDown = false

	-- the clientside gun.model refers to the 1st person gun model
	-- BUT it reuses it in viewmodel so that visual/sound effects replicate
	-- also, since this is all clientside, the serverside version of the model actually stays
	-- in the character's hands; thus 3rd person animations work
	self.CasingModel = GUNS[self.Instance.Name].Casing

	self.AimPercent = NamedInstance.new("AimPercent", "NumberValue")

	self.RecoilEvent = self.Instance:WaitForChild("RecoilEvent")
end

function GunClient:Aim(bool: boolean)
	-- print("aiming:", self.Aiming)
	self.Aiming = bool
	self.AimEvent:FireServer(self.Aiming)

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

	self._primaryDown = userInputState == Enum.UserInputState.Begin

	return Enum.ContextActionResult.Sink
end

function GunClient:_handleReloadInput(_, userInputState: Enum.UserInputState, _)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	self.ReloadEvent:FireServer()

	return Enum.ContextActionResult.Sink
end

function GunClient:_flingMagazine(viewmodel)
	local magazineClone = self.Model.Magazine:Clone()
	local motor = magazineClone:FindFirstChildOfClass("Motor6D")
	if motor then motor:Destroy() end
	magazineClone.Parent = workspace
	magazineClone.CanCollide = true
	magazineClone.CollisionGroup = "GunDebris"

	-- TODO: add a sound when it hits the ground

	local viewmodelRoot = viewmodel.PrimaryPart
	magazineClone.AssemblyLinearVelocity =
		(-viewmodelRoot.CFrame.RightVector) * 21

	game.Debris:AddItem(magazineClone, 20)
end

function GunClient:_ejectCasing()
	local casingClone = self.CasingModel:Clone()
	casingClone.Parent = workspace
	casingClone.CFrame = self.EjectionPoint.WorldCFrame * CFrame.Angles(0, math.pi/2, 0)

	-- TODO: add a sound when it hits the ground

	local ejectionCFrame = self.EjectionPoint.WorldCFrame
	casingClone.AssemblyLinearVelocity = (
		ejectionCFrame.LookVector * 2 +
		ejectionCFrame.RightVector * 0.2  +
		ejectionCFrame.UpVector
	) * 10

	local rotationMultiplier = 1 + Random:NextNumber()
	local xRotation = 2*math.pi * rotationMultiplier
	local yRotation = -4*math.pi * rotationMultiplier
	casingClone.AssemblyAngularVelocity = Vector3.new(xRotation, yRotation, 0)

	-- for debugging
	-- task.wait(.1)
	-- casingClone.Anchored = true

	game.Debris:AddItem(casingClone, 3)
end

function GunClient:ToggleBoltHeldOpen(open: boolean)
	self.BoltHeldOpen = open

	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)

	if self.BoltHeldOpen then
		-- print("holding bolt")
		-- just play the openbolt idle on top of the normal one since the bolt isn't animated in normal one
		viewmodel:PlayAnimation("IdleOpenBolt", 0)
	else
		-- print("closing bolt")
		viewmodel:StopAnimation("IdleOpenBolt", 0)
	end
end

function GunClient:_loadViewmodel()
	local viewmodel = workspace.CurrentCamera:WaitForChild("Viewmodel")
	local viewmodelComponent = ViewmodelClient:FromInstance(viewmodel)

	viewmodelComponent:LoadAnimations(GUNS[self.Instance.Name].Animations["1P"])
	-- print(viewmodelComponent.Animations)

	local fireAnimationTrack: AnimationTrack = viewmodelComponent:GetAnimation("Fire")
	self._equipTrove:Connect(fireAnimationTrack:GetMarkerReachedSignal("eject"), function()
		self:_ejectCasing()
	end)
	if self.Config.HasBoltHoldOpen then
		self._equipTrove:Connect(fireAnimationTrack:GetMarkerReachedSignal("bolt_open") ,function()
			if self.Ammo >= 1 then return end

			-- freeze the bolt in place
			fireAnimationTrack:AdjustSpeed(0)
			-- switch the idle animation
			self:ToggleBoltHeldOpen(true)

			-- fireAnimationTrack:Stop()
			fireAnimationTrack:Stop()
		end)
	end

	if self.Config.ThrowsMagazine then
		local reload = viewmodelComponent:GetAnimation("Reload")
		if reload ~= nil then
			-- sync extras
			self._equipTrove:Connect(reload:GetMarkerReachedSignal("mag_throw"), function()
				self:_flingMagazine(viewmodel)
			end)
			-- sync sounds
			self._equipTrove:Connect(reload:GetMarkerReachedSignal("mag_release"), function()
				self.Equipment.WorldModel.PrimaryPart["ak-magazine-release"]:Play()
			end)
			self._equipTrove:Connect(reload:GetMarkerReachedSignal("mag_insert"), function()
				self.Equipment.WorldModel.PrimaryPart["ak-magazine-insert"]:Play()
			end)
			self._equipTrove:Connect(reload:GetMarkerReachedSignal("bolt_slide"), function()
				self.Equipment.WorldModel.PrimaryPart["ak-bolt-slide"]:Play()
			end)
		end
		local reloadOpenBolt: AnimationTrack = viewmodelComponent:GetAnimation("ReloadOpenBolt")
		if reloadOpenBolt ~= nil then
			-- sync extras
			self._equipTrove:Connect(reloadOpenBolt:GetMarkerReachedSignal("mag_throw"), function()
				self:_flingMagazine(viewmodel)
			end)
			self._equipTrove:Connect(reloadOpenBolt.Ended, function()
				self:ToggleBoltHeldOpen(false)
			end)
			-- sync sounds
			self._equipTrove:Connect(reloadOpenBolt:GetMarkerReachedSignal("mag_release"), function()
				self.Equipment.WorldModel.PrimaryPart["ak-magazine-release"]:Play()
			end)
			self._equipTrove:Connect(reloadOpenBolt:GetMarkerReachedSignal("mag_insert"), function()
				self.Equipment.WorldModel.PrimaryPart["ak-magazine-insert"]:Play()
			end)
			self._equipTrove:Connect(reloadOpenBolt:GetMarkerReachedSignal("bolt_slide"), function()
				self.Equipment.WorldModel.PrimaryPart["ak-bolt-slide"]:Play()
			end)
		end
	end

	viewmodelComponent:PlayAnimation("Idle", 0)
	-- play equip animation
	viewmodelComponent:PlayAnimation("Equip", 0)

	viewmodelComponent:ToggleVisibility(true)

	-- hide the viewmodel upon destruction of this trove
	self._equipTrove:Add(function()
		viewmodelComponent:ToggleVisibility(false)
	end)
end

function GunClient:_onEquipped()
	self._equipTrove = self._localPlayerTrove:Extend()

	local viewmodel = ViewmodelController.Viewmodel

	-- rig receiver & magazine to viewmodel root
	local magazinePart = self.Equipment.WorldModel.Magazine
	local magazineJoint = magazinePart.Magazine
	-- magazineJoint.C0 = magazinePart.ViewmodelC0.Value -- revert motor6d scaling
	magazineJoint.Part0 = viewmodel.Instance.PrimaryPart -- gun's receiver

	self:_loadViewmodel()

	self.RecoilSpring = Spring.new(Vector3.new(0, 0, 0)) -- x: horizontal recoil, y: vertical recoil, z: "forwards" recoil
	self.RecoilSpring.Speed = 10
	self.RecoilSpring.Damper = 1
	self._lastOffset = Vector3.new()

	ContextActionService:BindActionAtPriority("FireGun", function(...)
		self:_handleFireInput(...)
	end, true, Enum.ContextActionPriority.High.Value,  InputController:GetKeybind("Use").Key)

	ContextActionService:BindActionAtPriority("AimGun", function(...)
		self:_handleAimInput(...)
	end, true, Enum.ContextActionPriority.High.Value, InputController:GetKeybind("AlternateUse").Key, Enum.KeyCode.Q)

	ContextActionService:BindAction("ReloadGun", function(...)
		self:_handleReloadInput(...)
	end, true, InputController:GetKeybind("Reload").Key)

	self._equipTrove:Add(function()
		ContextActionService:UnbindAction("FireGun")
		ContextActionService:UnbindAction("AimGun")
		ContextActionService:UnbindAction("Reload")
	end)

	self._equipTrove:BindToRenderStep("GunClientOnRenderStepped", Enum.RenderPriority.Camera.Value, function(...)
		if self._primaryDown then self.Equipment:Use(workspace.CurrentCamera.CFrame.LookVector) end
		self:OnRenderStepped(...)
	end)
end

function GunClient:_onUnequipped()
	self._equipTrove:Clean()

	self._primaryDown = false
end

function GunClient:OnRecoilEvent(verticalKick: number, horizontalKick: number, ammoLeft: number)
	self.Ammo = ammoLeft
	self.RecoilSpring:Impulse(Vector3.new(horizontalKick, verticalKick, verticalKick))

	local viewmodel = ViewmodelController.Viewmodel
	viewmodel:PlayAnimation("Fire")
end

function GunClient:OnReloadEvent()
	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)

	local reloadAnimationTrack = if self.Config.HasBoltHoldOpen and self.BoltHeldOpen
		then viewmodel:GetAnimation("ReloadOpenBolt")
		else viewmodel:GetAnimation("Reload")

	reloadAnimationTrack:Play()

	if self.Config.HasBoltHoldOpen then
		self:ToggleBoltHeldOpen(false)
	end
end

-- as percent increases, the value of this function will decrease to the minimum
local function reduceNumberWithMinimum(minimum: number, percent: number)
	return (minimum-1)*percent+1
end

function GunClient:OnRenderStepped()
	local recoilOffset = self.RecoilSpring.Position

	local cameraRecoil = CFrame.Angles(
		math.rad(recoilOffset.Y * 2),
		math.rad(recoilOffset.X * 2),
		0
	)
	CameraController:UpdateOffset("Recoil", cameraRecoil)
	CameraController:SetOffsetAlpha("Recoil", reduceNumberWithMinimum(0.75, self.AimPercent.Value))

	local viewmodel = ViewmodelController.Viewmodel
	local viewmodelRecoil =
		CFrame.new(0, -recoilOffset.Y/10, recoilOffset.Y/5) *
		CFrame.Angles(recoilOffset.Y/25, recoilOffset.X/25, 0)
	viewmodel:UpdateOffset("Recoil", viewmodelRecoil)
	viewmodel:SetOffsetAlpha("Recoil", reduceNumberWithMinimum(0.25, self.AimPercent.Value))
	viewmodel:UpdateOffset("Aim", GUNS[self.Instance.Name].Offsets.Aiming.Value) -- for calibrating/debugging
	viewmodel:SetOffsetAlpha("Aim", self.AimPercent.Value)

	viewmodel.SwayScale = reduceNumberWithMinimum(0.4, self.AimPercent.Value)
	viewmodel.ViewbobScale = reduceNumberWithMinimum(0.1, self.AimPercent.Value)
	viewmodel.PullScale = reduceNumberWithMinimum(0.1, self.AimPercent.Value)
end

function GunClient:_setupForLocalPlayer()
	self._localPlayerTrove = self._trove:Extend()

	local viewmodel = ViewmodelController.Viewmodel
	viewmodel:ApplyOffset("Recoil", CFrame.new(), 1)
	viewmodel:ApplyOffset("Aim", GUNS[self.Instance.Name].Offsets.Aiming.Value, 0)
	CameraController:ApplyOffset("Recoil", CFrame.new(), 1)

	self.Equipment.UseRequest.OnClientInvoke = function(...)
		self:OnRecoilEvent(...)
		return workspace.CurrentCamera.CFrame.LookVector
	end
	self._localPlayerTrove:Add(function() self.Equipment.UseRequest.OnClientInvoke = nil end)

	-- TODO: maybe let input controller switch keybinds based on context (action service :O)
	-- self._localPlayerTrove:Connect(RunService.RenderStepped, function() self:OnRenderStepped() end)
end

function GunClient:_cleanUpForLocalPlayer()
	if self._localPlayerTrove then self._localPlayerTrove:Clean() end
end

function GunClient:Start()
	Knit.OnStart():andThen(function()
		CameraController = Knit.GetController("CameraController")
		ViewmodelController = Knit.GetController("ViewmodelController")
		InputController = Knit.GetController("InputController")
	end):catch(warn)

	self.Equipment = self:GetComponent(EquipmentClient)

	self.EjectionPoint = self.Equipment.WorldModel:WaitForChild("Receiver"):WaitForChild("EjectionPoint")

	self._trove:Connect(self.Equipment.Equipped, function(equipped: boolean)
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

return GunClient
