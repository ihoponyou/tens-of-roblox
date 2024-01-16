
export type Hitbox = {
    Size: Vector3 | number,
    Offset: Vector3?
}

local HitboxManager = {}
HitboxManager.__index = HitboxManager

function HitboxManager.new()
    local self = setmetatable({}, HitboxManager)

    self._hitboxes = {} :: {[string]: Hitbox}

    return self
end

function HitboxManager:AddHitbox(name: string, size: Vector3 | number, offset: Vector3?)
	if type(name) ~= "string" then error("name must be a string") end
    if not (type(size) == "number" or typeof(size) == "Vector3") then error("size must be a number (radius) or Vector3") end
    if offset ~= nil and typeof(offset) ~= "Vector3" then error("offset must be a Vector3") end

    self._hitboxes[name] = {
        Size = size,
        Offset = offset
    }
end

function HitboxManager:GetHitbox(name: string): Hitbox
	if type(name) ~= "string" then error("name must be a string") end

	local hitbox = self._hitbox[name]

	if hitbox == nil then error("No hitbox with name \""..name.."\"") end

	return hitbox
end

function HitboxManager:SpawnHitbox(name: string, position: Vector3, overlapParams: OverlapParams?, direction: Vector3?): {BasePart}
	local hitbox = self:GetHitbox(name)

    if hitbox.Offset ~= nil then
        position += hitbox.Offset
    end

    if type(hitbox.Size) == "number" then
        return workspace:GetPartBoundsInRadius(position, hitbox.Size, overlapParams)
    else
        return workspace:GetPartBoundsInBox(CFrame.lookAt(position, position + direction), hitbox.Size, overlapParams)
    end
end

function HitboxManager:Destroy()
	setmetatable(self, nil)
    table.clear(self)
    table.freeze(self)
end

return HitboxManager
