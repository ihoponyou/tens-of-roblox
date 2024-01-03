local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RaycastUtil = require(ReplicatedStorage.Source.Modules.RaycastUtil)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode ~= Enum.KeyCode.F then return end
    RaycastUtil.RaycastWithVisual(Players.LocalPlayer.Character.Head.CFrame.Position, workspace.CurrentCamera.CFrame.LookVector * 20)
end)