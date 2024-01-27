--!strict

-- essentially an npc spawner

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local RaycastUtil = require(ReplicatedStorage.Source.Modules.RaycastUtil)
local VectorMath = require(ReplicatedStorage.Source.Modules.VectorMath)

local Habitat = Component.new({
	Tag = "Habitat",
	Extensions = {
		Logger,
	},
})

local VISUALIZE_SPAWNS = false

function Habitat:Construct()
	self._trove = Trove.new()

    self.Population = self.Instance:GetAttribute("Population")
    self._populus = {}

    for i=1, self.Population do
        local npc = Instance.new("Model")

        npc.Name = i

        CollectionService:AddTag(npc, "NonplayerCharacter")

        table.insert(self._populus, npc)
    end
end

function Habitat:Start()
    for _, npc: Model in self._populus do
        npc.Parent = self.Instance

        local spawnPosition = self:GetValidSpawnPosition() + Vector3.yAxis * 3
        npc:PivotTo(CFrame.new(spawnPosition))
        npc:SetAttribute("SpawnLocation", spawnPosition)

        task.wait()
    end
end

function Habitat:Stop()
	self._trove:Destroy()
end

-- returns a position that sits on a solid surface in the habitat
function Habitat:GetValidSpawnPosition(): Vector3
    local floorCast: RaycastResult?
    repeat
        local origin = VectorMath.GetPositionInPart(self.Instance)
        floorCast = if VISUALIZE_SPAWNS
            then RaycastUtil.RaycastWithVisual(origin, Vector3.yAxis * -100)
            else workspace:Raycast(origin, Vector3.yAxis * -100)
    until floorCast ~= nil

    if VISUALIZE_SPAWNS then
        local visual = Instance.new("Part")
        visual.BrickColor = BrickColor.Yellow()
        visual.Anchored = true
        visual.CFrame = CFrame.new(floorCast.Position)
        visual.CanCollide = false
        visual.CanQuery = false
        visual.CanTouch = false
        visual.Parent = workspace
    end

    return floorCast.Position
end

return Habitat
