
-- allows for attacking like a melee weapon

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)
local Find = require(ReplicatedStorage.Source.Modules.Find)
local MeleeStats = require(ServerStorage.Source.MeleeStats)

local Melee = Component.new({
	Tag = "Melee",
})

function Melee:Construct()
	self._trove = Trove.new()
	self._serverComm = self._trove:Construct(Comm.ServerComm, self.Instance, "Melee")

    self.Stats = MeleeStats[self.Instance.Name] :: MeleeStats.StatBlock

    self._canAttack = false
    self._combo = 0

	self.AttackRequest = self._serverComm:CreateSignal("AttackRequest")
    self._trove:Connect(self.AttackRequest, function(...)
        self:Attack(...)
    end)
end

function Melee:Start()
    self.Equipment = self:GetComponent(Equipment)

    -- ensure animations exist
    local animations = self.Equipment.Folder.Animations
    for i=0, self.Stats.MaxCombo do
        local animationName = "Attack"..tostring(i+1)

        Find.path(animations, "3P/"..animationName)

        if not self.Equipment.Config.AllowFirstPerson then continue end
        Find.path(animations, "1P/"..animationName)
    end

    self._trove:Connect(self.Equipment.Equipped, function(isEquipped: boolean)
        self._canAttack = false
        if isEquipped then
            self._readyThread = task.delay(self.Stats.DeployTime, function()
                self._canAttack = true
                self._readyThread = nil
            end)
        else
            if self._readyThread then
                task.cancel(self._readyThread)
                self._readyThread = nil
            end
        end
    end)
end

function Melee:Stop()
	self._trove:Destroy()
end

function Melee:Attack(player)
    if player ~= self.Equipment.Owner then return end
    if not self._canAttack then return end
    print("shawing")
    self._combo += 1
end

return Melee
