
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewmodelClient = require(ReplicatedStorage.Source.ClientComponents.ViewmodelClient)

local player = Players.LocalPlayer
local viewmodel

local function Setup()
    viewmodel = ReplicatedStorage.Viewmodel:Clone()
    viewmodel.Parent = player

    -- clean viewmodel of clothing/accessories just in case
    for _,v in viewmodel:GetDescendants() do
        if not (v:IsA("Accessory")) then continue end
        v:Destroy()
    end
    viewmodel.RigHumanoid:ApplyDescription(
        if player.UserId < 0 then
            ReplicatedStorage.GuestDescription
        else
            game.Players:GetHumanoidDescriptionFromUserId(player.UserId)
    )

    -- remove unused accessories
    for _,v in viewmodel:GetDescendants() do
        if not (v:IsA("Accessory")) then continue end
        v:Destroy()
    end

    ViewmodelClient:WaitForInstance(viewmodel):andThen(function(component)
        component:ToggleVisibility(false)
    end):catch(warn)
end

local function CleanUp()
    viewmodel:Destroy()
end

player.CharacterAdded:Connect(Setup)
player.CharacterRemoving:Connect(CleanUp)
