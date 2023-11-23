
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local Settings = Roact.Component:extend("MainSettings")
local TabButton = require(script.TabButton)
local Tab = require(script.Tab)

local tabTitles = {
	"Gameplay";
    "Controls";
	"Video";
    "Audio";
}

function Settings:init()
    self.activeTab, self.updateActiveTab = Roact.createBinding(tabTitles[1])
    self.tabs = {}
    for i, tabTitle in tabTitles do
        self.tabs[tabTitle] = Roact.createRef()
    end
    self.pageLayoutRef = Roact.createRef()
end

function Settings:TabButtons()
    local tabButtons = {}
	for index, title: string in tabTitles do
		tabButtons[title] = Roact.createElement(TabButton, {
                name = title;
                layout_order = index;
                on_clicked = function()
                    self.pageLayoutRef:getValue():JumpTo(self.tabs[title]:getValue())
                end
            })
	end
	return Roact.createFragment(tabButtons)
end

function Settings:Tabs(): Roact.Fragment
    local tabs = {}
    for index, title: string in tabTitles do
        tabs[title] = Tab({
            name = title;
            bkg_color = Color3.fromHSV(index/#tabTitles, 1, 1);
            layout_order = index;
            [Roact.Ref] = self.tabs[title]
        })
    end
    return Roact.createFragment(tabs)
end

function Settings:Navbar(props)
    return Roact.createElement("Frame", {
        Name = "Navbar";
        AnchorPoint = Vector2.new(0.5, 0);
        Position = UDim2.new(0.5, 0, 0, 0);
        Size = UDim2.new(1, 0, 0.05, 0);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
    }, {
        ButtonLayout = Roact.createElement("UIListLayout", {
            Name = "ButtonLayout";
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            VerticalAlignment = Enum.VerticalAlignment.Center;
            SortOrder = Enum.SortOrder.LayoutOrder
        });
        TabButtons = self:TabButtons();
    })
end

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
            UIPadding = Roact.createElement("UIPadding", {
                PaddingBottom = UDim.new(0.08, 0);
                PaddingTop = UDim.new(0.1, 0);
                PaddingLeft = UDim.new(0.1, 0);
                PaddingRight = UDim.new(0.1, 0);
            });
            UIListLayout = Roact.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder;
            });
            Navbar = self:Navbar();
            Body = Roact.createElement("Frame", {
                Name = "Body";
                Size = UDim2.new(1, 0, 1, 0);
                LayoutOrder = 1;
            },{
                PageLayout = Roact.createElement("UIPageLayout", {
                    Animated = false;
                    Circular = true;
                    HorizontalAlignment = Enum.HorizontalAlignment.Center;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    TweenTime = 0.4;
                    EasingStyle = Enum.EasingStyle.Exponential;
                    [Roact.Ref] = self.pageLayoutRef
                });
                Padding = Roact.createElement("UIPadding", {
                    PaddingTop = UDim.new(0.02, 0);
                });
                Tabs = self:Tabs();
            })
        });
    })
end

function Settings:didMount()
    self.tabs.Gameplay:getValue()
end

return Settings
