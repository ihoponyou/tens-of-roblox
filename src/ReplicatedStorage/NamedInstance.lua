local NamedInstance = {}

function NamedInstance.new(name: string, class: string, parent: Instance): Instance
	local instance = Instance.new(class)
	instance.Parent = parent
	instance.Name = name
	return instance
end

return NamedInstance