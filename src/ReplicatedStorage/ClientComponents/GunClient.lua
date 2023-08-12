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

	self.RecoilSpring = Spring.new(Vector3.zero)
	self.RecoilSpring.Speed = 20
	self.RecoilIndicator = Instance.new("TextLabel")
	self.RecoilIndicator.Parent = Knit.Player.PlayerGui:WaitForChild("Main")
	self.RecoilIndicator.Name = "RecoilIndicator"
	self.RecoilIndicator.Position = UDim2.new(0.25, 0, 0.5, 0 )

	self._primaryDown = false
end

function GunClient:UpdateMouseIcon()
	if self.Mouse and not self.Instance.Parent:IsA("Backpack") then
		self.Mouse.Icon = "rbxasset://textures/GunCursor.png"
	end
end

function GunClient:OnEquipped(mouse: Mouse)
	--print(self.Instance.Parent, "equipped", self.Instance.Name)
	self.Mouse = mouse
	self:UpdateMouseIcon()
end

function GunClient:OnRecoilEvent(verticalKick: number, horizontalKick: number)
	self.RecoilSpring:Impulse(Vector3.new(verticalKick*5, horizontalKick, 0))
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
	self._primaryDown = false
	self:UpdateMouseIcon()
end

function GunClient:OnStepped(deltaTime: number)
	if self._primaryDown then
		self.MouseEvent:FireServer(self.Mouse.Hit.Position)
	end
end

function GunClient:OnRenderStepped(deltaTime: number)
	local springPosition = self.RecoilSpring.Position
	workspace.CurrentCamera.CFrame = CFrame.Angles(math.rad(springPosition.X), 0, 0) + workspace.CurrentCamera.CFrame.Position
	self.RecoilIndicator.Text = tostring(springPosition.X)
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
	self._trove:Connect(RunService.RenderStepped, function(...)
		self:OnRenderStepped(...)
	end)
end

function GunClient:Stop()
	self._trove:Destroy()
end

return GunClient
