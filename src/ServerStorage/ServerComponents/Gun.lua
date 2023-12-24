
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
local Find = require(ReplicatedStorage.Source.Modules. Find)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)

-- module level constants
local DEBUG = true

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

	self._trove = Trove.new()

	self.Aiming = false
	self.Firing = false
	self.Reloading = false
	self.CanFire = false

	local CastParams = RaycastParams.new()
	CastParams.IgnoreWater = true
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.FilterDescendantsInstances = {}
	self.CastParams = CastParams

	local recoilEvent = Instance.new("RemoteEvent")
	recoilEvent.Name = "RecoilEvent"
	recoilEvent.Parent = self.Instance
	self.RecoilEvent = recoilEvent
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
	self.CanFire = equipped
end)

	local config = self.Equipment.Config
	self.Ammo = config.MagazineCapacity
	self.ReserveAmmo = config.MagazineCapacity * config.ReserveMagazines
end

function Gun:Stop()
    self._trove:Destroy()
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

function Gun:Fire(player, direction: Vector3)
	if not self.CanFire then return end
	-- print(player, direction)

	-- TODO: make recoil patterns
	local verticalKick = 25
	local horizontalKick = math.random(-10, 10)

	self.Equipment.AnimationManager:PlayAnimation("Fire")
	self.Equipment.UseEvent:FireClient(self.Equipment.Owner, horizontalKick, verticalKick)

	self:PlayFireSound()
	self:DoMuzzleFlash()
	-- self:MakeImpactParticleFX()
end

return Gun
