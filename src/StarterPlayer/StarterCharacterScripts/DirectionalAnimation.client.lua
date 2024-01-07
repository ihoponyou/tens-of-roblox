--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local _character = Players.LocalPlayer.Character
local _humanoid: Humanoid = _character:WaitForChild("Humanoid")
local _humanoidRootPart: Part = _character:WaitForChild("HumanoidRootPart")
local _torso: Part = _character:WaitForChild("Torso")

local BASE_C0 = {
    RootJoint = (_humanoidRootPart:WaitForChild("RootJoint") :: Motor6D).C0;
    Neck = (_torso:WaitForChild("Neck") :: Motor6D).C0;
	HipR = (_torso:WaitForChild("Right Hip") :: Motor6D).C0;
	HipL = (_torso:WaitForChild("Left Hip") :: Motor6D).C0;
}

local RANGE_OF_MOTION = 50
local RANGE_OF_MOTION_TORSO = 65-RANGE_OF_MOTION
local RANGE_OF_MOTION_XZ = RANGE_OF_MOTION/140
local LERP_SPEED = 0.1

RANGE_OF_MOTION = math.rad(RANGE_OF_MOTION)
RANGE_OF_MOTION_TORSO = math.rad(RANGE_OF_MOTION_TORSO)

local function calculateC0(dt, humanoidRootPart, humanoid, torso)
    local direction: Vector3 = humanoidRootPart.CFrame:VectorToObjectSpace(humanoidRootPart.AssemblyLinearVelocity)
    direction = Vector3.new(direction.X/humanoid.WalkSpeed, 0, direction.Z/humanoid.WalkSpeed)

    local newX = (direction.X * (RANGE_OF_MOTION - (math.abs(direction.Z) * (RANGE_OF_MOTION/2))))
    local newTorso = (direction.X * (RANGE_OF_MOTION_TORSO - (math.abs(direction.Z) * (RANGE_OF_MOTION_TORSO/2))))
    local newXZ = (direction.X * (RANGE_OF_MOTION_XZ - (math.abs(direction.Z) * (RANGE_OF_MOTION_XZ/2))))

    if direction.Z > 0.1 then
        newX *= -1
        newTorso *= -1
        newXZ *= -1
    end

    local newHipR = BASE_C0.HipR * CFrame.new(-newXZ, 0, 0) * CFrame.Angles(0, -newX, 0)
    local newHipL = BASE_C0.HipL * CFrame.new(-newXZ, 0, 0) * CFrame.Angles(0, -newX, 0)
    local newRootJoint = BASE_C0.RootJoint * CFrame.Angles(0, 0, -newTorso)
    local newNeck = BASE_C0.Neck * CFrame.Angles(0, 0, newTorso)

    local lerpTime = 1 - LERP_SPEED ^ dt

    torso["Right Hip"].C0 = torso["Right Hip"].C0:Lerp(newHipR, lerpTime)
    torso["Left Hip"].C0 = torso["Left Hip"].C0:Lerp(newHipL, lerpTime)
    --humanoidRootPart.RootJoint.C0 = humanoidRootPart.RootJoint.C0:Lerp(newRootJoint, lerpTime)
    --torso.Neck.C0 = torso.Neck.C0:Lerp(newNeck, lerpTime)
end

RunService.RenderStepped:Connect(function(deltaTime)
    -- for _,v in Players:GetPlayers() do
        
    -- end
    calculateC0(deltaTime, _humanoidRootPart, _humanoid, _torso)
end)
