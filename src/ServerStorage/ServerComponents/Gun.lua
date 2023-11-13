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
		Logger
	}
})

local RNG = Random.new()
local TAU = math.pi * 2

function Gun:Construct()
	self._trove = Trove.new()

	self.Aiming = false
	self.CanFire = true

	self.Animations = {}

	self.MouseEvent = NamedInstance.new("MouseEvent", "RemoteEvent", self.Instance)
	self.RecoilEvent = NamedInstance.new("RecoilEvent", "RemoteEvent", self.Instance)
	self.AimEvent = NamedInstance.new("AimEvent", "RemoteEvent", self.Instance)
	self.EquipEvent = NamedInstance.new("EquipEvent", "RemoteEvent", self.Instance)
	self.ModelLoaded = NamedInstance.new("ModelLoaded", "RemoteEvent", self.Instance)

	self.Config = ReplicatedStorage.Weapons[self.Instance.Name].Configuration
	local GUN_STATS = self.Config:GetAttributes()

	self.BULLET_SPEED = GUN_STATS.BulletSpeed
	self.BULLET_MAXDIST = GUN_STATS.BulletMaxDistance
	self.BULLET_GRAVITY = GUN_STATS.BulletGravity
	self.MIN_SPREAD_ANGLE = GUN_STATS.MinSpreadAngle
	self.MAX_SPREAD_ANGLE = GUN_STATS.MaxSpreadAngle
	self.BULLETS_PER_SHOT = GUN_STATS.BulletsPerShot
	self.CAN_PIERCE = GUN_STATS.CanPierce
	self.DAMAGE = GUN_STATS.Damage or 5
	self.RPM = GUN_STATS.RPM or 100

	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self.CastParams = CastParams

	self.Instance.CanBeDropped = false
	self.Instance.RequiresHandle = false

	-- the serverside gun component refers to the 3rd person gun model
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
		task.spawn(function()
			if v:IsA("ParticleEmitter") then
				v.Transparency = NumberSequence.new(v.repTransparency.Value)
				v.Enabled = true
				task.wait(.1)
				v.Enabled = false
				v.Transparency = NumberSequence.new(v.transparency.Value)
			end
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

	local headPosition = character.HumanoidRootPart.Position + Vector3.yAxis * 1.5

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
end

function Gun:OnMouseEvent(player: Player, direction: Vector3)
	if not self.CanFire then return end
	self.CanFire = false
	for _ = 1, self.BULLETS_PER_SHOT do
		self:Fire(direction)
	end
	task.wait(60 / self.RPM)
	self.CanFire = true
end

function Gun:OnAimEvent(player: Player, isAiming: boolean)
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
	for _,v in animations3P:GetChildren() do
		self.Animations[v.Name] =  humanoid:LoadAnimation(v)
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
end

function Gun:OnUnequipped()
	--print(self.Instance.Parent, "unequipped", self.Instance.Name)
	for _,v in self.Animations do
		v:Stop()
	end

	self.Model.PrimaryPart.RootJoint.Part0 = self.Character.Torso
	self.Animations.Holster:Play()

	self.EquipEvent:FireClient(self.Owner, false)
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
end

function Gun:Stop()
	self._trove:Destroy()
end

return Gun
