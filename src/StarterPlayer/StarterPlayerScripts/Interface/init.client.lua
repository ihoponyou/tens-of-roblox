
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local PLAYER_GUI = Players.LocalPlayer:WaitForChild("PlayerGui")
local UI_EVENTS = ReplicatedStorage.UIEvents
local UI_ELEMENTS = ReplicatedStorage.Source.UIElements

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local RoactRoduxStore = require(script.RoactRoduxStore)

local AmmoCounters = require(script.AmmoCounters)
local SettingsMenu = require(UI_ELEMENTS.SettingsMenu)
local Crosshair = require(UI_ELEMENTS.Crosshair)

-- Roact.setGlobalConfig({
--     elementTracing = true;
-- })

local menuBlur = Instance.new("BlurEffect")
menuBlur.Enabled = false
menuBlur.Size = 16
menuBlur.Name = "MenuBlur"
menuBlur.Parent = workspace.CurrentCamera

local settingsOpen = false
local settingsGui = Roact.createElement(SettingsMenu)

local function NoInsetGui()
    return Roact.createElement("ScreenGui", {
        IgnoreGuiInset = true;
    })
end

local crosshairGui = Roact.createElement(NoInsetGui,
{}, {
    Crosshair = Roact.createElement(Crosshair, {
        gap = 3;
        length = 6;
        thickness = 2;
        color = Color3.fromRGB(255, 255, 255);
    })
})

local settingsTree
local crosshairTree = Roact.mount(crosshairGui, PLAYER_GUI)
UserInputService.MouseIconEnabled = false
ContextActionService:BindAction("toggle_settings", function(_, userInputState, _)
    if userInputState ~= Enum.UserInputState.Begin then return end

    settingsOpen = not settingsOpen
    if settingsOpen then
        UserInputService.MouseIconEnabled = true
        settingsTree = Roact.mount(settingsGui, PLAYER_GUI)
        if crosshairTree ~= nil then Roact.unmount(crosshairTree) end
    else
        UserInputService.MouseIconEnabled = false
        crosshairTree =  Roact.mount(crosshairGui, PLAYER_GUI)
        if settingsTree ~= nil then Roact.unmount(settingsTree) end
    end

    menuBlur.Enabled = settingsOpen

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

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local app = Roact.createElement(RoactRodux.StoreProvider, {
    store = RoactRoduxStore.Instance;
}, {
    GunGui = Roact.createElement("ScreenGui",
    {}, {
        AmmoCounters = Roact.createElement(AmmoCounters);
    });
})
Roact.mount(app, PLAYER_GUI)
