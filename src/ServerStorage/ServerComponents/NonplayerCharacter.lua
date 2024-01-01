
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
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
	local habitat = Instance.new("ObjectValue")
	habitat.Name = "Habitat"
	habitat.Parent = self.Instance
	habitat.Value = self.Habitat

	self.Humanoid = Instance.new("Humanoid")
	self.Humanoid.Parent = self.Instance
	self.Humanoid.WalkSpeed = RAND:NextInteger(8, 24)
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
	self.Humanoid.NameDisplayDistance = 10
	self.Humanoid.HealthDisplayDistance = 10
	self.Humanoid:ApplyDescriptionReset(CHARACTER_FOLDER.NoobDescription)
	self._trove:Add(self.Humanoid)

	self.CurrentState = function() print("override this") end
	self._target = nil
	self._destination = Vector3.new()
	-- time between npc heartbeats
	self._heartbeatDelay = RAND:NextNumber(1, 5)
	-- time that has passed since last npc heartbeat
	self._heartbeatTime = 0

	self._searchParams = OverlapParams.new()
	self._searchParams.CollisionGroup = "Character"
	self._searchParams.FilterDescendantsInstances = { self.Instance }
	self._searchParams.FilterType = Enum.RaycastFilterType.Exclude
end

function NonplayerCharacter:Start()
	self.Knockable = self:GetComponent(Knockable)

	self.CurrentState = self.Wandering
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

function NonplayerCharacter:HeartbeatUpdate(deltaTime: number)
	self._heartbeatTime += deltaTime
	if self._heartbeatTime < self._heartbeatDelay then return end
	self._heartbeatTime = 0

	self:CurrentState()
end

function NonplayerCharacter:SearchForTarget()
	for _,player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end

		local distance = (character.PrimaryPart.Position - self.Instance.PrimaryPart.Position).Magnitude
		if distance <= 50 then
			print(self.Instance.Name..": target found")
			self._target = character
		end
	end
end

function NonplayerCharacter:Wandering()
	self:SearchForTarget()

	if self._target == nil then
		self._heartbeatDelay = RAND:NextNumber(1, 3)
		self:_calculateDestination()
		self.Humanoid:MoveTo(self._destination)
	else
		self.CurrentState = self.Following
	end
end

function NonplayerCharacter:Jumping()
	
end

function NonplayerCharacter:Following()
	self._heartbeatDelay = 0.1

	local targetRoot = self._target.PrimaryPart
	local targetVelocity = targetRoot.AssemblyLinearVelocity
	local projectedPosition = targetRoot.CFrame.Position + targetVelocity

	self.Humanoid:MoveTo(projectedPosition)
end

function NonplayerCharacter:_calculateDestination()
	self._destination = GetRandomPositionInPart(self.Habitat)

    self.Instance:SetAttribute("Destination", self._destination)
end

return NonplayerCharacter
