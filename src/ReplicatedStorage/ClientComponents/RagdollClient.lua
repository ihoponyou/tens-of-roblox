
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(script.Parent.Extensions.Logger)

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

function RagdollClient:OnRagdolledChanged()
	local enabled = self.Instance:GetAttribute("Ragdolled")
	if enabled then
		self.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	else
		self.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

function RagdollClient:Start()
	self._trove:Connect(self.Instance:GetAttributeChangedSignal("Ragdolled"), function() self:OnRagdolledChanged() end)
end

return RagdollClient
