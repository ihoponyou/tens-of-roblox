local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Logger = require(script.Parent.Extensions.Logger)

local ViewmodelClient

local GunClient = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

function GunClient:Construct()
	self._trove = Trove.new()

	self.MouseEvent = self.Instance:WaitForChild("MouseEvent")
	self.RecoilEvent = self.Instance:WaitForChild("RecoilEvent")
	self.Config = self.Instance:WaitForChild("Configuration")

	local playerGui = Knit.Player.PlayerGui

	local gunGui = playerGui:FindFirstChild("GunGui")
	if not gunGui then
		gunGui = Instance.new("ScreenGui")
		gunGui.Parent = playerGui
		gunGui.Name = "GunGui"
		gunGui.Enabled = false
	end
	self.GunGui = gunGui

	local recoilIndicator = self.GunGui:FindFirstChild("RecoilIndicator")
	if not recoilIndicator then
		recoilIndicator = Instance.new("TextLabel")
		recoilIndicator.Parent = self.GunGui
		recoilIndicator.Name = "RecoilIndicator"
		recoilIndicator.Position = UDim2.new(0.25, 0, 0.5, 0)
		recoilIndicator.BackgroundTransparency = 1
	end
	self.RecoilIndicator = recoilIndicator

	self._primaryDown = false
end

function GunClient:UpdateMouseIcon()
	if self.Mouse and not self.Instance.Parent:IsA("Backpack") then
		self.Mouse.Icon = "rbxasset://textures/GunCursor.png"
	end
end

function GunClient:Aim(bool: boolean)
	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)
	self.Aiming = if bool == nil then not self.Aiming else bool
	-- print("aiming:", self.Aiming)

	local adsSpeed = 0.5

	UserInputService.MouseIconEnabled = not self.Aiming

	local tweeningInformation =
		TweenInfo.new(if self.Aiming then adsSpeed else adsSpeed / 2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local properties = { Value = if self.Aiming then 1 else 0 }

	TweenService:Create(viewmodel.LerpValues.Aiming, tweeningInformation, properties):Play()
end

function GunClient:_handleAimInput(actionName: string, userInputState: Enum.UserInputState, inputObject: InputObject)
	self:Aim(userInputState == Enum.UserInputState.Begin)
	return Enum.ContextActionResult.Sink
end

function GunClient:OnEquipped(mouse: Mouse)
	--print(self.Instance.Parent, "equipped", self.Instance.Name)

	self.Viewmodel = self._trove:Clone(ReplicatedStorage.Viewmodel)
	self.Viewmodel.Parent = self.Instance

	self.RecoilSpring = Spring.new(Vector3.new(0, 0, 0))
	self.RecoilSpring.Speed = 10
	self.RecoilSpring.Damper = 1
	self._lastOffset = Vector3.new()

	self.GunGui.Enabled = true
	self.Mouse = mouse
	self:UpdateMouseIcon()

	ContextActionService:BindAction("aim" .. self.Instance.Name, function(...)
		self:_handleAimInput(...)
	end, true, Enum.UserInputType.MouseButton2)

	RunService:BindToRenderStep("GunClientOnRenderStepped", Enum.RenderPriority.Camera.Value, function(...)
		self:OnRenderStepped(...)
	end)
end

function GunClient:OnRecoilEvent(verticalKick: number, horizontalKick: number)
	local viewmodel = ViewmodelClient:FromInstance(workspace.CurrentCamera.Viewmodel)
	viewmodel.Animations.Fire:Play()
	for _, v in pairs(viewmodel.Instance.WeaponRootPart:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v:Emit(v.Rate)
		end
	end
	local soundClone = self._trove:Clone(viewmodel.Instance:FindFirstChild("FireSound", true))
	soundClone.Parent = viewmodel.Instance.PrimaryPart
	Debris:AddItem(soundClone, soundClone.TimeLength)
	soundClone:Play()
	
	self.RecoilSpring:Impulse(Vector3.new(verticalKick * 5, horizontalKick * 5, 0))
	-- print(self.RecoilSpring.Position)
end

function GunClient:OnActivated()
	--print(self.Instance.Parent, "activated", self.Instance.Name)
	if self.Config:GetAttribute("FullyAutomatic") then
		self._primaryDown = true
	else
		self.MouseEvent:FireServer(self.Mouse.Hit.Position)
	end
end

function GunClient:OnDeactivated()
	--print(self.Instance.Parent, "deactivated", self.Instance.Name)
	self._primaryDown = false
end

function GunClient:OnUnequipped()
	--print(self.Instance.Parent, "unequipped", self.Instance.Name)

	self.Viewmodel:Destroy()

	ContextActionService:UnbindAction("aim" .. self.Instance.Name)
	RunService:UnbindFromRenderStep("GunClientOnRenderStepped")

	self.GunGui.Enabled = false
	self._primaryDown = false
	self:UpdateMouseIcon()
end

function GunClient:OnStepped(deltaTime: number)
	if self._primaryDown then
		self.MouseEvent:FireServer(self.Mouse.Hit.Position)
	end
end

local function toRoundedString(number: number): string
	local num = math.round(number)
	return tostring(num)
end

function GunClient:OnRenderStepped(deltaTime: number)
	local currentOffset = self.RecoilSpring.Position
	-- self.RecoilIndicator.Text = ("curr: "..toRoundedString(self.RecoilSpring.Position.X).."\n".."last: "..toRoundedString(self._lastOffset.X))
	workspace.CurrentCamera.CFrame *= CFrame.Angles(
		math.rad(currentOffset.X - self._lastOffset.X),
		math.rad(currentOffset.Y - self._lastOffset.Y),
		0
	)
	self._lastOffset = self.RecoilSpring.Position
end

function GunClient:Start()
	ViewmodelClient = require(script.Parent.ViewmodelClient)
	-- CameraController = Knit.GetController("CameraController")

	self._trove:Connect(self.RecoilEvent.OnClientEvent, function(...)
		self:OnRecoilEvent(...)
	end)
	self._trove:Connect(self.Instance.Activated, function(...)
		self:OnActivated(...)
	end)
	self._trove:Connect(self.Instance.Deactivated, function(...)
		self:OnDeactivated(...)
	end)
	self._trove:Connect(self.Instance.Equipped, function(...)
		self:OnEquipped(...)
	end)
	self._trove:Connect(self.Instance.Unequipped, function(...)
		self:OnUnequipped(...)
	end)
	self._trove:Connect(RunService.Stepped, function(...)
		self:OnStepped(...)
	end)
end

function GunClient:Stop()
	self._trove:Destroy()
end

return GunClient
