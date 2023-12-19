
local DEBUG = false

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local DEFAULT_KEYBINDS = require(script.DefaultKeybinds)

local InventoryController
-- maps inputs to functionality
local InputController = Knit.CreateController {
	Name = "InputController";
	Keybinds = {};
	_lastW = 0;
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
		warn(string.format("Action \"%s\" does not have a matching method", action))
		return
	end

	ContextActionService:BindAction(action,
		function(_, userInputState: Enum.UserInputState, _)
			if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
			self["_"..action](self)
			return Enum.ContextActionResult.Sink
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


-- INVENTORY CONTROLS
function InputController:_Use(userInputState: Enum.UserInputState)
	InventoryController:UseActiveItem()
end
function InputController:_AlternateUse()
	InventoryController:AlternativelyUseActiveItem()
end

function InputController:_Drop(_)
	InventoryController:DropActiveItem()
end

function InputController:_Primary(userInputState: Enum.UserInputState)
	InventoryController:SwitchSlot("Primary")
end
function InputController:_Secondary(userInputState: Enum.UserInputState)
	InventoryController:SwitchSlot("Secondary")
end
function InputController:_Tertiary(userInputState: Enum.UserInputState)
	InventoryController:SwitchSlot("Tertiary")
end

function InputController:KnitStart()
	InventoryController = Knit.GetController("InventoryController")

	self.Keybinds = table.clone(DEFAULT_KEYBINDS)

	self:LoadAllKeybinds(DEBUG)
	ContextActionService:BindAction("ResetKeybinds",
		function(_, userInputState: Enum.UserInputState, _)
			if userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end

			self:ResetKeybinds()

			return Enum.ContextActionResult.Sink
		end,
		false, Enum.KeyCode.BackSlash
	)
end

return InputController
