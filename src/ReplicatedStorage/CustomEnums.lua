
local EnumList = require(game.ReplicatedStorage.Packages.EnumList)

local CustomEnums = {}

CustomEnums.InventorySlots = EnumList.new("InventorySlot", {
    "Primary",
    "Secondary",
    "Tertiary",
    "Melee",
})

return CustomEnums
