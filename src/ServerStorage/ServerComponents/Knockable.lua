
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Logger = require(script.Parent.Extensions.Logger)

local Knockable = Component.new({
	Tag = "Knockable",
	Extensions = {
		Logger,
	},
})

local KNOCK_THRESHOLD = 0

function Knockable:Construct()
    self._trove = Trove.new()

    local h: Humanoid = self.Instance:FindFirstChildOfClass("Humanoid") -- for intellisense
	self.Humanoid = h

    self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

function Knockable:OnKnocked()
    self.Instance:SetAttribute("Ragdolled", true)
    self.Instance:SetAttribute("Knocked", true)
    self.Humanoid:UnequipTools()
end

function Knockable:Start()
    self._trove:Connect(self.Humanoid.HealthChanged, function(health: number)
        if health > KNOCK_THRESHOLD then return end
        self:OnKnocked()
    end)
end

return Knockable
