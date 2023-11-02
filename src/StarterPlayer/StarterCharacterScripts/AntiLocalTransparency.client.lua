
local character = game.Players.LocalPlayer.Character

local hide = {
	"Head",
	"HumanoidRootPart",
	"Left Arm",
	"Right Arm",
	-- "Torso",
	-- "Left Leg",
	-- "Right Leg"
}

local function onDescendantAdded(descendant: Instance)
	if not descendant:IsA("BasePart") then return end
	if table.find(hide, descendant.Name) then return end
	
	-- print(descendant, descendant.LocalTransparencyModifier)

	descendant:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
		-- print(descendant.LocalTransparencyModifier)
		descendant.LocalTransparencyModifier = descendant.Transparency
	end)

	descendant.LocalTransparencyModifier = descendant.Transparency

	if descendant.Parent:IsA("Accessory") then
		--print(descendant.Name)
		descendant.Transparency = 1

	end
end

for _, v in character:GetDescendants() do
	onDescendantAdded(v)
end

local conn = character.DescendantAdded:Connect(onDescendantAdded)
script.Destroying:Once(function() print("successfully disconnected") conn:Disconnect() end)
