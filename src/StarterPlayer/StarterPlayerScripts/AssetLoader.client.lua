
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animations = 0
local sounds = 0
local assets = {}
for _, asset: Animation | Sound in ReplicatedStorage.Equipment:GetDescendants() do
    if asset:IsA("Animation") then
        animations += 1
    elseif asset:IsA("Sound") then
        sounds += 1
    else
        continue
    end

    table.insert(assets, asset)
end

ContentProvider:PreloadAsync(assets)
print(animations, "animations loaded.")
print(sounds, "sounds loaded.")
