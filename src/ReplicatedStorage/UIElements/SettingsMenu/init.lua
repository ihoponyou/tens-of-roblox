
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local SettingsMenu = Roact.Component:extend("SettingsMenu")
local TabButton = require(script.TabButton)
local Tab = require(script.Tab)

local TAB_TITLES = {
	"Gameplay";
    "Controls";
	"Video";
    "Audio";
}

local TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

function SettingsMenu:init()
    self.activeTab, self.updateActiveTab = Roact.createBinding(TAB_TITLES[1])
    self.tabs = {}
    self.tabButtons = {}
    for _, tabTitle in TAB_TITLES do
        self.tabs[tabTitle] = Roact.createRef()
        self.tabButtons[tabTitle] = Roact.createRef()
    end

    self.pageLayoutRef = Roact.createRef()
end

function SettingsMenu:SwitchTab(tabName: string)
    -- print(self.activeTab:getValue(), "->", tabName)

    local oldButton: TextButton = self.tabButtons[self.activeTab:getValue()]:getValue()
    TweenService:Create(
        oldButton,
        TWEEN_INFO,
        {
            TextSize = 32,
            TextColor3 = Color3.fromHSV(0, 0, .7)
        }
    ):Play()

    self.updateActiveTab(tabName) -- update active tab

    local activeButton: TextButton = self.tabButtons[tabName]:getValue()
    TweenService:Create(
        activeButton,
        TWEEN_INFO,
        {
            TextSize = 40,
            TextColor3 = Color3.fromHSV(0, 0, 1)
        }
    ):Play()

    self.pageLayoutRef:getValue():JumpTo(self.tabs[tabName]:getValue()) -- switch to active tab
end

function SettingsMenu:TabButtons(): Roact.Fragment
    local tabButtons = {}
	for index, title: string in TAB_TITLES do
		tabButtons[title.."Button"] = Roact.createElement(TabButton, {
            name = title;
            layout_order = index;

            [Roact.Ref] = self.tabButtons[title];

            on_clicked = function(tabName)
                self:SwitchTab(tabName)
            end;
        })
	end
	return Roact.createFragment(tabButtons)
end

-- creates a fragment that contains all settings tabs
function SettingsMenu:Tabs(): Roact.Fragment
    local tabs = {}
    for index, title: string in TAB_TITLES do
        tabs[title] = Roact.createElement(Tab, {
            name = title;
            bkg_color = Color3.fromHSV(index/#TAB_TITLES, 1, 1);
            layout_order = index;

            [Roact.Ref] = self.tabs[title];
        })
    end
    return Roact.createFragment(tabs)
end

function SettingsMenu:Navbar()
    return Roact.createElement("Frame", {
        Name = "Navbar";
        AnchorPoint = Vector2.new(0.5, 0);
        Position = UDim2.fromScale(0.5, 0);
        Size = UDim2.fromScale(1, 0.05);
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

function SettingsMenu:render(): Roact.Element
    return Roact.createElement("ScreenGui",{
        Name = "Menu";
        IgnoreGuiInset = true;
        Enabled = true;
    },{
        MainFrame = Roact.createElement("Frame", {
            Name = "Main";
            Size = UDim2.fromScale(1, 1);
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
                Size = UDim2.fromScale(1, 1);
                LayoutOrder = 1;
                ClipsDescendants = true;
                BackgroundTransparency = 1;
            },{
                PageLayout = Roact.createElement("UIPageLayout", {
                    Animated = false;
                    Circular = false;
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
            });
        });
    })
end

function SettingsMenu:didMount()
    -- self.tabs.Gameplay:getValue()
end

return SettingsMenu
