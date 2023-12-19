
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PartCache = require(ReplicatedStorage.Packages.PartCache) -- use for bullet casings maybe
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local NamedInstance = require(ReplicatedStorage.Source.NamedInstance)
local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)

local Gun = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

local dependencies = {
	"Equipment"
}

local UPDATE_CURRENT_AMMO_UI = ReplicatedStorage.UIEvents.UpdateCurrentAmmo
local UPDATE_RESERVE_AMMO_UI = ReplicatedStorage.UIEvents.UpdateReserveAmmo

local WEAPONS = ReplicatedStorage.Equipment.Weapons

function Gun:Construct()
	self._trove = Trove.new()

	self.Aiming = false
	self.Firing = false
	self.Reloading = false
	self.CanFire = true

	self.Animations = {}

	self.MouseEvent = self._trove:Add(NamedInstance.new("MouseEvent", "RemoteEvent", self.Instance))
	self.RecoilEvent = self._trove:Add(NamedInstance.new("RecoilEvent", "RemoteEvent", self.Instance))
	self.AimEvent = self._trove:Add(NamedInstance.new("AimEvent", "RemoteEvent", self.Instance))
	self.ReloadEvent = self._trove:Add(NamedInstance.new("ReloadEvent", "RemoteEvent", self.Instance))
	self.EquipEvent = self._trove:Add(NamedInstance.new("EquipEvent", "RemoteEvent", self.Instance))
	self.ModelLoaded = self._trove:Add(NamedInstance.new("ModelLoaded", "RemoteEvent", self.Instance))

	self.Config = WEAPONS[self.Instance.Name].Configuration
	self.GUN_STATS = self.Config:GetAttributes()

	self.Ammo = self.GUN_STATS.MagazineCapacity
	self.ReserveAmmo = self.GUN_STATS.MagazineCapacity * self.GUN_STATS.ReserveMagazines

	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self.CastParams = CastParams

	-- serverside gun.model refers to the 3rd person gun model
	self.Model = self._trove:Clone(WEAPONS[self.Instance.Name].WorldModel)
	if self.Instance.Name == "AK-47" then
		self.Model:ScaleTo(0.762) -- viewmodel uses normal scale while physical model needs to be smaller
	end
	self.Model.Parent = self.Instance

	self.FirePoint = self.Model:FindFirstChild("FirePoint", true)
	self.FireSound = self.Model:FindFirstChild("FireSound", true)
	self.ReloadSound = self.Model.PrimaryPart:FindFirstChild("ReloadSound", true)

	self.ImpactParticle = self.Model.Receiver:FindFirstChild("ImpactParticle")

	-- a reference to the gun's Equipment component
	self.Equipment = nil

	-- ensure dependencies
	for _,v in dependencies do
		CollectionService:AddTag(self.Instance, v)
	end
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
	local firePoint = self.Model.Receiver.FirePoint
	for _, v in firePoint:GetChildren() do
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

function Gun:Fire(direction: Vector3) -- (adapted from FastCast Example Gun)
	local character: Model = self.Instance.Parent

	self.Firing = true

	local headPosition = character.HumanoidRootPart.Position + Vector3.yAxis * 1.5
	local hitscan = workspace:Raycast(headPosition, direction.Unit * self.GUN_STATS.BulletMaxDistance, self.CastParams)
	if hitscan then
		if hitscan.Instance.Parent then
			-- print(hitscan.Instance.Parent)
			local headshot = (hitscan.Instance.Name == "Head")
			local humanoid: Humanoid? = hitscan.Instance.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid ~= nil then
				-- print("hit", hitscan.Instance.Parent)
				humanoid:TakeDamage(self.GUN_STATS.Damage * if headshot then 2 else 1)
				if humanoid.Health - self.GUN_STATS.Damage <= 0 then
					hitscan.Instance:ApplyImpulse(direction.Unit * self.GUN_STATS.Damage * 23)
				end
			end
		end
	end

	local verticalKick = 25
	local horizontalKick = math.random(-10, 10)
	self.RecoilEvent:FireClient(self.Equipment.Owner, verticalKick, horizontalKick, self.Ammo)

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

function Gun:PlayReloadSound()
	self.ReloadSound:Play()
end

function Gun:Reload()
	local roundsNeeded = (self.GUN_STATS.MagazineCapacity - self.Ammo)
	if roundsNeeded < 1 then
		-- error("reloading is pointless")
		return
	end

	self.Reloading = true
	self.ReloadEvent:FireClient(self.Equipment.Owner)

	-- should probably sync this with anim events
	-- self:PlayReloadSound()

	local reloadAnim: AnimationTrack
	if self.Aiming and self.Animations.AimReload ~= nil then
		reloadAnim = self.Animations.AimReload
	elseif self.Animations.Reload ~= nil then
		reloadAnim = self.Animations.Reload
	end

	if reloadAnim ~= nil then
		reloadAnim.Stopped:Once(function()
			self:_refillMagazine(roundsNeeded)
			self.Reloading = false
		end)
		reloadAnim:Play()
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

