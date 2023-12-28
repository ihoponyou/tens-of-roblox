local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)

local SpringTest = Roact.Component:extend("App")

function SpringTest:init()
    self.showing = false
    self.styles, self.api = RoactSpring.Controller.new({
        transparency = 1 
    })
end

-- When button is pressed, animate transparency to 0
function SpringTest:render()
    return Roact.createElement("TextButton", {
        Size = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = self.styles.transparency,
        [Roact.Event.Activated] = function()
            self.showing = not self.showing
            local t = if self.showing then 0 else 1
            self.api:start({ transparency = t })
        end,
    })
end

return SpringTest