
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

type Props = {
    prefab: Model
}

local Viewport: React.FC<Props> = function(props: Props)
    local viewportRef = React.useRef(React.createRef())

    React.useEffect(function()
      local vf = viewportRef.current:getValue()
      local model = props.prefab:Clone()
      model.Parent = vf

      return function()
        model:Destroy()
      end
    end, { props.prefab })

    return React.createElement("ViewportFrame", {
        Ambient = Color3.new(0, 0, 0);
        LightColor = Color3.new(1, 1, 1);
        AnchorPoint = Vector2.new(1, 0.5);
        BackgroundTransparency = 1;
        Position = props.position;
        Size = UDim2.fromScale(4, 2);
        SizeConstraint = Enum.SizeConstraint.RelativeYY;
        ref = viewportRef.current;
    })
end

return Viewport