local character = script.Parent
character:WaitForChild("Head")
character:WaitForChild("Torso")
character:WaitForChild("Left Arm")
character:WaitForChild("Left Leg")
character:WaitForChild("Right Arm")
character:WaitForChild("Right Leg")

for _, v in script.Parent:GetChildren() do
	if v:IsA("BasePart") and v.Name ~= "Head" and v.Name ~= "HummanoidRootPart" then
		print(v, v.LocalTransparencyModifier)

		v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			v.LocalTransparencyModifier = v.Transparency
		end)

		v.LocalTransparencyModifier = v.Transparency
	end
end