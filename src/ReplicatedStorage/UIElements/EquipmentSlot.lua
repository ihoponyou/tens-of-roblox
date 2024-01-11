
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local GunClient = require(ReplicatedStorage.Source.ClientComponents.GunClient)
local AmmoCounter = require(ReplicatedStorage.Source.UIElements.AmmoCounter)
local ViewportFrame = require(ReplicatedStorage.Source.UIElements.ViewportFrame)

local AMMO_SLOT_SIZE = UDim2.fromScale(0.15, 0.1);
local DEFAULT_SLOT_SIZE = UDim2.fromScale(0.15, 0.08);

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

    local viewportSettings = EquipmentConfig[props.equipmentInstance.Name].Viewport
    worldModel:PivotTo(viewportSettings.ModelCFrame or CFrame.new())
    local viewportPosition = viewportSettings.ElementPosition or UDim2.fromScale(1, 0.5)

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
            Portrait = React.createElement(ViewportFrame, {
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

return EquipmentSlot