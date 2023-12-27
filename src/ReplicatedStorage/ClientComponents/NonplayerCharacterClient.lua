
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Timer = require(ReplicatedStorage.Packages.Timer)
local Trove = require(ReplicatedStorage.Packages.Trove)

local AnimationManager = require(ReplicatedStorage.Source.Modules.AnimationManager)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local CHARACTER_FOLDER = ReplicatedStorage.Character

local NonplayerCharacterClient = Component.new({
	Tag = "NonplayerCharacter",
	Extensions = {
		Logger,
	},
})

function NonplayerCharacterClient:Construct()
    CollectionService:AddTag(self.Instance, "Ragdoll")
	CollectionService:AddTag(self.Instance, "Knockable")

	self._trove = Trove.new()

	self._path = PathfindingService:CreatePath({
        AgentRadius = 3;
        AgentHeight = 5;
        AgentCanClimb = true;
        AgentCanJump = true;
        Costs = {
            Water = 20;
        }
    })

	self.Character = self._trove:Clone(CHARACTER_FOLDER.CharacterModel)
	for _, v in self.Character:GetChildren() do
		v.Parent = self.Instance
	end
	self.Humanoid = Instance.new("Humanoid")
	self.Humanoid.Parent = self.Instance
	self.Humanoid:ApplyDescriptionReset(CHARACTER_FOLDER.NoobDescription)
	self._trove:Add(self.Humanoid)

	self.Animator = Instance.new("Animator")
	self.Animator.Parent = self.Humanoid
    self._trove:Add(self.Animator)

	self.AnimationManager = AnimationManager.new(self.Animator)
    self._trove:Add(self.AnimationManager)

	local animations = Find.path(CHARACTER_FOLDER, "Animations")
	self.AnimationManager:LoadAnimations(animations:GetChildren())
	self.AnimationManager:PlayAnimation("Idle", 0)

    self._trove:Connect(self.Instance:GetAttributeChangedSignal("Destination"), function()
        if self.Instance:GetAttribute("Destination") == nil then return end
        self.Humanoid:MoveTo(self.Instance:GetAttribute("Destination"))
    end)

	self.Humanoid = self.Instance:WaitForChild("Humanoid")
	self.Animator = self.Humanoid:WaitForChild("Animator")
end

function NonplayerCharacterClient:Start()
	Timer.Simple(5, function()
        -- self:_calculateDestination()
    end, true)
end

function NonplayerCharacterClient:Stop()
	self._trove:Destroy()
end


function NonplayerCharacterClient:_followPath()
    local waypoints
    local nextWaypointIndex
    local reachedConnection
    local blockedConnection

	-- Compute the path
	local success, errorMessage = pcall(function()
		self._path:ComputeAsync(self.Instance.PrimaryPart.Position, self._destination)
	end)

	if success and self._path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		waypoints = self._path:GetWaypoints()

		-- Detect if path becomes blocked
		blockedConnection = self._path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= nextWaypointIndex then
				-- Stop detecting path blockage until path is re-computed
				blockedConnection:Disconnect()

				-- Call function to re-compute new path
				self:_followPath(self._destination)
			end
		end)

		-- Detect when movement to next waypoint is complete
		if not reachedConnection then
			reachedConnection = self.Humanoid.MoveToFinished:Connect(function(reached)
				if reached and nextWaypointIndex < #waypoints then
					-- Increase waypoint index and move to next waypoint
					nextWaypointIndex += 1
					self.Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
				else
					reachedConnection:Disconnect()
					blockedConnection:Disconnect()
				end
			end)
		end

		-- Initially move to second waypoint (first waypoint is path start; skip it)
		nextWaypointIndex = 2
		self.Humanoid:MoveTo(waypoints[nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
	end
end

return NonplayerCharacterClient
