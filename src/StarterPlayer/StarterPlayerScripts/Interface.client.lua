
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local PLAYER_GUI = Players.LocalPlayer:WaitForChild("PlayerGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local UI_ELEMENTS = ReplicatedStorage.Source.UIElements
local Roact = require(ReplicatedStorage.Packages.Roact)
Roact.setGlobalConfig({
    elementTracing = true;
})

local SettingsMenu = require(UI_ELEMENTS.SettingsMenu)
local Crosshair = require(UI_ELEMENTS.Crosshair)

local settingsOpen = false
local mainSettings = Roact.createElement(SettingsMenu)

local menuBlur = Instance.new("BlurEffect")
menuBlur.Enabled = false
menuBlur.Size = 16
menuBlur.Name = "MenuBlur"
menuBlur.Parent = workspace.CurrentCamera

local handle
ContextActionService:BindAction("toggle_settings", function(actionName, userInputState, inputObject)
    if userInputState ~= Enum.UserInputState.Begin then return end

    settingsOpen = not settingsOpen
    if settingsOpen then
        handle = Roact.mount(mainSettings, PLAYER_GUI)
    else
        Roact.unmount(handle)
    end

    menuBlur.Enabled = settingsOpen

    return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.M)

local crosshair = Roact.createElement(Crosshair, {
    gap = 3;
    length = 6;
    thickness = 2;
    color = Color3.fromRGB(255, 255, 255);
})
local gunGui = Roact.createElement("ScreenGui", {
    IgnoreGuiInset = true;
}, {
    Crosshair = crosshair;
})

Roact.mount(gunGui, PLAYER_GUI)