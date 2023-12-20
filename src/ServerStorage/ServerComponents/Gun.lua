
local DEBUG = false

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PartCache = require(ReplicatedStorage.Packages.PartCache) -- use for bullet casings maybe
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)

local Gun = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

local UPDATE_CURRENT_AMMO_UI = ReplicatedStorage.UIEvents.UpdateCurrentAmmo
local UPDATE_RESERVE_AMMO_UI = ReplicatedStorage.UIEvents.UpdateReserveAmmo

local GUNS = ReplicatedStorage.Equipment.Guns

function Gun:Construct()
	-- ensure gun has an equipment component
	CollectionService:AddTag(self.Instance, "Equipment")

	self._trove = Trove.new()

	self.Aiming = false
	self.Firing = false
	self.Reloading = false
	self.CanFire = true

	self.Animations = {}

	self.Config = GUNS[self.Instance.Name].Configuration:GetAttributes()

	self.Ammo = self.Config.MagazineCapacity
	self.ReserveAmmo = self.Config.MagazineCapacity * self.Config.ReserveMagazines

	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self.CastParams = CastParams

	local recoilEvent = Instance.new("RemoteEvent")
	recoilEvent.Name = "RecoilEvent"
	recoilEvent.Parent = self.Instance
	self.RecoilEvent = recoilEvent

	self._lastFired = 0
end

function Gun:PlayFireSound()
	local soundClone: Sound = self._trove:Clone(self.FireSound)
	soundClone.Parent = self.FireSound.Parent
	soundClone.TimePosition = 0.02
	soundClone.Ended:Connect(function(_) -- very inefficient but it keeps the sound's position with the firer so it doesnt sound weird
		soundClone:Destroy()
	end)
	soundClone:Play()
end

