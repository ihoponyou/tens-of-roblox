
-- allows for attacking like a melee weapon

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Equipment = require(ServerStorage.Source.ServerComponents.Equipment)

local DEPLOY_TIME = 0

local Melee = Component.new({
	Tag = "Melee",
})

function Melee:Construct()
	self._trove = Trove.new()
	self._serverComm = self._trove:Construct(Comm.ServerComm, self.Instance, "Melee")

    self._canAttack = false

	self.AttackRequest = self._serverComm:CreateSignal("AttackRequest")
    self._trove:Connect(self.AttackRequest, function(...)
        self:Attack(...)
    end)
end

function Melee:Start()
    self.Equipment = self:GetComponent(Equipment)

    self._trove:Connect(self.Equipment.Equipped, function(isEquipped: boolean)
        self._canAttack = false
        if isEquipped then
            self._readyThread = task.delay(DEPLOY_TIME, function()
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
end

return Melee
