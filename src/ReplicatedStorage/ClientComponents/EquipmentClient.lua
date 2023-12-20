
local DEBUG = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PromptGui = require(ReplicatedStorage.Source.UIElements.PromptGui)

local ViewmodelController
local EquipmentClient = Component.new({
	Tag = "Equipment",
	Extensions = {
		LocalPlayerExclusive,
        Logger,
	},
})

function EquipmentClient:Construct()
    self._trove = Trove.new()

    self.WorldModel = self.Instance:WaitForChild("WorldModel")

    self.PickUpPrompt = self.WorldModel:WaitForChild("PickUpPrompt")
    self.PickUpPrompt.RequiresLineOfSight = false
    self.PromptGui = Roact.createRef()
    local promptGui = Roact.createElement(PromptGui, {
        equipment_name = self.Instance.Name;
        ref = self.PromptGui;
    })
    self._promptTree = Roact.mount(promptGui, self.WorldModel)

    self.EquipRequest = self.Instance:WaitForChild("Equip")
    self.PickUpRequest = self.Instance:WaitForChild("PickUp")
    self.UseRequest = self.Instance:WaitForChild("Use")
    self.AlternateUseRequest = self.Instance:WaitForChild("AltUse")

    -- the folder that is somewhere within ReplicatedStorage.Equipment
    self.Folder = ReplicatedStorage.Equipment:FindFirstChild(self.Instance.Name, true)
    self.AnimationFolder = self.Folder:FindFirstChild("Animations")
    if not self.AnimationFolder then warn(self.Instance.Name, " does not have any animations") end

    -- signals to be used by other components
    self.PickedUp = Signal.new()
    self.Equipped = Signal.new()
    self.Used = Signal.new()
    self.AltUsed = Signal.new()
end

function EquipmentClient:_setupForLocalPlayer()
    if DEBUG then print('LOCAL PLAYER OWNS THIS') end
    self:_onPickedUp()
end

function EquipmentClient:_cleanUpForLocalPlayer()
    if DEBUG then print('LOCAL PLAYER NO LONGER OWNS THIS') end
    self:_onDropped()
end

function EquipmentClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
    end)

    self._trove:Connect(self.EquipRequest.OnClientEvent, function(equipped: boolean)
        if equipped then
            self:_onEquipped()
        else
            self:_onUnequipped()
        end
    end)
    -- self._trove:Connect(self.PickUpRequest.OnClientEvent, function(pickedUp: boolean)
    --     if pickedUp then
    --         self:_onPickedUp()
    --     else
    --         self:_onDropped()
    --     end
    -- end)

    self._trove:Connect(self.PickUpPrompt.PromptShown, function() self.PromptGui:getValue().Enabled = true end)
    self._trove:Connect(self.PickUpPrompt.PromptHidden, function() self.PromptGui:getValue().Enabled = false end)
end

function EquipmentClient:Stop()
    self._trove:Clean()
end

function EquipmentClient:_onPickedUp()
    if DEBUG then print("picked up", self.Instance.Name) end

    self.WorldModel:ScaleTo(self.WorldModel:GetAttribute("ViewmodelScale"))
    -- TODO: add to inventory GUI

    self.PickedUp:Fire(true)
end

function EquipmentClient:Equip()
    self.EquipRequest:FireServer(true)
end
function EquipmentClient:_onEquipped()
    if DEBUG then print("equipped", self.Instance.Name) end

    local viewmodel = ViewmodelController.Viewmodel
    if not viewmodel then error("Cannot rig equipment to viewmodel; no viewmodel") end

    local modelRootJoint = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot rig equipment to viewmodel; equipment missing RootJoint") end

    for _, part: BasePart in self.WorldModel:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CastShadow = false
    end

    -- rig to viewmodel
    self.WorldModel.Parent = viewmodel.Instance
    modelRootJoint.Part0 = viewmodel.Instance.PrimaryPart

    if self.AnimationFolder ~= nil then
        viewmodel:LoadAnimations(self.AnimationFolder["1P"])
        viewmodel:PlayAnimation("Idle", 0)
        viewmodel:ToggleVisibility(true)
        viewmodel:PlayAnimation("Equip", 0)
    end

    self.Equipped:Fire(true)
end

function EquipmentClient:Use()
    self.UseRequest:FireServer(true)
end
function EquipmentClient:_onUse()
    print('use of', self.Instance.Name, "successful")

    self.Used:Fire()
end

function EquipmentClient:_onAlternateUse()
    print('alternate use of', self.Instance.Name, "successful")

    self.AltUsed:Fire()
end

function EquipmentClient:Unequip()
    self.EquipRequest:FireServer(false)
end
function EquipmentClient:_onUnequipped()
    local viewmodel = ViewmodelController.Viewmodel
    if not viewmodel then error("Cannot unrig equipment from viewmodel; no viewmodel") end

    local modelRootJoint: Motor6D = self.WorldModel.PrimaryPart:FindFirstChild("RootJoint")
    if not modelRootJoint then error("Cannot unrig equipment from viewmodel; equipment missing RootJoint") end

    viewmodel:StopPlayingAnimations()
    modelRootJoint.Part0 = nil
    self.WorldModel.Parent = self.Instance -- instance always stays in owner's backpack

    for _, part: BasePart in self.WorldModel:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        part.CastShadow = true
    end

    viewmodel:ToggleVisibility(false)

    self.Equipped:Fire(false)
end

function EquipmentClient:Drop()
    self.PickUpRequest:FireServer(false)
end
function EquipmentClient:_onDropped()
    self.WorldModel:ScaleTo(self.WorldModel:GetAttribute("WorldScale"))

    -- throw it
    local cameraCFrame = workspace.CurrentCamera.CFrame
    self.WorldModel:PivotTo(cameraCFrame + cameraCFrame.LookVector)
    self.WorldModel.PrimaryPart.AssemblyLinearVelocity = (workspace.CurrentCamera.CFrame.LookVector * 30)

    -- unequip if needed and remove from inventory GUI

    self.PickedUp:Fire(false)
end


return EquipmentClient
