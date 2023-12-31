
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local React = require(ReplicatedStorage.Packages.React)
local ReactSpring = require(ReplicatedStorage.Packages.ReactSpring)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local container = Instance.new("ScreenGui")
container.Parent = Players.LocalPlayer.PlayerGui
container.IgnoreGuiInset = true

local root = ReactRoblox.createRoot(container)

local hitmarker = React.createElement(Hitmarker)

local show = true
-- root:render(hitmarker)
while task.wait(1) do
    print'a'
    -- root:render(React.createElement("ScreenGui", {
    --     IgnoreGuiInset = true;
    --     children = {
    --         Hitmarker = React.createElement(Hitmarker);
    --     }
    -- }))
    root:render(if show then hitmarker else nil)
    show = not show
end