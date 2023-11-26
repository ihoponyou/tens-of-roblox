
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local AmmoCounters = Roact.Component:extend("AmmoCounters")

local function AmmoLabel(props)
    return Roact.createElement("TextLabel", {
        Text = props.amount;
        Size = UDim2.fromOffset(75, 20);
        BackgroundTransparency = 1;
        TextStrokeTransparency = 0;
        TextSize = 24;
        TextColor3 = Color3.fromRGB(255, 255, 255);
    })
end

local CurrentAmmoCounter = RoactRodux.connect(
    function(state, props)
        -- print(state)
        return {
            amount = state.CurrentAmmo;
        }
    end
)(AmmoLabel)

local ReserveAmmoCounter = RoactRodux.connect(
    function(state, props)
        return {
            amount = state.ReserveAmmo;
        }
    end
)(AmmoLabel)

function AmmoCounters:render()
    return Roact.createElement("Frame", {
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
end

return AmmoCounters
