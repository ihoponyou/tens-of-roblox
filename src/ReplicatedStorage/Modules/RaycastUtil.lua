local Debris = game:GetService("Debris")

local RaycastUtil = {}

local container = Instance.new("Folder")
container.Name = "RaycastUtil"
container.Parent = workspace

-- fires a raycast with a laser like visual
function RaycastUtil.RaycastWithVisual(origin: Vector3, direction: Vector3, raycastParams: RaycastParams?, duration: number?): RaycastResult?
    local cast = workspace:Raycast(origin, direction, raycastParams)

    local size, cFrame, color
    if not cast then
        local endPoint = origin + direction
        local distance = (endPoint-origin).Magnitude
        size = Vector3.new(0.1, 0.1, distance)
        cFrame = CFrame.lookAt(origin, endPoint) * CFrame.new(0, 0, -distance/2)
        color = Color3.fromRGB(255, 0, 0)
    else
        size = Vector3.new(0.1, 0.1, cast.Distance)
        cFrame = CFrame.lookAt(origin, cast.Position) * CFrame.new(0, 0, -cast.Distance/2)
        color = Color3.fromRGB(0, 255)
    end

    local visual = Instance.new("Part")
    visual.Size = size
    visual.CFrame = cFrame
    visual.Color = color
    visual.Transparency = 0.8
    visual.CanCollide = false
    visual.CanQuery = false
    visual.CanTouch = false
    visual.Anchored = true
    visual.Locked = true
    visual.Parent = container

    if duration then
        Debris:AddItem(visual, duration)
    end

    return cast
end

return RaycastUtil
