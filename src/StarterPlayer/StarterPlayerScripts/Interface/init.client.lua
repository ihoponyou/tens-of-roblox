
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")
local UI_EVENTS = ReplicatedStorage.UIEvents
local UI_ELEMENTS = ReplicatedStorage.Source.UIElements

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local RoactRoduxStore = require(script.RoactRoduxStore)

local SettingsMenu = require(UI_ELEMENTS.SettingsMenu)
local HeadsUpDisplay = require(UI_ELEMENTS.HeadsUpDisplay)

-- Roact.setGlobalConfig({
--     elementTracing = true;
-- })

local menuBlur = Instance.new("BlurEffect")
menuBlur.Enabled = false
menuBlur.Size = 16
menuBlur.Name = "MenuBlur"
menuBlur.Parent = workspace.CurrentCamera

local settingsOpen = false

local app = Roact.createElement(RoactRodux.StoreProvider, {
    store = RoactRoduxStore.Instance;
}, {
    SettingsGui = Roact.createElement(SettingsMenu);
    HUD = Roact.createElement(HeadsUpDisplay);
})
Roact.mount(app, PLAYER_GUI)

ContextActionService:BindAction("toggle_settings", function(_, userInputState, _)
    if userInputState ~= Enum.UserInputState.Begin then return end

    settingsOpen = not settingsOpen
    RoactRoduxStore.Instance:dispatch(RoactRoduxStore.Actions.ToggledSettings(settingsOpen))
    UserInputService.MouseIconEnabled = settingsOpen
    menuBlur.Enabled = settingsOpen
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, not settingsOpen)

    return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.M)

UI_EVENTS.UpdateCurrentAmmo.OnClientEvent:Connect(function(ammo: number)
    -- print("current ammo: "..ammo)
    RoactRoduxStore.Instance:dispatch(RoactRoduxStore.Actions.UpdatedCurrentAmmo(ammo))
end)
UI_EVENTS.UpdateReserveAmmo.OnClientEvent:Connect(function(ammo: number)
    -- print("reserve ammo: "..ammo)
    RoactRoduxStore.Instance:dispatch(RoactRoduxStore.Actions.UpdatedReserveAmmo(ammo))
end)

UserInputService.MouseIconEnabled = false
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- print("Interface loaded")
