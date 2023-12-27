
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local DEBUG = false
local SOCKET_ANGLES = {
	Hip = {
		UpperAngle = 30;
		TwistAngle = 135;
	};
	Shoulder = {
		UpperAngle = 100;
	};
	Neck = {
		UpperAngle = 10;
		TwistAngle = 30;
	};
}

local Ragdoll = Component.new({
	Tag = "Ragdoll",
	Extensions = {
		Logger,
	},
})

type RagdollJoint = {
	Motor: Motor6D;
	Socket: BallSocketConstraint;
	DragDetector: DragDetector;
}

function Ragdoll:Construct()
	-- new instances; base types then instances
	self.IsRagdolled = false
	self._joints = {}

	self._trove = Trove.new()

	-- existing instances
	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid")
	self.Humanoid.BreakJointsOnDeath = false

	for _, motor: Motor6D in self.Instance:GetDescendants() do
		if not motor:IsA("Motor6D") then continue end
		if motor.Name == "RootJoint" then continue end
		local socketType = motor.Name:match("Hip") or motor.Name:match("Shoulder") or motor.Name:match("Neck")
		local jointName = motor.Name:gsub(" ", "")

		local attachment0 = Instance.new("Attachment")
		attachment0.Name = jointName.."Attachment0"
		attachment0.Parent = motor.Part0
		-- attachment0.Visible = true

		local attachment1 = Instance.new("Attachment")
		attachment1.Name = jointName.."Attachment1"
		attachment1.Parent = motor.Part1
		-- attachment1.Visible = true

		if socketType == "Hip" then
			local c0Position = motor.C0.Position
			local legC0 = CFrame.new(c0Position.X/2, c0Position.Y, c0Position.Z) * motor.C0.Rotation
			attachment0.CFrame = legC0

			local c1Position = motor.C1.Position
			local legC1 = CFrame.new(0, c1Position.Y, c1Position.Z) * motor.C1.Rotation
			attachment1.CFrame = legC1
		else
			attachment0.CFrame = motor.C0
			attachment1.CFrame = motor.C1
		end

		local socket = Instance.new("BallSocketConstraint")
		socket.Name = jointName.."Socket"
		socket.Parent = motor.Part1
		socket.Attachment0 = attachment0
		socket.Attachment1 = attachment1
		socket.LimitsEnabled = true
		socket.MaxFrictionTorque = 100
		socket.Restitution = 0.25
		socket.UpperAngle = SOCKET_ANGLES[socketType].UpperAngle
		socket.TwistLimitsEnabled = socketType ~= "Shoulder"
		if socket.TwistLimitsEnabled then
			local twistAngle = SOCKET_ANGLES[socketType].TwistAngle
			socket.TwistUpperAngle = twistAngle
			socket.TwistLowerAngle = -twistAngle
		end

		local drag = Instance.new("DragDetector")
		drag.Parent = motor.Part1
		drag.Enabled = false
		drag.DragStyle = Enum.DragDetectorDragStyle.TranslateViewPlane
		drag.Responsiveness = 10

		self._joints[jointName] = {
			Motor = motor;
			Socket = socket;
			DragDetector = drag;
		}

		-- need to clean up joints if the motor gets destroyed
        --      e.g. an explosion
		self._trove:Connect(motor:GetPropertyChangedSignal("Parent"), (function()
			if motor.Parent ~= nil then return end

			-- "amputate" the connected limb
			socket:Destroy()
			motor.Part1.CanCollide = true

			self._joints[motor.Name] = nil
		end))
	end

	self._trove:Connect(self.Instance:GetAttributeChangedSignal("Ragdolled"), function()
		self:_onRagdolledChanged()
	end)
end

function Ragdoll:_onRagdolledChanged()
	local enabled = self.Instance:GetAttribute("Ragdolled")

	local state = if enabled then Enum.HumanoidStateType.Physics else Enum.HumanoidStateType.GettingUp
	self.Humanoid:ChangeState(state)
	self.Humanoid.AutoRotate = not enabled

	self:ToggleAllJoints(enabled)
end

function Ragdoll:ToggleJoint(jointName: string, loose: boolean)
	local joint: RagdollJoint = self._joints[jointName]
	if not joint then
		error("No joint of name " .. jointName)
	end

	joint.Motor.Enabled = not loose
	joint.Motor.Part1.CanCollide = loose
	joint.DragDetector.Enabled = loose
end

function Ragdoll:ToggleAllJoints(loose: boolean)
	for k, _: RagdollJoint in self._joints do
		self:ToggleJoint(k, loose)
	end

	if loose then
		local rootPart = self.Instance.PrimaryPart
		rootPart.AssemblyLinearVelocity = rootPart.CFrame.UpVector * 25 + rootPart.CFrame.LookVector * -25
	end
end

function Ragdoll:Stop()
	self._trove:Destroy()
end

return Ragdoll
