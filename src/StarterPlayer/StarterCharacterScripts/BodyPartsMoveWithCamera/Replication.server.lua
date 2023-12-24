
local updateEvent = script.Parent:WaitForChild("UpdateC0", true)

updateEvent.OnServerEvent:Connect(function(transmitter, neckCFrame, RsCFrame, LsCFrame)
	for _, player in game.Players:GetPlayers() do
		if player == transmitter then continue end
		updateEvent:FireClient(player, transmitter, neckCFrame, RsCFrame, LsCFrame)
	end
end)
