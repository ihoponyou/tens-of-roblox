local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")


local characterTags = {
    "Ragdoll";
    "Knockable";
}

function OnCharacterAdded(character: Model)
    for _, tag in characterTags do
        CollectionService:AddTag(character, tag)
    end
end

function OnPlayerAdded(player: Player)
    player.CharacterAdded:Connect(OnCharacterAdded)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
