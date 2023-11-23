
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local TabButton = Roact.Component:extend("TabButton")

function TabButton:init()
	function self.onClicked()
		self.props.on_clicked(self.props.name)
	end
end

function TabButton:OnClicked()
	self.props.on_clicked(self.props.name)
end

function TabButton:render()
	return Roact.createElement("TextButton", {
		Size = UDim2.new(0,200,0,50);
		Modal = true;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		LayoutOrder = self.props.layout_order;

		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold);
		Text = self.props.name:upper();
		TextSize = 32;
		TextStrokeTransparency = 0;
		TextColor3 = Color3.new(255,255,255);

		[Roact.Event.MouseButton1Click] = function()
			self.props.on_clicked(self.props.name)
		end;
    })
end

return TabButton
