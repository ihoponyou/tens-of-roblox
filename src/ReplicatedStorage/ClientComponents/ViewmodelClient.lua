
-- adapted code from BlackShibe's FPS Framework input/viewmodel controller to component system
-- https://devforum.roblox.com/t/writing-an-fps-framework-2020/503318

-- NOV 1 2023 | idk how much of it is from this anymore after big refactor but it was very helpful in getting started regardless

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)

local ViewmodelClient = Component.new({
	Tag = "Viewmodel",
	Extensions = {},
})


local EMPTY_CFRAME = CFrame.new()
local NO_YAXIS = Vector3.new(1, 0, 1)

type Offset = {
	Value: Vector3,
	Alpha: number -- between 0 and 1
}

function ViewmodelClient:Construct()
	self._trove = Trove.new()

	self.Visible = true

	self.Animations = {}
	self.Humanoid = self.Instance:WaitForChild("RigHumanoid")

	self.SwayScale = 1 -- determines how much sway to display
	self.SwaySensitivity = 1.4 -- scales sway with camera movement; lower will be less responsive and vice versa
	self.SwaySpring = Spring.new(Vector3.zero)
	self.SwaySpring.Speed = 25
	self.SwaySpring.Damper = .8 -- lower value = more bounce

	self.ViewbobScale = 1
	self._time = 0 -- argument for viewbob equations
	self._viewbobPosition = EMPTY_CFRAME
	self._viewbobRotation = EMPTY_CFRAME

	self._dragPosition = EMPTY_CFRAME

	self._lastFrameRotation = EMPTY_CFRAME -- the camera's rotation from the previous frame

	-- dictionary that tracks all applied offsets
	self.AppliedOffsets = {
		Base = {Value = self.Instance.BaseOffset.Value, Alpha = 1},
		Sway = {Value = EMPTY_CFRAME, Alpha = self.SwayScale},
		Viewbob = {Value = EMPTY_CFRAME, Alpha = self.ViewbobScale},
		Drag = {Value = EMPTY_CFRAME, Alpha = 1},
	}

	-- the m6d that rigs a world model to the viewmodel
	self.ModelJoint = nil
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

function ViewmodelClient:GetAnimation(animationName: string): AnimationTrack
	if type(animationName) ~= "string" then error("Invalid animation name") end
	local animationTrack = self.Animations[animationName]
	if animationTrack == nil then error("No loaded animation with name \""..animationName.."\"") end

	return self.Animations[animationName]
end

function ViewmodelClient:PlayAnimation(animationName: string, fadeTime: number?, weight: number?, speed: number?)
	local animationTrack = self:GetAnimation(animationName)
	animationTrack:Play(fadeTime or 0.100000001, weight or 1, speed or 1)
end

function ViewmodelClient:StopAnimation(animationName: string, fadeTime: number?)
	local animationTrack = self:GetAnimation(animationName)
	animationTrack:Stop(fadeTime or 0.100000001)
end

-- adds an offset to the viewmodel; alpha is like the "scale" of the offset
function ViewmodelClient:ApplyOffset(name: string, offset: CFrame, alpha: number)
	if type(name) ~= "string" then error("Invalid offset name") end
	if typeof(offset) ~= "CFrame" then error("Invalid offset value") end

	self.AppliedOffsets[name] = {
		Value = offset,
		Alpha = 0
	}

	self:SetOffsetAlpha(name, alpha)
end

function ViewmodelClient:UpdateOffset(name: string, offset: CFrame)
	if type(name) ~= "string" then error("Invalid offset name") end
	if typeof(offset) ~= "CFrame" then error("Invalid offset value") end
	local appliedOffset = self.AppliedOffsets[name]
	if not appliedOffset then error("No offset to update") end
	appliedOffset.Value = offset
end

-- removes an offset from the AppliedOffsets table if the offset exists; otherwise does nothing
function ViewmodelClient:RemoveOffset(name: string)
	if type(name) ~= "string" then error("Invalid offset name") end
	self.AppliedOffsets[name] = nil
end

