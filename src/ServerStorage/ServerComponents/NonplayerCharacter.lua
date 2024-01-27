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
	self._trove = Trove.new()

	-- self.RootPart = Instance.new("Part")
	-- self.RootPart.Name = "HumanoidRootPart"
	-- self.RootPart.CFrame = self.Instance:GetPivot()
    -- self.RootPart.Size = Vector3.new(2, 2, 1)
    -- self.RootPart.Anchored = true
	-- self.RootPart.CanCollide = false
	-- self.RootPart.Parent = self.Instance
	-- self.RootPart.BrickColor = BrickColor.Red()

	-- self.Instance.PrimaryPart = self.RootPart
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

return NonplayerCharacter