function Gun:DoMuzzleFlash()
	for _, v in self.FirePoint:GetChildren() do
		if not v:IsA("ParticleEmitter") and not v:IsA("PointLight") then continue end
		task.spawn(function()
			v.Enabled = true
			task.wait(0.1)
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

function Gun:_registerHit(hitscan: RaycastResult, direction: Vector3)
	if not hitscan.Instance.Parent then return end

	-- print(hitscan.Instance.Parent)
	local headshot = (hitscan.Instance.Name == "Head")
	local humanoid: Humanoid? = hitscan.Instance.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then return end
	-- print("hit", hitscan.Instance.Parent)

	humanoid:TakeDamage(self.Config.Damage * if headshot then 2 else 1)
	if humanoid.Health - self.Config.Damage <= 0 then
		hitscan.Instance:ApplyImpulse(direction.Unit * self.Config.Damage * 23)
	end
end

function Gun:Fire(direction: Vector3)
	self.Firing = true

	local headPosition = self.Character.HumanoidRootPart.Position + Vector3.yAxis * 1.5
	local hitscan = workspace:Raycast(headPosition, direction.Unit * self.Config.BulletMaxDistance, self.CastParams)
	if hitscan ~= nil then
		self:_registerHit(hitscan, direction)
	end

	-- TODO: make recoil patterns
	local verticalKick = 25
	local horizontalKick = math.random(-10, 10)
	-- self.Equipment.UseRequest:InvokeClient(self.Equipment.Owner, verticalKick, horizontalKick, self.Ammo)

	self:PlayFireSound()
	self:DoMuzzleFlash()
	if self.Aiming and self.Animations.AimFire ~= nil then
		self.Animations.AimFire:Play()
	elseif self.Animations.Fire ~= nil then
		self.Animations.Fire:Play()
	end

	self.Firing = false
end

function Gun:_refillMagazine(roundsNeeded: number)
	if self.ReserveAmmo < roundsNeeded then
		-- dump the rest of the ammo into the mag
		self:SetCurrentAmmo(self.Ammo + self.ReserveAmmo)
		self:SetReserveAmmo(0)
	else
		self:SetCurrentAmmo(self.Ammo + roundsNeeded)
		self:SetReserveAmmo(self.ReserveAmmo - roundsNeeded)
	end
end

function Gun:Reload()
	local roundsNeeded = (self.Config.MagazineCapacity - self.Ammo)
	if roundsNeeded < 1 then
		-- error("reloading is pointless")
		return
	end

	self.Reloading = true
	self.ReloadEvent:FireClient(self.Equipment.Owner)

	local reloadTrack: AnimationTrack
	if self.Aiming and self.Animations.AimReload ~= nil then
		reloadTrack = self.Animations.AimReload
	elseif self.Animations.Reload ~= nil then
		reloadTrack = self.Animations.Reload
	end

	if reloadTrack ~= nil then
		reloadTrack.Stopped:Once(function()
			self:_refillMagazine(roundsNeeded)
			self.Reloading = false
		end)
		reloadTrack:Play()
	else
		self:_refillMagazine(roundsNeeded)
		self.Reloading = false
	end
end

function Gun:OnReloadEvent(player: Player)
	if player ~= self.Equipment.Owner then error("non owner cannot reload") end
	if self.Firing then error("currently firing") end
	if self.Reloading then
		-- error("already reloading")
		return
	end
	if self.ReserveAmmo < 1 then
		-- error("no reserve ammo")
		return
	end

	local character: Model? = self.Instance.Parent
	if not character then error("Gun reloading with no parent") end
	if character:IsA("Backpack") then return end
	if character:GetAttribute("Ragdolled") then return end

	self:Reload()
end

function Gun:_use(direction: Vector3)
	if not self.CanFire then return end
	if self.Reloading then return end
	local character: Model? = self.Equipment.WorldModel.Parent
	if not character then error("Gun cannot fire with no parent") end
	if character:IsA("Backpack") then return end
	if character:GetAttribute("Ragdolled") then return end

	if self.Ammo <= 0 then
		if DEBUG then warn("No ammo") end
		return
	end

	self.CanFire = false
	print(string.format("time between shots: %d ms", (time() - self._lastFired)*1000))
	self._lastFired = time()

	-- avoid negative ammo with shotguns
	self:SetCurrentAmmo(self.Ammo - 1)

	for _ = 1, self.Config.BulletsPerShot do
		self:Fire(direction)
	end

	task.wait(60 / self.Config.RoundsPerMinute)

	self.CanFire = true
end

function Gun:OnAimEvent(player: Player, isAiming: boolean)
	if player ~= self.Equipment.Owner then return end
	if not self.Animations.AimIdle then return end
	-- print(isAiming)

	self.Aiming = isAiming

	local animTrack = self.Animations.AimIdle
	if isAiming then
		animTrack:Play()
	elseif animTrack.IsPlaying then
		animTrack:Stop()
	end
end

function Gun:LoadAnimations()
	local character = self.Character
	if not character then warn("cannot load animations without character") end
	local humanoid = self.Character:FindFirstChildOfClass("Humanoid")

	local animations3P = GUNS[self.Instance.Name].Animations["3P"]
	for _, v in animations3P:GetChildren() do
		local animTrack: AnimationTrack = humanoid.Animator:LoadAnimation(v)
		if animTrack.Name:match("[iI]dle") then animTrack.Priority = Enum.AnimationPriority.Idle end
		-- print(animTrack.Priority)
		self.Animations[v.Name] = animTrack
	end
end

function Gun:SetCurrentAmmo(ammo: number)
	self.Ammo = ammo
	UPDATE_CURRENT_AMMO_UI:FireClient(self.Equipment.Owner, ammo)
end

function Gun:SetReserveAmmo(ammo: number)
	self.ReserveAmmo = ammo
	UPDATE_RESERVE_AMMO_UI:FireClient(self.Equipment.Owner, ammo)
end

function Gun:_onEquipped()
	print("Gun:_onEquipped")
	self.Equipment.Owner.CameraMode = Enum.CameraMode.LockFirstPerson
	self.Character = self.Equipment.WorldModel.Parent
	self.CastParams.FilterDescendantsInstances = { self.Character }

	self:LoadAnimations()

	-- rig magazine
	local magazinePart = self.Equipment.WorldModel:WaitForChild("Magazine")
	local magazineJoint = magazinePart.Magazine
	-- magazineJoint.Part0 = self.Character.PrimaryPart -- character's hrp
	-- print('rigged')

	UPDATE_CURRENT_AMMO_UI:FireClient(self.Equipment.Owner, self.Ammo)
	UPDATE_RESERVE_AMMO_UI:FireClient(self.Equipment.Owner, self.ReserveAmmo)
end

function Gun:_onUnequipped()
	print("Gun:_onUnequipped")

	for _, v in self.Animations do
		v:Stop()
	end
	self.Equipment.Owner.CameraMode = Enum.CameraMode.Classic

	-- unrig magazine
	local magazinePart = self.Equipment.WorldModel.Magazine
	local magazineJoint = magazinePart.Magazine
	magazineJoint.Part0 = self.Equipment.WorldModel.PrimaryPart -- gun's receiver
end

function Gun:Start()
	self.Equipment = self:GetComponent(Equipment)

	self.Equipment.useFunctioniality = function(...) self:_use(...) end

	local modelRoot = self.Equipment.WorldModel.PrimaryPart
	self.FirePoint = modelRoot.FirePoint
	self.FireSound = modelRoot.FireSound
	self.ImpactParticle = modelRoot:FindFirstChild("ImpactParticle") -- some guns may not have impact particles :)

	self._trove:Connect(self.Equipment.Equipped, function(player, equipping: boolean)
		if equipping then
			self:_onEquipped()
		else
			self:_onUnequipped()
		end
	end)
end

function Gun:Stop()
	self._trove:Destroy()
end

return Gun
