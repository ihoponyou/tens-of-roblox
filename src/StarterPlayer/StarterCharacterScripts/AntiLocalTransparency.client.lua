
local character = game.Players.LocalPlayer.Character
character:WaitForChild("Head")
character:WaitForChild("Torso")
character:WaitForChild("Left Arm")
character:WaitForChild("Left Leg")
character:WaitForChild("Right Arm")
character:WaitForChild("Right Leg")

local function onDescendantAdded(descendant: Instance)
	if descendant:IsA("BasePart") and descendant.Name ~= "Head" and descendant.Name ~= "HummanoidRootPart" then
		-- print(descendant, descendant.LocalTransparencyModifier)

		descendant:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			-- print(descendant.LocalTransparencyModifier)
			-- descendant.LocalTransparencyModifier = descendant.Transparency
		end)

		-- descendant.LocalTransparencyModifier = descendant.Transparency
	end
end

for _, v in character:GetChildren() do
	onDescendantAdded(v)
end
character.DescendantAdded:Connect(onDescendantAdded)
