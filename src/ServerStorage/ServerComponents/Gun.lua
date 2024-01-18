
-- allows for attacking like a gun

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local GunConfig = require(ReplicatedStorage.Source.GunConfig)

local Gun = Component.new({
	Tag = "Gun",
})

function Gun:Construct()
    self._canFire = false

	self._trove = Trove.new()
	self._serverComm = self._trove:Construct(Comm.ServerComm, self.Instance, "Gun")

    -- directly adopt fields in config
    for k, v in GunConfig[self.Instance.Name] do
        self[k] = v
    end

    -- for projectile caster
    for k, v in self.Ballistics do
        self.Instance:SetAttribute(k, v)
    end

    self.FireEvent = self._serverComm:CreateSignal("FireEvent")
    self._trove:Connect(self.FireEvent, function(...)
        self:Fire(...)
    end)

    self.HitEvent = self._serverComm:CreateSignal("HitEvent")
    self._trove:Connect(self.HitEvent, function(...)
        self:RegisterHit(...)
    end)

    CollectionService:AddTag(self.Instance, "ProjectileCaster")
end

function Gun:Start()
    self.Equipment = self:GetComponent(Equipment)

    -- ensure animations exist
    Find.path(self.Equipment.Folder, "Animations/3P/Fire")

    self._trove:Connect(self.Equipment.Equipped, function(isEquipped: boolean)
        self._canFire = false

        if isEquipped then
            self._readyThread = task.delay(self.DeployTime, function()
                self._canFire = true
                self._readyThread = nil
            end)
        else
            if self._readyThread then
                task.cancel(self._readyThread)
                self._readyThread = nil
            end
        end
    end)
end

function Gun:Stop()
	self._trove:Destroy()
end

-- allows for special damage calculation e.g. backstab
function Gun:_calculateDamage(_humanoid: Humanoid, hit: Instance): number
    local damage = self.Damage

    local headshot = hit.Name == "Head"
    if headshot then damage *= 2 end

    return damage
end

function Gun:_dealDamage(humanoid: Humanoid, hit: Instance)
    if humanoid.Health <= 0 then return end

    local damage = self:_calculateDamage(humanoid, hit)

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

function Gun:Fire(player: Player, origin: Vector3, direction: Vector3)
    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
        warn(player.Name, "is WEIRD!!!")
        return
    end
    if self.Equipment.Owner ~= player then return end
    if not self._canFire then return end

    self.Equipment.AnimationManager:PlayAnimation("Fire")
    self.FireEvent:FireExcept(self.Equipment.Owner, origin, direction)
end

function Gun:RegisterHit(player: Player, instance: Instance)
    if not self.Equipment.IsPickedUp:Get() then return end
    if self.Equipment.Owner ~= player then return end

    print("hit", instance.Name)

    local parent = instance.Parent
    if not parent then return end
    local humanoid = parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    self:_dealDamage(humanoid, instance)
end

return Gun
