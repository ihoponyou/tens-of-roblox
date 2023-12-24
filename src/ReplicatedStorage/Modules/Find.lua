
local Find = {}

function Find.path(parent: Instance, path: string)
	local pathParts = string.split(path, "/")

	local instance = parent
	for _, pathPart in pathParts do
		local child = instance:FindFirstChild(pathPart)
		if child == nil then
			error(`failed to find {pathPart} in {instance:GetFullName()} (full path: {path})`, 2)
		end
		instance = child
	end

	return instance
end

return Find
