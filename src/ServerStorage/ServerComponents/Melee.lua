
-- allows for attacking like a melee weapon

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)
local MeleeCaster = require(ServerStorage.Source.ServerComponents.MeleeCaster)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local MeleeConfig = require(ServerStorage.Source.MeleeConfig)

local COMBO_RESET_DELAY = 0.5

local Melee = Component.new({
	Tag = "Melee",
})

function Melee:Construct()
	self._trove = Trove.new()
	self._serverComm = self._trove:Construct(Comm.ServerComm, self.Instance, "Melee")

    -- directly adopt fields in config
    for k, v in MeleeConfig[self.Instance.Name] do
        self[k] = v
    end

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
    for i=0, self.MaxCombo do
        local animationName = "Attack"..tostring(i+1)

        Find.path(animations, "3P/"..animationName)

        if self.Equipment.AllowFirstPerson then
            Find.path(animations, "1P/"..animationName)
        end
    end

    if self.UsesClientCast then
        self:_setupClientCast()
    end

    self._trove:Connect(self.Equipment.Equipped, function(isEquipped: boolean)
        self._canAttack = false

        if isEquipped then
            self._equipTrove = self._trove:Extend()

            self._readyThread = task.delay(self.DeployTime, function()
                self._canAttack = true
                self._readyThread = nil
            end)

            for i=0, self.MaxCombo do
                local animationName = "Attack"..tostring(i+1)

                local attackTrack = self.Equipment.AnimationManager:GetAnimation(animationName)
                self:_setupAttackAnimation(attackTrack, self._equipTrove)
            end

            if self.UsesClientCast then
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
end

function Melee:Stop()
	self._trove:Destroy()
end

-- allows for special damage calculation e.g. backstab
function Melee:_calculateDamage(_humanoid: Humanoid): number
    return self.Damage
end

function Melee:_dealDamage(humanoid: Humanoid)
    if humanoid.Health <= 0 then return end

    local damage = self:_calculateDamage(humanoid)

    humanoid:TakeDamage(damage)

    local hitType = "Hit"
    if humanoid.Health <= 0 then
        hitType = "Kill"
    elseif damage > self.Damage then
    	hitType = "Headshot"
    elseif damage < 15 then
        hitType = "Graze"
    end

    ReplicatedStorage.UIEvents.HitRegistered:FireClient(self.Equipment.Owner, hitType)
end

function Melee:_setupClientCast()
    -- self.Equipment.WorldModel:SetAttribute("Log", true)
    -- self.Equipment.WorldModel:SetAttribute("DebugCasts", true)
    self.Equipment.WorldModel:AddTag("MeleeCaster")

    MeleeCaster:WaitForInstance(self.Equipment.WorldModel):andThen(function(component)
        self.Caster = component

        self.Caster.OnHumanoidCollided = function(_caster, _raycastResult: RaycastResult, humanoid: Humanoid)
            if self._hitDebounce[humanoid] then return end

            self:_dealDamage(humanoid)

            self._hitDebounce[humanoid] = true
        end
    end, warn)
end

function Melee:_spawnHitbox(visualize: boolean): {BasePart}
    local cframe: CFrame = self.Equipment.Owner.Character.HumanoidRootPart.CFrame
    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = { self.Equipment.Owner.Character }
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local finalCFrame = cframe + cframe.LookVector * self.HitboxSize.Z/2

    if visualize then
        local visualizer = Instance.new("Part")
        visualizer.CFrame = finalCFrame
        visualizer.Size = self.HitboxSize
        visualizer.BrickColor = BrickColor.Red()
        visualizer.Parent = workspace
        visualizer.Transparency = 0.8
        visualizer.CanCollide = false
        visualizer.CanQuery = false
        visualizer.CanTouch = false
        visualizer.Anchored = true
        visualizer.Name = "Hitbox Visualizer"

        Debris:AddItem(visualizer, 1)
    end

    return workspace:GetPartBoundsInBox(finalCFrame, self.HitboxSize, overlapParams)
end

function Melee:_setupAttackAnimation(animationTrack: AnimationTrack, trove)
    if trove == nil then error("need a trove") end

	trove:Connect(animationTrack:GetMarkerReachedSignal("start"), function()
		-- print("sha")
        if self.UsesClientCast then
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
        if self.UsesClientCast then
            self.Caster:StopCast()
        end

        self._combo += 1
        if self._combo > self.MaxCombo then
            self._combo = 0

            task.wait(self.Endlag)

            self._canAttack = true
        else
            self._comboResetThread = task.delay(COMBO_RESET_DELAY, function()
                self._combo = 0
            end)

            self._canAttack = true
        end
	end)

    if not self.UsesClientCast then
        trove:Connect(animationTrack:GetMarkerReachedSignal("contact"), function()
            local hits = self:_spawnHitbox(true)
            local processed: {[Instance]: boolean} = {}
            for _, hit in hits do
                local parent = hit.Parent
                if not parent then continue end

                if processed[parent] then continue end
                processed[parent] = true

                local humanoid = parent:FindFirstChildOfClass("Humanoid")
                if not humanoid then continue end

                self:_dealDamage(humanoid)
            end
        end)
    end
end

function Melee:Attack(player)
    if player ~= self.Equipment.Owner then return end
    if not self._canAttack then return end

    self._canAttack = false

    self.AttackRequest:Fire(self.Equipment.Owner, self._combo)
    self.Equipment.AnimationManager:PlayAnimation("Attack"..tostring(self._combo+1))
end

return Melee
