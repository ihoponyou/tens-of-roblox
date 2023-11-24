
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
-- local Tab = Roact.Component:extend("Tab")

local TabModules = {
    Gameplay = require(script.Gameplay);
    Controls = require(script.Controls);
    Video = require(script.Video);
    Audio = require(script.Audio);
}

-- function Tab:render()
    return Roact.forwardRef(function(props, ref)
        return Roact.createElement("Frame", {
            Name = props.name;
            BackgroundColor3 = props.bkg_color;
            BackgroundTransparency = 1;
            LayoutOrder = props.layout_order;
            Size = UDim2.fromScale(1, 1);

            [Roact.Ref] = ref;
        }, {
            SettingLayout = Roact.createElement("UIListLayout", {
                Name = "SettingLayout";
                FillDirection = Enum.FillDirection.Vertical;
                HorizontalAlignment = Enum.HorizontalAlignment.Center;
                VerticalAlignment = Enum.VerticalAlignment.Top;
                SortOrder = Enum.SortOrder.LayoutOrder
            });
            UIPadding = Roact.createElement("UIPadding", {
                PaddingLeft = UDim.new(.1, 0);
                PaddingRight = UDim.new(.1, 0);
            });
            Settings = Roact.createFragment(TabModules[props.name]);
        })
    end)
-- end

-- return Tab
