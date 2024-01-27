
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local impulseEvent: RemoteEvent = ReplicatedStorage.ReplicateImpulse

impulseEvent.OnClientEvent:Connect(function(part: BasePart, impulse: Vector3)
    part:ApplyImpulse(impulse)
end)
