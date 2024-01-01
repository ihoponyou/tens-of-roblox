--!strict

local VectorMath = {}

function VectorMath.DistanceBetweenVectors(a: Vector3, b: Vector3): number
    return (a - b).Magnitude
end

function VectorMath.DistanceBetweenParts(a: BasePart, b: BasePart): number
    local positionA = a.CFrame.Position
    local positionB = b.CFrame.Position

    return VectorMath.DistanceBetweenVectors(positionA, positionB)
end

return VectorMath
