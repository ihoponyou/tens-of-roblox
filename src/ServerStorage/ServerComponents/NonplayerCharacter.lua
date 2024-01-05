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

	-- self:FollowPath(Vector3.new(16.399, 60, -141.673))
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

function NonplayerCharacter:HeartbeatUpdate(deltaTime: number)
	if not self.Instance.PrimaryPart then
		self.Instance:Destroy()
		return
	end

	if self.Humanoid.Health <= 0 then
		self.CurrentState = self.Idling
	end

	self:CurrentState()
end

function NonplayerCharacter:Wandering()
	-- self:_pathTo(Vector3.zero)
end

function NonplayerCharacter:Idling()
	self.Humanoid:Move(Vector3.zero)
end

function NonplayerCharacter:Following()
	local destination = Vector3.new()

	for _, v in Players:GetPlayers() do
		local char = v.Character
		if not char then continue end
		destination = char.HumanoidRootPart.Position
	end

	local currentPosition = self.Instance.PrimaryPart.Position
	local above = destination.Y - currentPosition.Y > 0.5

	self.Humanoid:MoveTo(destination)
	if not above then return end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = CollectionService:GetTagged("NonplayerCharacter")
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local castOrigin = self.Instance.PrimaryPart.CFrame
	local castSize = Vector3.new(2, 4, 0.1)
	local blocked = workspace:Blockcast(castOrigin, castSize, (destination-currentPosition).Unit * 3, raycastParams)

	if blocked then
		if blocked.Instance:IsA("TrussPart") then return end
		self.Humanoid.Jump = true
	end
end

return NonplayerCharacter
