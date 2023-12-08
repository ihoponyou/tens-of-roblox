local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)
local NamedInstance = require(ReplicatedStorage.Source.NamedInstance)
local NumberLerp = require(ReplicatedStorage.Source.NumberLerp)
local ClientComponents = ReplicatedStorage.Source.ClientComponents
local Logger = require(ClientComponents.Extensions.Logger)
local Knit = require(ReplicatedStorage.Packages.Knit)

local ViewmodelClient, CameraController

local GunClient = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

local fieldOfView = 85

local WEAPONS = ReplicatedStorage.Weapons

local Random = Random.new()

function GunClient:Construct()
	self._trove = Trove.new()

	self.Config = WEAPONS[self.Instance.Name].Configuration

	self.HasBoltHoldOpen = self.Config:GetAttribute("HasBoltHoldOpen")
	self.ThrowsMagazine = self.Config:GetAttribute("ThrowsMagazine")
	self.BoltHeldOpen = false
	self._primaryDown = false

	self.MouseEvent = self.Instance:WaitForChild("MouseEvent")
	self.RecoilEvent = self.Instance:WaitForChild("RecoilEvent")
	self.AimEvent = self.Instance:WaitForChild("AimEvent")
	self.ReloadEvent = self.Instance:WaitForChild("ReloadEvent")
	self.EquipEvent = self.Instance:WaitForChild("EquipEvent")

	self.CasingModel = self._trove:Clone(ReplicatedStorage.Weapons[self.Instance.Name].Casing)

	self.Model = nil

	-- the clientside gun.model refers to the 1st person gun model
	-- BUT it reuses it in viewmodel so that visual/sound effects replicate
	-- also, since this is all clientside, the serverside version of the model actually stays
	-- in the character's hands; thus 3rd person animations work

	self.Config = ReplicatedStorage.Weapons[self.Instance.Name].Configuration

	self.AimPercent = NamedInstance.new("AimPercent", "NumberValue", self.Model)
end

