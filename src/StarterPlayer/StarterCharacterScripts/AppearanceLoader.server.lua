
local character = script.Parent.Parent
local player = game.Players:GetPlayerFromCharacter(character)
local humanoid = character:WaitForChild("Humanoid")

for _,v in character:GetDescendants() do
    if not (v:IsA("Clothing") or v:IsA("Accessory")) then continue end
    v:Destroy()
end
humanoid:ApplyDescription(game.Players:GetHumanoidDescriptionFromUserId(player.UserId))
