
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local KnockableClient = Component.new {
	Tag = "Knockable";
	Extensions = {
		Logger,
	};
}

function KnockableClient:Construct()
	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid")
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

return KnockableClient
