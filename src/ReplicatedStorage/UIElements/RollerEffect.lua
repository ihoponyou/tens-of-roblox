
local TweenService = game:GetService("TweenService")

local RollerEffect = {}

RollerEffect.TweenInfo = TweenInfo.new(0.01)

function RollerEffect.Play(label: TextLabel)
	local tween = TweenService:Create(label, RollerEffect.TweenInfo, {LineHeight = 3})
	tween.Completed:Connect(function()
		label.LineHeight = 0
		TweenService:Create(label, RollerEffect.TweenInfo, {LineHeight = 1}):Play()
	end)
	tween:Play()
end

return RollerEffect
