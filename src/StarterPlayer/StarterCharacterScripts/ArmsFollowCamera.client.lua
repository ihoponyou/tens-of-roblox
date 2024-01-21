
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Comm = require(ReplicatedStorage.Packages.Comm)

local clientComm = Comm.ClientComm.new(ReplicatedStorage, true, "BodyPartMovement")

local ORIGIN_NECK = CFrame.new(0, 1, 0) * CFrame.fromOrientation(-math.pi/2, -math.pi, 0)
local ORIGIN_R = CFrame.new(1, 0.5, 0) * CFrame.fromOrientation(0, math.pi/2, 0)
local ORIGIN_L = CFrame.new(-1, 0.5, 0) * CFrame.fromOrientation(0, -math.pi/2, 0)

local updateEvent = clientComm:GetSignal("Update")

local function rotateJoints(character: Model?, angle: number)
    if not character then return end
    local torso: Part? = character:FindFirstChild("Torso")
    if not torso then return end

    -- allow for missing arms
    local shoulderR: Motor6D? = torso:FindFirstChild("Right Shoulder")
    if shoulderR ~= nil then
        shoulderR.C0 = shoulderR.C0:Lerp(ORIGIN_R * CFrame.fromOrientation(0, 0, angle), 0.1)
    end

    local shoulderL: Motor6D? = torso:FindFirstChild("Left Shoulder")
    if shoulderL ~= nil then
        shoulderL.C0 = shoulderL.C0:Lerp(ORIGIN_L * CFrame.fromOrientation(0, 0, -angle), 0.1)
    end

    local neck: Motor6D? = torso:FindFirstChild("Neck")
    if neck ~= nil then
        neck.C0 = neck.C0:Lerp(ORIGIN_NECK * CFrame.fromOrientation(-angle, 0, 0), 0.2)
    end
end

-- update my arms
RunService.Heartbeat:Connect(function(deltaTime)
    local camera = workspace.CurrentCamera
    local xAngle, _, _ = camera.CFrame:ToOrientation()

    rotateJoints(Players.LocalPlayer.Character, xAngle)

    updateEvent:Fire(xAngle)
end)

-- update other peoples' arms
updateEvent:Connect(function(player: Player, x: number)
    rotateJoints(player.Character, x)
end)
