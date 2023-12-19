
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local Clickable = Component.new {
	Tag = "Clickable";
	Extensions = {
		Logger,
	};
}

function Clickable:Construct()
	self._trove = Trove.new()

	self.ClickDetector = Instance.new("ClickDetector")
	self.ClickDetector.Parent = self.Instance
	self.Functionality = require(self.Instance.Functionality)
end

function Clickable:Start()
	self._trove:Connect(self.ClickDetector.MouseClick, function(...) self.Functionality:OnClicked(...) end)
end

function Clickable:Stop()
	self._trove:Clean()
end

return Clickable
