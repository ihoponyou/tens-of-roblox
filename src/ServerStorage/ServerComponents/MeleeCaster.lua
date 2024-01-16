
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local ClientCast = require(ReplicatedStorage.Packages.ClientCast)

local Logger = require(ReplicatedStorage.Source.Extensions.Logger)

local DAMAGE_POINTS_PER_STUD = 2

local MeleeCaster = Component.new {
	Tag = "MeleeCaster";
	Extensions = {
		Logger,
	};
}

function MeleeCaster:Construct()
	self._trove = Trove.new()

    self._caster = self._trove:Construct(ClientCast, self.Instance, RaycastParams.new())
    self._caster:SetRecursive(true)

    -- create damage points for client cast
    local tip: Attachment? = self.Instance.PrimaryPart:FindFirstChild("Tip")
    local pommel: Attachment? = self.Instance.PrimaryPart:FindFirstChild("Pommel")
    if tip and pommel then
        local bladeDirection: Vector3 = tip.Position - pommel.Position
        local points = math.round(bladeDirection.Magnitude/DAMAGE_POINTS_PER_STUD)
        for i=0, points do
            local dmgPoint = Instance.new("Attachment")
            dmgPoint.Name = "DmgPoint"
            dmgPoint.Parent = self.Instance.PrimaryPart
            dmgPoint.Position = pommel.Position + bladeDirection * i/points
        end
    else
        warn("cannot setup damage points for "..self.Instance.Name)
    end

    self._debug = self.Instance:GetAttribute("DebugCasts") or false
    self._trove:Connect(self.Instance:GetAttributeChangedSignal("DebugCasts"), function()
        self._debug = self.Instance:GetAttribute("DebugCasts") or false
    end)

    -- self._caster.Collided:Connect(function(raycastResult: RaycastResult)
    --     print(raycastResult)
    -- end)
    self._caster.HumanoidCollided:Connect(function(...)
        if self.OnHumanoidCollided ~= nil then
            self:OnHumanoidCollided(...)
        else
            print(...)
        end
    end)
end

function MeleeCaster:StartCast()
    if self._debug then
        self._caster:StartDebug()
    end
    self._caster:Start()
end

function MeleeCaster:StopCast()
    if self._debug then
        self._caster:DisableDebug()
    end
    self._caster:Stop()
end

function MeleeCaster:EditRaycastParams(raycastParams: RaycastParams)
    self._caster:EditRaycastParams(raycastParams)
end

function MeleeCaster:Stop()
	self._trove:Clean()
end

return MeleeCaster
