
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local GetRandomPositionInPart = require(ReplicatedStorage.Source.Modules.GetRandomPositionInPart)
local Knockable = require(ServerStorage.Source.ServerComponents.Knockable)

local CHARACTER_FOLDER = ReplicatedStorage.Character
local RAND = Random.new(tick())

local NonplayerCharacter = Component.new({
	Tag = "NonplayerCharacter",
	Extensions = {
		Logger,
	},
})

function NonplayerCharacter:Construct()
	CollectionService:AddTag(self.Instance, "Ragdoll")
	CollectionService:AddTag(self.Instance, "Knockable")

	self._trove = Trove.new()

	self.Habitat = self.Instance.Parent

	self.Humanoid = Instance.new("Humanoid")
	self.Humanoid.Parent = self.Instance
	self.Humanoid.WalkSpeed = 8
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
	self.Humanoid.NameDisplayDistance = 10
	self.Humanoid.HealthDisplayDistance = 10
	self.Humanoid:ApplyDescriptionReset(CHARACTER_FOLDER.NoobDescription)
	self._trove:Add(self.Humanoid)

	local habitat = Instance.new("ObjectValue")
	habitat.Name = "Habitat"
	habitat.Parent = self.Instance
	habitat.Value = self.Habitat

	self._destination = Vector3.new()
	self._travelDelay = RAND:NextNumber(1, 5)
end

function NonplayerCharacter:Start()
	self.Knockable = self:GetComponent(Knockable)

	self._trove:Add(Timer.Simple(self._travelDelay, function()
		if self.Instance:GetAttribute("Knocked") then return end

		self._travelDelay = RAND:NextNumber(1, 5)

        self:_calculateDestination()
		self.Humanoid:MoveTo(self._destination)
    end, true))
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

function NonplayerCharacter:_calculateDestination()
	self._destination = GetRandomPositionInPart(self.Habitat)

    self.Instance:SetAttribute("Destination", self._destination)
end

return NonplayerCharacter
