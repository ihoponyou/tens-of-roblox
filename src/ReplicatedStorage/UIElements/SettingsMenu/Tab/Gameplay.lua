

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local Setting = require(script.Parent.Setting)

local Gameplay: {Roact.Element} = {
    testsetting = Roact.createElement(Setting, {
        labelTxt = "test setting:";
        control = Roact.createElement("TextBox", {
            Name = "testsetting";
            Size = UDim2.fromScale(1, 1);
            BackgroundColor3 = Color3.new();
            BackgroundTransparency = 0.5;

            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold);
            TextColor3 = Color3.new(1, 1, 1);
            TextStrokeTransparency = 0;
            TextSize = 20;

            Text = "";
            PlaceholderText = 1;
        });
    });
}

return Gameplay
