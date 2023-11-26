
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NamedInstance = require(ReplicatedStorage.Source.NamedInstance)
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local PLAYER_GUI = Players.LocalPlayer:WaitForChild("PlayerGui")
local UI_EVENTS = ReplicatedStorage.UIEvents
local UPDATE_CURRENT_AMMO_UI = UI_EVENTS.UpdateCurrentAmmo
local UPDATE_RESERVE_AMMO_UI = UI_EVENTS.UpdateReserveAmmo

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local UI_ELEMENTS = ReplicatedStorage.Source.UIElements
local Roact = require(ReplicatedStorage.Packages.Roact)
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local SettingsMenu = require(UI_ELEMENTS.SettingsMenu)
local Crosshair = require(UI_ELEMENTS.Crosshair)



Roact.setGlobalConfig({
    elementTracing = true;
})

local function UpdatedAmmo(newAmmo: number)
    return {
        type = "UpdatedAmmo";
        ammo = newAmmo;
    }
end

local function UpdatedReserveAmmo(newReserveAmmo: number)
    return {
        type = "UpdatedReserveAmmo";
        reserveAmmo = newReserveAmmo
    }
end

local ammoReducer = Rodux.createReducer(0, {
    UpdatedAmmo = function(state, action)
        return action.ammo
    end
})

local reserveAmmoReducer = Rodux.createReducer(0, {
    UpdatedReserveAmmo = function(state, action)
        return action.reserveAmmo
    end
})

local reducer = Rodux.combineReducers({
    myAmmo = ammoReducer;
    myReserveAmmo = reserveAmmoReducer;
})

local store = Rodux.Store.new(reducer, nil, {
    -- Rodux.loggerMiddleware
})

-- store:dispatch(UpdatedAmmo(30))
-- store:dispatch(UpdatedReserveAmmo(150))

local menuBlur = Instance.new("BlurEffect")
menuBlur.Enabled = false
menuBlur.Size = 16
menuBlur.Name = "MenuBlur"
menuBlur.Parent = workspace.CurrentCamera

local settingsOpen = false
local mainSettings = Roact.createElement(SettingsMenu)

local crosshairGui = Roact.createElement("ScreenGui",
    {
        IgnoreGuiInset = true;
    }, {
        Crosshair = Roact.createElement(Crosshair, {
            gap = 3;
            length = 6;
            thickness = 2;
            color = Color3.fromRGB(255, 255, 255);
        })
    })

local function CounterLabel(props)
    return Roact.createElement("TextLabel", {
        Text = props.text;
        BackgroundTransparency = 1;
        TextSize =  24;
        TextColor3 = Color3.fromRGB(255, 255, 255);
        TextStrokeTransparency = 0;
        Size = UDim2.fromOffset(75, 20);
    })
end

local CurrentAmmoCounter = RoactRodux.connect(
    function(state, props)
        return {
            text = state.myAmmo;
        }
    end,
    nil
)(CounterLabel)

local ReserveAmmoCounter = RoactRodux.connect(
    function(state, props)
        return {
            text = state.myReserveAmmo;
        }
    end,
    nil
)(CounterLabel)

local ammoCounters = Roact.createElement("Frame", {
    AnchorPoint = Vector2.new(1, 1);
    Position = UDim2.fromScale(1, 1);
    BackgroundTransparency = 1;
}, {
    ListLayout = Roact.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        VerticalAlignment = Enum.VerticalAlignment.Bottom;
    });
    CurrentAmmoCounter = Roact.createElement(CurrentAmmoCounter);
    ReserveAmmoCounter = Roact.createElement(ReserveAmmoCounter);
})

local app = Roact.createElement(RoactRodux.StoreProvider, {
    store = store;
}, {
    GunGui = Roact.createElement("ScreenGui", {
        IgnoreGuiInset = true;
    }, {
        AmmoCounters = ammoCounters
    })
})
Roact.mount(app, PLAYER_GUI)

local settingsTree
local crosshairTree = Roact.mount(crosshairGui, PLAYER_GUI)
UserInputService.MouseIconEnabled = false
ContextActionService:BindAction("toggle_settings", function(_, userInputState, _)
    if userInputState ~= Enum.UserInputState.Begin then return end

    settingsOpen = not settingsOpen
    if settingsOpen then
        UserInputService.MouseIconEnabled = true
        settingsTree = Roact.mount(mainSettings, PLAYER_GUI)
        if crosshairTree ~= nil then Roact.unmount(crosshairTree) end
    else
        UserInputService.MouseIconEnabled = false
        crosshairTree =  Roact.mount(crosshairGui, PLAYER_GUI)
        if settingsTree ~= nil then Roact.unmount(settingsTree) end
    end

    menuBlur.Enabled = settingsOpen

    return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.M)


-- task.wait(3)

-- store:dispatch(UpdatedAmmo(30))

UPDATE_CURRENT_AMMO_UI.OnClientEvent:Connect(function(ammo: number)
    store:dispatch(UpdatedAmmo(ammo))
end)
UPDATE_RESERVE_AMMO_UI.OnClientEvent:Connect(function(reserveAmmo: number)
    store:dispatch(UpdatedReserveAmmo(reserveAmmo))
end)