-- sets the alpha of an applied offset
function ViewmodelClient:SetOffsetAlpha(name: string, alpha: number)
	local offset: Offset = self.AppliedOffsets[name]
	if not offset then error("no offset found with name: "..name) end
	if type(alpha) ~= "number" then error("Invalid offset alpha") end
	if alpha < 0 or alpha > 1 then error("Offset alpha outside of range [0, 1]: "..alpha) end
	offset.Alpha = alpha
end

-- model MUST HAVE A RootJoint
function ViewmodelClient:HoldModel(model: Model)
	local modelRootJoint: Motor6D = model:FindFirstChild("RootJoint", true)
	modelRootJoint.Part0 = self.Instance["Right Arm"]
	self.ModelJoint = modelRootJoint
end

function ViewmodelClient:ReleaseModel()
	self.ModelJoint.Part0 = nil
end

function ViewmodelClient:_updateSway()
	local camera = workspace.CurrentCamera

	local angleDelta: CFrame = Vector3.new(camera.CFrame.Rotation:ToObjectSpace(self._lastFrameRotation):ToOrientation()) * 150
	self.SwaySpring:Impulse(Vector3.new(angleDelta.Y, angleDelta.X, 0) * self.SwaySensitivity)
	local swaySpringPos = self.SwaySpring.Position
	self:ApplyOffset("Sway", CFrame.Angles(math.rad(swaySpringPos.Y), math.rad(swaySpringPos.X), 0), self.SwayScale)
end

function ViewmodelClient:_updateViewbob(deltaTime: number)
	local character = Players.LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local hrp = character.PrimaryPart
	if not hrp then return end

	-- https://www.desmos.com/calculator/arxdha4ccb
	local viewbobFrequency = 1
	local viewbobAmplitude = 1
	local walkVelocity = hrp.AssemblyLinearVelocity * NO_YAXIS
	local speedPercent = walkVelocity.Magnitude / humanoid.WalkSpeed -- what % of my max walk speed am i moving at

	if humanoid.MoveDirection.Magnitude == 0 then self._time = 0 end
	self._time += deltaTime * speedPercent

	if humanoid.MoveDirection.Magnitude ~= 0 then
		local viewbobX = 0.2 * viewbobAmplitude * math.sin(4 * self._time * viewbobFrequency)
		local viewbobY = 0.1 * viewbobAmplitude * math.sin(4 * self._time * viewbobFrequency * 2)
		self._viewbobPosition = CFrame.new(viewbobX, viewbobY, 0)
		-- self._viewbobRotation = CFrame.Angles(0, -viewbobX/3, 0)
	else
		self._viewbobPosition = self._viewbobPosition:Lerp(EMPTY_CFRAME, .25)
		-- self._viewbobRotation = self._viewbobRotation:Lerp(EMPTY_CFRAME, .4)
	end

	self:ApplyOffset("Viewbob", self._viewbobPosition * self._viewbobRotation, self.ViewbobScale)
end

function ViewmodelClient:_updateDrag()
	local character = Players.LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local hrp = character.PrimaryPart
	if not hrp then return end

	-- always a unit vector
	local wishDirection = hrp.CFrame:VectorToObjectSpace(humanoid.MoveDirection)

	local goal = CFrame.new(0, -0.1 * wishDirection.Magnitude, 0.2 * wishDirection.Magnitude)
	self._dragPosition = self._dragPosition:Lerp(goal, 0.1)

	self:UpdateOffset("Drag", self._dragPosition)
end

function ViewmodelClient:Update(deltaTime: number)
	local camera = workspace.CurrentCamera

	self:_updateSway()
	self:_updateViewbob(deltaTime)
	self:_updateDrag()

	local finalOffset = EMPTY_CFRAME
	for _, v: Offset in self.AppliedOffsets do
		finalOffset = finalOffset:Lerp((finalOffset * v.Value), v.Alpha)
	end
	self.Instance.RootPart.CFrame = workspace.CurrentCamera.CFrame * finalOffset

	self._lastFrameRotation = camera.CFrame.Rotation
end

function ViewmodelClient:Stop()
	self._trove:Destroy()
end

return ViewmodelClient
