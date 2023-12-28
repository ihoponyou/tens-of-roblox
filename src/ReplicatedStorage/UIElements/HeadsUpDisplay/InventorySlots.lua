
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local NUMBER_OF_SLOTS = 4

local InventorySlots = Roact.PureComponent:extend("InventorySlots")

local function Slot(props)
    return Roact.createElement("Frame", {
        Size = UDim2.fromScale(1, 1/NUMBER_OF_SLOTS);
        BackgroundTransparency = 1;
        LayoutOrder = props.layoutOrder;
    }, {
        EquipmentLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.xAxis;
            Position = UDim2.fromScale(1, 0);
            Size = UDim2.fromScale(1.5, 1);
            Text = props.equipment or "nil";

            BackgroundTransparency = 1;
            TextStrokeTransparency = 0;

            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold);
            TextScaled = true;
            TextColor3 = Color3.fromRGB(255, 255, 255);
            TextXAlignment = Enum.TextXAlignment.Right;
        });
        -- KeybindLabel = Roact.createElement("TextLabel", {
        --     AnchorPoint = Vector2.new(0.5, 0.5);
        --     Position = UDim2.fromScale(1, 0);
        --     Size = UDim2.fromScale(0.05, 0.2);
        --     Text = props.layoutOrder;

        --     BackgroundTransparency = 1;
        --     TextStrokeTransparency = 0;

        --     FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold);
        --     TextScaled = true;
        --     TextColor3 = Color3.fromRGB(255, 255, 255);
        --     TextXAlignment = Enum.TextXAlignment.Center;
        -- })
    })
end

function InventorySlots:render()
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(1, .5);
        Position = UDim2.fromScale(1, 0.5);
        Size = UDim2.fromScale(.2, .25);
        BackgroundTransparency = 1;
    }, {
        ListLayout = Roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            VerticalAlignment = Enum.VerticalAlignment.Bottom;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Padding = UDim.new(0.02, 0)
        });
        PrimarySlot = Slot({
            layoutOrder = 1;
            equipment = if self.props.inventory ~= nil then self.props.inventory.Primary else nil
        });
        SecondarySlot = Slot({
            layoutOrder = 2;
            equipment = if self.props.inventory ~= nil then self.props.inventory.Secondary else nil
        });
        MeleeSlot = Slot({
            layoutOrder = 3;
            equipment = if self.props.inventory ~= nil then self.props.inventory.Melee else nil
        });
        TertiarySlot = Slot({
            layoutOrder = 4;
            equipment = if self.props.inventory ~= nil then self.props.inventory.Tertiary else nil
        });
    })
end

InventorySlots = RoactRodux.connect(
    function(state, _)
        -- print(state)
        return {
            inventory = state.Inventory
        }
    end
)(InventorySlots)

return InventorySlots
