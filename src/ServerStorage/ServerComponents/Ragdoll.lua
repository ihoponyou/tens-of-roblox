
local DEBUG = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local Ragdoll = Component.new({
	Tag = "Ragdoll",
	Extensions = {
		Logger,
	},
})

type RagdollJoint = {
	Motor: Motor6D,
	Socket: BallSocketConstraint,
}

function Ragdoll:Construct()
	self._trove = Trove.new()
	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid")
	self.Joints = {}
end

function Ragdoll:OnRagdolledChanged()
	local enabled = self.Instance:GetAttribute("Ragdolled")
	if enabled then
		self.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	else
		self.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	self:ToggleAllJoints(enabled)
end

function Ragdoll:OnDied()
	self:ToggleAllJoints(true)
end

function Ragdoll:_readJoints(torso: Part)
	for _, v: Instance in torso:GetChildren() do
		if not v:IsA("Motor6D") then continue end

		local socket = torso:FindFirstChild(v.Name:gsub(" ", "") .. "Socket")
		if not socket then
			if DEBUG then warn("Ragdoll setup @ "..self.Instance:GetFullName()..": no corresponding ballsocket to " .. v.Name) end
			continue
		end

		self.Joints[v.Name] = {
			Motor = v,
			Socket = socket,
		}

        -- need to clean up joints if the motor gets destroyed
        --      e.g. an explosion
		self._trove:Connect(v:GetPropertyChangedSignal("Parent"), (function()
			if v.Parent ~= nil then return end

			-- "amputate" the connected limb
			socket:Destroy()
			v.Part1.CanCollide = true

			self.Joints[v.Name] = nil
		end))
	end
end

function Ragdoll:Start()
	local torso: Part = self.Instance:FindFirstChild("Torso")
	if not torso then
		error("Ragdoll setup failed; no torso found")
	end

	self:_readJoints(torso)

	self.Humanoid.BreakJointsOnDeath = false
	self._trove:Connect(self.Instance:GetAttributeChangedSignal("Ragdolled"), function()
		self:OnRagdolledChanged()
	end)
end

function Ragdoll:ToggleJoint(jointName: string, loose: boolean?)
	local joint: RagdollJoint = self.Joints[jointName]
	if not joint then
		error("No joint of name " .. jointName)
	end

	loose = if loose == nil then not joint.Motor.Enabled else loose

	joint.Motor.Enabled = not loose
	joint.Motor.Part0.CanCollide = loose
end

function Ragdoll:ToggleAllJoints(loose: boolean?)
	local ragdolled = if loose == nil then not self.Instance:GetAttribute("Ragdolled") else loose

	for k, _: RagdollJoint in self.Joints do
		self:ToggleJoint(k, ragdolled)
		-- ragdolled = if enable == nil then not v.Motor.Enabled else enable
	end

	if ragdolled then
		self.Instance.PrimaryPart.AssemblyLinearVelocity = Vector3.new(100, 100, 100)
	end
end

function Ragdoll:Stop()
	self._trove:Destroy()
	self.Humanoid = nil
	self.Joints = nil
end

return Ragdoll
