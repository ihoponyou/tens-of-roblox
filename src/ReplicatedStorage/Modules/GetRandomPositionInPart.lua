local RAND = Random.new(time())

return function(part: BasePart)
    local xOffset = part.Size.X/2 * RAND:NextNumber(-1, 1)
    local zOffset = part.Size.Z/2 * RAND:NextNumber(-1, 1)
	return part.CFrame.Position + Vector3.new(xOffset, 0, zOffset)
end
