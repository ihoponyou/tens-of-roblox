
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local FastCast = require(ReplicatedStorage.Packages.FastCastRedux)
local PartCache = require(ReplicatedStorage.Packages.PartCache)

FastCast.VisualizeCasts = false

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local MAX_PIERCES = 3
local RICOCHET_ANGLE = 5
local _RICOCHET_DOT = math.cos(math.rad(90+RICOCHET_ANGLE))

local ProjectileCaster = Component.new {
	Tag = "ProjectileCaster";
	Extensions = {
		Logger,
	};
}

function ProjectileCaster:Construct()
	self._trove = Trove.new()

    -- default caster values
    self.CanPierce = self.Instance:GetAttribute("CanPierce")
    self.BulletSpeed = self.Instance:GetAttribute("BulletSpeed")

    self.Caster = FastCast.new()
    self._trove:Connect(self.Caster.RayHit, function(...) self:_onRayHit(...) end)
	self._trove:Connect(self.Caster.RayPierced, function(...) self:_onRayPierced(...) end)
	self._trove:Connect(self.Caster.LengthChanged, function(...) self:_onRayUpdated(...) end)
    self._trove:Connect(self.Caster.CastTerminating, function(...) self:_onRayTerminated(...) end)

    self._castParams = RaycastParams.new()
	self._castParams.IgnoreWater = true
	self._castParams.FilterType = Enum.RaycastFilterType.Exclude
	self._castParams.FilterDescendantsInstances = {}

    self._castBehavior = FastCast.newBehavior()
    self._castBehavior.RaycastParams = self._castParams
    self._castBehavior.MaxDistance = self.Instance:GetAttribute("BulletMaxDistance")
    self._castBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default
    self._castBehavior.CosmeticBulletContainer = workspace:FindFirstChild("ActiveCosmeticBullets")
	self._castBehavior.CosmeticBulletProvider = PartCache.new(ReplicatedStorage.bullet, 999, self._castBehavior.CosmeticBulletContainer)
    self._castBehavior.Acceleration = self.Instance:GetAttribute("BulletGravity")
end

function ProjectileCaster:Stop()
	self._trove:Destroy()
end

function ProjectileCaster:UpdateFilter(instances: {Instance})
    self._castParams.FilterDescendantsInstances = instances
end

function ProjectileCaster:Cast(origin: Vector3, direction: Vector3)
    -- UPD. 11 JUNE 2019 - Add support for random angles.
	-- local directionalCF = CFrame.new(Vector3.new(), direction)
	-- Now, we can use CFrame orientation to our advantage.
	-- Overwrite the existing Direction value.
	-- local direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(
	-- 	math.rad(RNG:NextNumber(self.MIN_SPREAD_ANGLE, self.MAX_SPREAD_ANGLE)),
	-- 	0,
	-- 	0
	-- )).LookVector

	if self.CanPierce then
		self._castBehavior.CanPierceFunction = self._canRayPierce
	end

	local simBullet = self.Caster:Fire(origin, direction.Unit, self.BulletSpeed, self._castBehavior)
	-- Optionally use some methods on simBullet here if applicable.
end

local function reflect(surfaceNormal: Vector3, bulletNormal: Vector3) -- (from FastCast Example Gun)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

-- returns whether or not bullet should pierce
function ProjectileCaster._canRayPierce(cast, raycastResult: RaycastResult, segmentVelocity: Vector3) -- (from FastCast Example Gun)

	-- ignore accessories
	if raycastResult.Instance:FindFirstAncestorOfClass("Accessory") then
		return true
	end

	local hits = cast.UserData.Hits
	if hits == nil then
		-- If the hit data isn't registered, set it to 1 (because this is our first hit)
		cast.UserData.Hits = 1
	else
		-- If the hit data is registered, add 1.
		cast.UserData.Hits += 1
	end
	if cast.UserData.Hits > MAX_PIERCES then return false end
	local hitPart = raycastResult.Instance

    -- ricochet if applicable
    local normal = raycastResult.Normal
    local dot = (segmentVelocity.Unit):Dot(normal)
    -- print(dot, ":", math.deg(math.acos(dot)))
    -- -1 > dot > 0
	if dot > _RICOCHET_DOT then
        -- print("ricochet")
        local newNormal = reflect(normal, segmentVelocity.Unit)
        cast:SetVelocity(newNormal * segmentVelocity.Magnitude)
        return true
    end

	local material = raycastResult.Material
	if material == Enum.Material.Plastic
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

-- override this
function ProjectileCaster.OnRayHit(_raycastResult: RaycastResult, _segmentVelocity: Vector3)
end

function ProjectileCaster:_onRayHit(_cast, raycastResult: RaycastResult, segmentVelocity: Vector3, _cosmeticBulletObject: BasePart)  -- (adapted from FastCast Example Gun)
    self.OnRayHit(raycastResult, segmentVelocity)
end

function ProjectileCaster:_onRayPierced(cast, raycastResult: RaycastResult, _segmentVelocity: Vector3, _cosmeticBulletObject: BasePart)
	cast:SetPosition(raycastResult.Position)
end

function ProjectileCaster:_onRayUpdated(
	_cast,
	segmentOrigin: Vector3,
	segmentDirection: Vector3,
	length: number,
	_segmentVelocity: Vector3,
	cosmeticBulletObject: BasePart
)
	-- Whenever the caster steps forward by one unit, this function is called.
	-- The bullet argument is the same object passed into the fire function.
	if cosmeticBulletObject == nil then return end
	local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
end

-- override this
function ProjectileCaster:OnRayTerminated(_cast)
end

function ProjectileCaster:_onRayTerminated(cast)
	local cosmeticBullet: Part? = cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet ~= nil then
        self._castBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
	end
    self:OnRayTerminated(cast)
end

return ProjectileCaster
