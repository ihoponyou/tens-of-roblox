
local character = game.Players.LocalPlayer.Character
local humanoid = character:WaitForChild("Humanoid")

local originalOffset = 1.1
humanoid.CameraOffset = Vector3.new(0, 0, -originalOffset)

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {character}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

function OnRenderStepped(deltaTime: number)
    local hit = workspace:Raycast(
        character.HumanoidRootPart.CFrame.Position+Vector3.yAxis*1.5,
        character.HumanoidRootPart.CFrame.LookVector * originalOffset,
        raycastParams
    )

    local newOffset = if not hit then originalOffset else hit.Distance
    humanoid.CameraOffset = Vector3.new(0, 0, -newOffset)
end

game:GetService("RunService").RenderStepped:Connect(OnRenderStepped)
