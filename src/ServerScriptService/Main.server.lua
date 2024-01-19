local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

--[[
    @class ServerMain
]]
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local client, server, shared = require(script:FindFirstChild("LoaderUtils", true)).toWallyFormat(script.src, false)

server.Name = "Nevermore"
server.Parent = ServerScriptService

client.Name = "_SoftShutdownClientPackages"
client.Parent = ReplicatedFirst

shared.Name = "_SoftShutdownSharedPackages"
shared.Parent = ReplicatedFirst

local clientScript = script.ClientScript
clientScript.Name = "QuentySoftShutdownClientScript"
clientScript:Clone().Parent = ReplicatedFirst

local serviceBag = require(server.ServiceBag).new()
serviceBag:GetService(require(server.SoftShutdownService))

serviceBag:Init()
serviceBag:Start()

local Loader = require(ReplicatedStorage.Packages.Loader)
local Knit = require(ReplicatedStorage.Packages.Knit)

Loader.LoadDescendants(ServerStorage.Source.Services, Loader.MatchesName("Service$"))

Knit.Start():andThen(function()
    -- print("Knit started.")
    Loader.LoadChildren(ServerStorage.Source.ServerComponents)
end):catch(warn)
