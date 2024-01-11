
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local Respawnable = Component.new {
	Tag = "Respawnable";
	Extensions = {
		Logger,
	};
}

function Respawnable:Construct()
	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid") :: Humanoid

	self.SpawnLocation = self.Instance:GetAttribute("SpawnLocation") or Vector3.zero
end

function Respawnable:Respawn()
	self.Humanoid.Health = self.Humanoid.MaxHealth
	self.Instance:PivotTo(CFrame.new(self.SpawnLocation))
end

return Respawnable
