
-- adapted code from BlackShibe's FPS Framework input/viewmodel controller to component system
-- https://devforum.roblox.com/t/writing-an-fps-framework-2020/503318

-- NOV 01 2023 | idk how much of it is from this anymore after big refactor but it was very helpful in getting started regardless
-- DEC 21 2023 | doubt any of it remains but still -   -   -   -   -   -   -   -   -   ^

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Spring = require(ReplicatedStorage.Packages.Spring)

local AnimationManager = require(ReplicatedStorage.Source.Modules.AnimationManager)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local OffsetManager = require(ReplicatedStorage.Source.Modules.OffsetManager)

local ViewmodelClient = Component.new({
	Tag = "Viewmodel",
	Extensions = {},
})

local EMPTY_CFRAME = CFrame.new()
local NO_YAXIS = Vector3.new(1, 0, 1)

export type Offset = {
	Value: Vector3,
	Alpha: number -- between 0 and 1
}

function ViewmodelClient:Construct()
	self._trove = Trove.new()

	local animator = Find.path(self.Instance, "RigHumanoid/Animator")
	self.AnimationManager = AnimationManager.new(animator)
	self._trove:Add(self.AnimationManager)

	self.OffsetManager = OffsetManager.new()
	self._trove:Add(self.OffsetManager)

	self.Visible = false
	self.HeldModel = nil

	self.SwayScale = 1 -- determines how much sway to display
	self.SwaySensitivity = 1.4 -- scales sway with camera movement; lower will be less responsive and vice versa
	self.SwaySpring = Spring.new(Vector3.zero)
	self.SwaySpring.Speed = 25
	self.SwaySpring.Damper = .8 -- lower value = more bounce

	self.ViewbobScale = 1
	self._time = 0 -- argument for viewbob equations
	self._viewbobPosition = EMPTY_CFRAME
	self._viewbobRotation = EMPTY_CFRAME

	self.PullScale = 1
	self._pullPosition = EMPTY_CFRAME

	self.OffsetManager:AddOffsets({
		Base = {Value = self.Instance.BaseOffset.Value, Alpha = 1};
		Sway = {Value = EMPTY_CFRAME, Alpha = self.SwayScale};
		Viewbob = {Value = EMPTY_CFRAME, Alpha = self.ViewbobScale};
		Pull = {Value = EMPTY_CFRAME, Alpha = self.PullScale};
	})

	self._lastFrameRotation = EMPTY_CFRAME -- the camera's rotation from the previous frame
end

function ViewmodelClient:Start()
	self:ToggleVisibility(self.Visible)
	self.Instance.Parent = workspace.CurrentCamera
end

function ViewmodelClient:_changeHeldModelTransparency(transparency: number)
	if self.HeldModel == nil then return end
	for _, v: BasePart in self.HeldModel:GetDescendants() do
		if not v:IsA("BasePart") then continue end
		v.Transparency = transparency
	end
end

function ViewmodelClient:ToggleVisibility(show: boolean)
	self.Visible = if show==nil then not self.Visible else show
	local transparency = if self.Visible then 0 else 1
	self.Instance["Right Arm"].Transparency = transparency
	self.Instance["Left Arm"].Transparency = transparency

	self:_changeHeldModelTransparency(transparency)
end

function ViewmodelClient:HoldModel(modelToHold: Model)
	if type(modelToHold) ~= "userdata" then error("Given \"model\" is a primitive type or nil") end
	if not modelToHold:IsA("Model") then error("Given \"model\" is not of class Model") end

	local modelRoot = modelToHold.PrimaryPart
	if not modelRoot then error(modelToHold.Name.." has nil PrimaryPart") end

	local rootJoint: Motor6D = modelRoot:FindFirstChild("RootJoint")
	if not rootJoint then error(modelToHold.Name.." is missing a RootJoint") end

	local scale = modelToHold:GetAttribute("ViewmodelScale")
	if not scale then
		warn(modelToHold, "does not have a set viewmodel scale")
	else
		modelToHold:ScaleTo(scale)
	end

	modelToHold.Parent = self.Instance
	rootJoint.Part0 = self.Instance["Right Arm"]
	rootJoint.C0 = rootJoint:GetAttribute("ViewmodelEquippedC0")
	self.HeldModel = modelToHold

	for _, part: BasePart in self.HeldModel:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CastShadow = false
    end

	if self.Visible then return end
	self:_changeHeldModelTransparency(1)
