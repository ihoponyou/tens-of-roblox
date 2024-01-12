--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)

local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local TableUtil = require(ReplicatedStorage.Source.Modules.TableUtil)

local EQUIPMENT_NAMES = TableUtil.GetKeys(EquipmentConfig)
local RANDOM = Random.new()

local Vendor = Component.new {
	Tag = "Vendor";
	Extensions = {
		Logger,
	};
}

function Vendor:Construct()
    self._trove = Trove.new()

    self.OpenPrompt = Instance.new("ProximityPrompt")
    self.OpenPrompt.Parent = self.Instance
    self.OpenPrompt.ClickablePrompt = false
    self.OpenPrompt.KeyboardKeyCode = Enum.KeyCode.B
    self._trove:Add(self.OpenPrompt)
    self._trove:Connect(self.OpenPrompt.Triggered, function(playerWhoTriggered: Player)
        self:GiveItem(playerWhoTriggered)
    end)
end

function Vendor:GiveItem(player: Player)
    local item = Instance.new("Model")
    item.Name = EQUIPMENT_NAMES[RANDOM:NextInteger(1, #EQUIPMENT_NAMES)]
    item.Parent = workspace

    CollectionService:AddTag(item, "Equipment")

    item:WaitForChild("WorldModel"):PivotTo(self.Instance.PrimaryPart.CFrame)
end

return Vendor
