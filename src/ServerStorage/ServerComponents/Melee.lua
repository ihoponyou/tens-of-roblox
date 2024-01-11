--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ClientCast = require(ReplicatedStorage.Packages.ClientCast)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)

local DEBUG = true
local COMBO_RESET_DELAY = 1.3
local DAMAGE_POINTS_PER_STUD = 1

local Melee = Component.new({
	Tag = "Melee",
	Extensions = {
		Logger,
	},
})

function Melee:Construct()
	self._cfg = EquipmentConfig[self.Instance.Name]
	self._trove = Trove.new()

	local castParams = RaycastParams.new()
	castParams.FilterType = Enum.RaycastFilterType.Exclude
	castParams.FilterDescendantsInstances = {}
	self._castParams = castParams

	self._combo = 1
	self._attacking = false
end

function Melee:_setupAttackAnimation(animationTrack: AnimationTrack)
	local startSignal = animationTrack:GetMarkerReachedSignal("start")
	if not startSignal then
		warn(self.Instance.Name, animationTrack.Name, "has no start KeyframeMarker")
		return
	end
	self._equipTrove:Connect(startSignal, function()
		self._hitDebounce = {}
		-- self._caster:StartDebug()
		self._caster:Start()

		self:PlayAttackSound()
	end)

	local endSignal = animationTrack:GetMarkerReachedSignal("end")
	if not startSignal then
		warn(self.Instance.Name, animationTrack.Name, "has no end KeyframeMarker")
		return
	end
	self._equipTrove:Connect(endSignal, function()
		-- self._caster:DisableDebug()
		self._caster:Stop()

		self._attacking = false
	end)
end

function Melee:Start()
	self.Equipment = self:GetComponent(Equipment)

	self.AttackSound = self.Equipment.WorldModel.PrimaryPart:FindFirstChild("AttackSound")
	if not self.AttackSound then
		warn(self.Instance.Name.." has no attack sound")
	end

	-- create damage points for client cast
	local tip = self.Equipment.WorldModel.PrimaryPart:FindFirstChild("Tip")
	local pommel = self.Equipment.WorldModel.PrimaryPart:FindFirstChild("Pommel")
	if tip and pommel then
		local bladeDirection: Vector3 = tip.WorldPosition - pommel.WorldPosition
		local points = math.round(bladeDirection.Magnitude/DAMAGE_POINTS_PER_STUD)

		for i=0, points do
			local dmgPoint = Instance.new("Attachment")
			dmgPoint.Name = "DmgPoint"
			dmgPoint.Parent = self.Equipment.WorldModel.PrimaryPart
			dmgPoint.WorldPosition = pommel.WorldPosition + bladeDirection * i/points
		end
	else
		warn("cannot setup damage points for "..self.Instance.Name)
	end

	self._caster = ClientCast.new(self.Equipment.WorldModel, self._castParams)
	self._caster:SetRecursive(true)
	self._trove:Add(self._caster)

	self._caster.HumanoidCollided:Connect(function(...)
		self:_onHumanoidCollided(...)
	end)

	self.Equipment.Use = function(player, ...)
		self:Attack(player, ...)
	end

	self._trove:Connect(self.Equipment.Equipped, function(equipped: boolean)
		if equipped then
			self._equipTrove = self._trove:Extend()

			for i=1, self._cfg.MaxCombo do
				local attackAnimation = self.Equipment.AnimationManager:GetAnimation("Attack"..tostring(i))
				if not attackAnimation then continue end

				self:_setupAttackAnimation(attackAnimation)
			end

			-- reset any animation controlled values
			self._equipTrove:Add(function()
				self._caster:DisableDebug()
				self._caster:Stop()

				self._attacking = false
			end)

			self._castParams.FilterDescendantsInstances = { self.Equipment.Character }
			self._caster:EditRaycastParams(self._castParams)
		else
			self._castParams.FilterDescendantsInstances = {}
			self._caster:EditRaycastParams(self._castParams)

			self._equipTrove:Clean()
		end
	end)
end

function Melee:Stop()
    self._trove:Destroy()
end

function Melee:PlayAttackSound()
	local sound = self.AttackSound
	if not sound then return end

	local pitchShift: PitchShiftSoundEffect = sound:FindFirstChildOfClass("PitchShiftSoundEffect")
	if pitchShift then
		local minShift = pitchShift:GetAttribute("Lower") or 0.5
		local maxShift = pitchShift:GetAttribute("Upper") or 2
		pitchShift.Octave = math.random(minShift, maxShift)
	end

	self.AttackSound:Play()
end

function Melee:Attack(player: Player, ...)
	if not self.Equipment.IsEquipped then return end
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

function Melee:_onHumanoidCollided(raycastResult: RaycastResult, humanoid: Humanoid)
	if self._hitDebounce[humanoid] then return end
	self._hitDebounce[humanoid] = true
	if humanoid.Health <= 0 then return end

	humanoid:TakeDamage(self._cfg.Damage)

	local hitType = "Hit"
	if humanoid.Health <= 0 then
		hitType = "Kill"
	elseif self._cfg.Damage < 15 then
		hitType = "Graze"
	end

	ReplicatedStorage.UIEvents.HitRegistered:FireClient(self.Equipment.Owner, hitType)

	task.delay(0.5, function()
		self._hitDebounce[humanoid] = false
	end)
end

return Melee
