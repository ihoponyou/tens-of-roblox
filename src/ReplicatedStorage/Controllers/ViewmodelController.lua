
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ViewmodelClient = require(ReplicatedStorage.Source.ClientComponents.ViewmodelClient)

local ViewmodelController = Knit.CreateController({
    Name = "ViewmodelController";
    Viewmodel = nil; -- the component reference, not the model itself
})

function ViewmodelController:Setup()
    local viewmodelModel = ReplicatedStorage.Viewmodel:Clone()
    viewmodelModel.Parent = Knit.Player

    -- apply local player's avatar to viewmodel
    viewmodelModel.RigHumanoid:ApplyDescription(
        if Knit.Player.UserId < 0 then
            ReplicatedStorage.GuestDescription
        else
            Players:GetHumanoidDescriptionFromUserId(Knit.Player.UserId)
    )

    -- remove accessories
    for _,v in viewmodelModel:GetDescendants() do
        if not (v:IsA("Accessory")) then continue end
        v:Destroy()
    end

    ViewmodelClient:WaitForInstance(viewmodelModel):andThen(function(component)
        self.Viewmodel = component
        component:ToggleVisibility(false)
    end):catch(warn)
end

function ViewmodelController:CleanUp()
    self.Viewmodel.Instance:Destroy()
    self.Viewmodel = nil
end

function ViewmodelController:KnitInit()
    if Knit.Player.Character then self:Setup() end
    Knit.Player.CharacterAdded:Connect(function(_)
        self:Setup()
    end)
    Knit.Player.CharacterRemoving:Connect(function(_)
        self:CleanUp()
    end)
end

return ViewmodelController
