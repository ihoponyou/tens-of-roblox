
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

return Roact.forwardRef(function(props, ref)
	return Roact.createElement("TextButton", {
		Size = UDim2.new(0,200,0,50);
		Modal = true;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		LayoutOrder = props.layout_order;

		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold);
		Text = props.name:upper();
		TextSize = 32;
		TextStrokeTransparency = 0;
		TextColor3 = Color3.new(255,255,255);

		[Roact.Ref] = ref;

		[Roact.Event.Activated] = function()
			props.on_clicked(props.name)
		end;
    })
end)
