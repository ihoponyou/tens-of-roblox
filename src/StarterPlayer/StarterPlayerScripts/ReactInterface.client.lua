
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

local START_SIZE = UDim2.fromOffset(60, 60)
local END_SIZE = UDim2.fromOffset(50, 50)

local function Hitmarker()
    local styles, api = ReactSpring.useSpring(function()
        return {
            reset = true;
            from = { size = START_SIZE };
            to = { size = END_SIZE };
        }
    end)

    -- React.useEffect(function()
    --     api.start({ size = END_SIZE })
    -- end, {})

    return React.createElement("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5);
        Size = styles.size;
        Image = "rbxassetid://15763310980";
        ImageTransparency = 0;
        BackgroundTransparency = 1;
        Position = UDim2.fromScale(0.5, 0.5);
    })
end

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