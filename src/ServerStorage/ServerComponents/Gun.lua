
-- allows for attacking like a gun

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
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

    self.CanFire = self._serverComm:CreateProperty("CanFire", false)
    self.CanReload = self._serverComm:CreateProperty("CanReload", false)

    self.CurrentAmmo = self.MagazineCapacity
    self.UpdateCurrentAmmo = self._serverComm:CreateSignal("UpdateCurrentAmmo")

    self.ReserveAmmo = self.MagazineCapacity * self.ReserveMagazines
    self.UpdateReserveAmmo = self._serverComm:CreateSignal("UpdateReserveAmmo")

    self.ReloadEvent = self._serverComm:CreateSignal("ReloadEvent")
    self._trove:Connect(self.ReloadEvent, function(...)
        self:Reload(...)
    end)

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

    self.Magazine = self.Equipment.WorldModel:FindFirstChild("Magazine")

    -- ensure animations exist
    Find.path(self.Equipment.Folder, "Animations/3P/Fire")

    self._trove:Connect(self.Equipment.PickedUp, function(isPickedUp: boolean)
        if isPickedUp then
            self.UpdateCurrentAmmo:Fire(self.Equipment.Owner, self.CurrentAmmo)
            self.UpdateReserveAmmo:Fire(self.Equipment.Owner, self.ReserveAmmo)
        end
    end)

    self._trove:Connect(self.Equipment.Equipped, function(isEquipped: boolean)
        self.CanFire:Set(false)
        self.CanReload:Set(true)

        if isEquipped then
            self:_setupAnimationEvents()
            self._readyThread = task.delay(self.DeployTime, function()
                self.CanFire:Set(true)
                self._readyThread = nil
            end)
        else
            self:_cleanupAnimationEvents()
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

function Gun:_setupAnimationEvents()
    local animationManager = self.Equipment.AnimationManager

    local reloadTrack: AnimationTrack = animationManager:GetAnimation("Reload")
    self._animTrove = self._trove:Extend()

    self._animTrove:Connect(reloadTrack:GetMarkerReachedSignal("out"), function()
        if self.Magazine == nil then return end
        self.Magazine.Transparency = 1
    end)
    self._animTrove:Connect(reloadTrack:GetMarkerReachedSignal("in"), function()
        self:RefillMagazine(self.MagazineCapacity - self.CurrentAmmo)
        self.CanReload:Set(true)
        if self.Magazine == nil then return end
        self.Magazine.Transparency = 0
    end)
    self._animTrove:Connect(reloadTrack.Stopped, function()
        -- could be weird if reload is faster than deploy
        self.CanFire:Set(true)
    end)
end

function Gun:_cleanupAnimationEvents()
    self._animTrove:Destroy()
    self._animTrove = nil
end

function Gun:SetCurrentAmmo(amount: number)
    self.CurrentAmmo = amount
    self.UpdateCurrentAmmo:Fire(self.Equipment.Owner, amount)
end

function Gun:SetReserveAmmo(amount: number)
    self.ReserveAmmo = amount
    self.UpdateReserveAmmo:Fire(self.Equipment.Owner, amount)
end

function Gun:RefillMagazine(roundsNeeded: number)
    local roundsGiven = 0
	if self.ReserveAmmo < roundsNeeded then
		-- dump the rest of the ammo into the mag
		roundsGiven = self.ReserveAmmo
	else
		roundsGiven = roundsNeeded
	end
	self:SetCurrentAmmo(self.CurrentAmmo + roundsGiven)
    self:SetReserveAmmo(self.ReserveAmmo - roundsGiven)
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
    if not self.CanFire:Get() then return end
    if self.CurrentAmmo == 0 then return end

    self:SetCurrentAmmo(self.CurrentAmmo - 1)

    self.Equipment.AnimationManager:PlayAnimation("Fire")
    self.FireEvent:FireExcept(self.Equipment.Owner, origin, direction)
end

function Gun:RegisterHit(player: Player, instance: Instance)
    if not self.Equipment.IsPickedUp:Get() then return end
    if self.Equipment.Owner ~= player then return end

    -- print("hit", instance.Name)

    local parent = instance.Parent
    if not parent then return end
    local humanoid = parent:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    self:_dealDamage(humanoid, instance)
end

function Gun:Reload(player: Player)
    if self.Equipment.Owner ~= player then return end
    if not self.Equipment.IsPickedUp:Get() then return end
    if not self.Equipment.IsEquipped:Get() then return end
    if not self.CanReload:Get() then return end
    if self.CurrentAmmo == self.MagazineCapacity or self.ReserveAmmo < 1 then return end

    self.CanReload:Set(false)
    self.CanFire:Set(false)

    -- print("reloading")
    self.ReloadEvent:Fire(self.Equipment.Owner)
    self.Equipment.AnimationManager:PlayAnimation("Reload")
end

return Gun
