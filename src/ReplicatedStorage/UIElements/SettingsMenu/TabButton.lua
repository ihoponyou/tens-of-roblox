
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
		TextSize = if props.layout_order > 1 then 32 else 40;
		TextStrokeTransparency = 0;
		TextColor3 = if props.layout_order > 1 then Color3.fromHSV(0, 0, 0.7) else Color3.fromHSV(0, 0, 1);

		[Roact.Ref] = ref;

		[Roact.Event.Activated] = function()
			props.on_clicked(props.name)
		end;
    })
end)
