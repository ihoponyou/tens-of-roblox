local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local characterTags = {
    "Character";
    "Ragdoll";
    "Knockable";
}

local function OnCharacterAdded(character: Model)
    for _, tag in characterTags do
        CollectionService:AddTag(character, tag)
    end
end

local function OnPlayerAdded(player: Player)
    if player.Character then OnCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(OnCharacterAdded)
end

for _,v in Players:GetPlayers() do
    OnPlayerAdded(v)
end
Players.PlayerAdded:Connect(OnPlayerAdded)
