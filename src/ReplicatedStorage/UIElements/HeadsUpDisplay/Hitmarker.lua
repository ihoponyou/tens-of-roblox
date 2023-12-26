
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local Hitmarker = Roact.PureComponent:extend("Hitmarker")

function Hitmarker:init()
    self._tween = nil
end

function Hitmarker:render()
   return Roact.createElement("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5);
        Size = UDim2.fromOffset(25, 25);
        Position = UDim2.fromScale(0.5, 0.5);
        Visible = self.props.visible;
        Image = "rbxassetid://15443763135";
        ImageColor3 = Color3.fromRGB(255, 0, 0);
        BackgroundTransparency = 1;

        [Roact.Change.Visible] = function(rbx: ImageLabel)
            if not rbx.Visible then return end
            rbx.Size = UDim2.fromOffset(25, 25);
            rbx.ImageTransparency = 0
            rbx:TweenSize(UDim2.fromOffset(20, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1.5, true)

            if self._tween then self._tween:Cancel() end
            self._tween = TweenService:Create(rbx, TweenInfo.new(1.5), {ImageTransparency = .5})
            self._tween:Play()
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
