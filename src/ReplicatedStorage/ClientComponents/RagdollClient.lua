
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local RagdollClient = Component.new {
	Tag = "Ragdoll";
	Extensions = {
		Logger,
	};
}

function RagdollClient:Construct()
	self._trove = Trove.new()
	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid")
end

function RagdollClient:Start()
	self._trove:Connect(self.Instance:GetAttributeChangedSignal("Ragdolled"), function() self:_onRagdolledChanged() end)
end

function RagdollClient:Stop()
	self._trove:Destroy()
end

function RagdollClient:_onRagdolledChanged()
	local enabled = self.Instance:GetAttribute("Ragdolled")

	local state = if enabled then Enum.HumanoidStateType.Physics else Enum.HumanoidStateType.GettingUp
	self.Humanoid:ChangeState(state)
end

return RagdollClient
