
local RunService = game:GetService("RunService")

local character: Model = script.Parent.Parent
local neck: Motor6D = character:WaitForChild("Torso"):WaitForChild("Neck")

local DEG = math.deg
local RAD = math.rad
local CLAMP = math.clamp

local ORIGINAL_NECK_C0 = neck.C0
local MAX_PERIPHERAL_ANGLE = RAD(100)

function OnRenderStepped(dt: number)    
    if not neck.Enabled then return end

    local camera = workspace.CurrentCamera

    local worldRotation = camera.CFrame.Rotation
    local worldX, _, _ = worldRotation:ToOrientation()
    worldX *= 0.5

    local relativeRotation = character.PrimaryPart.CFrame.Rotation:ToObjectSpace(worldRotation)
    local _, relativeY, _ = relativeRotation:ToOrientation()
    if relativeY < -MAX_PERIPHERAL_ANGLE or relativeY > MAX_PERIPHERAL_ANGLE then
        relativeY = 0
    end
    -- relativeY = CLAMP(relativeY, RAD(-80), RAD(80))

    neck.C0 = neck.C0:Lerp(ORIGINAL_NECK_C0 * CFrame.Angles(-worldX, 0, relativeY), 0.2)
end

RunService.RenderStepped:Connect(OnRenderStepped)
