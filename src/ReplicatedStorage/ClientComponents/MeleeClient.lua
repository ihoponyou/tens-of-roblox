
-- allows clients to request interaction with melee (server)

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)

local MeleeClient = Component.new({
    Tag = "Melee";
    Extensions = {
        LocalPlayerExclusive
    };
})

function MeleeClient:Construct()
    self._trove = Trove.new()
    self._clientComm = self._trove:Construct(Comm.ClientComm, self.Instance, true, "Melee")

    self.AttackRequest = self._clientComm:GetSignal("AttackRequest")
end

function MeleeClient:_setupForLocalPlayer()
    self._localPlayerTrove = self._trove:Extend()

    ContextActionService:BindAction(self.Instance.Name.."Attack", function(_, uis, _)
       if uis ~= Enum.UserInputState.Begin then return end
       self.AttackRequest:Fire()
    end, false, Enum.UserInputType.MouseButton1)
end

function MeleeClient:_cleanUpForLocalPlayer()
    if self._localPlayerTrove then
        self._localPlayerTrove:Destroy()
    end
end

return MeleeClient
