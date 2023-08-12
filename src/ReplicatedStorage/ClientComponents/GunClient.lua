
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Logger = require(script.Parent.Extensions.Logger)

local GunClient = Component.new {
	Tag = "Gun";
	Extensions = {
		Logger,
	};
}



function GunClient:Construct()
	self._trove = Trove.new()
	
	self.MouseEvent = self.Instance:WaitForChild("MouseEvent")
	self.RecoilEvent = self.Instance:WaitForChild("RecoilEvent")
	self.Config = self.Instance:WaitForChild("Configuration")
	
    self.VerticalRecoilSpring = Spring.new()
	
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

function GunClient:OnRecoilEvent(horizontalKick: number, verticalKick: number)
	print(self.VerticalRecoilSpring)
    self.VerticalRecoilSpring:Impulse(verticalKick)
    print(self.VerticalRecoilSpring)
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
	local camera = workspace.CurrentCamera
end

function GunClient:Start()
	self._trove:Connect(self.RecoilEvent.OnClientEvent, function(...) self:OnRecoilEvent(...) end)
	self._trove:Connect(self.Instance.Activated, function(...) self:OnActivated(...) end)
	self._trove:Connect(self.Instance.Deactivated, function(...) self:OnDeactivated(...) end)
	self._trove:Connect(self.Instance.Equipped, function(...) self:OnEquipped(...) end)
	self._trove:Connect(self.Instance.Unequipped, function(...) self:OnUnequipped(...) end)
	self._trove:Connect(RunService.Stepped, function(...) self:OnStepped(...) end)
	self._trove:Connect(RunService.RenderStepped, function(...) self:OnRenderStepped(...) end)
end

function GunClient:Stop()
	self._trove:Destroy()
end

return GunClient
