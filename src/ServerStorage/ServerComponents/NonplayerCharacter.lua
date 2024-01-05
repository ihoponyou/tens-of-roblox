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
	self.Humanoid.WalkSpeed = 8
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
	self.Humanoid.NameDisplayDistance = 10
	self.Humanoid.HealthDisplayDistance = 10
	self.Humanoid:ApplyDescriptionReset(CHARACTER_FOLDER.NoobDescription)
	-- self._trove:Connect(self.Humanoid.StateChanged, print)
	self._trove:Add(self.Humanoid)

	-- time between npc heartbeats
	self._heartbeatDelay = 1 -- RAND:NextNumber(0.5, 1.5)
	-- time that has passed since last npc heartbeat
	self._heartbeatTime = 0

	self.CurrentState = function() print("override this") end

	self._targetPart = nil
	self._path = PathfindingService:CreatePath({
		AgentRadius = 1;
		AgentHeight = 5;
		AgentCanJump = true;
		AgentCanClimb = false;
		Costs = {
			Water = 20;
		};
	})
	self._waypoints = nil
	self._nextWaypointIndex = nil
	self._reachedConnection = nil
	self._blockedConnection = nil

	self._searchParams = OverlapParams.new()
	self._searchParams.CollisionGroup = "Character"
	self._searchParams.FilterDescendantsInstances = { self.Instance }
	self._searchParams.FilterType = Enum.RaycastFilterType.Exclude
end

function NonplayerCharacter:Start()
	self.Knockable = self:GetComponent(Knockable)

	self.Instance.PrimaryPart:SetNetworkOwner(nil)

	self._targetPart = workspace:WaitForChild("ihoponyou").PrimaryPart
	self.CurrentState = self.Following
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

	if self.Humanoid.Health <= 0 then
		self.CurrentState = self.Idling
	end

	self:CurrentState()
end

function NonplayerCharacter:_travelToNextWaypoint()
	local waypoint = self._waypoints[self._nextWaypointIndex]
	if not waypoint then
		warn("no next waypoint"..tostring(self._nextWaypointIndex))
		return
	end

	if waypoint.Action == Enum.PathWaypointAction.Jump then
		self.Humanoid.Jump = true
	end
	self.Humanoid:MoveTo(waypoint.Position)
end

function NonplayerCharacter:_pathTo(destination: Vector3)
	local success, errorMessage = pcall(function()
		self._path:ComputeAsync(self.Instance.PrimaryPart.Position, destination)
	end)

	self._waypoints = nil
	self._nextWaypointIndex = -1

	if not success then
		warn(errorMessage)
	elseif self._path.Status == Enum.PathStatus.NoPath then
		self.Humanoid:MoveTo(destination)
	elseif self._path.Status == Enum.PathStatus.Success then
		self._waypoints = self._path:GetWaypoints()

		for i, v in self._waypoints do
			self._nextWaypointIndex = i+1
			self:_travelToNextWaypoint()
			local reached = self.Humanoid.MoveToFinished:Wait()
		end

		self._nextWaypointIndex = 2
		self:_travelToNextWaypoint()
	end
end

function NonplayerCharacter:Wandering()
	self:_pathTo(Vector3.zero)
end

function NonplayerCharacter:Idling()
	self.Humanoid:Move(Vector3.zero)
end

function NonplayerCharacter:Following()
	local targetPosition = self._targetPart.Position
	self:_pathTo(targetPosition)
end

return NonplayerCharacter
