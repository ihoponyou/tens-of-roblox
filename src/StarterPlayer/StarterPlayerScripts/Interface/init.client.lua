
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Knit = require(ReplicatedStorage.Packages.Knit)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local InventoryController, InventoryService

local Inventory = require(ReplicatedStorage.Source.UIElements.Inventory)

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER.PlayerGui

export type SlotType = "Primary" | "Secondary" | "Tertiary" | "Melee"

Knit.OnStart():andThen(function()
    InventoryController = Knit.GetController("InventoryController")
    InventoryService = Knit.GetService("InventoryService")
end):catch(warn):await()

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local container = Instance.new("Folder")
container.Name = "Interface"
container.Parent = PLAYER_GUI

local root = ReactRoblox.createRoot(container)

root:render(ReactRoblox.createPortal({
    Inventory = React.createElement(Inventory, {
        inventoryChanged = InventoryService.InventoryChanged,
        activeSlotChanged = InventoryController.ActiveSlotChanged
    })
}, PLAYER_GUI))

-- print("Interface loaded")
