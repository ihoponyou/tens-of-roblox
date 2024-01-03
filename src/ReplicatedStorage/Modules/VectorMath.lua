--!strict

local VectorMath = {}

local RAND = Random.new(tick())

function VectorMath.DistanceBetweenVectors(a: Vector3, b: Vector3): number
    return (a - b).Magnitude
end

function VectorMath.DistanceBetweenParts(a: BasePart, b: BasePart): number
    local positionA = a.CFrame.Position
    local positionB = b.CFrame.Position

    return VectorMath.DistanceBetweenVectors(positionA, positionB)
end

-- returns a random position within the specified radius
function VectorMath.GetPositionInRadius(origin: Vector3, radius: number)
    local distance = math.random(0, radius)
    local direction = RAND:NextUnitVector()
    return origin + direction * distance
end

function VectorMath.GetPositionInPart(part: BasePart, withY: boolean?)
    local xOffset = part.Size.X/2 * RAND:NextNumber(-1, 1)
    local yOffset = part.Size.Y/2 * RAND:NextNumber(-1, 1)
    local zOffset = part.Size.Z/2 * RAND:NextNumber(-1, 1)
	return part.CFrame.Position + Vector3.new(xOffset, if withY then yOffset else 0, zOffset)
end

return VectorMath
