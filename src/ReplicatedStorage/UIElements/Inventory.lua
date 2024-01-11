
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local useEventConnection = require(ReplicatedStorage.Source.Modules.useEventConnection)
local EquipmentSlot = require(ReplicatedStorage.Source.UIElements.EquipmentSlot)

type Props = {
    inventoryChanged: RBXScriptSignal,
    activeSlotChanged: RBXScriptSignal
}

local Inventory: React.ReactElement<Props, ScreenGui> = function(props: Props)
    local inventory: { [string]: Instance }, setInventoriesState = React.useState({})
    useEventConnection(props.inventoryChanged, function(value: string)
        setInventoriesState(function(oldValue)
            return table.clone(value)
        end)
    end, { props.inventoryChanged })

    local equippedSlot: string, setEquippedSlot = React.useState("")
    useEventConnection(props.activeSlotChanged, function(activeSlot: string)
        setEquippedSlot(function(oldSlot)
            return activeSlot
        end)
    end, { props.activeSlotChanged })

    local elements = {
        ListLayout = React.createElement("UIListLayout", {
            Padding = UDim.new(0, 5);
            FillDirection = Enum.FillDirection.Vertical;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Center;
        }),
        Padding = React.createElement("UIPadding", {
            PaddingRight = UDim.new(0, 5);
        })
    }
    for slot, equipment in inventory do
        elements[slot] = React.createElement(EquipmentSlot, {
            slotType = slot;
            equipmentInstance = equipment;
            isEquipped = equippedSlot == slot;
        })
    end

    return React.createElement("ScreenGui", {
        IgnoreGuiInset = true;
        ResetOnSpawn = false;
        children = elements;
    })
end

return Inventory
