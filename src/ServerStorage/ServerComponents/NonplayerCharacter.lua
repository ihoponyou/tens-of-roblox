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
	self._heartbeatDelay = 2
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

	self:CurrentState()
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

function NonplayerCharacter:_travelToNextWaypoint()
	local waypoint = self._waypoints[self._nextWaypointIndex]
	self.Humanoid:MoveTo(waypoint.Position)
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		self.Humanoid.Jump = true
	end
end

function NonplayerCharacter:_onMoveToFinished(reached: boolean)
	local stepSuccess = reached and self._nextWaypointIndex < #self._waypoints
	if stepSuccess then
		self._nextWaypointIndex += 1
		self:_travelToNextWaypoint()
	elseif  self._nextWaypointIndex == #self._waypoints then
		self.CurrentState = self.Idling
	else
		self._reachedConnection:Disconnect()
		self._blockedConncetion:Disconnect()
	end
end

function NonplayerCharacter:_followPath(destination: Vector3)
	local success, errorMessage = pcall(function()
		self._path:ComputeAsync(self.Instance.PrimaryPart.Position, destination)
	end)

	if success and self._path.Status == Enum.PathStatus.Success then
		self._waypoints = self._path:GetWaypoints()

		self._blockedConncetion = self._path.Blocked:Connect(function(...)
			self:_onBlocked(..., destination)
		end)

		if not self._reachedConnection then
			self._reachedConnection = self.Humanoid.MoveToFinished:Connect(function(...)
				self:_onMoveToFinished(...)
			end)
		end

		local belowStart = self.Instance.PrimaryPart.CFrame.Position.Y < self._waypoints[1].Position.Y
		if belowStart then
			self.Humanoid.Jump = true
		end

		self._nextWaypointIndex = 2
		self:_travelToNextWaypoint()
	elseif success and self._path.Status == Enum.PathStatus.NoPath then
		local a = Instance.new("Attachment")
		a.Parent = workspace.Terrain
		a.Visible = true
		a.CFrame = CFrame.new(destination)
	else
		warn(errorMessage)
	end
end

function NonplayerCharacter:Wandering()
	if not self._destination then
		self:_followPath(Vector3.new(0, 0, 0))
	end
	self:_followPath(Vector3.zero)
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
		local destinationXZ = VectorMath.GetPositionInPart(self.Habitat)
		floorCast = workspace:Raycast(destinationXZ, Vector3.yAxis * -100)
	until floorCast ~= nil

	-- return workspace["finch area"].finch.CFrame.Position
	return floorCast.Position
end

function NonplayerCharacter:_getPositionAround(): Vector3
	local position = VectorMath.GetPositionInRadius(self.Instance.PrimaryPart.CFrame.Position, 50)
	local floorCast = workspace:Raycast(position, Vector3.yAxis * -50)
	return if floorCast ~= nil then floorCast.Position else position
end

return NonplayerCharacter
