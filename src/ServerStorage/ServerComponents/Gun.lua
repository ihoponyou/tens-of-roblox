local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FastCast = require(ReplicatedStorage.Packages.FastCastRedux)
FastCast.DebugLogging = false
FastCast.VisualizeCasts = false

local PartCache = require(ReplicatedStorage.Packages.PartCache)

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(ServerStorage.Source.ServerComponents.Extensions.Logger)

local Gun = Component.new({
	Tag = "Gun",
	Extensions = {
		Logger,
	},
})

local RNG = Random.new()
local TAU = math.pi * 2

local function newNamedInstance(class: string, parent: Instance, name: string)
	local instance = Instance.new(class)
	instance.Parent = parent
	instance.Name = name
	return instance
end

function Gun:Construct()
	self._trove = Trove.new()

	self.Aiming = false
	self.CanFire = true

	self.Animations = {}

	self.MouseEvent = newNamedInstance("RemoteEvent", self.Instance, "MouseEvent")
	self.RecoilEvent = newNamedInstance("RemoteEvent", self.Instance, "RecoilEvent")
	self.AimEvent = newNamedInstance("RemoteEvent", self.Instance, "AimEvent")

	self.Config = self.Instance:FindFirstChild("Configuration")
	local GUN_STATS = self.Config:GetAttributes()

	self.BULLET_SPEED = GUN_STATS.BulletSpeed -- Studs/second - the speed of the bullet
	self.BULLET_MAXDIST = GUN_STATS.BulletMaxDistance -- The furthest distance the bullet can travel
	self.BULLET_GRAVITY = GUN_STATS.BulletGravity -- The amount of gravity applied to the bullet in world space (so yes, you can have sideways gravity)
	self.MIN_SPREAD_ANGLE = GUN_STATS.MinSpreadAngle -- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The least accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. Generally you want to keep this at 0 so there's at least some chance of a 100% accurate shot.
	self.MAX_SPREAD_ANGLE = GUN_STATS.MaxSpreadAngle -- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The most accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. This cannot be less than the value above. A value of 90 will allow the gun to shoot sideways at most, and a value of 180 will allow the gun to shoot backwards at most. Exceeding 180 will not add any more angular varience.
	self.BULLETS_PER_SHOT = GUN_STATS.BulletsPerShot -- The amount of bullets to fire every shot. Make this greater than 1 for a shotgun effect.
	self.CAN_PIERCE = GUN_STATS.CanPierce
	self.DAMAGE = GUN_STATS.Damage or 5
	self.RPM = GUN_STATS.RPM or 100

	self.Caster = FastCast.new()

	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self.CastParams = CastParams

	local CastBehavior = FastCast.newBehavior()
	CastBehavior.RaycastParams = CastParams
	CastBehavior.MaxDistance = self.BULLET_MAXDIST
	CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default
	CastBehavior.CosmeticBulletContainer = workspace:FindFirstChild("ActiveCosmeticBullets")
	CastBehavior.CosmeticBulletProvider = PartCache.new(self.Config.Bullet.Value, self.RPM, CastBehavior.CosmeticBulletContainer)
	CastBehavior.Acceleration = self.BULLET_GRAVITY
	self.CastBehavior = CastBehavior

	self.Instance.CanBeDropped = false
	self.Instance.RequiresHandle = false

	self.Model = self._trove:Clone(ReplicatedStorage.Weapons[self.Instance.Name])
	if self.Model.Name == "AK-47" then
		self.Model:ScaleTo(0.762)
	end
	self.Model.Name = "GunModel"
	self.Model.Parent = self.Instance

	self.FirePoint = self.Instance:FindFirstChild("FirePoint", true)
	self.FireSound = self.Instance:FindFirstChild("FireSound", true)
end

function Gun:PlayFireSound()
	local soundClone: Sound = self._trove:Clone(self.FireSound)
	soundClone.TimePosition = 0.02
	soundClone.Parent = self.Character.PrimaryPart
	soundClone.PlayOnRemove = true
	soundClone:Destroy()
end

function Gun:MakeParticleFX(position, normal) -- (adapted from FastCast Example Gun)
	if self.ImpactParticle == nil then return end

	-- This is a trick I do with attachments all the time.
	-- Parent attachments to the Terrain - It counts as a part, and setting position/rotation/etc. of it will be in world space.
	-- UPD 11 JUNE 2019 - Attachments now have a "WorldPosition" value, but despite this, I still see it fit to parent attachments to terrain since its position never changes.
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.new(position, position + normal)
	attachment.Parent = workspace.Terrain
	local particle = self.ImpactParticle:Clone()
	particle.Parent = attachment
	Debris:AddItem(attachment, particle.Lifetime.Max) -- Automatically delete the particle effect after its maximum lifetime.

	-- A potentially better option in favor of this would be to use the Emit method (Particle:Emit(numParticles)) though I prefer this since it adds some natural spacing between the particles.
	particle.Enabled = true
	wait(0.05)
	particle.Enabled = false
