
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local InventorySlots = Roact.Component:extend("AmmoCounters")

local function Slot(props)
    return Roact.createElement("Frame", {
        Size = UDim2.fromOffset(200, 50);
        BackgroundTransparency = 1;
        LayoutOrder = props.layoutOrder;
        [Roact.Ref] = props.ref;
    }, {
        EquipmentLabel = Roact.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1);
            TextScaled = true;
            Text = props.equippedItem;
        });
        KeybindLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Position = UDim2.fromScale(1, 0);
            Size = UDim2.fromOffset(10, 10);
            Text = props.layoutOrder;

            BackgroundTransparency = 1;
            BackgroundColor3 = Color3.fromRGB(163, 162, 165);
            TextStrokeTransparency = 0.5;

            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold);
            TextScaled = true;
            TextColor3 = Color3.fromRGB(255, 255, 255);
            TextXAlignment = Enum.TextXAlignment.Center;
        })
    })
end

function InventorySlots:init()
    self.PrimarySlot = Roact.createRef();
    self.SecondarySlot = Roact.createRef();
    self.MeleeSlot = Roact.createRef();
    self.TertiarySlot = Roact.createRef();
end

function InventorySlots:render()
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(1, 1);
        Position = UDim2.new(1, 0, 1, -80);
        Size = UDim2.fromOffset(200, 200);
        BackgroundTransparency = 1;
    }, {
        ListLayout = Roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Bottom;
            SortOrder = Enum.SortOrder.LayoutOrder;
        });
        PrimarySlot = Slot({
            layoutOrder = 1;
            equippedItem = self.props.equipment_name;
            ref = self.PrimarySlot;
        });
        SecondarySlot = Slot({
            layoutOrder = 2;
            ref = self.SecondarySlot;
        });
        MeleeSlot = Slot({
            layoutOrder = 3;
            ref = self.MeleeSlot;
        });
        TertiarySlot = Slot({
            layoutOrder = 4;
            ref = self.TertiarySlot;
        });
    })
end

return InventorySlots
