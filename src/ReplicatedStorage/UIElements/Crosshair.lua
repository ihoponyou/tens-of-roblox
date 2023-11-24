
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Crosshair = Roact.Component:extend("Crosshair")

function Crosshair:_crosshairTick(props)
    return Roact.createElement("Frame", {
        AnchorPoint = props.anchorPoint;
        Position = props.position;
        Size = if props.vertical then UDim2.fromOffset(self.props.thickness, self.props.length) else UDim2.fromOffset(self.props.length, self.props.thickness);
        BackgroundColor3 = self.props.color;
    })
end

function Crosshair:render()
    return Roact.createElement("Frame", {
        Name = self.props.name or "Crosshair";
        BackgroundTransparency = 1;
        Position = UDim2.fromScale(0.5, 0.5);
    }, {
        North = self:_crosshairTick{
            anchorPoint = Vector2.new(0.5, 1);
            vertical = true;
            position = UDim2.new(0.5, 0, 0.5, -self.props.gap);
        };
        South = self:_crosshairTick{
            anchorPoint = Vector2.new(0.5, 0);
            vertical = true;
            position = UDim2.new(0.5, 0, 0.5, self.props.gap)
        };
        East = self:_crosshairTick{
            anchorPoint = Vector2.new(0, 0.5);
            vertical = false;
            position = UDim2.new(0.5, self.props.gap, 0.5, 0)
        };
        West = self:_crosshairTick{
            anchorPoint = Vector2.new(1, 0.5);
            vertical = false;
            position = UDim2.new(0.5, -self.props.gap, 0.5, 0)
        };
    });
end

return Crosshair
