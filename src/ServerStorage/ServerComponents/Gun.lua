local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PartCache = require(ReplicatedStorage.Packages.PartCache)

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ServerStorage.Source.ServerComponents.Extensions.Logger)

local NamedInstance = require(ReplicatedStorage.Source.NamedInstance)

local Gun = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

function Gun:Construct()
	self._trove = Trove.new()

	self.Aiming = false
	self.Firing = false
	self.Reloading = false
	self.CanFire = true
	self.CanReload = true

	self.Animations = {}

	self.MouseEvent = self._trove:Add(NamedInstance.new("MouseEvent", "RemoteEvent", self.Instance))
	self.RecoilEvent = self._trove:Add(NamedInstance.new("RecoilEvent", "RemoteEvent", self.Instance))
	self.AimEvent = self._trove:Add(NamedInstance.new("AimEvent", "RemoteEvent", self.Instance))
	self.ReloadRemoteFunction = self._trove:Add(NamedInstance.new("Reload", "RemoteFunction", self.Instance))
	self.EquipEvent = self._trove:Add(NamedInstance.new("EquipEvent", "RemoteEvent", self.Instance))
	self.ModelLoaded = self._trove:Add(NamedInstance.new("ModelLoaded", "RemoteEvent", self.Instance))

	self.Config = ReplicatedStorage.Weapons[self.Instance.Name].Configuration
	self.GUN_STATS = self.Config:GetAttributes()

	self.Ammo = self.GUN_STATS.MagazineCapacity
	self.ReserveAmmo = self.GUN_STATS.MagazineCapacity * self.GUN_STATS.ReserveMagazines

	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self.CastParams = CastParams

	self.Instance.CanBeDropped = false
	self.Instance.RequiresHandle = false

	-- serverside gun.model refers to the 3rd person gun model
	self.Model = self._trove:Clone(ReplicatedStorage.Weapons[self.Instance.Name].GunModel)
	if self.Instance.Name == "AK-47" then
		self.Model:ScaleTo(0.762) -- viewmodel uses normal scale while physical model needs to be smaller
	end

	self.FirePoint = self.Model:FindFirstChild("FirePoint", true)
	self.FireSound = self.Model:FindFirstChild("FireSound", true)

	self.ImpactParticle = self.Model.Receiver:FindFirstChild("ImpactParticle")
end