function Gun:OnMouseEvent(player: Player, direction: Vector3)
	if player ~= self.Equipment.Owner then return end
	if not self.CanFire then return end
	if self.Reloading then return end
	local character: Model? = self.Instance.Parent
	if not character then error("Gun cannot fire with no parent") end
	if character:IsA("Backpack") then return end
	if character:GetAttribute("Ragdolled") then return end

	self.CanFire = false
	if self.Ammo > 0 then
		-- avoid negative ammo with shotguns
		self:SetCurrentAmmo(self.Ammo - 1)

		for _ = 1, self.GUN_STATS.BulletsPerShot do
			self:Fire(direction)
		end

		task.wait(60 / self.GUN_STATS.RPM)
	end
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

	local animations3P = WEAPONS[self.Instance.Name].Animations["3P"]
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

function Gun:OnEquipped(playerWhoEquipped: Player)
	self.Model.PrimaryPart.CanCollide = false
	self.Instance.Parent = playerWhoEquipped.Character
	self.Character = self.Instance.Parent
	self.CastParams.FilterDescendantsInstances = { self.Character }

	self:LoadAnimations()

	local magazinePart = self.Model:WaitForChild("Magazine")
	local magazineJoint = magazinePart.Magazine
	magazineJoint.Part0 = self.Character.PrimaryPart -- character's hrp

	self.Model.PrimaryPart.RootJoint.Part0 = self.Character.PrimaryPart
	self.Animations.Idle:Play()

	self.EquipEvent:FireClient(self.Equipment.Owner, true)
	UPDATE_CURRENT_AMMO_UI:FireClient(self.Equipment.Owner, self.Ammo)
	UPDATE_RESERVE_AMMO_UI:FireClient(self.Equipment.Owner, self.ReserveAmmo)
	self.Equipment.Owner.CameraMode = Enum.CameraMode.LockFirstPerson
end

function Gun:OnUnequipped()
	self.Model.PrimaryPart.CanCollide = true
	print(self.Instance.Parent, "unequipped", self.Instance.Name)
	for _, v in self.Animations do
		v:Stop()
	end

	-- release rig and reconnect the magazine
	local magazinePart = self.Model.Magazine
	local magazineJoint = magazinePart.Magazine
	magazineJoint.Part0 = self.Model.PrimaryPart -- gun's receiver

	self.Model.PrimaryPart.RootJoint.Part0 = self.Character.Torso
	-- self.Animations.Holster:Play()

	self.EquipEvent:FireClient(self.Equipment.Owner, false)
	self.Equipment.Owner.CameraMode = Enum.CameraMode.Classic
end

function Gun:Start()
	-- -- TODO: this may introduce a race condition in (un)equip event handlers where self.Equipment.Owner is not yet updated
	-- local function OnInstanceAncestryChanged(child: Instance, parent: Instance)
	-- 	if child ~= self.Instance then return end

	-- 	local owner = nil
	-- 	if parent.ClassName == "Model" then
	-- 		owner = Players:GetPlayerFromCharacter(parent)
	-- 	elseif parent.ClassName == "Backpack" then
	-- 		owner = parent.Parent
	-- 	end

	-- 	self.Equipment.Owner = owner
	-- 	if owner == nil then return end
	-- 	self.Instance:SetAttribute("OwnerID", owner.UserId)
	-- end
	-- OnInstanceAncestryChanged(self.Instance, self.Instance.Parent)
	-- self._trove:Connect(self.Instance.AncestryChanged, OnInstanceAncestryChanged)

	Equipment:WaitForInstance(self.Instance):andThen(function(component)
		self.Equipment = component
		self._trove:Connect(component.EquipEvent.Event, function(owner: Player, equipped: boolean)
			if equipped then
				self:OnEquipped(owner)
			else
				self:OnUnequipped()
			end
		end)
	end):await()

	self.Model.Parent = self.Instance
	if self.Equipment.Owner ~= nil then
		self.Character = self.Equipment.Owner.Character
		-- self.Model.Parent = self.Character
		self:LoadAnimations()

		self.Model.PrimaryPart.RootJoint.Part0 = self.Character.Torso
		self.Animations.Holster:Play()
	else
		self.Model.PrimaryPart.CanCollide = true
	end
	-- self.ModelLoaded:FireClient(self.Equipment.Owner, self.Model)

	self._trove:Connect(self.MouseEvent.OnServerEvent, function(...) self:OnMouseEvent(...) end)
	self._trove:Connect(self.AimEvent.OnServerEvent, function(...) self:OnAimEvent(...) end)
	self._trove:Connect(self.ReloadEvent.OnServerEvent, function(...) self:OnReloadEvent(...) end)
end

function Gun:Stop()
	self._trove:Destroy()
end

return Gun
