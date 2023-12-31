
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- definition of common ancestor
local Packages = ReplicatedStorage.Packages

-- block of all imported packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

-- definitions derived from packages

-- block for modules imported from same project
local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)

-- module level constants
local DEBUG = true
local UI_EVENTS = ReplicatedStorage.UIEvents

local Gun = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

local dependencies = {
	"Equipment"
}

function Gun:Construct()
	-- ensure gun gets dependent components
	for _, v in dependencies do
		CollectionService:AddTag(self.Instance, v)
	end

	self._cfg = EquipmentConfig[self.Instance.Name]
	self._trove = Trove.new()

	self.Aiming = false
	self.Firing = false
	self.Reloading = false
	self.CanFire = false

	local CastParams = RaycastParams.new()
	CastParams.CollisionGroup = "Character"
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self._castParams = CastParams

	local function newRemoteEvent(name: string): RemoteEvent
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = self.Instance
		return event
	end

	self.ReloadEvent = newRemoteEvent("ReloadEvent")
	self.UpdateCurrentAmmo = newRemoteEvent("UpdateCurrentAmmo")
	self.UpdateReserveAmmo = newRemoteEvent("UpdateReserveAmmo")
end

function Gun:Start()
	Equipment:WaitForInstance(self.Instance):andThen(function(component)
		self.Equipment = component
	end):catch(warn):await()

	local modelRoot = self.Equipment.WorldModel.PrimaryPart
	self.FirePoint = modelRoot.FirePoint
	self.FireSound = modelRoot.FireSound
	self.ImpactParticle = modelRoot:FindFirstChild("ImpactParticle") -- some guns may not have impact particles :)

	self.Magazine = Find.path(self.Equipment.WorldModel, "Magazine")

	self.Equipment.Use = function(player, ...)
		self:Fire(player, ...)
	end

	self._trove:Connect(self.Equipment.PickedUp, function(pickedUp: boolean)
		-- print(self.Ammo, "/", self.ReserveAmmo)
		if pickedUp then
			self.UpdateCurrentAmmo:FireClient(self.Equipment.Owner, self.Ammo)
			self.UpdateReserveAmmo:FireClient(self.Equipment.Owner, self.ReserveAmmo)
		end
	end)

	self._trove:Connect(self.Equipment.Equipped, function(equipped: boolean)
		if equipped then
			self._castParams.FilterDescendantsInstances = { self.Equipment.Character }
			self.UpdateCurrentAmmo:FireClient(self.Equipment.Owner, self.Ammo)
			self.UpdateReserveAmmo:FireClient(self.Equipment.Owner, self.ReserveAmmo)
			task.wait(0.8)
			self.CanFire = true
		else
			self._castParams.FilterDescendantsInstances = {}
			self.CanFire = false
		end
	end)

	self._trove:Connect(self.ReloadEvent.OnServerEvent, function(player: Player)
		local verbose = false
		if self.Equipment.Owner ~= player then
			if verbose then error("Non-owner tried reload") else return end
		elseif not self.Equipment.IsEquipped then
			if verbose then error("not equipped") else return end
		elseif self.Firing then
			if verbose then error("currently firing") else return end
		elseif self.Reloading then
			if verbose then error("already reloading") else return end
		end

		self:Reload()
	end)

	self.Ammo = self._cfg.MagazineCapacity
	self.ReserveAmmo = self._cfg.MagazineCapacity * self._cfg.ReserveMagazines
end

function Gun:Stop()
    self._trove:Destroy()
end

function Gun:PlayFireSound()
	local soundClone: Sound = self._trove:Clone(self.FireSound)
	soundClone.Parent = self.FireSound.Parent
	soundClone.TimePosition = 0.02 -- TODO: just fix the sounds

	soundClone:Play()
	Debris:AddItem(soundClone, soundClone.TimeLength)
end

function Gun:DoMuzzleFlash()
	for _, v in self.FirePoint:GetChildren() do
		if not v:IsA("ParticleEmitter") and not v:IsA("PointLight") then continue end
		task.spawn(function()
			v.Enabled = true
			task.wait(0.05)
			v.Enabled = false
		end)
	end
end

function Gun:MakeImpactParticleFX(position, normal) -- (adapted from FastCast Example Gun)
	if self.ImpactParticle == nil then return end

	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain
	attachment.WorldCFrame = CFrame.new(position, position + normal)

	local particle = self.ImpactParticle:Clone()
	particle.Parent = attachment
	Debris:AddItem(attachment, particle.Lifetime.Max)

	-- A potentially better option in favor of this would be to use the Emit method (Particle:Emit(numParticles)) though I prefer this since it adds some natural spacing between the particles.
	particle.Enabled = true
	task.wait(0.05)
	particle.Enabled = false
