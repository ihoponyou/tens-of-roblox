--!strict

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
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
	self._serverComm = self._trove:Construct(Comm.ServerComm, self.Instance, "NPC")

	self.RootPart = Instance.new("Part")
	self.RootPart.Name = "Ghost"
	self.RootPart.CFrame = self.Instance:GetPivot()
    self.RootPart.Size = Vector3.new(2, 2, 1)
    -- self.RootPart.Anchored = true
	self.RootPart.CanCollide = true
	self.RootPart.CollisionGroup = "Ghost"
	self.RootPart.Parent = self.Instance
	self.RootPart.BrickColor = BrickColor.Red()

	self.UpdatePosition = self._serverComm:CreateSignal("UpdatePosition", true)
	self._trove:Connect(self.UpdatePosition, function(player, cframe: CFrame)
		self.Instance:PivotTo(cframe)
	end)
end

function NonplayerCharacter:Stop()
	self._trove:Destroy()
end

return NonplayerCharacter
