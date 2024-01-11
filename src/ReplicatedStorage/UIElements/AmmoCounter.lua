
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local useEventConnection = require(ReplicatedStorage.Source.Modules.useEventConnection)

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

return AmmoCounter
