--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)

local DEBUG = true

local Melee = Component.new({
	Tag = "Melee",
	Extensions = {
		Logger,
	},
})

local dependencies = {
	"Equipment"
}

function Melee:Construct()
	for _, v in dependencies do
		CollectionService:AddTag(self.Instance, v)
	end

	self._cfg = EquipmentConfig[self.Instance.Name]
	self._trove = Trove.new()

	local CastParams = RaycastParams.new()
	CastParams.CollisionGroup = "Character"
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self._castParams = CastParams
end

function Melee:Start()
	Equipment:WaitForInstance(self.Instance):andThen(function(component)
		self.Equipment = component
	end):catch(warn):await()

	self.Equipment.Use = function(player, ...)
		self:Attack()
	end

	self._trove:Connect(self.Equipment.PickedUp, function(pickedUp: boolean)

	end)

	self._trove:Connect(self.Equipment.Equipped, function(equipped: boolean)
		if equipped then
			self._castParams.FilterDescendantsInstances = { self.Equipment.Character }
		else
			self._castParams.FilterDescendantsInstances = {}
		end
	end)
end

function Melee:Stop()
    self._trove:Destroy()
end

function Melee:Attack()
    print("shawing")
    self.Equipment.AnimationManager:PlayAnimation("Attack")
end

return Melee
