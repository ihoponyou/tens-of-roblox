
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local RollerEffect = require(ReplicatedStorage.Source.UIElements.RollerEffect)

local AmmoCounters = Roact.Component:extend("AmmoCounters")

local function AmmoLabel(props)
    return Roact.createElement("TextLabel", {
        Text = props.amount or -1;
        Size = UDim2.new(0, 90, 0, 40);
        BackgroundTransparency = 1;
        BackgroundColor3 = Color3.fromRGB(163, 162, 165);
        TextStrokeTransparency = 0.5;

        LineHeight = props.lineHeight or 1;
        FontFace = Font.new("rbxassetid://12187365364", if props.bold then Enum.FontWeight.Bold else Enum.FontWeight.Regular);
        TextSize = props.textSize;
        TextColor3 = props.textColor3;
        TextXAlignment = props.textXAlign or Enum.TextXAlignment.Center;
    })
end

-- local function getDigit(num, digit)
-- 	local n = 10 ^ digit
-- 	local n1 = 10 ^ (digit - 1)
-- 	return math.floor((num % n) / n1)
-- end

-- local function Digit(props)
--     return Roact.createElement("TextLabel", {
--         BackgroundTransparency = 1;
--         LayoutOrder = props.layoutOrder;
--         FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold);
--         Size = UDim2.new(0, 34, 1, 0);
--         Text = props.text;
--         TextColor3 = Color3.fromRGB(255, 255, 255);
--         TextSize = 60;
--         TextStrokeTransparency = 0.5;
--         TextXAlignment = Enum.TextXAlignment.Right;
--     })
-- end

-- local function Roller(props)
--     return Roact.createElement("Frame", {
--         BackgroundTransparency = 1;
--         Size = UDim2.new(0, 100, 1, 0);
--         ClipsDescendants = true;
--     }, {
--         ListLayout = Roact.createElement("UIListLayout", {
--             FillDirection = Enum.FillDirection.Horizontal;
--             HorizontalAlignment = Enum.HorizontalAlignment.Right;
--             VerticalAlignment = Enum.VerticalAlignment.Top;
--             SortOrder = Enum.SortOrder.LayoutOrder;
--         });
--         Thousand = Roact.createElement(Digit, {
--             text = props.thousand;
--             layoutOrder = 0;
--         });
--         Hundred = Roact.createElement(Digit, {
--             text = props.hundred;
--             layoutOrder = 1;
--         });
--         Ten = Roact.createElement(Digit, {
--             text = props.ten;
--             layoutOrder = 2;
--         });
--         One = Roact.createElement(Digit, {
--             text = props.one;
--             layoutOrder = 3;
--         })
--     })
-- end

-- local CurrentAmmoRoller = RoactRodux.connect(
--     function(state, props)
--         local ammo = state.CurrentAmmo
--         return {
--             thousand = getDigit(ammo, 4);
--             hundred = getDigit(ammo, 3);
--             ten = getDigit(ammo, 2);
--             one = getDigit(ammo, 1);
--         }
--     end
-- )(Roller)

local CurrentAmmoCounter = RoactRodux.connect(
    function(state, props)
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
            textXAlign = Enum.TextXAlignment.Right;
            lineHeight = 1;
            textColor3 = Color3.fromRGB(255, 255, 255);
        });
        ReserveAmmoCounter = Roact.createElement(ReserveAmmoCounter, {
            textSize = 38;
            bold = false;
            textXAlign = Enum.TextXAlignment.Left;
            lineHeight = 1.2;
            textColor3 = Color3.fromRGB(220, 220, 220);
        });
    })
end

return AmmoCounters
