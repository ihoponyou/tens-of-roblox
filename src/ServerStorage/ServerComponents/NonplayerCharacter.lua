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

local ModelUtil = require(ReplicatedStorage.Source.Modules.ModelUtil)
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
	CollectionService:AddTag(self.Instance, "Character")
	CollectionService:AddTag(self.Instance, "Ragdoll")
	CollectionService:AddTag(self.Instance, "Knockable")
	CollectionService:AddTag(self.Instance, "Respawnable")
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

	self.CurrentState = function() print("nil state") end

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

	self.AttackRadius = 0.5
end

function NonplayerCharacter:Start()
	self.Knockable = self:GetComponent(Knockable)

	ModelUtil.SetModelNetworkOwner(self.Instance, nil)
	self._trove:Connect(self.Knockable.Knocked, function(isKnocked: boolean)
		if isKnocked then
			ModelUtil.SetModelNetworkOwnershipAuto(self.Instance)
		else
			ModelUtil.SetModelNetworkOwner(self.Instance, nil)
		end
	end)

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

	if self.Humanoid.Health <= 0 then
		self.CurrentState = self.Idling
	end

	if self._targetPart ~= nil then
		if self._targetPart.Parent == nil then
			self._targetPart = nil
			self.CurrentState = self.Wandering
		else
			self.CurrentState = self.Following
		end
	else
		self.CurrentState = self.Wandering
	end

	self:CurrentState()
end

function NonplayerCharacter:SearchForTarget()
	local results = workspace:GetPartBoundsInRadius(self.Instance.PrimaryPart.Position, 50, self._searchParams)

	-- local closestPlayer
	local shortestDistance = math.huge
	local processed: { [Model]: number? } = {}
	for _, v in results do
		local parent: Model? = v.Parent
		if not parent then continue end
		if processed[parent] then continue end

		if not parent.ClassName == "Model" then
			processed[parent] = -1
			continue
		end

		local player = Players:GetPlayerFromCharacter(parent)
		if not player then
			processed[parent] = -2
			continue
		end

		local distance = (self.Instance.PrimaryPart.Position - parent.PrimaryPart.Position).Magnitude
		if distance < shortestDistance then
			shortestDistance = distance
			self._targetPart = parent.PrimaryPart
			-- closestPlayer = player
		end
	end
	-- print(closestPlayer)
end

function NonplayerCharacter:Wandering()
	self.Humanoid:MoveTo(Vector3.zero)
	self:SearchForTarget()
end

function NonplayerCharacter:Idling()
	self.Humanoid:Move(Vector3.zero)
	self:SearchForTarget()
end

function NonplayerCharacter:Following()
	local destination = self._targetPart.Position

	local currentPosition = self.Instance.PrimaryPart.Position
	local toDestination = destination - currentPosition
	local above = toDestination.Y > 0.5
	local flatDirection = Vector3.new(1, 0, 1) * toDestination.Unit

	self.Humanoid:MoveTo(destination - flatDirection * self.AttackRadius)
	if not above then return end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = CollectionService:GetTagged("Character")
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local castOrigin = self.Instance.PrimaryPart.CFrame + Vector3.yAxis * -self.Humanoid.HipHeight
	local castSize = Vector3.new(2, 2, 0.1)
	local blocked = workspace:Blockcast(castOrigin, castSize, (destination-currentPosition).Unit * 2, raycastParams)

	if blocked then
		local hitInstance = blocked.Instance
		if hitInstance:IsA("TrussPart") then return end
		if hitInstance.Parent then
			local player = Players:GetPlayerFromCharacter(hitInstance.Parent)
			if player ~= nil then return end
		end

		self.Humanoid.Jump = true
	end
end

return NonplayerCharacter
