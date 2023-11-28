
local RunService = game:GetService("RunService")

local PlayerExclusive = {}

function PlayerExclusive.ShouldExtend(component)
    local onClient = RunService:IsClient()
    if not onClient then warn(component.Instance.Name.." extends PlayerExclusive outside of client") end
    local setupFunction = component.SetupForLocalPlayer
    if setupFunction == nil then warn(component.Instance.Name.." extends PlayerExclusive without setup function") end
    local cleanupFunction = component.CleanUpForLocalPlayer
    if cleanupFunction == nil then warn(component.Instance.Name.." extends PlayerExclusive without cleanup function") end
	return onClient and (setupFunction ~= nil or cleanupFunction ~= nil)
end
function PlayerExclusive.ShouldConstruct(_)
    return true
end

return PlayerExclusive
