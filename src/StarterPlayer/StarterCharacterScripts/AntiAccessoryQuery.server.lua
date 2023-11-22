
local character = script.Parent.Parent

character.DescendantAdded:Connect(function(descendant: Instance)
    if not descendant:IsA("Accessory") then return end
    for _, v: Instance in descendant:GetDescendants() do
        if not v:IsA("BasePart") then continue end
        v.CanCollide = false
        v.CanQuery = false
    end
end)
