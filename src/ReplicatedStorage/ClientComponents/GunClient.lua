local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Logger = require(script.Parent.Extensions.Logger)

local CameraController

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
		recoilIndicator.Position = UDim2.new(0.25, 0, 0.5, 0 )
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

function GunClient:OnEquipped(mouse: Mouse)
	--print(self.Instance.Parent, "equipped", self.Instance.Name)

	self.Viewmodel = self._trove:Clone(ReplicatedStorage.Viewmodel)
	self.Viewmodel.Parent = self.Instance

	self.RecoilSpring = Spring.new(Vector3.new(0,0,0))
	self.RecoilSpring.Speed = 10
	self.RecoilSpring.Damper = 1
	self._lastOffset = Vector3.new()

	self.GunGui.Enabled = true
	self.Mouse = mouse
	self:UpdateMouseIcon()

	RunService:BindToRenderStep("GunClientOnRenderStepped", Enum.RenderPriority.Camera.Value, function(...)
		self:OnRenderStepped(...)
	end)
end

function GunClient:OnRecoilEvent(verticalKick: number, horizontalKick: number)
	self.RecoilSpring:Impulse(Vector3.new(verticalKick*5, horizontalKick*5, 0))
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
	workspace.CurrentCamera.CFrame *= CFrame.Angles(math.rad(currentOffset.X-self._lastOffset.X), math.rad(currentOffset.Y-self._lastOffset.Y), 0)
	self._lastOffset = self.RecoilSpring.Position
end

function GunClient:Start()
	CameraController = Knit.GetController("CameraController")

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
