
-- adapted code from BlackShibe's FPS Framework input/viewmodel controller to component system
-- https://devforum.roblox.com/t/writing-an-fps-framework-2020/503318

-- NOV 1 2023 | idk how much of it is from this anymore after big refactor but it was very helpful in setting it up regardless

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)

local ViewmodelClient = Component.new({
	Tag = "Viewmodel",
	Extensions = {},
})

function ViewmodelClient:Construct()
	self.Visible = true

	self.Animations = {}
	self.Humanoid = self.Instance:WaitForChild("RigHumanoid")

	self.PositionOffset = Vector3.new()
	self.RotationOffset = Vector3.new() -- xyz angles in radians

	self._trove = Trove.new()

	self.SwaySpring = Spring.new(Vector3.new()) -- "sways" viewmodel in response to mouse movement
	self.SwaySpring.Speed = 20
	self.SwaySpring.Damper = .75 -- lower value = more bounce
end

function ViewmodelClient:Start()
	self.Instance.Parent = workspace.CurrentCamera

    self._trove:Connect(RunService.RenderStepped, function(...) self:Update(...) end)
end

function ViewmodelClient:ToggleVisibility(show: boolean)
	self.Visible = if show==nil then not self.Visible else show
	self.Instance["Right Arm"].Transparency = if self.Visible then 0 else 1
	self.Instance["Left Arm"].Transparency = if self.Visible then 0 else 1
end

function ViewmodelClient:LoadAnimations(animationFolder: Folder)
	-- empty current animation dict
	self.Animations = {}

	for _,v in animationFolder:GetDescendants() do
		if not v:IsA("Animation") then continue end
		-- index each animation with its name as key and animationtrack as value
		self.Animations[v.Name] =  self.Humanoid:LoadAnimation(v)
	end
end

function ViewmodelClient:PlayAnimation(animationName: string)
	if animationName == nil or type(animationName) ~= "string" then error("Invalid animation name") end
	local animationTrack: AnimationTrack = self.Animations[animationName]
	if animationTrack == nil then error("No loaded animation with name \""..animationName.."\"") end
	animationTrack:Play()
end

local startTick = 0
function ViewmodelClient:Update(deltaTime: number)
	local mouseDelta = UserInputService:GetMouseDelta()
	local character = Players.LocalPlayer.Character
	if not character then return end
	local humanoid = character.Humanoid
	local humanoidSpeed = humanoid.WalkSpeed*humanoid.MoveDirection.Magnitude
	-- if humanoid.MoveDirection.Magnitude < .1 then startTick = tick() end -- this allows the sine to be zero every time the player starts moving (thanks desmos)

	local baseOffset: CFrame = self.Instance.BaseOffset.Value
	--local aimOffset = baseOffset:Lerp(self.Instance.Offsets.Aiming.Value, self.LerpValues.Aiming.Value)

	self.SwaySpring:Impulse(Vector3.new(mouseDelta.X, mouseDelta.Y, 0))
	local swaySpringPos = self.SwaySpring.Position

	local swayOffset = CFrame.Angles(math.rad(swaySpringPos.Y), math.rad(swaySpringPos.X), 0)
						* CFrame.new(swaySpringPos.X/25, 0, 0)

	-- local viewbobArgs = (tick()-startTick)*(humanoidSpeed)/4
	-- local viewbobScale = 1/6
	-- local viewbobX = math.sin(viewbobArgs)*viewbobScale -- different functions to do a figure 8
	-- local viewbobY = math.sin(viewbobArgs*2)*viewbobScale/2

	-- local viewbobOffset = CFrame.new(viewbobX/2, viewbobY, 0)
	-- 					* CFrame.Angles(viewbobY/3, -viewbobX/2, 0)

	local totalOffset = CFrame.new(self.PositionOffset)
						* CFrame.Angles(self.RotationOffset.X, self.RotationOffset.Y, self.RotationOffset.Z)

	local finalOffset = swayOffset * totalOffset
	self.Instance.RootPart.CFrame = workspace.CurrentCamera.CFrame * baseOffset * finalOffset
end

function ViewmodelClient:Stop()
	self._trove:Destroy()
end

return ViewmodelClient
