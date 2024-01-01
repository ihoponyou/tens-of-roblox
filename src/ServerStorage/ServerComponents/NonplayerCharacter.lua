
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local VectorMath = require(ReplicatedStorage.Source.Modules.VectorMath)
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
	-- self.Instance:SetAttribute("Log", true)

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
	self._heartbeatDelay = 0.2
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
	if not self.Instance.PrimaryPart then
		self.Instance:Destroy()
		return
	end

	-- self._heartbeatTime += deltaTime
	-- if self._heartbeatTime < self._heartbeatDelay then return end
	-- self._heartbeatTime = 0

	self:CurrentState()
end

function NonplayerCharacter:SearchForTarget()
	for _,player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end

		local distance = (character.PrimaryPart.Position - self.Instance.PrimaryPart.Position).Magnitude
		if distance <= 50 then
			self._target = character
			CollectionService:AddTag(self._target, "Targeted")
		end
	end
end

function NonplayerCharacter:Wandering()
	self:SearchForTarget()

	if self._target ~= nil then
		self.CurrentState = self.Following
		return
	end

	local alignedVelocty = Vector3.zero-- self:GetAlignedVelocity()

	if alignedVelocty.Magnitude > 0 then
		self.Humanoid:Move(alignedVelocty)
	else
		local myRoot = self.Instance.PrimaryPart
		local floorCast = workspace:Raycast(myRoot.CFrame.Position + myRoot.CFrame.LookVector, Vector3.yAxis * -5)

		self.Humanoid:Move(if floorCast ~= nil then myRoot.CFrame.LookVector else -self.Humanoid.MoveDirection)
	end
end

function NonplayerCharacter:Following()
	self._heartbeatDelay = 0.1

	local targetRoot = self._target.PrimaryPart
	-- local targetVelocity = targetRoot.AssemblyLinearVelocity
	-- local projectedPosition = targetRoot.CFrame.Position + targetVelocity * self._heartbeatDelay

	self.Humanoid:MoveTo(targetRoot.CFrame.Position, targetRoot)
end

function NonplayerCharacter:_calculateDestination()
	self._destination = GetRandomPositionInPart(self.Habitat)

    self.Instance:SetAttribute("Destination", self._destination)
end

function NonplayerCharacter:GetAlignedVelocity(): Vector3
	local resultant = { X = 0, Y = 0, Z = 0 }
	local neighborCount = 0

	for _, agent: Model in CollectionService:GetTagged("NonplayerCharacter") do
		if agent == self.Instance then continue end
		if agent.PrimaryPart == nil then continue end

		local distanceToAgent = VectorMath.DistanceBetweenParts(agent.PrimaryPart, self.Instance.PrimaryPart)
		if distanceToAgent <= 10 then
			local agentVelocity = agent.PrimaryPart.AssemblyLinearVelocity
			resultant.X += agentVelocity.X
			resultant.Z += agentVelocity.Z
			neighborCount += 1
		end
	end

	if neighborCount == 0 then
		return Vector3.new()
	end

	resultant.X /= neighborCount
	resultant.Z /= neighborCount
	local resultantVector = Vector3.new(resultant.X, 0, resultant.Z)

	return resultantVector.Unit
end

return NonplayerCharacter
