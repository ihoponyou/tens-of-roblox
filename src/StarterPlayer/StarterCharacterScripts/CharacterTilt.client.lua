--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character: Model = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: Part

local rootJoint = humanoidRootPart:WaitForChild("RootJoint") :: Motor6D

local ROOT_ORIGIN_C0 = (rootJoint :: Motor6D).C0

local function OnRenderStepped(dt: number)
	local v1 = 0
	local v2 = 0

	local relativeVelocity = humanoidRootPart.AssemblyLinearVelocity * Vector3.new(1,0,1)
	if relativeVelocity.Magnitude > 0.1 then
		v1 = humanoidRootPart.CFrame.RightVector:Dot(relativeVelocity.Unit)
		v2 = humanoidRootPart.CFrame.LookVector:Dot(relativeVelocity.Unit)
	end

	-- tilt the character in the direction they move
	local xRotation = math.rad(v2 * 6)
	local yRotation = math.rad(-v1 * 8)
	rootJoint.C0 = rootJoint.C0:Lerp(ROOT_ORIGIN_C0 * CFrame.Angles(xRotation, yRotation, 0), 1-0.05^dt)
end

RunService.RenderStepped:Connect(OnRenderStepped)