function GunClient:Aim(bool: boolean)
	self.Aiming = if bool == nil then not self.Aiming else bool
	self.AimEvent:FireServer(self.Aiming)
	-- print("aiming:", self.Aiming)

	local adsSpeed = 0.4

	local tweeningInformation =
		TweenInfo.new(if self.Aiming then adsSpeed else adsSpeed * 0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local properties = { Value = if self.Aiming then 1 else 0 }

	TweenService:Create(self.AimPercent, tweeningInformation, properties):Play()
end

function GunClient:Reload()
	self.ReloadEvent:FireServer()
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
	self:Reload()
	return Enum.ContextActionResult.Sink
end

function GunClient:_flingMagazine(viewmodel)
	local magazineClone = self.Model.Magazine:Clone()
	magazineClone.Parent = workspace
	magazineClone.CanCollide = true
	magazineClone.CollisionGroup = "GunDebris"

	local viewmodelRoot = viewmodel.PrimaryPart
	magazineClone.AssemblyLinearVelocity =
		(viewmodelRoot.CFrame.LookVector + -viewmodelRoot.CFrame.RightVector) * 20

	game.Debris:AddItem(magazineClone, 20)
end

function GunClient:_ejectCasing()
	local casingClone = self.CasingModel:Clone()
	casingClone.Parent = workspace
	local ejectionPoint = self.Model.PrimaryPart.EjectionPoint
	casingClone.CFrame = ejectionPoint.WorldCFrame * CFrame.Angles(0, math.pi/2, 0)

	casingClone.AssemblyLinearVelocity =
	(ejectionPoint.WorldCFrame.LookVector * 2 + ejectionPoint.WorldCFrame.RightVector * 0.2  + ejectionPoint.WorldCFrame.UpVector) * 10

	local rotationMultiplier = 1 + Random:NextNumber()
	local xRotation = 2*math.pi * rotationMultiplier
	local yRotation = -4*math.pi * rotationMultiplier
	casingClone.AssemblyAngularVelocity = Vector3.new(xRotation, yRotation, 0)

	-- task.wait(.1)
	-- casingClone.Anchored = true

	game.Debris:AddItem(casingClone, 3)
end

function GunClient:_equip()
	self._equipTrove = self._localPlayerTrove:Extend()

	self.Model = self.Instance:WaitForChild("WorldModel")

	local viewmodel = workspace.CurrentCamera:WaitForChild("Viewmodel")
	local viewmodelComponent = ViewmodelClient:FromInstance(viewmodel)
	self.Model.Parent = viewmodel
	self.Model:ScaleTo(1)
	viewmodelComponent:HoldModel(self.Model)
	viewmodelComponent:ToggleVisibility(true)
	viewmodelComponent:LoadAnimations(ReplicatedStorage.Weapons[self.Instance.Name].Animations["1P"])

	if self.ThrowsMagazine then
		local reload = viewmodelComponent:GetAnimation("Reload")
		if reload ~= nil then
			self._equipTrove:Connect(reload:GetMarkerReachedSignal("throw_mag"), function()
				self:_flingMagazine(viewmodel)
			end)
		end
		local reloadOpenBolt = viewmodelComponent:GetAnimation("ReloadOpenBolt")
		if reloadOpenBolt ~= nil then
			self._equipTrove:Connect(reloadOpenBolt:GetMarkerReachedSignal("throw_mag"), function()
				self:_flingMagazine(viewmodel)
			end)
		end
	end

	self._equipTrove:Connect(viewmodelComponent:GetAnimation("Fire"):GetMarkerReachedSignal("eject"), function()
		self:_ejectCasing()
	end)

	viewmodelComponent:PlayAnimation("Idle")

	self._equipTrove:Add(function()
		viewmodelComponent:ToggleVisibility(false)
	end)

	self.RecoilSpring = Spring.new(Vector3.new(0, 0, 0)) -- x: horizontal recoil, y: vertical recoil, z: "forwards" recoil
	self.RecoilSpring.Speed = 10
	self.RecoilSpring.Damper = 1
	self._lastOffset = Vector3.new()

	ContextActionService:BindAction("aim" .. self.Instance.Name, function(...)
		self:_handleAimInput(...)
	end, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.Q)

	ContextActionService:BindAction("fire" .. self.Instance.Name, function(...)
		self:_handleFireInput(...)
	end, true, Enum.UserInputType.MouseButton1)

	ContextActionService:BindAction("reload"..self.Instance.Name, function(...)
		self:_handleReloadInput(...)
	end, true, Enum.KeyCode.R)

	self._equipTrove:Add(function()
		ContextActionService:UnbindAction("aim" .. self.Instance.Name)
		ContextActionService:UnbindAction("fire" .. self.Instance.Name)
		ContextActionService:UnbindAction("reload" .. self.Instance.Name)
	end)

	self._equipTrove:BindToRenderStep("GunClientOnRenderStepped", Enum.RenderPriority.Camera.Value, function(...)
		self:OnRenderStepped(...)
	end)
end

function GunClient:_unequip()
	self._equipTrove:Clean()

	self.Model.PrimaryPart.RootJoint.Part0 = nil
	self.Model.Parent = self.Instance
	self.Model:PivotTo(CFrame.new())

	self._primaryDown = false
end

-- use remote event to prevent race condition while giving gun to viewmodel
function GunClient:OnEquipEvent(equipped: boolean)
	if equipped then
		self:_equip()
	else
		self:_unequip()
	end
end

function GunClient:ToggleBoltHeldOpen(open: boolean?)
	self.BoltHeldOpen = if open ~= nil then open else not self.BoltHeldOpen

	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)
	-- local boltJoint = self.Model.PrimaryPart:FindFirstChild("Bolt")
	-- if not boltJoint then warn("no bolt joint") return end

	if self.BoltHeldOpen then
		-- print("holding bolt")
		viewmodel:StopAnimation("Idle", 0)
		viewmodel:PlayAnimation("IdleOpenBolt", 0)
		-- TweenService:Create(boltJoint, BOLT_POSITIONS.TweenInfo, {C0 = BOLT_POSITIONS[self.Instance.Name].Open}):Play()
	else
		-- print("closing bolt")
		viewmodel:StopAnimation("IdleOpenBolt", 0)
		viewmodel:PlayAnimation("Idle", 0)
		-- TweenService:Create(boltJoint, BOLT_POSITIONS.TweenInfo, {C0 = BOLT_POSITIONS[self.Instance.Name].Closed}):Play()
	end
end

function GunClient:OnRecoilEvent(verticalKick: number, horizontalKick: number, ammoLeft: number)
	self.RecoilSpring:Impulse(Vector3.new(horizontalKick, verticalKick, verticalKick))

	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)

	local fireAnimationTrack: AnimationTrack = viewmodel:GetAnimation("Fire")
	if ammoLeft < 1 and self.HasBoltHoldOpen then
		fireAnimationTrack:GetMarkerReachedSignal("boltOpen"):Once(function()
			fireAnimationTrack:AdjustSpeed(0)
			self:ToggleBoltHeldOpen(true)
			fireAnimationTrack:Stop(0)
		end)
	end
	viewmodel:PlayAnimation("Fire")