end

function Gun._reflect(surfaceNormal: Vector3, bulletNormal: Vector3) -- (adapted from FastCast Example Gun)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

function Gun._canRayPierce(cast, rayResult: RaycastResult, segmentVelocity: Vector3) -- (adapted from FastCast Example Gun)
	-- returns whether or not bullet should pierce
	local MAX_PIERCES = 3

	local hits = cast.UserData.Hits
	if hits == nil then
		-- If the hit data isn't registered, set it to 1 (because this is our first hit)
		cast.UserData.Hits = 1
	else
		-- If the hit data is registered, add 1.
		cast.UserData.Hits += 1
	end

	if cast.UserData.Hits > MAX_PIERCES then return false end

	local hitPart = rayResult.Instance
	-- deal damage to ricocheted objects
	--if hitPart ~= nil and hitPart.Parent ~= nil then
	--	local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
	--	if humanoid then
	--		humanoid:TakeDamage(self.DAMAGE/2) -- Damage.
	--	end
	--end

	-- Do note that if you want this to work properly, you will need to edit the OnRayPierced event handler below so that it doesn't bounce.
	local material = rayResult.Material
	if
		material == Enum.Material.Plastic
		or material == Enum.Material.Ice
		or material == Enum.Material.Glass
		or material == Enum.Material.SmoothPlastic
	then
		if hitPart.Transparency >= 0.5 then
			return true
		end
	end

	return false
end

function Gun:Fire(direction: Vector3) -- (adapted from FastCast Example Gun)
	local character: Model? = self.Instance.Parent
	if character:IsA("Backpack") then return end
	-- Note: Above isn't in the event as it will prevent the CanFire value from being set as needed.
	if character:GetAttribute("Ragdolled") then return end

	-- UPD. 11 JUNE 2019 - Add support for random angles.
	local directionalCF = CFrame.new(Vector3.new(), direction)
	-- Now, we can use CFrame orientation to our advantage.
	-- Overwrite the existing Direction value.
	-- local direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(
	-- 	math.rad(RNG:NextNumber(self.MIN_SPREAD_ANGLE, self.MAX_SPREAD_ANGLE)),
	-- 	0,
	-- 	0
	-- )).LookVector

	-- UPDATE V6: Proper bullet velocity!
	-- IF YOU DON'T WANT YOUR BULLETS MOVING WITH YOUR CHARACTER, REMOVE THE THREE LINES OF CODE BELOW THIS COMMENT.
	-- Requested by https://www.roblox.com/users/898618/profile/
	-- We need to make sure the bullet inherits the velocity of the gun as it fires, just like in real life.
	local humanoidRootPart = self.Instance.Parent:WaitForChild("HumanoidRootPart", 1) -- Add a timeout to this.
	local myMovementSpeed = humanoidRootPart.Velocity -- To do: It may be better to get this value on the clientside since the server will see this value differently due to ping and such.
	local modifiedBulletSpeed = (direction * self.BULLET_SPEED) -- + myMovementSpeed	-- We multiply our direction unit by the bullet speed. This creates a Vector3 version of the bullet's velocity at the given speed. We then add MyMovementSpeed to add our body's motion to the velocity.

	if self.CAN_PIERCE then
		self.CastBehavior.CanPierceFunction = self._canRayPierce
	end

	local simBullet = self.Caster:Fire(character.PrimaryPart.Position, direction, modifiedBulletSpeed, self.CastBehavior)
	-- Optionally use some methods on simBullet here if applicable.

	local verticalKick = 25
	local horizontalKick = math.random(-10, 10)
	self.RecoilEvent:FireClient(Players:GetPlayerFromCharacter(character), verticalKick, horizontalKick)

	self:PlayFireSound()
	if self.Aiming and self.Animations.AimFire ~= nil then
		self.Animations.AimFire:Play()
	elseif self.Animations.Fire ~= nil then
		self.Animations.Fire:Play()
	end
end

function Gun:_onRayHit(cast, raycastResult: RaycastResult, segmentVelocity: Vector3, cosmeticBulletObject: BasePart)  -- (adapted from FastCast Example Gun)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal
	if hitPart ~= nil and hitPart.Parent ~= nil then -- Test if we hit something
		local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
		self:MakeParticleFX(hitPoint, normal) -- Particle FX
		if not humanoid then return end

		-- print("hit", humanoid.Parent.Name)
		humanoid:TakeDamage(self.DAMAGE)
	end
end

