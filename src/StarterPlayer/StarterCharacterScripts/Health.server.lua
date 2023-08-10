-- Gradually regenerates the Humanoid's Health over time.

local REGEN_RATE = 1/100 -- Regenerate this fraction of MaxHealth per second.
-- local REGEN_STEP = 1 -- Wait this long between each regeneration step.

--------------------------------------------------------------------------------

local Character = script:FindFirstAncestorOfClass("Model")
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

--------------------------------------------------------------------------------

game:GetService("RunService").Heartbeat:Connect(function(dt: number) 
	if Humanoid.Health < Humanoid.MaxHealth then
		Humanoid:TakeDamage(-REGEN_RATE * Humanoid.MaxHealth * dt)
	end
end)