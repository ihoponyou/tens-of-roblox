--!strict

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
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

	-- self.Habitat = self.Instance.Parent
	-- local habitat = Instance.new("ObjectValue")
	-- habitat.Name = "Habitat"
	-- habitat.Parent = self.Instance
	-- habitat.Value = self.Habitat

	self.Humanoid = Instance.new("Humanoid")
	self.Humanoid.Parent = self.Instance
	self.Humanoid.WalkSpeed = RAND:NextInteger(8, 24)
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
	self.Humanoid.NameDisplayDistance = 10
	self.Humanoid.HealthDisplayDistance = 10
	self.Humanoid:ApplyDescriptionReset(CHARACTER_FOLDER.NoobDescription)
	-- self._trove:Connect(self.Humanoid.StateChanged, print)
	self._trove:Add(self.Humanoid)

	-- time between npc heartbeats
	self._heartbeatDelay = 10
	-- time that has passed since last npc heartbeat
	self._heartbeatTime = 0

	self.CurrentState = function() print("override this") end
	self._target = nil

	self._destination = nil
	self._path = PathfindingService:CreatePath({
		AgentRadius = 1;
		AgentHeight = 5;
		AgentCanJump = true;
		AgentCanClimb = true;
		Costs = {
			Water = 20;
		};
	})
	self._waypoints = nil
	self._nextWaypointIndex = nil
	self._reachedConnection = nil
	self._blockedConncetion = nil

	self._searchParams = OverlapParams.new()
	self._searchParams.CollisionGroup = "Character"
	self._searchParams.FilterDescendantsInstances = { self.Instance }
	self._searchParams.FilterType = Enum.RaycastFilterType.Exclude
end

function NonplayerCharacter:Start()
	self.Knockable = self:GetComponent(Knockable)

	local visual = Instance.new("Part")
	visual.Anchored = true
	-- visual.CanCollide = false
	-- visual.Parent = workspace
	-- visual.BrickColor = BrickColor.Yellow()

	local spawnLocation = self:_getPositionAround()
	visual.CFrame = CFrame.new(spawnLocation)

	self.Instance:PivotTo(visual.CFrame)

	self.CurrentState = self.Wandering
	self:CurrentState()
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

function NonplayerCharacter:HeartbeatUpdate(deltaTime: number)
	if not self.Instance.PrimaryPart then
		self.Instance:Destroy()
		return
	end

	self._heartbeatTime += deltaTime
	if self._heartbeatTime < self._heartbeatDelay then return end
	self._heartbeatTime = 0

	if self.CurrentState == self.Idling then return end
	-- self:SearchForTarget()

	if self._target ~= nil then
		self.CurrentState = self.Following
		return
	else
		-- if RAND:NextInteger(0,1) == 1 then
			self.CurrentState = self.Wandering
		-- else
		-- 	self.CurrentState = self.Idling
		-- end
	end

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

function NonplayerCharacter:_onBlocked(blockedWaypointIdx: number, destination)
	-- only consider blocked waypoints in front
	if blockedWaypointIdx >= self._nextWaypointIndex then
		-- disconnect current handler; new one is connected when path is calculated
		self._blockedConncetion:Disconnect()

		-- recalculate path around obstacle
		self:_followPath(destination)
	end
end

function NonplayerCharacter:_onMoveToFinished(reached: boolean, destination)
	local stepSuccess = reached and self._nextWaypointIndex < #self._waypoints
	if stepSuccess then
		self._nextWaypointIndex += 1

		local waypoint = self._waypoints[self._nextWaypointIndex]

		self.Humanoid:MoveTo(waypoint.Position)
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			self.Humanoid.Jump = true
		end
	elseif  self._nextWaypointIndex == #self._waypoints then
		self._destination = self:_getPositionAround()
	else
		print("completed path")
		self.CurrentState = self.Idling
		self._reachedConnection:Disconnect()
		self._blockedConncetion:Disconnect()
	end
end

function NonplayerCharacter:_followPath(destination: Vector3)
	local success, errorMessage = pcall(function()
		self._path:ComputeAsync(self.Instance.PrimaryPart.Position, self._destination)
	end)
	if success and self._path.Status == Enum.PathStatus.Success then
		self._waypoints = self._path:GetWaypoints()

		self._blockedConncetion = self._path.Blocked:Connect(function(...)
			self:_onBlocked(..., destination)
		end)

		if not self._reachedConnection then
			self._reachedConnection = self.Humanoid.MoveToFinished:Connect(function(...)
				self:_onMoveToFinished(..., destination)
			end)
		end

		self._nextWaypointIndex = 2

		local waypoint = self._waypoints[self._nextWaypointIndex]
		self.Humanoid:MoveTo(self._waypoints[self._nextWaypointIndex].Position)
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			self.Humanoid.Jump = true
		end
	elseif self._path.Status == Enum.PathStatus.NoPath then
		local a = Instance.new("Attachment")
		a.Visible = true
		a.Parent = workspace.Terrain
		a.CFrame = CFrame.new(self._destination)
		self._destination = self:_getPositionAround()
	else
		warn(errorMessage)
		return
	end
end

function NonplayerCharacter:Wandering()
	if not self._destination then
		self._destination = self:_getPositionAround()
	end
	self:_followPath(workspace["finch area"].finch.CFrame.Position)
end

function NonplayerCharacter:Idling()
	self.Humanoid:Move(Vector3.zero)
end

function NonplayerCharacter:Following()
	self._heartbeatDelay = 0.1

	local targetRoot = self._target.PrimaryPart
	-- local targetVelocity = targetRoot.AssemblyLinearVelocity
	-- local projectedPosition = targetRoot.CFrame.Position + targetVelocity * self._heartbeatDelay

	self.Humanoid:MoveTo(targetRoot.CFrame.Position, targetRoot)
end

function NonplayerCharacter:_getPositionWithinHabitat(): Vector3
	local floorCast
	repeat
		local destinationXZ = GetRandomPositionInPart(self.Habitat)
		floorCast = workspace:Raycast(destinationXZ, Vector3.yAxis * -100)
	until floorCast ~= nil

	-- return workspace["finch area"].finch.CFrame.Position
	return floorCast.Position
end

function NonplayerCharacter:_getPositionAround(): Vector3
	return VectorMath.GetPositionInRadius(self.Instance.PrimaryPart.CFrame.Position, 10)
end

function NonplayerCharacter:MapNeighborsToVelocity(neighbors: {Model}, fn: (Model) -> Vector3): Vector3
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

	if neighborCount > 0 then
		resultant.X /= neighborCount
		resultant.Z /= neighborCount
	end

	local resultantVector = Vector3.new(unpack(resultant))
	return resultantVector.Unit
end

function NonplayerCharacter:GetAlignedVelocity(agent: Model, velocity: Vector3): Vector3
	local distanceToAgent = VectorMath.DistanceBetweenParts(agent.PrimaryPart, self.Instance.PrimaryPart)
	if distanceToAgent <= 10 then
		local agentVelocity = agent.PrimaryPart.AssemblyLinearVelocity
		resultant.X += agentVelocity.X
		resultant.Z += agentVelocity.Z
	end
end

return NonplayerCharacter
