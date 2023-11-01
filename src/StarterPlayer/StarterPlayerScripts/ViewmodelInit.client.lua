
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewmodelClient = require(ReplicatedStorage.Source.ClientComponents.ViewmodelClient)

local viewmodel = ReplicatedStorage.Viewmodel:Clone()
viewmodel.Parent = game.Players.LocalPlayer

ViewmodelClient:WaitForInstance(viewmodel):andThen(function(component)
    component:ToggleVisibility(false)
end):catch(warn)

