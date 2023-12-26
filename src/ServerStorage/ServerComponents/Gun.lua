
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- definition of common ancestor
local Packages = ReplicatedStorage.Packages

-- block of all imported packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

-- definitions derived from packages

-- block for modules imported from same project
local GunConfig = require(ReplicatedStorage.Source.GunConfig)
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

	self._cfg = GunConfig[self.Instance.Name]
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

	local reloadEvent = Instance.new("RemoteEvent")
	reloadEvent.Name = "Reload"
	reloadEvent.Parent = self.Instance
	self.ReloadEvent = reloadEvent
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

	self._trove:Connect(self.Equipment.Equipped, function(equipped: boolean)
		if equipped then
			self._castParams.FilterDescendantsInstances = { self.Equipment.Character }
			UI_EVENTS.UpdateCurrentAmmo:FireClient(self.Equipment.Owner, self.Ammo)
			UI_EVENTS.UpdateReserveAmmo:FireClient(self.Equipment.Owner, self.ReserveAmmo)
			task.wait(.75)
			self.CanFire = true
		else
			self._castParams.FilterDescendantsInstances = {}
			self.CanFire = false
		end
	end)

	self._trove:Connect(self.ReloadEvent.OnServerEvent, function(player: Player)
		local verbose = true
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

function Gun:_registerHit(instance: Instance)
	local head = Find.path(self.Equipment.Character, "Head")
	local cast = workspace:Raycast(head.CFrame.Position, instance.CFrame.Position-head.CFrame.Position, self._castParams)
	-- print(cast.Instance, result)
	if not cast then
		print("erm (found nothing instead of hit)")
		return
	elseif cast.Distance > self._cfg.BulletMaxDistance then
		print(string.format("erm... (%d vs. %d)", cast.Distance, self._cfg.BulletMaxDistance))
		return
	elseif cast.Instance ~= instance then
		print(string.format("erm...... (%s vs. %s)", cast.Instance.Name, instance.Name))
		return
	end

	local character: Model? = instance.Parent
	if instance.Parent == nil then return end
	if not character:IsA("Model") then return end

	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then return end

	humanoid:TakeDamage(self._cfg.Damage)
end

function Gun:Fire(_, result: Instance)
	if not self.CanFire then return end
	if self.Reloading or self.Firing then return end
	if self.Ammo < 1 then return end

	-- TODO: check if gun is firing too fast

	-- print(result)
	self.Firing = true

	self.Ammo -= 1

	-- TODO: make recoil patterns
	local verticalKick = 25
	local horizontalKick = math.random(-10, 10)

	self.Equipment.AnimationManager:PlayAnimation("Fire")
	self.Equipment.UseEvent:FireClient(self.Equipment.Owner, horizontalKick, verticalKick)
	UI_EVENTS.UpdateCurrentAmmo:FireClient(self.Equipment.Owner, self.Ammo)

	self:PlayFireSound()
	self:DoMuzzleFlash()

	self:_registerHit(result)

	self.Firing = false
end

function Gun:SetCurrentAmmo(ammo: number)
	self.Ammo = ammo
	UI_EVENTS.UpdateCurrentAmmo:FireClient(self.Equipment.Owner, ammo)
end

function Gun:SetReserveAmmo(ammo: number)
	self.ReserveAmmo = ammo
	UI_EVENTS.UpdateReserveAmmo:FireClient(self.Equipment.Owner, ammo)
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
