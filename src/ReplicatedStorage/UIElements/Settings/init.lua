
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
end

function Settings:TabButtons()
    local tabButtons = {}
	for index, title: string in tabTitles do
		tabButtons[title] = Roact.createElement(TabButton, {
                Name = title;
                layout_order = index;
            })
	end
	return Roact.createFragment(tabButtons)
end

local Tab = Roact.forwardRef(function(props, ref): Roact.Component
    return Roact.createElement("Frame", {
        Name = props.name;
        BackgroundColor3 = props.bkg_color;
        [Roact.Ref] = ref;
    })
end)

function Settings:Tabs(): Roact.Fragment
    local tabs = {}
    for index, title: string in tabTitles do
        tabs[title] = Tab({
            name = title;
            bkg_color = Color3.fromHSV(index/#tabTitles, 1, 1);
            [Roact.Ref] = self.tabs[title]
        })
    end
    return Roact.createFragment(tabs)
end

local function Navbar(props, children)
    return Roact.createElement("Frame", {
        Name = "Navbar";
        AnchorPoint = Vector2.new(0.5, 0);
        Position = UDim2.new(0.5, 0, 0, 0);
        Size = UDim2.new(1, 0, 0.05, 0);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
    }, children)
end

local FancyTextBox = Roact.forwardRef(function(props, ref)
    return Roact.createElement("TextBox", {
        MultiLine = true;
        PlaceholderText = "Enter your text here";
        PlaceholderColor3 = Color3.new(0.4, 0.4, 0.4);
        [Roact.Change.Text] = props.onTextChange;
        [Roact.Ref] = ref;
    })
end)

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
            Navbar = Navbar({
                ButtonLayout = Roact.createElement("UIListLayout", {
                    Name = "ButtonLayout";
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Center;
                    VerticalAlignment = Enum.VerticalAlignment.Center;
                    SortOrder = Enum.SortOrder.LayoutOrder
                });
                -- TabButtons = self:TabButtons();
            });
            Body = Roact.createElement("Frame", {
                Name = "Body";
                Size = UDim2.new(1, 0, 1, 0);
                LayoutOrder = 1;
            },{
                PageLayout = Roact.createElement("UIPageLayout", {
                    Circular = true;
                    HorizontalAlignment = Enum.HorizontalAlignment.Center;
                    SortOrder = Enum.SortOrder.LayoutOrder;
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
    self.tabs.Gameplay:getValue().Size = UDim2.new(1, 0, 1, 0)
end

return Settings
