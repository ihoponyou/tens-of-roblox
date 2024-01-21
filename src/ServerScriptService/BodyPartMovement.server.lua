local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)

local serverComm = Comm.ServerComm.new(ReplicatedStorage, "BodyPartMovement")

local updateEvent = serverComm:CreateSignal("Update", true, {
    function (_player, args: {any})
        if args.n ~= 1 then
            return false
        end
        if type(args[1]) ~= "number" then
            return false
        end
        return true
    end
})

updateEvent:Connect(function(player, armAngle)
    -- tell everybody except sender to replicate their angle
    updateEvent:FireExcept(player, player, armAngle)
end)