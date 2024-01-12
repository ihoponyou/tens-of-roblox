local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local InventoryService

local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)
local EquipmentConfig = require(ReplicatedStorage.Source.EquipmentConfig)

local DEBUG = false

local InventoryController = Knit.CreateController({
	Name = "InventoryController",

	Inventory = {},
	InventoryChanged = Signal.new(),

	ActiveItem = nil,
	ActiveSlot = nil,
	ActiveSlotChanged = Signal.new(),
})

function InventoryController:UseActiveItem()
	if not self.ActiveItem then
		warn("No active item to use")
		return
	end
	EquipmentClient:FromInstance(self.ActiveItem):Use()
end

function InventoryController:DropActiveItem()
	if not self.ActiveItem then
		warn("No active item to drop")
		return
	end
	EquipmentClient:FromInstance(self.ActiveItem):Drop()
end

local function isValidSlot(slot: string)
	return type(slot) == "string" and (slot == "Primary" or slot == "Secondary" or slot == "Tertiary")
end
function InventoryController:SwitchSlot(slot: string)
	if not isValidSlot(slot) then
		error("invalid slot")
	end

	local heldItem = self.ActiveItem
	local newItem = self.Inventory[slot]

	-- unequip the currently held item if it exists; will happen even if new slot is same
	if heldItem ~= nil then
		local unequipSuccess = EquipmentClient:FromInstance(heldItem):Unequip()
		if unequipSuccess then
			self.ActiveItem = nil
		end
	end

	UserInputService.MouseIconEnabled = newItem == nil

	-- allows slot to be de-selected and have no active slot
	if self.ActiveSlot == slot then
		self.ActiveSlot = nil
		self.ActiveSlotChanged:Fire(nil)
		return
	end

	-- equip the item at the new slot if it exists
	if newItem ~= nil then
		local equipSuccess = EquipmentClient:FromInstance(newItem):Equip()
		if equipSuccess then
			self.ActiveItem = newItem
		end
	end

	self.ActiveSlot = slot
	self.ActiveSlotChanged:Fire(slot)
end

function InventoryController:KnitStart()
	InventoryService = Knit.GetService("InventoryService")
end

return InventoryController
