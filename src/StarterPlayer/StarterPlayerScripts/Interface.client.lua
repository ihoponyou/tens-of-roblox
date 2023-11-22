
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local PLAYER_GUI = Players.LocalPlayer:WaitForChild("PlayerGui")

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local Roact = require(ReplicatedStorage.Packages.Roact)
local MainSettings = require(ReplicatedStorage.Source.UIElements.Settings)

local mainSettings = Roact.createElement(MainSettings)

Roact.mount(mainSettings, PLAYER_GUI)
