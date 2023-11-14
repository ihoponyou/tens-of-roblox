
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NamedInstance = require(ReplicatedStorage.Source.NamedInstance)
local updateEvent = script.Parent:FindFirstChild("UpdateC0", true) or NamedInstance.new("UpdateC0", "RemoteEvent", script.Parent)

updateEvent.OnServerEvent:Connect(function(transmitter, neckCFrame, RsCFrame, LsCFrame)
	for _, player in game.Players:GetPlayers() do
		if player == transmitter then continue end
		updateEvent:FireClient(player, transmitter, neckCFrame, RsCFrame, LsCFrame)
	end
end)
