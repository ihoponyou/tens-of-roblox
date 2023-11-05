local RunService = game:GetService("RunService")

local updateEvent = script:WaitForChild("UpdateC0")

local Camera = game.Workspace.CurrentCamera
local Player = game.Players.LocalPlayer

local char = Player.Character
local origRightS = char:WaitForChild("Torso"):WaitForChild("Right Shoulder").C0
local origLeftS = char:WaitForChild("Torso"):WaitForChild("Left Shoulder").C0
local origNeck = char:WaitForChild("Torso"):WaitForChild("Neck").C0

local m = Player:GetMouse()

local IsEquipped = false

RunService.RenderStepped:Connect(function()
	if IsEquipped == true then

		if char.Torso:FindFirstChild("Right Shoulder") then
			char.Torso["Right Shoulder"].C0 = char.Torso["Right Shoulder"].C0:Lerp(CFrame.new(1, .65, 0) * CFrame.Angles(-math.asin((m.Origin.p - m.Hit.p).unit.y), 1.55, 0) , 0.1)
		end
		if char.Torso:FindFirstChild("Left Shoulder") then
			char.Torso["Left Shoulder"].C0 = char.Torso["Left Shoulder"].C0:Lerp(CFrame.new(-1, .65, 0) * CFrame.Angles(-math.asin((m.Origin.p - m.Hit.p).unit.y), -1.55, 0) , 0.1)
		end
		if char.Torso:FindFirstChild("Neck") then
			char.Torso["Neck"].C0 = char.Torso["Neck"].C0:Lerp(CFrame.new(0, 1, 0) * CFrame.Angles(-math.asin((m.Origin.p - m.Hit.p).unit.y) + 1.55, 3.15, 0), 0.2)
		end

	else

		if char.Torso:FindFirstChild("Right Shoulder") then
			char.Torso["Right Shoulder"].C0 = char.Torso["Right Shoulder"].C0:lerp(origRightS, 0.1)
		end

		if char.Torso:FindFirstChild("Left Shoulder") then
			char.Torso["Left Shoulder"].C0 = char.Torso["Left Shoulder"].C0:lerp(origLeftS, 0.1)
		end

		if char.Torso:FindFirstChild("Neck") then
			char.Torso["Neck"].C0 = char.Torso["Neck"].C0:lerp(origNeck, 0.1)

		end
	end
end)

char.ChildAdded:Connect(function()
	for i,v in pairs(char:GetChildren()) do
		if v:IsA("Tool") then
			if not v:FindFirstChild("HoldArmsStill") then
				IsEquipped = true
			end
		end
	end
end)

updateEvent.OnClientEvent:Connect(function(PlrAgain, neckCFrame, RsCFrame, LsCFrame)
	local Neck = PlrAgain.Character.Torso:FindFirstChild("Neck", true)
	local Rs = PlrAgain.Character.Torso:FindFirstChild("Right Shoulder", true)
	local Ls = PlrAgain.Character.Torso:FindFirstChild("Left Shoulder", true)

	if Neck then
		Neck.C0 = neckCFrame
	end

	if Rs then
		Rs.C0 = RsCFrame
	end

	if Ls then
		Ls.C0 = LsCFrame
	end
end)

while wait(2) do -- you can change here if you want
	updateEvent:FireServer(char.Torso["Neck"].C0, char.Torso["Right Shoulder"].C0, char.Torso["Left Shoulder"].C0)
end
