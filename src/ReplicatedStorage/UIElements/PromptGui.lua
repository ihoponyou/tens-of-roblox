
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local PromptGui = Roact.Component:extend("PromptGui")

function PromptGui:render()
    return Roact.createElement("BillboardGui", {
        AlwaysOnTop = true;
        Size = UDim2.fromOffset(200, 50);
        Enabled = false;
        StudsOffset = Vector3.yAxis;
        [Roact.Ref] = self.props.ref;
    }, {
        PromptLabel = Roact.createElement("TextLabel", {
            BackgroundTransparency = 1;
            TextStrokeTransparency = 0.5;
            TextColor3 = Color3.fromRGB(255, 255, 255);
            FontFace = Font.new("rbxassetid://12187365364");
            RichText = true;
            Text = "<b>[E]</b> PICK UP " .. self.props.equipment_name:upper();
            TextSize = 24;
            Size = UDim2.fromScale(1, 1);
        })
    });
end

return PromptGui