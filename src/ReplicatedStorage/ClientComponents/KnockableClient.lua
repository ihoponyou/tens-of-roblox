local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local KnockableClient = Component.new {
	Tag = "Knockable";
	Extensions = {
		Logger,
	};
}



function KnockableClient:Construct()
	self.Humanoid = self.Instance:FindFirstChildOfClass("Humanoid")
end

function KnockableClient:Start()
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

return KnockableClient
