
-- essentially an npc spawner that defines where they may path

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

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
        local npc = Instance.new("Model")
        npc.Name = i
        npc.Parent = self.Instance
        CollectionService:AddTag(npc, "NonplayerCharacter")

        npc:PivotTo(self.Instance.CFrame * CFrame.new(0, 5, 0))
        table.insert(self._populus, npc)
    end
end

function Habitat:Stop()
	self._trove:Destroy()
end

return Habitat
