
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Knit = require(ReplicatedStorage.Packages.Knit)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local InventoryController

local Find = require(ReplicatedStorage.Source.Modules.Find)
local UI_ELEMENTS = ReplicatedStorage.Source.UIElements
local HeadsUpDisplay = require(UI_ELEMENTS.HeadsUpDisplay)
local useEventConnection = require(script.useEventConnection)
local ViewportSlot = require(script.ViewportSlot)

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER.PlayerGui
local UI_EVENTS = ReplicatedStorage.UIEvents

export type SlotType = "Primary" | "Secondary" | "Tertiary" | "Melee"

Knit.OnStart():andThen(function()
    InventoryController = Knit.GetController("InventoryController")
end):catch(warn)

local AMMO_SLOT_SIZE = UDim2.fromScale(0.15, 0.1);
local DEFAULT_SLOT_SIZE = UDim2.fromScale(0.15, 0.08);

local AMMO_STYLES = {
    Current = {
        AnchorPoint = Vector2.new(0, 1);
        Position = UDim2.fromScale(0.1, 0.6);
        Size = UDim2.fromScale(0.5, 0.5);
        TextColor3 = Color3.fromRGB(255, 255, 255);
    },
    Reserve = {
        AnchorPoint = Vector2.new(0, 0);
        Position = UDim2.fromScale(0.1, 0.5);
        Size = UDim2.fromScale(0.5, 0.35);
        TextColor3 = Color3.fromRGB(180, 180, 180);
    }
}

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local testAmmoEvent = Instance.new("BindableEvent")

local function AmmoCounter(props)
    return React.createElement("TextLabel", {
        AnchorPoint = AMMO_STYLES[props.counterType].AnchorPoint;
        BackgroundTransparency = 1;
        Position = AMMO_STYLES[props.counterType].Position;
        Size = AMMO_STYLES[props.counterType].Size;
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold);
        Text = props.ammo;
        TextColor3 = AMMO_STYLES[props.counterType].TextColor3;
        TextScaled = true;
        TextStrokeColor3 = Color3.new(0, 0, 0);
        TextStrokeTransparency = 0;
        TextXAlignment = Enum.TextXAlignment.Right;
        TextYAlignment = Enum.TextYAlignment.Center;
    })
end

local function AmmoLabels(_)
    local currentAmmo: number, setCurrentAmmo = React.useState(-1)
    useEventConnection(testAmmoEvent.Event, function(ammo: number)
        setCurrentAmmo(function(oldAmmo)
            return ammo
        end)
    end)
    local reserveAmmo: number, setReserveAmmo = React.useState(-1)
    useEventConnection(testAmmoEvent.Event, function(ammo: number)
        setReserveAmmo(function(oldAmmo)
            return ammo
        end)
    end)

    return React.createElement(
        React.Fragment,
        nil,
        React.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.fromScale(0.75, 0.5);
            Size = UDim2.fromScale(0.5, 0.6);
        }),
        React.createElement(AmmoCounter, {
            counterType = "Current";
            ammo = currentAmmo;
        }),
        React.createElement(AmmoCounter, {
            counterType = "Reserve";
            ammo = reserveAmmo;
        })
    )
end

local function EquipmentSlot(props)
    local worldModel = Find.path(ReplicatedStorage, "Equipment/"..props.equipmentName.."/WorldModel");
    local viewportPosition = worldModel:GetAttribute("ViewportPosition") or UDim2.fromScale(1, 0.5)
    local hasAmmo = worldModel:GetAttribute("HasAmmo") or false

    return React.createElement("Frame", {
        AnchorPoint = Vector2.new(1, 0.5);
        BackgroundColor3 = Color3.new(0, 0, 0);
        BackgroundTransparency = 0.6;
        Size = if hasAmmo then AMMO_SLOT_SIZE else DEFAULT_SLOT_SIZE;
        SizeConstraint = Enum.SizeConstraint.RelativeYY;

        children = {
            Corner = React.createElement("UICorner");
            Stroke = React.createElement("UIStroke", {
                Color = Color3.new(1, 1, 1);
                Thickness = if props.isEquipped then 1 else 0;
            });
            Portrait = React.createElement(ViewportSlot, {
                prefab = worldModel;
                position = viewportPosition
            });
            if hasAmmo then React.createElement(AmmoLabels) else nil;
        }
    })
end

-- local dict: {[string]: number}

local exampleEvent = Instance.new("BindableEvent")

local function Inventory()
    local inventoryState: { [string]: string }, setInventoriesState = React.useState({})
    useEventConnection(exampleEvent.Event, function(value: string)
        setInventoriesState(function(oldValue)
            return table.clone(value)
        end)
    end, {})

    local equippedSlot: string, setEquippedSlot = React.useState("")
    useEventConnection(InventoryController.ActiveSlotChanged, function(activeSlot: string)
        setEquippedSlot(function(oldSlot)
            return activeSlot
        end)
    end, {})

    local elements = {
        ListLayout = React.createElement("UIListLayout", {
            Padding = UDim.new(0, 5);
            FillDirection = Enum.FillDirection.Vertical;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Center;
        }),
        Padding = React.createElement("UIPadding", {
            PaddingRight = UDim.new(0, 5);
        })
    }
    for slot, equipment in inventoryState do
        elements[slot] = React.createElement(EquipmentSlot, {
            slotType = slot;
            equipmentName = equipment;
            isEquipped = equippedSlot == slot;
        })
    end

    return React.createElement("ScreenGui", {
        IgnoreGuiInset = true;
        children = elements
    })
end

local container = Instance.new("Folder")
container.Name = "Interface"
container.Parent = PLAYER_GUI

local root = ReactRoblox.createRoot(container)

root:render({
    Inventory = React.createElement(Inventory)
})

local inv: {[SlotType]: string} = {
    Primary = "Dragonslayer";
    Secondary = "Deagle";
}
local ammo = 99
while task.wait(3) do
    if time() > 9 then
        inv.Primary = nil
    end

    testAmmoEvent:fire(ammo)
    ammo -= 1

    exampleEvent:Fire(inv)
    -- print(inv)
end

-- print("Interface loaded")
