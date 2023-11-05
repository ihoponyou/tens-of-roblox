
local updateEvent = script.Parent.UpdateC0

updateEvent.OnServerEvent:Connect(function(player, neckCFrame, RsCFrame, LsCFrame)
	for value in game.Players:GetPlayers() do
		if value ~= player then
			updateEvent:FireClient(value, player, neckCFrame, RsCFrame, LsCFrame)
		end
	end
end)
