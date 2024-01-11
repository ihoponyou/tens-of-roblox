
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local function PromptGui(props)
    return React.createElement("BillboardGui", {
        AlwaysOnTop = true;
        Adornee = props.adornee;
        Size = UDim2.fromOffset(200, 50);
        Enabled = true;
        StudsOffset = Vector3.yAxis * 0.5;
    }, {
        PromptLabel = React.createElement("TextLabel", {
            BackgroundTransparency = 1;
            TextStrokeTransparency = 0.5;
            TextColor3 = Color3.fromRGB(255, 255, 255);
            FontFace = Font.new("rbxassetid://12187365364");
            RichText = true;
            Text = "<b>[E]</b> PICK UP " .. props.equipmentName:upper();
            TextSize = 24;
            Size = UDim2.fromScale(1, 1);
        })
    });
end

return PromptGui