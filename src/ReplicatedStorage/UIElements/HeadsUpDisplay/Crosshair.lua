
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Crosshair = Roact.PureComponent:extend("Crosshair")

function Crosshair:_crosshairTick(props)
    return Roact.createElement("Frame", {
        AnchorPoint = props.anchorPoint;
        Position = props.position;
        Size = if props.vertical then UDim2.fromOffset(self.props.thickness, self.props.length) else UDim2.fromOffset(self.props.length, self.props.thickness);
        BackgroundColor3 = self.props.color;
    })
end

local function MainFrame(props)
    return Roact.createElement("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.fromScale(0.5, 0.5);
        AnchorPoint = Vector2.new(0.5, 0.5);
        Visible = props.visible;
        Rotation = props.rotation or 0;

        [Roact.Children] = props.children;
    })
end
MainFrame = RoactRodux.connect(
    function(state, props)
        return {
            visible = not state.SettingsEnabled and state.CrosshairEnabled
        }
    end
)(MainFrame)

function Crosshair:render()
    return Roact.createElement(MainFrame, {
        rotation = self.props.rotation;
        children = {
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
        }
    });
end

return Crosshair
