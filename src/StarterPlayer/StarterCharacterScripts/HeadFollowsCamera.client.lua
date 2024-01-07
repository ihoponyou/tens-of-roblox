--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character: Model = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: Part
local neck = character:WaitForChild("Torso"):WaitForChild("Neck") :: Motor6D

local DEG = math.deg
local RAD = math.rad
local CLAMP = math.clamp

local NECK_C0_ORIGIN = neck.C0
local MAX_PERIPHERAL_ANGLE = RAD(120)

local function OnRenderStepped(dt: number)    
	if not neck.Enabled then
		neck.C0 = NECK_C0_ORIGIN
		return
	end

	local camera = workspace.CurrentCamera

	local cameraWorldRotation = camera.CFrame.Rotation
	local cameraRelativeRotation = humanoidRootPart.CFrame.Rotation:ToObjectSpace(cameraWorldRotation)
	local cameraRelativeX, cameraRelativeY, _ = cameraRelativeRotation:ToOrientation()

	if cameraRelativeY < -MAX_PERIPHERAL_ANGLE or cameraRelativeY > MAX_PERIPHERAL_ANGLE then
		cameraRelativeY = 0
	end

	neck.C0 = neck.C0:Lerp(NECK_C0_ORIGIN * CFrame.Angles(-cameraRelativeX, 0, cameraRelativeY), 1-0.05^dt)
end

RunService.RenderStepped:Connect(OnRenderStepped)
