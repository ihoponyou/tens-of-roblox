
-- allows for attacking like a gun

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local GunConfig = require(ServerStorage.Source.GunConfig)

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

end

function Gun:Start()
    self.Equipment = self:GetComponent(Equipment)

    -- ensure animations exist
    Find.path(self.Equipment.Folder, "Animations/3P/Fire")
end

function Gun:Stop()
	self._trove:Destroy()
end

-- allows for special damage calculation e.g. backstab
function Gun:_calculateDamage(_humanoid: Humanoid): number
    return self.Damage
end

function Gun:_dealDamage(humanoid: Humanoid)
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

return Gun
