local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)

local ClientComponents = ReplicatedStorage.Source.ClientComponents
local Logger = require(ClientComponents.Extensions.Logger)

local ViewmodelClient

local NamedInstance = require(ReplicatedStorage.Source.NamedInstance)
local NumberLerp = require(ReplicatedStorage.Source.NumberLerp)

local GunClient = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

local fieldOfView = 85

local CUSTOM_SCALES = {
	["AK-47"] = 1
}

function GunClient:Construct()
	self._trove = Trove.new()

	self._primaryDown = false

	self.MouseEvent = self.Instance:WaitForChild("MouseEvent")
	self.RecoilEvent = self.Instance:WaitForChild("RecoilEvent")
	self.AimEvent = self.Instance:WaitForChild("AimEvent")
	self.EquipEvent = self.Instance:WaitForChild("EquipEvent")

	self.ModelLoaded = self.Instance:WaitForChild("ModelLoaded")
	self._trove:Connect(self.ModelLoaded.OnClientEvent, function(model)
		self.Model = model
		local scale = CUSTOM_SCALES[self.Instance.Name]
		if scale~=nil then
			self.Model:ScaleTo(scale)
		end
		self.Model.Parent = self.Instance
	end)

	-- the clientside gun.model refers to the 1st person gun model
	-- BUT it reuses it in viewmodel so that visual/sound effects replicate
	-- also, since this is all clientside, the serverside version of the model actually stays
	-- in the character's hands; thus 3rd person animations work
	-- self.Model = self.Instance:WaitForChild("GunModel")

	self.Config = ReplicatedStorage.Weapons[self.Instance.Name].Configuration

	self.AimPercent = NamedInstance.new("AimPercent", "NumberValue", self.Model)
end

function GunClient:Aim(bool: boolean)
	self.Aiming = if bool == nil then not self.Aiming else bool
	self.AimEvent:FireServer(self.Aiming)
	-- print("aiming:", self.Aiming)

	local adsSpeed = 0.4

	-- UserInputService.MouseIconEnabled = not self.Aiming

	local tweeningInformation =
		TweenInfo.new(if self.Aiming then adsSpeed else adsSpeed * 0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local properties = { Value = if self.Aiming then 1 else 0 }

	TweenService:Create(self.AimPercent, tweeningInformation, properties):Play()
end

function GunClient:_handleAimInput(actionName: string, userInputState: Enum.UserInputState, inputObject: InputObject)
	if userInputState == Enum.UserInputState.Cancel then return Enum.ContextActionResult.Pass end
	self:Aim(userInputState == Enum.UserInputState.Begin)
	return Enum.ContextActionResult.Sink
end

function GunClient:_handleFireInput(actionName: string, userInputState: Enum.UserInputState, inputObject: InputObject)
	self._primaryDown = userInputState == Enum.UserInputState.Begin
	return Enum.ContextActionResult.Sink
end

function GunClient:_equip()
	-- print(self.Instance.Parent, "equipped", self.Instance.Name)

	local mouse = Players.LocalPlayer:GetMouse()
	mouse.Icon = "rbxasset://textures/GunCursor.png"

	local viewmodel = workspace.CurrentCamera:WaitForChild("Viewmodel")
	self.Model.Parent = viewmodel
	self.Model.PrimaryPart.RootJoint.Part0 = viewmodel["Right Arm"]

	local viewmodelComponent = ViewmodelClient:FromInstance(viewmodel)
	viewmodelComponent:ToggleVisibility(true)
	viewmodelComponent:LoadAnimations(ReplicatedStorage.Weapons[self.Instance.Name].Animations["1P"])
	viewmodelComponent:PlayAnimation("Idle")

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

	RunService:BindToRenderStep("GunClientOnRenderStepped", Enum.RenderPriority.Camera.Value, function(...)
		self:OnRenderStepped(...)
	end)
end

function GunClient:_unequip()
	local viewmodel = workspace.CurrentCamera:WaitForChild("Viewmodel")
	local viewmodelComponent = ViewmodelClient:FromInstance(viewmodel)
	viewmodelComponent:ToggleVisibility(false)

	self.Model.PrimaryPart.RootJoint.Part0 = nil
	self.Model.Parent = self.Instance
	self.Model:PivotTo(CFrame.new())

	ContextActionService:UnbindAction("aim" .. self.Instance.Name)
	ContextActionService:UnbindAction("fire" .. self.Instance.Name)
	RunService:UnbindFromRenderStep("GunClientOnRenderStepped")

	self._primaryDown = false

	local mouse = Players.LocalPlayer:GetMouse()
	mouse.Icon = ""
end

-- use remote event to prevent race condition while giving gun to viewmodel
function GunClient:OnEquipEvent(equipped: boolean)
	if equipped then
		self:_equip()
	else
		self:_unequip()
	end
end

function GunClient:OnRecoilEvent(verticalKick: number, horizontalKick: number)
	self.RecoilSpring:Impulse(Vector3.new(horizontalKick, verticalKick, verticalKick))

	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)

	viewmodel:PlayAnimation("Fire")

	workspace.CurrentCamera.CFrame *= CFrame.Angles(
		math.rad(verticalKick/10),
		math.rad(horizontalKick/10),
		0
	)
