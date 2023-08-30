
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

local GunClient

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
    self.Character = Knit.Player.Character

	self.Animations = {}

	self.SwaySpring = Spring.new(Vector3.new())
	self.SwaySpring.Speed = 20
	self.SwaySpring.Damper = .75 -- lower value = more bounce

	self.ViewbobSpring = Spring.new(0)
	self.ViewbobSpring.Speed = 10
	self.ViewbobSpring.Damper = 1

	self.LerpValues = {
		Aiming = Instance.new("NumberValue")
	}

    -- cant clone parts directly or else welds/m6ds get messed up
    local modelClone = self._trove:Clone(ReplicatedStorage.Weapons[self.Instance.Parent.Name])
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
	self.Enabled = if bool==nil then not self.Enabled else bool
end

function ViewmodelClient:Start()
	GunClient = require(script.Parent.GunClient)

	self.Gun = GunClient:FromInstance(self.Instance.Parent)

	for _,v in self.Instance.Animations:GetChildren() do
		if not v:IsA("Animation") then continue end
        self.Animations[v.Name] = self._trove:Add(self.Instance.AnimationController:LoadAnimation(v))
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

local startTick = 0
function ViewmodelClient:Update(deltaTime: number)
	local mouseDelta = UserInputService:GetMouseDelta()
	local humanoid = self.Character.Humanoid
	local modifier = if self.Gun.Aiming then .1 else .5
	local humanoidSpeed = humanoid.WalkSpeed*humanoid.MoveDirection.Magnitude
	if humanoid.MoveDirection.Magnitude < .1 then startTick = tick() end -- this allows the sine to be zero every time the player starts moving (thanks desmos)

	local baseOffset: CFrame = self.Instance.Offsets.Base.Value
	local aimOffset = baseOffset:Lerp(self.Instance.Offsets.Aiming.Value, self.LerpValues.Aiming.Value)

	self.SwaySpring:Impulse(Vector3.new(mouseDelta.X, mouseDelta.Y, 0)*if self.Gun.Aiming then 0.5 else 3)
	local swaySpringPos = self.SwaySpring.Position

	local swayOffset = CFrame.Angles(math.rad(swaySpringPos.Y), math.rad(swaySpringPos.X), 0)

	local viewbobArgs = (tick()-startTick)*(humanoidSpeed)/4
	local viewbobScale = modifier/6
	local viewbobX = math.sin(viewbobArgs)*viewbobScale -- different functions to do a figure 8
	local viewbobY = math.sin(viewbobArgs*2)*viewbobScale/2

	local viewbobOffset = CFrame.new(viewbobX/2, viewbobY, 0)
						-- * CFrame.Angles(viewbobY/3, -viewbobX/2, 0)

	local finalOffset = aimOffset * swayOffset * viewbobOffset
	self.Instance.RootPart.CFrame = self.Camera.CFrame * finalOffset
end

function ViewmodelClient:Stop()
	self._trove:Destroy()
end

return ViewmodelClient
