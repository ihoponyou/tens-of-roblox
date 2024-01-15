
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Viewmodel = require(ReplicatedStorage.Source.ClientComponents.Viewmodel)

local ViewmodelController = Knit.CreateController({
    Name = "ViewmodelController",

    Viewmodel = nil,
    ShowViewmodel = false
})

function ViewmodelController:KnitInit()
    self:CreateViewmodel()

    Knit.Player.CharacterAdded:Connect(function()
        self:CreateViewmodel()
    end)

    Knit.Player.CharacterRemoving:Connect(function()
        self.Viewmodel.Instance:Destroy()
        self.Viewmodel = nil
    end)

    RunService.RenderStepped:Connect(function(_dt)
        if self.Viewmodel == nil then return end
        if self.ShowViewmodel then
            if not self.Viewmodel.Visible then
                self.Viewmodel:ToggleVisibility(true)
            end
        else
            if self.Viewmodel.Visible then
                self.Viewmodel:ToggleVisibility(false)
            end
        end
    end)
end

function ViewmodelController:CreateViewmodel()
    if self.Viewmodel then return end

    local newViewmodel = ReplicatedStorage.Viewmodel:Clone()
    newViewmodel.Parent = workspace.CurrentCamera
    local appearance = if Knit.Player.UserId > 0 then Players:GetHumanoidDescriptionFromUserId(Knit.Player.UserId) else ReplicatedStorage.test
    newViewmodel.RigHumanoid:ApplyDescriptionReset(appearance)

    for _, v in newViewmodel:GetDescendants() do
        if not v:IsA("Accessory") then continue end
        v:Destroy()
    end

    CollectionService:AddTag(newViewmodel, "Viewmodel")

    local success, component = Viewmodel:WaitForInstance(newViewmodel):andThen(function(_component)
        return _component
    end, warn):await()

    if success then
        self.Viewmodel = component
    else
        error("didnt work")
    end
end

return ViewmodelController
