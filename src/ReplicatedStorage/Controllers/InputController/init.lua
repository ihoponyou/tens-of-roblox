
local DEBUG = false

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local InventoryController, CameraController, MovementController

local DEFAULT_KEYBINDS = require(script.DefaultKeybinds)

-- maps inputs to functionality
local InputController = Knit.CreateController {
	Name = "InputController";
	Keybinds = {};
}

-- returns 1, 0, or -1 based on input on a given axis |
-- 0 = no input or both inputs pressed |
-- Horizontal: 1 = right, -1 = left |
-- Vertical: 1 = forward, -1 = backward
function InputController.GetAxis(axis : string)
    axis = axis:lower()
	if axis == "horizontal" then
        local leftDown = UserInputService:IsKeyDown(Enum.KeyCode.A)
        local rightDown = UserInputService:IsKeyDown(Enum.KeyCode.D)
		if leftDown and rightDown  then
			return 0
		elseif leftDown then
			return -1
		elseif rightDown then
			return 1
		else
			return 0
		end
	elseif axis == "vertical" then
        local backwardDown = UserInputService:IsKeyDown(Enum.KeyCode.S)
        local forwardDown = UserInputService:IsKeyDown(Enum.KeyCode.W)
		if backwardDown and forwardDown then
			return 0
		elseif backwardDown then
			return -1
		elseif forwardDown then
			return 1
		else
			return 0
		end
	else
		print("getAxis("..axis..") failed")
	end
end

function InputController.IsWasdDown(): boolean
	return UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D)
end


function InputController:LoadKeybind(action: string, keybind: Enum.KeyCode, log: boolean)
	if not self["_"..action] then
		if log then print(string.format("Action \"%s\" does not have a matching method", action)) end
		return
	end

	ContextActionService:BindAction(action,
		function(_, userInputState: Enum.UserInputState, _)
			return self["_"..action](self, userInputState)
		end,
		false, keybind)

	if log then print(string.format("%s loaded @ %s", action, keybind.Name)) end
end

function InputController:LoadAllKeybinds(log: boolean)
	-- for keybindName, value: Keybinding in KEYBINDS do
	-- 	ContextActionService:BindAction(keybindName, function(_, userInputState, _)
	-- 		if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	-- 		return value.Action()
	-- 	end, false, value.Key)
	-- end
	for action, keybind: DEFAULT_KEYBINDS.Keybind in self.Keybinds do
		self:LoadKeybind(action, keybind.Key, log)
	end
end

function InputController:UnloadKeybind(action: string, log: boolean)
	ContextActionService:UnbindAction("input_"..action)
	if log then print(string.format("%-12s unloaded", action)) end
end

function InputController:UnloadAllKeybinds(log: boolean)
	for action, _ in self.Keybinds do
		self:UnloadKeybind(action, log)
	end
end

function InputController:ReloadKeybinds(log: boolean)
	self:UnloadAllKeybinds(log)
	self:LoadAllKeybinds(log)
end

function InputController:ChangeKeybind(action: string, newKey: Enum.KeyCode, log: boolean?)
	self.Keybinds[action].Key = newKey
	self:UnloadKeybind(action, log)
	self:LoadKeybind(action, newKey, log)
end

function InputController:ResetKeybinds(log: boolean)
	for action: string, _ in self.Keybinds do
		local defaultKey = DEFAULT_KEYBINDS[action].Key
		self:ChangeKeybind(action, defaultKey, false)
	end

	print("Keybinds reset to default.")
end

function InputController:GetKeybind(action: string): Enum.KeyCode
	return self.Keybinds[action].Key
end

function InputController:_Use(userInputState)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if InventoryController.ActiveItem == nil then return Enum.ContextActionResult.Pass end
	InventoryController:UseActiveItem()
	return Enum.ContextActionResult.Sink
end

function InputController:_Drop(userInputState)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	if InventoryController.ActiveItem == nil then return Enum.ContextActionResult.Pass end
	InventoryController:DropActiveItem()
	return Enum.ContextActionResult.Sink
end

function InputController:_Primary(userInputState)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	InventoryController:SwitchSlot("Primary")
	return Enum.ContextActionResult.Sink
end
function InputController:_Secondary(userInputState)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	InventoryController:SwitchSlot("Secondary")
	return Enum.ContextActionResult.Sink
end
function InputController:_Tertiary(userInputState)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	InventoryController:SwitchSlot("Tertiary")
	return Enum.ContextActionResult.Sink
end

function InputController:_ChangeCameraMode(userInputState)
	if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	CameraController:TogglePOV()
	return Enum.ContextActionResult.Sink
end

function InputController:_Run(userInputState: Enum.UserInputState)
	if userInputState == Enum.UserInputState.Begin then
		MovementController:StartRun()
	else
		MovementController:StopRun()
	end
end

function InputController:KnitStart()
	InventoryController = Knit.GetController("InventoryController")
	CameraController = Knit.GetController("CameraController")
	MovementController = Knit.GetController("MovementController")

	self.Keybinds = table.clone(DEFAULT_KEYBINDS)

	self:LoadAllKeybinds(DEBUG)
	ContextActionService:BindAction("ResetKeybinds",
		function(_, userInputState: Enum.UserInputState, _)
			if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end

			self:ResetKeybinds()

			return Enum.ContextActionResult.Sink
		end,
		false, Enum.KeyCode.BackSlash)
end

return InputController
