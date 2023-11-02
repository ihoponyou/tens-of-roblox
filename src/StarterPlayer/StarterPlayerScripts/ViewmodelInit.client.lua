
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewmodelClient = require(ReplicatedStorage.Source.ClientComponents.ViewmodelClient)

local player = Players.LocalPlayer
local viewmodel = ReplicatedStorage.Viewmodel:Clone()
viewmodel.Parent = player

-- clean viewmodel of clothing/accessories just in case
for _,v in viewmodel:GetDescendants() do
    if not (v:IsA("Accessory")) then continue end
    v:Destroy()
end
viewmodel.RigHumanoid:ApplyDescription(game.Players:GetHumanoidDescriptionFromUserId(player.UserId))
-- remove unused accessories
for _,v in viewmodel:GetDescendants() do
    if not (v:IsA("Accessory")) then continue end
    v:Destroy()
end

ViewmodelClient:WaitForInstance(viewmodel):andThen(function(component)
    component:ToggleVisibility(false)
end):catch(warn)

