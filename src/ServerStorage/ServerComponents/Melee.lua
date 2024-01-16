
-- allows for attacking like a melee weapon

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)
local MeleeCaster = require(ServerStorage.Source.ServerComponents.MeleeCaster)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local MeleeStats = require(ServerStorage.Source.MeleeStats)
local HitboxManager = require(ReplicatedStorage.Source.Modules.HitboxManager)

local COMBO_RESET_DELAY = 0.5

local Melee = Component.new({
	Tag = "Melee",
})

function Melee:Construct()
	self._trove = Trove.new()
	self._serverComm = self._trove:Construct(Comm.ServerComm, self.Instance, "Melee")

    self.Stats = MeleeStats[self.Instance.Name] :: MeleeStats.StatBlock

    self._canAttack = false
    self._combo = 0

	self.AttackRequest = self._serverComm:CreateSignal("AttackRequest")
    self._trove:Connect(self.AttackRequest, function(...)
        self:Attack(...)
    end)
end

function Melee:Start()
    self.Equipment = self:GetComponent(Equipment)

    -- ensure animations exist
    local animations = self.Equipment.Folder.Animations
    for i=0, self.Stats.MaxCombo do
        local animationName = "Attack"..tostring(i+1)

        Find.path(animations, "3P/"..animationName)

        if self.Equipment.Config.AllowFirstPerson then
            Find.path(animations, "1P/"..animationName)
        end
    end

    self._trove:Connect(self.Equipment.Equipped, function(isEquipped: boolean)
        self._canAttack = false

        if isEquipped then
            self._equipTrove = self._trove:Extend()

            self._readyThread = task.delay(self.Stats.DeployTime, function()
                self._canAttack = true
                self._readyThread = nil
            end)

            for i=0, self.Stats.MaxCombo do
                local animationName = "Attack"..tostring(i+1)

                local attackTrack = self.Equipment.AnimationManager:GetAnimation(animationName)
                self:_setupAttackAnimation(attackTrack, self._equipTrove)
            end

            if self.Stats.UsesClientCast then
                local newParams = RaycastParams.new()
                newParams.FilterDescendantsInstances = { self.Equipment.Owner.Character, self.Equipment.WorldModel }
                newParams.FilterType = Enum.RaycastFilterType.Exclude
                self.Caster:EditRaycastParams(newParams)
            end
        else
            self._equipTrove:Destroy()

            if self._readyThread then
                task.cancel(self._readyThread)
                self._readyThread = nil
            end
        end
    end)

    if self.Stats.UsesClientCast then
        self:_setupClientCast()
    else
        self.HitboxManager = self._trove:Construct(HitboxManager)
    end
end

function Melee:Stop()
	self._trove:Destroy()
end

function Melee:_setupClientCast()
    -- self.Equipment.WorldModel:SetAttribute("Log", true)
    -- self.Equipment.WorldModel:SetAttribute("DebugCasts", true)
    self.Equipment.WorldModel:AddTag("MeleeCaster")

    MeleeCaster:WaitForInstance(self.Equipment.WorldModel):andThen(function(component)
        self.Caster = component

        self.Caster.OnHumanoidCollided = function(_caster, _raycastResult: RaycastResult, humanoid: Humanoid)
            if self._hitDebounce[humanoid] then return end
            if humanoid.Health <= 0 then return end
            local damage = self.Stats.Damage

            humanoid:TakeDamage(damage)

            local hitType = "Hit"
            if humanoid.Health <= 0 then
                hitType = "Kill"
            -- elseif isHeadshot then
            -- 	hitType = "Headshot"
            elseif damage < 15 then
                hitType = "Graze"
            end

            ReplicatedStorage.UIEvents.HitRegistered:FireClient(self.Equipment.Owner, hitType)

            self._hitDebounce[humanoid] = true
        end
    end, warn)
end

function Melee:_setupAttackAnimation(animationTrack: AnimationTrack, trove)
    if trove == nil then error("need a trove") end

	trove:Connect(animationTrack:GetMarkerReachedSignal("start"), function()
		-- print("sha")
        if self.Stats.UsesClientCast then
            self.Caster:StartCast()
        end

        self._hitDebounce = {}

        if self._comboResetThread then
            task.cancel(self._comboResetThread)
            self._comboResetThread = nil
        end
	end)

	trove:Connect(animationTrack:GetMarkerReachedSignal("end"), function()
		-- print("wing")
        if self.Stats.UsesClientCast then
            self.Caster:StopCast()
        end

        self._combo += 1
        if self._combo > self.Stats.MaxCombo then
            self._combo = 0

            task.wait(self.Stats.Endlag)

            self._canAttack = true
        else
            self._comboResetThread = task.delay(COMBO_RESET_DELAY, function()
                self._combo = 0
            end)

            self._canAttack = true
        end
	end)
end

function Melee:Attack(player)
    if player ~= self.Equipment.Owner then return end
    if not self._canAttack then return end

    self._canAttack = false

    self.AttackRequest:Fire(self.Equipment.Owner, self._combo)
    self.Equipment.AnimationManager:PlayAnimation("Attack"..tostring(self._combo+1))
end

return Melee
