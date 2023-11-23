
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local Tab = Roact.Component:extend("Tab")

function Tab:init()
  self.visibility, self.updateVisibility = Roact.createBinding(false)
end

function Tab:render()
  return Roact.createElement("Frame", {
    Name = self.props.name;
    BackgroundColor3 = self.props.bkg_color;
    Size = UDim2.new(1, 0, 1, 0)
  })
end

return Tab
