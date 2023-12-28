local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = script.Parent.Parent
local player = game.Players:GetPlayerFromCharacter(character)
local humanoid = character:WaitForChild("Humanoid")

for _,v in character:GetDescendants() do
    if v:IsA("Part") then v.CollisionGroup = "Character" end
    if not (v:IsA("Clothing") or v:IsA("Accessory")) then continue end
    v:Destroy()
end

humanoid:ApplyDescriptionReset(
    if player.UserId < 0 then
        ReplicatedStorage.Character.GuestDescription
    else
        game.Players:GetHumanoidDescriptionFromUserId(player.UserId)
)
