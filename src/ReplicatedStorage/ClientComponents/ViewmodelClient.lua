
-- adapted code from BlackShibe's FPS Framework input/viewmodel controller to component system
-- https://devforum.roblox.com/t/writing-an-fps-framework-2020/503318

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Logger = require(script.Parent.Extensions.Logger)

local ViewmodelClient = Component.new({
	Tag = "Viewmodel",
	Extensions = {
		Logger,
	},
})

function ViewmodelClient:Construct()
	self._trove = Trove.new()

	self.Enabled = false
    self.Camera = workspace.CurrentCamera
    self.Character = Knit.Player

	self.Animations = {}

	self.SwaySpring = Spring.new(Vector3.new(0,0,0))
	self.SwaySpring.Speed = 20
	self.SwaySpring.Damper = 1

    -- cant clone parts directly or else welds/m6ds get messed up
    local modelClone = self._trove:Clone(ReplicatedStorage.Viewmodels[self.Instance.Parent.Name])
    for _,v in modelClone:GetChildren() do
        v.Parent = self.Instance
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.CastShadow = false
		end
	end
    modelClone:Destroy()
end

function ViewmodelClient:Toggle(bool: boolean)
	self.Enabled = if bool ~= nil then bool else not self.Enabled
end

function ViewmodelClient:Start()
	for _,v in self.Instance.Animations:GetChildren() do
        self.Animations[v.Name] = self._trove:Add(self.Instance.AnimationController:LoadAnimation(v))
		self.Animations[v.Name]:Play()
    end
	
	self.Animations.Idle:Play(0, 1, 1)
	self.Instance.RootPart.CFrame = CFrame.new(0,-100,0)

	self.Instance.RootPart.WeaponJoint.Part1 = self.Instance.WeaponRootPart
	self.Instance["Left Arm"].LeftHand.Part0 = self.Instance.WeaponRootPart
	self.Instance["Right Arm"].RightHand.Part0 = self.Instance.WeaponRootPart

	self.Instance.Parent = workspace.Camera

    self._trove:Connect(RunService.RenderStepped, function(...)
        self:Update(...)
    end)
end

function ViewmodelClient:Update(deltaTime: number)
	local mouseDelta = UserInputService:GetMouseDelta()
	self.SwaySpring:Impulse(Vector3.new(mouseDelta.X, mouseDelta.Y, 0)*2)
	local swaySpringPos = self.SwaySpring.Position

	local finalOffset = self.Instance.Offsets.Base.Value * CFrame.Angles(math.rad(swaySpringPos.Y), math.rad(swaySpringPos.X), 0)
	self.Instance.RootPart.CFrame = self.Camera.CFrame:ToWorldSpace(finalOffset)
end

function ViewmodelClient:Stop()
	self._trove:Destroy()
end

return ViewmodelClient