end

function Gun:_registerHits(hits: {Instance})
	local verbose = false
	if hits == nil then
		if verbose then warn("nil hits") end
		return
	elseif type(hits) ~= "table" then
		if verbose then warn("invalid hit table") end
		return
	end

	-- local head = self.Equipment.Character:FindFirstChild("Head")
	for _, instance in hits do
		-- local cast = workspace:Raycast(head.CFrame.Position, instance.CFrame.Position-head.CFrame.Position, self._castParams)
		-- if not cast then
		-- 	print("erm (found nothing instead of hit)")
		-- 	return
		-- elseif cast.Distance - self._cfg.BulletMaxDistance > 50 then
		-- 	print(string.format("erm... (%d vs. %d)", cast.Distance, self._cfg.BulletMaxDistance))
		-- 	return
		-- elseif cast.Instance ~= instance then
		-- 	local distance = (cast.Position - instance.CFrame.Position).Magnitude
		-- 	if distance > 10 then
		-- 		print(string.format("erm...... (%s vs. %s)", cast.Instance.Name, instance.Name))
		-- 		return
		-- 	end
		-- end

		local character: Model? = instance.Parent
		if instance.Parent == nil then return end
		if not character:IsA("Model") then return end

		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		if humanoid == nil then return end
		if humanoid.Health <= 0 then return end

		local damage = self._cfg.Damage
		local isHeadshot = instance.Name == "Head"

		if isHeadshot then
			damage *= 2
		end

		humanoid:TakeDamage(damage)

		local hitType = "Hit"
		if humanoid.Health <= 0 then
			hitType = "Kill"
		-- elseif isHeadshot then
		-- 	hitType = "Headshot"
		elseif damage < 15 then
			hitType = "Graze"
		end

		UI_EVENTS.HitRegistered:FireClient(self.Equipment.Owner, hitType)
	end
end

function Gun:Fire(_, hits: {Instance})
	if not self.CanFire then return end
	if self.Reloading or self.Firing then return end
	if self.Ammo < 1 then return end

	-- TODO: check if gun is firing too fast

	-- print(result)
	self.Firing = true

	self.Ammo -= 1

	-- TODO: make recoil patterns
	-- local verticalKick = 25
	-- local horizontalKick = math.random(-10, 10)

	self.Equipment.AnimationManager:PlayAnimation("Fire")
	-- self.Equipment.UseEvent:FireClient(self.Equipment.Owner, horizontalKick, verticalKick)
	self.UpdateCurrentAmmo:FireClient(self.Equipment.Owner, self.Ammo)

	self:PlayFireSound()
	self:DoMuzzleFlash()

	self:_registerHits(hits)

	self.Firing = false
end

function Gun:SetCurrentAmmo(ammo: number)
	self.Ammo = ammo
	self.UpdateCurrentAmmo:FireClient(self.Equipment.Owner, ammo)
end

function Gun:SetReserveAmmo(ammo: number)
	self.ReserveAmmo = ammo
	self.UpdateReserveAmmo:FireClient(self.Equipment.Owner, ammo)
end

function Gun:_refillMagazine(roundsNeeded: number)
	local roundsGiven = 0
	if self.ReserveAmmo < roundsNeeded then
		-- dump the rest of the ammo into the mag
		roundsGiven = self.ReserveAmmo
	else
		roundsGiven = roundsNeeded
	end
	self:SetCurrentAmmo(self.Ammo + roundsGiven)
	self:SetReserveAmmo(self.ReserveAmmo - roundsGiven)
end

function Gun:Reload()
	if self.Reloading or self.Firing then return end
	if self.Ammo == self._cfg.MagazineCapacity or self.ReserveAmmo < 1 then return end

	local roundsNeeded = (self._cfg.MagazineCapacity - self.Ammo)

	self.Reloading = true
	self.ReloadEvent:FireClient(self.Equipment.Owner)

	-- should probably sync this with anim events
	-- self:PlayReloadSound()

	local animationManager = self.Equipment.AnimationManager
	local reloadTrack: AnimationTrack
	if self.Aiming then
		reloadTrack = animationManager:GetAnimation("AimReload")
	else
		reloadTrack = animationManager:GetAnimation("Reload")
	end

	if reloadTrack ~= nil then
		reloadTrack:Play()
		reloadTrack.Stopped:Wait()
	end

	self:_refillMagazine(roundsNeeded)

	self.Reloading = false
end

return Gun
