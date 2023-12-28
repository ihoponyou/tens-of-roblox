
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local START_SIZE = UDim2.fromOffset(60, 60)
local END_SIZE = UDim2.fromOffset(50, 50)

local Hitmarker = Roact.PureComponent:extend("Hitmarker")

function Hitmarker:render()
   return Roact.createElement("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5);
        Size = START_SIZE;
        Position = UDim2.fromScale(0.5, 0.5);
        Visible = self.props.visible;
        Image = "rbxassetid://15763310980";
        -- ImageColor3 = Color3.fromRGB(255, 0, 0);
        BackgroundTransparency = 1;

        [Roact.Change.Visible] = function(rbx: ImageLabel)
            if not rbx.Visible then return end
            rbx.Size = START_SIZE
            rbx:TweenSize(END_SIZE, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true, function(...)
                print(...)
                -- rbx.Visible = false
            end)
            
            -- if self._tween then self._tween:Cancel() end
            -- rbx.ImageTransparency = 0
            -- self._tween = TweenService:Create(rbx, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), { ImageTransparency = 0.5 })
            -- self._tween:Play()
        end;
    });
end

Hitmarker = RoactRodux.connect(
    function(state, props)
        return {
            visible = not state.SettingsEnabled and state.HitmarkerShown
        }
    end
)(Hitmarker)

return Hitmarker
