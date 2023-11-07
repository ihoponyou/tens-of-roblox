local RunService = game:GetService("RunService")

local updateEvent = script:WaitForChild("UpdateC0")

local Camera = game.Workspace.CurrentCamera
local Player = game.Players.LocalPlayer

local char = Player.Character
local torso = char:WaitForChild("Torso")
local rightShoulderOrigin = torso:WaitForChild("Right Shoulder").C0
local leftShoulderOrigin = torso:WaitForChild("Left Shoulder").C0
local neckOrigin = torso:WaitForChild("Neck").C0

local m = Player:GetMouse()

local IsEquipped = false

local function OnRenderStepped(deltaTime: number)
	if IsEquipped then
		local cameraToMouse = m.Origin.Position - m.Hit.Position

		if torso:FindFirstChild("Right Shoulder") then
			local rightShoulder: Motor6D = torso["Right Shoulder"]
			rightShoulder.C0 = rightShoulder.C0:Lerp(
				CFrame.new(1, 0.65, 0) * CFrame.Angles(-math.asin(cameraToMouse.Unit.Y), 1.55, 0),
				0.1
			)
		end
		if torso:FindFirstChild("Left Shoulder") then
			local leftShoulder: Motor6D = torso["Left Shoulder"]
			leftShoulder.C0 = leftShoulder.C0:Lerp(
				CFrame.new(-1, 0.65, 0) * CFrame.Angles(-math.asin(cameraToMouse.Unit.Y), -1.55, 0),
				0.1
			)
		end
		if torso:FindFirstChild("Neck") then
			local neck: Motor6D = torso.Neck
			neck.C0 = neck.C0:Lerp(
				CFrame.new(0, 1, 0) * CFrame.Angles(-math.asin(cameraToMouse.Unit.Y) + 1.55, 3.15, 0),
				0.2
			)
		end
	else
		if torso:FindFirstChild("Right Shoulder") then
			local rightShoulder: Motor6D = torso["Right Shoulder"]
			rightShoulder.C0 = rightShoulder.C0:Lerp(rightShoulderOrigin, 0.1)
		end
		if torso:FindFirstChild("Left Shoulder") then
			local leftShoulder: Motor6D = torso["Left Shoulder"]
			leftShoulder.C0 = leftShoulder.C0:Lerp(leftShoulderOrigin, 0.1)
		end
		if torso:FindFirstChild("Neck") then
			local neck: Motor6D = torso.Neck
			neck.C0 = neck.C0:Lerp(neckOrigin, 0.2)
		end
	end
end

local function OnUpdateEvent(toUpdate: Player, newNeckC0, newRsC0, newLsC0)
	local character = toUpdate.Character
	if not character then return end
	local neck = character.Torso:FindFirstChild("Neck")
	local rs = character.Torso:FindFirstChild("Right Shoulder")
	local ls = character.Torso:FindFirstChild("Left Shoulder")

	if neck then
		neck.C0 = newNeckC0
	end

	if rs then
		rs.C0 = newRsC0
	end

	if ls then
		ls.C0 = newLsC0
	end
end

local function OnCharacterChildAdded(child: Instance)
	if child.ClassName == "Tool" then
		IsEquipped = true
	end
end

local function OnCharacterChildRemoved(child: Instance)
	if child.ClassName == "Tool" then
		IsEquipped = false
	end
end

char.ChildAdded:Connect(OnCharacterChildAdded)
char.ChildRemoved:Connect(OnCharacterChildRemoved)

RunService.RenderStepped:Connect(OnRenderStepped)
updateEvent.OnClientEvent:Connect(OnUpdateEvent)

while task.wait(2) do -- you can change here if you want
	updateEvent:FireServer(torso["Neck"].C0, torso["Right Shoulder"].C0, torso["Left Shoulder"].C0)
end
