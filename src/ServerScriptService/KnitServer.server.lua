local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Loader = require(ReplicatedStorage.Packages.Loader)
local Knit = require(ReplicatedStorage.Packages.Knit)

Loader.LoadDescendants(ServerStorage.Source.Services, Loader.MatchesName("Services$"))

Knit.Start():andThen(function()
    -- print("Knit started.")
    Loader.LoadChildren(ServerStorage.Source.ServerComponents)
end):catch(warn)
