
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local Settings = Roact.Component:extend("TabButton")

function Settings:render(name)
    return Roact.createElement("TextButton",{
        Size = UDim2.new(0,200,0,50);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			FontFace = Font.new("Source Sans Pro", Enum.FontWeight.Bold);
			Text = name:upper();
			TextSize = 32;
			TextStrokeTransparency = 0;
			TextColor3 = Color3.new(255,255,255)
    })
end

return Settings
