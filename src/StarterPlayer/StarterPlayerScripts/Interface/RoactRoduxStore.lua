
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoactRoduxStore = {}

RoactRoduxStore.Actions = {
    UpdatedCurrentAmmo = function(newAmmo: number)
        return {
            type = "UpdatedCurrentAmmo";
            currentAmmo = newAmmo;
        }
    end;
    UpdatedReserveAmmo = function(newAmmo: number)
        return {
            type = "UpdatedReserveAmmo";
            reserveAmmo = newAmmo;
        }
    end;
}

RoactRoduxStore._reducers = {
    CurrentAmmo = Rodux.createReducer(0, {
        UpdatedCurrentAmmo = function(state, action)
            return action.currentAmmo
        end
    });
    ReserveAmmo = Rodux.createReducer(0, {
        UpdatedReserveAmmo = function(state, action)
            return action.reserveAmmo
        end
    });
}

RoactRoduxStore.Reducer = Rodux.combineReducers({
    currentAmmo = RoactRoduxStore._reducers.CurrentAmmo;
    reserveAmmo = RoactRoduxStore._reducers.ReserveAmmo;
})

RoactRoduxStore.Instance = Rodux.Store.new(RoactRoduxStore.Reducer, nil, {
    -- Rodux.loggerMiddleware
})

return RoactRoduxStore
