
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Knit = require(ReplicatedStorage.Packages.Knit)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local InventoryController

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local GunClient = require(ReplicatedStorage.Source.ClientComponents.GunClient)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local useEventConnection = require(script.useEventConnection)
local ViewportSlot = require(script.ViewportSlot)

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER.PlayerGui

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
        Position = UDim2.fromScale(0.1, 0.55);
        Size = UDim2.fromScale(0.5, 0.35);
        TextColor3 = Color3.fromRGB(180, 180, 180);
    }
}

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local function AmmoCounter(props)
    local ammo: number, setAmmo = React.useState(props.initial)
    useEventConnection(props.update.OnClientEvent, function(newAmmo: number)
        setAmmo(function(oldAmmo)
            return newAmmo
        end)
    end)

    return React.createElement("TextLabel", {
        AnchorPoint = AMMO_STYLES[props.counterType].AnchorPoint;
        BackgroundTransparency = 1;
        Position = AMMO_STYLES[props.counterType].Position;
        Size = AMMO_STYLES[props.counterType].Size;
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold);
        Text = ammo;
        TextColor3 = AMMO_STYLES[props.counterType].TextColor3;
        TextScaled = true;
        TextStrokeColor3 = Color3.new(0, 0, 0);
        TextStrokeTransparency = 0;
        TextXAlignment = Enum.TextXAlignment.Right;
        TextYAlignment = Enum.TextYAlignment.Center;
        ZIndex = 2;
    })
end

local function AmmoLabels(props)
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
            initial = props.initialCurrent;
            update = props.updateCurrent;
        }),
        React.createElement(AmmoCounter, {
            counterType = "Reserve";
            initial = props.initialReserve;
            update = props.updateReserve;
        })
    )
end

local function EquipmentSlot(props)
    local worldModel = Find.path(ReplicatedStorage, "Equipment/"..props.equipmentInstance.Name.."/WorldModel");
    local viewportPosition = EquipmentConfig[props.equipmentInstance.Name].ViewportPosition or UDim2.fromScale(1, 0.5)
    local gunComponent = GunClient:FromInstance(props.equipmentInstance)

    local hasAmmo = gunComponent ~= nil

    -- print(props.equipmentInstance.Name, "gun?", hasAmmo)
    return React.createElement("Frame", {
        AnchorPoint = Vector2.new(1, 0.5);
        BackgroundColor3 = Color3.new(0, 0, 0);
        BackgroundTransparency = 0.6;
        Size = if hasAmmo then AMMO_SLOT_SIZE else DEFAULT_SLOT_SIZE;
        SizeConstraint = Enum.SizeConstraint.RelativeYY;
        ZIndex = 0;

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
            if not hasAmmo then nil else React.createElement(AmmoLabels, {
                initialCurrent = gunComponent.CurrentAmmo;
                updateCurrent = gunComponent.UpdateCurrentAmmo;
                initialReserve = gunComponent.ReserveAmmo;
                updateReserve = gunComponent.UpdateReserveAmmo;
            });
        }
    })
end

local function Inventory()
    local inventory: { [string]: Instance }, setInventoriesState = React.useState({})
    useEventConnection(InventoryController.InventoryChanged, function(value: string)
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
    for slot, equipment in inventory do
        elements[slot] = React.createElement(EquipmentSlot, {
            slotType = slot;
            equipmentInstance = equipment;
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

-- print("Interface loaded")
