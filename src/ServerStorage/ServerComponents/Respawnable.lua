
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
	self._trove = Trove.new()

	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid") :: Humanoid

	self.SpawnLocation = Vector3.zero
end

function Respawnable:Start()

end

function Respawnable:Stop()
	self._trove:Clean()
end

-- refill health, teleport to spawn location
function Respawnable:Respawn()
	self.Humanoid.Health = self.Humanoid.MaxHealth
	self.Instance:PivotTo(CFrame.new(self.SpawnLocation))
end

return Respawnable
