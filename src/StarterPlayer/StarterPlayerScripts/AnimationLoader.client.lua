
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animations = {}
for _, animation: Animation in ReplicatedStorage.Equipment:GetDescendants() do
    if not animation:IsA("Animation") then continue end

    table.insert(animations, animation)
end

ContentProvider:PreloadAsync(animations)
print(#animations, "animations loaded.")
