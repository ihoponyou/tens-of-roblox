
local DEBUG = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(script.Parent.Extensions.Logger)
local Roact = require(ReplicatedStorage.Packages.Roact)

local PromptGui = require(ReplicatedStorage.Source.UIElements.PromptGui)

local EquippableClient = Component.new({
	Tag = "Equippable",
	Extensions = {
		Logger,
	},
})

function EquippableClient:Construct()
    self._trove = Trove.new()

    self.WorldModel = self.Instance:WaitForChild("WorldModel")

    self.EquipRequest = self.Instance:WaitForChild("EquipRequest")

    -- self.EquipEvent = self._trove:Add(Instance.new("BindableEvent"))

    self.ProximityPrompt = self.WorldModel:WaitForChild("EquipPrompt")
    self.ProximityPrompt.RequiresLineOfSight = false

    self.promptRef = Roact.createRef()
    self.PromptGui = Roact.createElement(PromptGui, {
        equipment_name = self.Instance.Name;
        ref = self.promptRef;
    })
    self._promptTree = Roact.mount(self.PromptGui, self.WorldModel)
end

function EquippableClient:_showPrompt()
    self.promptRef:getValue().Enabled = true
end

function EquippableClient:_hidePrompt()
    self.promptRef:getValue().Enabled = false
end

function EquippableClient:Start()
    self._trove:Connect(self.ProximityPrompt.PromptShown, function(...) self:_showPrompt(...) end)
    self._trove:Connect(self.ProximityPrompt.PromptHidden, function(...) self:_hidePrompt(...) end)
end

function EquippableClient:Stop()
    self._trove:Clean()
end

return EquippableClient
