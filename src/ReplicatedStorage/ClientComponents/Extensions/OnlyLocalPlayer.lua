local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local OnlyLocalPlayer = {}

function OnlyLocalPlayer.ShouldExtend(component)
	return RunService:IsClient()
end
function OnlyLocalPlayer.ShouldConstruct(component)
    return component.Instance:GetAttribute("OwnerID") == Players.LocalPlayer
end

return OnlyLocalPlayer
