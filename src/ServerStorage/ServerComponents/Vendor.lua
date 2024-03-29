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

    self._nextItemIdx = 1
end

function Vendor:GiveItem(_player: Player)
    local item = Instance.new("Model")
    item.Name = EQUIPMENT_NAMES[self._nextItemIdx]
    item.Parent = workspace

    self._nextItemIdx += 1
    if self._nextItemIdx > #EQUIPMENT_NAMES then
        self._nextItemIdx = 1
    end

    CollectionService:AddTag(item, "Equipment")

    local cframe: CFrame = self.Instance.PrimaryPart.CFrame
    item:WaitForChild("WorldModel"):PivotTo(cframe + cframe.LookVector)
end

return Vendor