end

function ViewmodelClient:ReleaseModel(modelToRelease: Model, newParent: Instance?)
	if type(modelToRelease) ~= "userdata" then error("Given \"model\" is a primitive type or nil") end
	if not modelToRelease:IsA("Model") then error("Given \"model\" is not of class Model") end
	if self.HeldModel ~= modelToRelease then warn("Viewmodel is not holding", modelToRelease) return end

	local modelRoot = self.HeldModel.PrimaryPart
	local rootJoint = modelRoot.RootJoint

	for _, part: BasePart in self.HeldModel:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CastShadow = true
    end

	local scale = modelToRelease:GetAttribute("WorldScale")
	if not scale then
		warn(modelToRelease, "does not have a set viewmodel scale")
	else
		modelToRelease:ScaleTo(scale)
	end

	self.HeldModel.Parent = newParent
	rootJoint.Part0 = nil
	self.HeldModel = nil

	self.AnimationManager:StopPlayingAnimations(0)

	if self.Visible then return end
	self:_changeHeldModelTransparency(0)
end

-- when you look around the gun lags as if it had weight
function ViewmodelClient:_updateSway()
	local camera = workspace.CurrentCamera

	local angleDelta: CFrame = Vector3.new(camera.CFrame.Rotation:ToObjectSpace(self._lastFrameRotation):ToOrientation()) * 150
	self.SwaySpring:Impulse(Vector3.new(angleDelta.Y, angleDelta.X, 0) * self.SwaySensitivity)
	local swaySpringPos = self.SwaySpring.Position

	local swayOffset = CFrame.Angles(math.rad(swaySpringPos.Y), math.rad(swaySpringPos.X), 0)
	self.OffsetManager:SetOffsetValue("Sway", swayOffset)
	self.OffsetManager:SetOffsetAlpha("Sway", self.SwayScale)
end

-- when you walk around the gun bobs up and down side to side
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
		self._viewbobPosition = self._viewbobPosition:Lerp(EMPTY_CFRAME, .1)
		-- self._viewbobRotation = self._viewbobRotation:Lerp(EMPTY_CFRAME, .4)
	end

	self.OffsetManager:SetOffsetValue("Viewbob", self._viewbobPosition * self._viewbobRotation)
	self.OffsetManager:SetOffsetAlpha("Viewbob", self.ViewbobScale)
end

-- when you walk around you pull the gun towards you
function ViewmodelClient:_updatePull()
	local character = Players.LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local hrp = character.PrimaryPart
	if not hrp then return end

	local wishDirection = hrp.CFrame:VectorToObjectSpace(humanoid.MoveDirection) -- always a unit vector
	local actualSpeed = hrp.AssemblyLinearVelocity.Magnitude
	local positionMultiplier = wishDirection.Magnitude * math.min(actualSpeed, 1)

	local goal = CFrame.new(0, -0.1 * positionMultiplier, 0.2 * positionMultiplier)
	self._pullPosition = self._pullPosition:Lerp(goal, 0.1)

	self.OffsetManager:SetOffsetValue("Pull", self._pullPosition)
	self.OffsetManager:SetOffsetAlpha("Pull", self.PullScale)
end

function ViewmodelClient:RenderSteppedUpdate(deltaTime: number)
	self.OffsetManager:SetOffsetValue("Base", self.Instance.BaseOffset.Value)

	self:_updateSway()
	self:_updateViewbob(deltaTime)
	self:_updatePull()

	local camera = workspace.CurrentCamera
	local combinedOffset = self.OffsetManager:GetCombinedOffset()
	self.Instance.RootPart.CFrame = workspace.CurrentCamera.CFrame * combinedOffset

	self._lastFrameRotation = camera.CFrame.Rotation
end

function ViewmodelClient:Stop()
	self._trove:Destroy()
end

return ViewmodelClient
