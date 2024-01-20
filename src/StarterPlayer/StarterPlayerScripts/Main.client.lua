
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Packages.Loader)
local Knit = require(ReplicatedStorage.Packages.Knit)

Loader.LoadDescendants(ReplicatedStorage.Source.Controllers, Loader.MatchesName("Controller$"))

Knit.Start():andThen(function()
    -- print("Knit started.")
    Loader.LoadChildren(ReplicatedStorage.Source.ClientComponents)
end, warn)
