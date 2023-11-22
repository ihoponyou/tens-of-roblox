
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local Settings = Roact.Component:extend("MainSettings")
local Tabs = require(script.Tabs)

function Settings:render()
    return Roact.createElement("ScreenGui",{
        Name = "Menu";
        IgnoreGuiInset = true;
        Enabled = true;
    },{
        MainFrame = Roact.createElement("Frame", {
            Name = "Main";
            Size = UDim2.new(1, 0, 1, 0);
            BackgroundTransparency = 0.3;
            BackgroundColor3 = Color3.new();
        },{
            TabsFrame = Roact.createElement("Frame", {
                Name = "TabFrame";
                AnchorPoint = Vector2.new(0.5, 0);
                Position = UDim2.new(0.5, 0, 0, 0);
                BorderSizePixel = 0;
            },{
                UIListLayout = Roact.createElement("UIListLayout", {
                    Name = "TabLayout";
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Center;
                    VerticalAlignment = Enum.VerticalAlignment.Center;
                });
                Tabs = Roact.createElement(Tabs);
            });
            UIPadding = Roact.createElement("UIPadding", {
                PaddingBottom = UDim.new(0.08, 0);
                PaddingTop = UDim.new(0.1, 0);
                PaddingLeft = UDim.new(0.1, 0);
                PaddingRight = UDim.new(0.1, 0);
            });
        });
    })
end

function Settings:SwitchTab()
    
end

return Settings
