
-- allows clients to request interaction with equipment (server)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local AnimationManager = require(ReplicatedStorage.Source.Modules.AnimationManager)
local OffsetManager = require(ReplicatedStorage.Source.Modules.OffsetManager)

local Viewmodel = Component.new({
    Tag = "Viewmodel";
})

function Viewmodel:Construct()
    self._trove = Trove.new()

    self.Visible = false

    self.AnimationManager = self._trove:Construct(AnimationManager, self.Instance:WaitForChild("RigHumanoid"):WaitForChild("Animator"))
    self.OffsetManager = OffsetManager.new()
    self._trove:Add(self.OffsetManager)

    self.Instance.Parent = workspace.CurrentCamera
end

function Viewmodel:Start()
    self:ToggleVisibility(self.Visible)
end

function Viewmodel:Stop()
    self._trove:Destroy()
end

function Viewmodel:RenderSteppedUpdate(_dt)
    local combinedOffset = self.OffsetManager:GetCombinedOffset()
    self.Instance:PivotTo(workspace.CurrentCamera.CFrame * combinedOffset)
end

function Viewmodel:ToggleVisibility(visible: boolean)
    self.Visible = visible
    self.Instance["Left Arm"].Transparency = if visible then 0 else 1
    self.Instance["Right Arm"].Transparency = if visible then 0 else 1
end

return Viewmodel
