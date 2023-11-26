
local TweenService = game:GetService("TweenService")

return function(label: TextLabel, newText)
	local tween = TweenService:Create(label, TweenInfo.new(0.15), {LineHeight = 3})
	tween.Completed:Once(function()
		task.wait(0.1)
		label.Text = newText
		label.LineHeight = 0 
		TweenService:Create(label, TweenInfo.new(0.15), {LineHeight = 1}):Play()
	end)
    tween:Play()
end
