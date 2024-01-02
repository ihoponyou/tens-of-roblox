local RAND = Random.new(tick())

return function(part: BasePart, withY: boolean?)
    local xOffset = part.Size.X/2 * RAND:NextNumber(-1, 1)
    local yOffset = part.Size.Y/2 * RAND:NextNumber(-1, 1)
    local zOffset = part.Size.Z/2 * RAND:NextNumber(-1, 1)
	return part.CFrame.Position + Vector3.new(xOffset, if withY then yOffset else 0, zOffset)
end