end

function GunClient:OnDeactivated()
	--print(self.Instance.Parent, "deactivated", self.Instance.Name)
	self._primaryDown = false
end

function GunClient:OnStepped(deltaTime: number)
	if self._primaryDown then
		self.MouseEvent:FireServer(workspace.CurrentCamera.CFrame.LookVector)
	end
end

local function toRoundedString(number: number): string
	local num = math.round(number)
	return tostring(num)
end

-- as percent increases, the value of this function will decrease to the minimum
local function reduceNumberWithMinimum(minimum: number, percent: number)
	return (minimum-1)*percent+1
end

function GunClient:OnRenderStepped(deltaTime: number)
	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)

	local aimPercentValue = self.AimPercent.Value
	local recoilScale = NumberLerp.Lerp(1, 0.25, aimPercentValue) -- reduce recoil if aiming
	local minimumSwayScale = 0.2
	viewmodel.SwayScale = reduceNumberWithMinimum(minimumSwayScale, aimPercentValue) -- reduce sway if aiming

	local aimOffset = ReplicatedStorage.Weapons[self.Instance.Name].Offsets.Aiming.Value
	local recoilSpringPos: Vector3 = self.RecoilSpring.Position
	local recoilPositionOffset = CFrame.new(
		0,
		0.05 * recoilSpringPos.Y * recoilScale,
		0.35 * recoilSpringPos.Y * recoilScale
	)
	local recoilRotationOffset = CFrame.Angles(
		0.04 * recoilSpringPos.Y * recoilScale,
		0.04 * recoilSpringPos.X * recoilScale,
		0
	)

	local minimumViewbobAlpha = 0.05
	viewmodel.ViewbobScale = reduceNumberWithMinimum(minimumViewbobAlpha, aimPercentValue)
	viewmodel:ApplyOffset("Aim", aimOffset, aimPercentValue)
	local minimumRecoilPositionAlpha = 0.6
	viewmodel:ApplyOffset("RecoilPosition", recoilPositionOffset, reduceNumberWithMinimum(minimumRecoilPositionAlpha, aimPercentValue))
	local minimumRecoilRotationAlpha = 0.8
	viewmodel:ApplyOffset("RecoilRotation", recoilRotationOffset, reduceNumberWithMinimum(minimumRecoilRotationAlpha, aimPercentValue))
	-- self.RecoilIndicator.Text = ("curr: "..toRoundedString(self.RecoilSpring.Position.X).."\n".."last: "..toRoundedString(self._lastOffset.X))

	-- https://www.desmos.com/calculator/fkrydqig88
	local magnification = 1.25
	workspace.CurrentCamera.FieldOfView = fieldOfView - ((fieldOfView - (fieldOfView / magnification)) * aimPercentValue)

	self._lastOffset = self.RecoilSpring.Position
end

function GunClient:_setupForLocalPlayer()
	self._localPlayerTrove = Trove.new()
	self._trove:Add(self._localPlayerTrove)

	self._localPlayerTrove:Connect(self.RecoilEvent.OnClientEvent, function(...) self:OnRecoilEvent(...) end)
	self._localPlayerTrove:Connect(self.EquipEvent.OnClientEvent, function(...) self:OnEquipEvent(...) end)

	self._localPlayerTrove:Connect(self.Instance.Activated, function(...) self:OnActivated(...) end)
	self._localPlayerTrove:Connect(self.Instance.Deactivated, function(...) self:OnDeactivated(...) end)

	self._localPlayerTrove:Connect(RunService.Stepped, function(...) self:OnStepped(...) end)
end

function GunClient:_cleanUpForLocalPlayer()
	self._localPlayerTrove:Clean()
end

function GunClient:Start()
	ViewmodelClient = require(script.Parent.ViewmodelClient)
	-- CameraController = Knit.GetController("CameraController")

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
