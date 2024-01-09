--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Component = require(Packages.Component)
local Knit = require(Packages.Knit)
local Trove = require(Packages.Trove)

local InputController, ViewmodelController, CameraController

local EquipmentClient = require(ReplicatedStorage.Source.ClientComponents.EquipmentClient)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local MeleeClient = Component.new({
	Tag = "Melee",
	Extensions = {
		Logger,
	},
})

function MeleeClient:Construct()
	self._trove = Trove.new()
end

function MeleeClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
        InputController = Knit.GetController("InputController")
        CameraController = Knit.GetController("CameraController")
    end):catch(warn)

	EquipmentClient:WaitForInstance(self.Instance):andThen(function(component)
		self.EquipmentClient = component
	end):catch(warn):await()

    self._trove:Connect(self.EquipmentClient.Equipped, function(equipped: boolean)
        if equipped then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end)
end

function MeleeClient:Stop()
    self._trove:Destroy()
end

function MeleeClient:_onEquipped()
	self._equipTrove = self._trove:Extend()
end

function MeleeClient:_onUnequipped()
    self._equipTrove:Clean()
end

return MeleeClient
