
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)


local NonplayerCharacter = Component.new({
	Tag = "NonplayerCharacter",
	Extensions = {
		Logger,
	},
})

local RAND = Random.new(tick())

function NonplayerCharacter:Construct()
	self._trove = Trove.new()

	self.Habitat = self.Instance.Parent
end

function NonplayerCharacter:Start()
	Timer.Simple(5, function()
        self:_calculateDestination()
    end, true)
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

function NonplayerCharacter:_calculateDestination()
    local xOffset = self.Habitat.Size.X/2 * RAND:NextNumber(-1, 1)
    local zOffset = self.Habitat.Size.Z/2 * RAND:NextNumber(-1, 1)
	local destination = self.Habitat.CFrame.Position + Vector3.new(xOffset, 0, zOffset)
    self.Instance:SetAttribute("Destination", destination)
end

return NonplayerCharacter