end

function GunClient:OnReloadEvent()
	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)

	local reloadAnimationTrack = if self.HasBoltHoldOpen and self.BoltHeldOpen
	then viewmodel:GetAnimation("ReloadOpenBolt")
	else viewmodel:GetAnimation("Reload")

	reloadAnimationTrack:Play()

	if self.HasBoltHoldOpen then
		self:ToggleBoltHeldOpen(false)
	end
end

function GunClient:OnStepped()
	if self._primaryDown then
		self.MouseEvent:FireServer(workspace.CurrentCamera.CFrame.LookVector)
	end
end


-- as percent increases, the value of this function will decrease to the minimum
local function reduceNumberWithMinimum(minimum: number, percent: number)
	return (minimum-1)*percent+1
end

function GunClient:OnRenderStepped()
	local recoilOffset = self.RecoilSpring.Position
	-- self.RecoilIndicator.Text = ("curr: "..toRoundedString(self.RecoilSpring.Position.X).."\n".."last: "..toRoundedString(self._lastOffset.X))

	local cameraRecoil = CFrame.Angles(
		math.rad(recoilOffset.Y * 2),
		math.rad(recoilOffset.X * 2),
		0
	)
	CameraController:UpdateOffset("Recoil", cameraRecoil)

	-- TODO: maybe make viewmodel a field idk?
	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)
	local viewmodelRecoil =
		CFrame.new(0, -recoilOffset.Y/10, recoilOffset.Y/5) *
		CFrame.Angles(recoilOffset.Y/25, recoilOffset.X/25, 0)
	viewmodel:UpdateOffset("Recoil", viewmodelRecoil)

	viewmodel:SetOffsetAlpha("Aim", self.AimPercent.Value)

	CameraController:SetOffsetAlpha("Recoil", reduceNumberWithMinimum(0.75, self.AimPercent.Value))
	viewmodel:SetOffsetAlpha("Recoil", reduceNumberWithMinimum(0.25, self.AimPercent.Value))
	viewmodel.SwayScale = reduceNumberWithMinimum(0.4, self.AimPercent.Value)
	viewmodel.ViewbobScale = reduceNumberWithMinimum(0.1, self.AimPercent.Value)
	viewmodel.PullScale = reduceNumberWithMinimum(0.1, self.AimPercent.Value)
end

function GunClient:_setupForLocalPlayer()
	self._localPlayerTrove = Trove.new()
	self._trove:Add(self._localPlayerTrove)

	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)
	viewmodel:ApplyOffset("Recoil", CFrame.new(), 1)
	viewmodel:ApplyOffset("Aim", ReplicatedStorage.Weapons[self.Instance.Name].Offsets.Aiming.Value, 0)
	CameraController:ApplyOffset("Recoil", CFrame.new(), 1)

	self._localPlayerTrove:Connect(self.RecoilEvent.OnClientEvent, function(...) self:OnRecoilEvent(...) end)
	self._localPlayerTrove:Connect(self.EquipEvent.OnClientEvent, function(...) self:OnEquipEvent(...) end)
	self._localPlayerTrove:Connect(self.ReloadEvent.OnClientEvent, function(...) self:OnReloadEvent(...) end)

	self._localPlayerTrove:Connect(RunService.Stepped, function() self:OnStepped() end)
	self._localPlayerTrove:Connect(RunService.RenderStepped, function() self:OnRenderStepped() end)
end

function GunClient:_cleanUpForLocalPlayer()
	if self._localPlayerTrove then self._localPlayerTrove:Clean() end
end

function GunClient:Start()
	ViewmodelClient = require(script.Parent.ViewmodelClient)
	Knit.OnStart():andThen(function()
		CameraController = Knit.GetController("CameraController")
	end):catch(warn)

	local function OwnerIDChanged()
		if self.Instance:GetAttribute("OwnerID") == Players.LocalPlayer.UserId then
			self:_setupForLocalPlayer()
		else
			self:_cleanUpForLocalPlayer()
		end
	end

	OwnerIDChanged()
	self._trove:Connect(self.Instance:GetAttributeChangedSignal("OwnerID"), OwnerIDChanged)
end

function GunClient:Stop()
	self._trove:Destroy()
end

return GunClient
