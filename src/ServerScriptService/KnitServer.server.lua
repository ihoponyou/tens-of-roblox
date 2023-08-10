local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Knit.AddServices(ServerStorage.Source.Services)
for _,v in ServerStorage.Source:GetDescendants() do
    if v:IsA("ModuleScript") and v.Name:match("Service$") then
        require(v)
    end
end


Knit.Start():andThen(function()
    print("Knit started.")
end):catch(warn)