function Gun:_onRayPierced(cast, raycastResult: RaycastResult, segmentVelocity: Vector3, cosmeticBulletObject: BasePart)  -- (adapted from FastCast Example Gun)
	-- You can do some really unique stuff with pierce behavior - In reality, pierce is just the module's way of asking "Do I keep the bullet going, or do I stop it here?"
	-- You can make use of this unique behavior in a manner like this, for instance, which causes bullets to be bouncy.
	local position = raycastResult.Position
	local normal = raycastResult.Normal

	--local newNormal = Gun._reflect(normal, segmentVelocity.Unit)
	--cast:SetVelocity(newNormal * segmentVelocity.Magnitude)

	-- It's super important that we set the cast's position to the ray hit position. Remember: When a pierce is successful, it increments the ray forward by one increment.
	-- If we don't do this, it'll actually start the bounce effect one segment *after* it continues through the object, which for thin walls, can cause the bullet to almost get stuck in the wall.
	cast:SetPosition(position)

	-- Generally speaking, if you plan to do any velocity modifications to the bullet at all, you should use the line above to reset the position to where it was when the pierce was registered.
end

function Gun:_onRayUpdated(
	cast,
	segmentOrigin: Vector3,
	segmentDirection: Vector3,
	length: number,
	segmentVelocity: Vector3,
	cosmeticBulletObject: BasePart
)
	-- Whenever the caster steps forward by one unit, this function is called.
	-- The bullet argument is the same object passed into the fire function.
	if cosmeticBulletObject == nil then return end
	local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
end

function Gun:_onRayTerminated(cast)
	local cosmeticBullet: Part? = cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet ~= nil then
		-- This code here is using an if statement on CastBehavior.CosmeticBulletProvider so that the example gun works out of the box.
		-- In your implementation, you should only handle what you're doing (if you use a PartCache, ALWAYS use ReturnPart. If not, ALWAYS use Destroy.

		if self.Instance.Name == "bazooka" then
			local explosion = Instance.new("Explosion")
			explosion.Parent = workspace
			explosion.Position = cosmeticBullet.Position
			explosion.BlastRadius = 10
			explosion.DestroyJointRadiusPercent = 0
			Debris:AddItem(explosion, cosmeticBullet.Boom.TimeLength)

			local processed = {}
			explosion.Hit:Connect(function(part: BasePart, distance: number)
				if table.find(processed, part.Parent) then
					return
				end
				local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid then
					table.insert(processed, part.Parent)
					distance = (humanoid.RootPart.Position - explosion.Position).Magnitude
					local splashDamage = (distance - 10) ^ 2

					humanoid:TakeDamage(splashDamage)
				end

				for _, v in part:GetDescendants() do
					if v:IsA("JointInstance") or v:IsA("WeldConstraint") then
						v:Destroy()
					end
				end
			end)
		end

		cosmeticBullet:Destroy()
	end
end

function Gun:OnMouseEvent(player: Player, mousePoint)
	if not self.CanFire then return end
	self.CanFire = false
	-- local mouseDirection = (mousePoint - self.FirePoint.WorldPosition).Unit
	for _ = 1, self.BULLETS_PER_SHOT do
		self:Fire(workspace.CurrentCamera.CFrame.LookVector)
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

function Gun:OnEquipped(mouse: Mouse)
	--print(self.Instance.Parent, "equipped", self.Instance.Name)
	self.Character = self.Instance.Parent
	self.CastParams.FilterDescendantsInstances = { self.Character }

	local humanoid = self.Character:FindFirstChildOfClass("Humanoid")

	self.Model.WeaponRootPart.Holster.Part0 = nil
	self.Model.WeaponRootPart.Grip.Part0 = self.Character["Right Arm"]

	local animations3P = self.Model.Animations["3P"]
	for _,v in animations3P:GetChildren() do
		self.Animations[v.Name] =  humanoid:LoadAnimation(v)
	end
	self.Animations.Idle:Play()
end

function Gun:OnUnequipped()
	--print(self.Instance.Parent, "unequipped", self.Instance.Name)
	for _,v in self.Animations do
		v:Stop()
	end
	self.Animations = {}
	self.Character = nil

	local player: Player = self.Instance:FindFirstAncestorOfClass("Player")
	local character = player.Character

	self.Model.Parent = character
	self.Model.WeaponRootPart.Grip.Part0 = nil
	self.Model.WeaponRootPart.Holster.Part0 = character.Torso
end

function Gun:Start()
	self._trove:Connect(self.Instance.Equipped, function(...) self:OnEquipped(...) end)
	self._trove:Connect(self.Instance.Unequipped, function(...) self:OnUnequipped(...) end)

	self._trove:Connect(self.Caster.RayHit, function(...) self:_onRayHit(...) end)
	self._trove:Connect(self.Caster.RayPierced, function(...) self:_onRayPierced(...) end)
	self._trove:Connect(self.Caster.LengthChanged, function(...) self:_onRayUpdated(...) end)
	self._trove:Connect(self.Caster.CastTerminating, function(...) self:_onRayTerminated(...) end)

	self._trove:Connect(self.MouseEvent.OnServerEvent, function(...) self:OnMouseEvent(...) end)
	self._trove:Connect(self.AimEvent.OnServerEvent, function(...) self:OnAimEvent(...) end)
end

function Gun:Stop()
	self._trove:Destroy()
end

return Gun