function Gun:PlayFireSound()
	local soundClone: Sound = self._trove:Clone(self.FireSound)
	soundClone.Parent = self.FireSound.Parent
	soundClone.TimePosition = 0.02
	soundClone.Ended:Connect(function(soundId) -- very inefficient but it keeps the sound's position with the firer so it doesnt sound weird
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
	local character: Model? = self.Instance.Parent
	if not character then error("Gun firing with no parent") end
	if character:IsA("Backpack") then return end
	if character:GetAttribute("Ragdolled") then return end

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
	self.RecoilEvent:FireClient(Players:GetPlayerFromCharacter(character), verticalKick, horizontalKick)

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
		self.Ammo += self.ReserveAmmo
		self.ReserveAmmo = 0
	else
		self.Ammo += roundsNeeded
		self.ReserveAmmo -= roundsNeeded
	end
end

function Gun:PlayReloadSound()
	
end

function Gun:Reload(): boolean?
	local character: Model? = self.Instance.Parent
	if not character then error("Gun reloading with no parent") end
	if character:IsA("Backpack") then return end
	if character:GetAttribute("Ragdolled") then return end

	self.Reloading = true

	local roundsNeeded = (self.GUN_STATS.MagazineCapacity - self.Ammo)
	if roundsNeeded < 1 then warn("reloading is pointless") self.Reloading = false return end

	self:PlayReloadSound()
	if self.Aiming and self.Animations.AimReload ~= nil then
		self.Animations.AimReload:Play()
	elseif self.Animations.Reload ~= nil then
		self.Animations.Reload:Play()
	end

	self:_refillMagazine(roundsNeeded)
	self.Reloading = false
	return true
end

function Gun:OnReloadInvoked(player: Player)
	if player ~= self.Owner then error("non owner cannot invoke reload") end
	if not self.CanReload then warn("cannot currently reload") return end
	if self.Firing then error("cannot reload; firing") end
	if self.Reloading then error("already reloading") end
	return self:Reload()
end

function Gun:OnMouseEvent(player: Player, direction: Vector3)
	if player ~= self.Owner then return end
	if not self.CanFire then return end

	self.CanFire = false
	if self.Ammo > 0 then
		self.Ammo -= 1

		-- avoid negative ammo with shotguns
		for _ = 1, self.GUN_STATS.BulletsPerShot do
			self:Fire(direction)
		end

		task.wait(60 / self.GUN_STATS.RPM)
	end
	self.CanFire = true
end

function Gun:OnAimEvent(player: Player, isAiming: boolean)
	if player ~= self.Owner then return end
	if not self.Animations.AimIdle then return end

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

	local animations3P = ReplicatedStorage.Weapons[self.Instance.Name].Animations["3P"]
	for _, v in animations3P:GetChildren() do
		self.Animations[v.Name] = humanoid:LoadAnimation(v)
	end
end

function Gun:OnEquipped()
	-- print(self.Instance.Parent, "equipped", self.Instance.Name)
	self.Character = self.Instance.Parent
	self.CastParams.FilterDescendantsInstances = { self.Character }

	self:LoadAnimations()

	self.Model.Parent = self.Character
	self.Model.PrimaryPart.RootJoint.Part0 = self.Character["Right Arm"]
	self.Animations.Idle:Play()

	self.EquipEvent:FireClient(self.Owner, true)
	self.Owner.CameraMode = Enum.CameraMode.LockFirstPerson
end

function Gun:OnUnequipped()
	--print(self.Instance.Parent, "unequipped", self.Instance.Name)
	for _, v in self.Animations do
		v:Stop()
	end

	self.Model.PrimaryPart.RootJoint.Part0 = self.Character.Torso
	self.Animations.Holster:Play()

	self.EquipEvent:FireClient(self.Owner, false)
	self.Owner.CameraMode = Enum.CameraMode.Classic
end

function Gun:Start()
	-- TODO: this may introduce a race condition in (un)equip event handlers where self.Owner is not yet updated
	local function OnInstanceAncestryChanged(child: Instance, parent: Instance)
		if child ~= self.Instance then return end

		local owner = nil
		if parent.ClassName == "Model" then
			owner = Players:GetPlayerFromCharacter(parent)
		elseif parent.ClassName == "Backpack" then
			owner = parent.Parent
		end

		self.Owner = owner
		self.Instance:SetAttribute("OwnerID", owner.UserId)
	end
	OnInstanceAncestryChanged(self.Instance, self.Instance.Parent)
	self._trove:Connect(self.Instance.AncestryChanged, OnInstanceAncestryChanged)

	self.Model.Parent = self.Instance
	if self.Owner ~= nil then
		self.Character = self.Owner.Character
		self.Model.Parent = self.Character
		self:LoadAnimations()

		self.Model.PrimaryPart.RootJoint.Part0 = self.Character.Torso
		self.Animations.Holster:Play()
	end
	self.ModelLoaded:FireClient(self.Owner, self.Model)

	self._trove:Connect(self.Instance.Equipped, function(...) self:OnEquipped(...) end)
	self._trove:Connect(self.Instance.Unequipped, function() self:OnUnequipped() end)

	self._trove:Connect(self.MouseEvent.OnServerEvent, function(...) self:OnMouseEvent(...) end)
	self._trove:Connect(self.AimEvent.OnServerEvent, function(...) self:OnAimEvent(...) end)
	self.ReloadRemoteFunction.OnServerInvoke = function(...) return self:OnReloadInvoked(...) end
end

function Gun:Stop()
	self._trove:Destroy()
end

return Gun
