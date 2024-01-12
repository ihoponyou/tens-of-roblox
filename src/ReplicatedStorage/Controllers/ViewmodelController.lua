
-- roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local CameraController

local ViewmodelClient = require(ReplicatedStorage.Source.ClientComponents.ViewmodelClient)

local ViewmodelController = Knit.CreateController({
    Name = "ViewmodelController";
    Viewmodel = nil; -- the component reference, not the model itself
    ShowViewmodel = false; -- whether or not the viewmodel should be shown when applicable
})

function ViewmodelController:OnCharacterAdded(character: Model)
    print("new")
    self._characterTrove = Trove.new()
    self._characterTrove:AttachToInstance(character)
    local viewmodelModel = ReplicatedStorage.Viewmodel:Clone()
    viewmodelModel.Parent = Knit.Player

    -- apply local player's avatar to viewmodel
    viewmodelModel.RigHumanoid:ApplyDescription(
        if Knit.Player.UserId < 0 then
            ReplicatedStorage.Character.GuestDescription
        else
            Players:GetHumanoidDescriptionFromUserId(Knit.Player.UserId)
    )

    -- remove accessories
    for _,v in viewmodelModel:GetDescendants() do
        if not (v:IsA("Accessory")) then continue end
        v:Destroy()
    end

    -- components are always loaded after knit starts
    ViewmodelClient:WaitForInstance(viewmodelModel):andThen(function(component)
        self.Viewmodel = component
        -- local head = character:WaitForChild("Head")

        component:ToggleVisibility(CameraController.InFirstPerson)
        self._characterTrove:BindToRenderStep("HideViewmodelOpportunely", Enum.RenderPriority.Camera.Value, function(_)
            if not self.ShowViewmodel or component.HeldModel == nil then
                if component.Visible then
                    component:ToggleVisibility(false)
                end
            elseif self.ShowViewmodel then
                if not component.Visible then
                    component:ToggleVisibility(true)
                end
            end
        end)
    end):catch(warn)
end

function ViewmodelController:CleanUp()
    print('cleaned')
    self.Viewmodel.Instance:Destroy()
    self.Viewmodel = nil
end

function ViewmodelController:KnitInit()
    if Knit.Player.Character then
        self:OnCharacterAdded(Knit.Player.Character)
    end
    Knit.Player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    Knit.Player.CharacterRemoving:Connect(function(_)
        self:CleanUp()
    end)
end

function ViewmodelController:KnitStart()
    CameraController = Knit.GetController("CameraController")

    CameraController.FirstPersonChanged:Connect(function(inFirstPerson: boolean)
        self.ShowViewmodel = inFirstPerson
    end)
end

return ViewmodelController
