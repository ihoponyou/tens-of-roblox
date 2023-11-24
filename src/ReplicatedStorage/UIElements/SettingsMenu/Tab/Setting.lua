
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Setting = Roact.Component:extend("Setting")

function Setting:render()
    return Roact.createElement("Frame", {
        Name = self.props.name;
        Size = UDim2.new(1, 0, 0, 35);
        LayoutOrder = self.props.layout_order;
        BackgroundTransparency = 1;
    }, {
        SettingName = Roact.createElement("TextLabel", {
            TextXAlignment = Enum.TextXAlignment.Left;
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold);
            TextColor3 = Color3.new(1, 1, 1);
            TextStrokeTransparency = 0;
            Text = self.props.labelTxt;
            TextSize = 20;
            Size = UDim2.fromScale(.52, 1);
            BackgroundTransparency = 1;
        });
        ControlFrame = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0.5);
            Position = UDim2.fromScale(1, 0.5);
            Size = UDim2.fromScale(0.48, 1);
            BackgroundTransparency = 1;
        },{
            Control = self.props.control
        })
    })
end

return Setting
