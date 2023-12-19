
local DEBUG = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local LocalPlayerExclusive = require(ReplicatedStorage.Source.Extensions.LocalPlayerExclusive)
local Logger = require(ReplicatedStorage.Source.Extensions.Logger)
local Roact = require(ReplicatedStorage.Packages.Roact)

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

    self.ProximityPrompt = self.WorldModel:WaitForChild("PickUpPrompt")
    self.ProximityPrompt.RequiresLineOfSight = false
    self.PromptGui = Roact.createRef()
    local promptGui = Roact.createElement(PromptGui, {
        equipment_name = self.Instance.Name;
        ref = self.PromptGui;
    })
    self._promptTree = Roact.mount(promptGui, self.WorldModel)

    self.EquipRequest = self.Instance:WaitForChild("EquipRequest")
    self.PickUpRequest = self.Instance:WaitForChild("PickUpRequest")
end

function EquipmentClient:_onPickedUp()
    -- TODO: add to inventory GUI
end

function EquipmentClient:_onEquipped()
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

    viewmodel:LoadAnimations(ReplicatedStorage.Equipment[self.Instance.Name].Animations)
    viewmodel:PlayAnimation("Idle", 0)
    viewmodel:ToggleVisibility(true)
    viewmodel:PlayAnimation("Equip", 0)
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
end

function EquipmentClient:_onDropped()
    -- unrig from viewmodel and drop it
    self.Instance.Parent = workspace
    self.WorldModel.Parent = self.Instance

    -- throw it
    local cameraCFrame = workspace.CurrentCamera.CFrame
    self.WorldModel:PivotTo(cameraCFrame + cameraCFrame.LookVector)
    self.WorldModel.PrimaryPart.AssemblyLinearVelocity = (workspace.CurrentCamera.CFrame.LookVector * 30)

    -- unequip if needed and remove from inventory GUI
end

function EquipmentClient:Use()
    print('use', self.Instance)
end

function EquipmentClient:AlternateUse()
    print('alt use', self.Instance)
end

function EquipmentClient:PickUp(): boolean
    local pickUpSuccess = self.PickUpRequest:InvokeServer(true)
    if pickUpSuccess then self:_onPickedUp() end
    return pickUpSuccess
end

function EquipmentClient:Equip(): boolean
    local equipSuccess = self.EquipRequest:InvokeServer(true)
    if equipSuccess then self:_onEquipped() end
    return equipSuccess
end

function EquipmentClient:Unequip(): boolean
    local unequipSuccess = self.EquipRequest:InvokeServer(false)
    if unequipSuccess then self:_onUnequipped() end
    return unequipSuccess
end

function EquipmentClient:Drop(): boolean
    local dropSuccess = self.PickUpRequest:InvokeServer(false)
    if dropSuccess then self:_onDropped() end
    return dropSuccess
end

function EquipmentClient:_setupForLocalPlayer()
    if DEBUG then print('LOCAL PLAYER OWNS THIS') end

    -- on picked up
end

function EquipmentClient:_cleanUpForLocalPlayer()
    if DEBUG then print('LOCAL PLAYER NO LONGER OWNS THIS') end

    self:_onUnequipped()
    -- on dropped
end

function EquipmentClient:Start()
    Knit.OnStart():andThen(function()
        ViewmodelController = Knit.GetController("ViewmodelController")
    end)

    self._trove:Connect(self.ProximityPrompt.Triggered, function()
        self:PickUp()
    end)
    self._trove:Connect(self.ProximityPrompt.PromptShown, function() self.PromptGui:getValue().Enabled = true end)
    self._trove:Connect(self.ProximityPrompt.PromptHidden, function() self.PromptGui:getValue().Enabled = false end)
end

function EquipmentClient:Stop()
    self._trove:Clean()
end

return EquipmentClient
