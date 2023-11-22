
local DEBUG = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(script.Parent.Extensions.Logger)

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
end

function Ragdoll:OnDied()
	self:ToggleAllJoints(false)
end

function Ragdoll:Start()
	local torso: Part = self.Instance:FindFirstChild("Torso")
	if not torso then
		error("Ragdoll setup failed; no torso found")
	end

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

	self.Humanoid.BreakJointsOnDeath = false
	self._trove:Connect(self.Humanoid.Died, function()
		self:OnDied()
	end)
end

function Ragdoll:ToggleJoint(jointName: string, enable: boolean?)
	local joint: RagdollJoint = self.Joints[jointName]
	if not joint then
		error("No joint of name " .. jointName)
	end

	joint.Motor.Enabled = if enable == nil then not joint.Motor.Enabled else enable
end

function Ragdoll:ToggleAllJoints(enable: boolean?)
	local ragdolled = if enable == nil then not self.Instance:GetAttribute("Ragdolled") else enable
	for k, v: RagdollJoint in self.Joints do
		self:ToggleJoint(k, if enable == nil then not v.Motor.Enabled else enable)
		ragdolled = if enable == nil then not v.Motor.Enabled else enable
	end

	self.Instance:SetAttribute("Ragdolled", ragdolled)
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
