
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local Tabs = Roact.Component:extend("Labels")

local contents = {
	"Gameplay";
    "Controls";
	"Video";
    "Audio";
}

function Tabs:init()
	self.partRef = Roact.createRef()
end

function Tabs:render()
	local tabs = {}
	for index, content: string in contents do
		tabs[index] = Roact.createElement("TextButton",{
			Size = UDim2.new(0,200,0,50);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			FontFace = Font.new("Source Sans Pro", Enum.FontWeight.Bold);
			Text = content:upper();
			TextSize = 32;
			TextStrokeTransparency = 0;
			TextColor3 = Color3.new(255,255,255)
		})
	end
	return Roact.createFragment(tabs)
end

return Tabs
