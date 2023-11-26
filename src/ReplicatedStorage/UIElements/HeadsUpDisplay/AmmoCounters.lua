
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local AmmoCounters = Roact.Component:extend("AmmoCounters")

local function AmmoLabel(props)
    return Roact.createElement("TextLabel", {
        Text = props.amount or -1;
        Size = UDim2.new(0, 90, 0, 40);
        BackgroundTransparency = 1;
        TextStrokeTransparency = 0.5;
        ClipsDescendants = true;

        LineHeight = props.lineHeight or 1;
        FontFace = Font.new("rbxasset://fonts/families/Oswald.json", if props.bold then Enum.FontWeight.Bold else Enum.FontWeight.Regular);
        TextSize = props.textSize;
        TextColor3 = Color3.fromRGB(255, 255, 255);
        TextXAlignment = props.textXAlign or Enum.TextXAlignment.Center;
    })
end

local function getDigit(num, digit)
	local n = 10 ^ digit
	local n1 = 10 ^ (digit - 1)
	return math.floor((num % n) / n1)
end

local CurrentAmmoCounter = RoactRodux.connect(
    function(state, props)
        local ammo = state.CurrentAmmo
        local thousands = getDigit(ammo, 4)
        local hundreds = getDigit(ammo, 3)
        local tens = getDigit(ammo, 2)
        local ones = getDigit(ammo, 1)
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
        Size = UDim2.fromScale(0.11, 0.08)
    }, {
        ListLayout = Roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Bottom;
            Padding = UDim.new(0, 5)
        });
        CurrentAmmoCounter = Roact.createElement(CurrentAmmoCounter, {
            textSize = 60;
            bold = true;
            textXAlign = Enum.TextXAlignment.Right
        });
        ReserveAmmoCounter = Roact.createElement(ReserveAmmoCounter, {
            textSize = 38;
            bold = false;
            textXAlign = Enum.TextXAlignment.Left;
            lineHeight = 1.2;
        });
    })
end

return AmmoCounters
