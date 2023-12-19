local Logger = {}

function Logger.ShouldExtend(component)
	return component.Instance:GetAttribute("Log")
end
function Logger.Constructing(component)
	print("Constructing", component, "@", component.Instance)
end
function Logger.Constructed(component)
	print("Constructed", component, "@", component.Instance)
end
function Logger.Starting(component)
	print("Starting", component, "@", component.Instance)
end
function Logger.Started(component)
	print("Started", component, "@", component.Instance)
end
function Logger.Stopping(component)
	print("Stopping", component, "@", component.Instance)
end
function Logger.Stopped(component)
	print("Stopped", component, "@", component.Instance)
end

return Logger