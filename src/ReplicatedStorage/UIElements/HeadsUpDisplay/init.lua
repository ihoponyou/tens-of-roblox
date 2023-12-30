
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local AmmoCounters = require(script.AmmoCounters)
local Crosshair = require(script.Crosshair)
local InventorySlots = require(script.InventorySlots)
local HeadsUpDisplay = Roact.Component:extend("HeadsUpDisplay")

local function MainFrame(props)
    return Roact.createElement("Frame", {
        Size = UDim2.fromScale(1, 1);
        BackgroundTransparency = 1;
        Visible = props.enabled;
        [Roact.Children] = props.elements;
    })
end
MainFrame = RoactRodux.connect(
    function(state, props)
        return {
            enabled = not state.SettingsEnabled
        }
    end
)(MainFrame)

function HeadsUpDisplay:render()
    return Roact.createElement("ScreenGui", {
        IgnoreGuiInset = true;
    }, {
        MainFrame = Roact.createElement(MainFrame, {
            elements = {
                UIPadding = Roact.createElement("UIPadding", {
                    PaddingBottom = UDim.new(0.03, 0);
                    PaddingTop = UDim.new(0.03, 0);
                    PaddingLeft = UDim.new(0.03, 0);
                    PaddingRight = UDim.new(0.03, 0);
                });
                Crosshair = Roact.createElement(Crosshair, {
                    gap = 3;
                    length = 6;
                    thickness = 2;
                    color = Color3.fromRGB(255, 255, 255);
                });
                AmmoCounters = Roact.createElement(AmmoCounters);
                InventorySlots = Roact.createElement(InventorySlots);
            }
        });
    });
end

return HeadsUpDisplay
