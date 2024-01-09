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
local COMBO_RESET_DELAY = 1

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

	self._combo = 1
	self._attacking = false
end

function Melee:Start()
	Equipment:WaitForInstance(self.Instance):andThen(function(component)
		self.Equipment = component
	end):catch(warn):await()

	self.Equipment.Use = function(player, ...)
		self:Attack(player, ...)
	end

	self._trove:Connect(self.Equipment.Equipped, function(equipped: boolean)
		if equipped then
			self._equipTrove = self._trove:Extend()

			for i=1, self._cfg.MaxCombo do
				local attackAnimation = self.Equipment.AnimationManager:GetAnimation("Attack"..tostring(i))
				self._equipTrove:Connect(attackAnimation:GetMarkerReachedSignal("end"), function()
					self._attacking = false
				end)
			end

			self._castParams.FilterDescendantsInstances = { self.Equipment.Character }
		else
			self._castParams.FilterDescendantsInstances = {}

			self._equipTrove:Clean()
		end
	end)
end

function Melee:Stop()
    self._trove:Destroy()
end

function Melee:Attack(player: Player, ...)
	if self._attacking then return end

	if self._comboResetThread then task.cancel(self._comboResetThread) end
    self._comboResetThread = task.delay(COMBO_RESET_DELAY, function()
		self._combo = 1
	end)

    self.Equipment.AnimationManager:PlayAnimation("Attack"..tostring(self._combo))

	self._combo += 1
	if self._combo > self._cfg.MaxCombo then
		-- if nothing is hit then endlag
		self._combo = 1
	end

	self._attacking = true
end

return Melee
