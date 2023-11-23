
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

return Roact.forwardRef(function(props, ref): Roact.Component
  return Roact.createElement("Frame", {
      Name = props.name;
      BackgroundColor3 = props.bkg_color;
      LayoutOrder = props.layout_order;
      Size = UDim2.new(1, 0, 1, 0);
      [Roact.Ref] = ref;
  })
end)
