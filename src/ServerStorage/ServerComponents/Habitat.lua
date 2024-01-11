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

function Habitat:Construct()
	self._trove = Trove.new()

    self.Population = self.Instance:GetAttribute("Population")
    self._populus = {}

    for i=1, self.Population do
        local npc = self._trove:Clone(ReplicatedStorage.Character.CharacterModel)
        npc.Name = i

        CollectionService:AddTag(npc, "NonplayerCharacter")

        table.insert(self._populus, npc)
    end
end

function Habitat:Start()
    for _, npc: Model in self._populus do
        local spawnPosition = self:GetValidSpawnPosition() + Vector3.yAxis * 3
        npc:PivotTo(CFrame.new(spawnPosition))
        npc.Parent = self.Instance
        npc:SetAttribute("SpawnLocation", spawnPosition)
        -- npc.PrimaryPart.Anchored = true
    end
end

function Habitat:Stop()
	self._trove:Destroy()
end

-- returns a position that sits on a solid surface in the habitat
function Habitat:GetValidSpawnPosition(): Vector3
    local visualize = false
    local floorCast: RaycastResult?
    repeat
        local origin = VectorMath.GetPositionInPart(self.Instance)
        floorCast = if visualize
            then RaycastUtil.RaycastWithVisual(origin, Vector3.yAxis * -50)
            else workspace:Raycast(origin, Vector3.yAxis * -50)
    until floorCast ~= nil

    if visualize then
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
