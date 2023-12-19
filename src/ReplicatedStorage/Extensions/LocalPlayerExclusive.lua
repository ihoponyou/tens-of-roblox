
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayerExclusive = {}

function LocalPlayerExclusive.ShouldExtend(component)
    local componentString = component.Instance.Name .. " (" .. component.Tag .. ")"

    local onClient = RunService:IsClient()
    if not onClient then warn(componentString .. " extends LocalPlayerExclusive outside of client") end

    local setupFunction = component._setupForLocalPlayer
    if setupFunction == nil then warn(componentString .. " extends LocalPlayerExclusive without setup function") end

    local cleanupFunction = component._cleanUpForLocalPlayer
    if cleanupFunction == nil then warn(componentString .. " extends LocalPlayerExclusive without cleanup function") end

	return onClient and setupFunction ~= nil and cleanupFunction ~= nil
end

function LocalPlayerExclusive.Started(component)
    local function OwnerIDChanged()
		if component.Instance:GetAttribute("OwnerID") == Players.LocalPlayer.UserId then
			component:_setupForLocalPlayer()
		else
			component:_cleanUpForLocalPlayer()
		end
	end

	if component.Instance:GetAttribute("OwnerID") ~= nil then
        OwnerIDChanged() 
    end
    component._trove:Connect(component.Instance:GetAttributeChangedSignal("OwnerID"), OwnerIDChanged)
end

return LocalPlayerExclusive
