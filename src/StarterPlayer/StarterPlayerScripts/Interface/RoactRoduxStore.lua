
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
    ToggledSettings = function(open: boolean)
        return {
            type = "ToggledSettings";
            settingsOpen = open;
        }
    end;
    EnabledCrosshair = function(enable: boolean)
        return {
            type = "EnabledCrosshair";
            crosshairEnabled = enable;
        }
    end;
    ToggledHitmarker = function(shown: boolean)
        return {
            type = "ToggledHitmarker";
            hitmarkerShown = shown;
        }
    end;
    UpdatedInventory = function(newInventory: {any})
        local parsedInventory = {}
        for k,v in newInventory do
            parsedInventory[k] = tostring(v)
        end

        return {
            type = "UpdatedInventory";
            inventory = parsedInventory
        }
    end
}

-- each entry is also an entry in the store's (?) state
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
    SettingsEnabled = Rodux.createReducer(false, {
        ToggledSettings = function(state, action)
            return action.settingsOpen
        end
    });
    CrosshairEnabled = Rodux.createReducer(false, {
        EnabledCrosshair = function(state, action)
            return action.crosshairEnabled
        end
    });
    HitmarkerShown = Rodux.createReducer(false, {
        ToggledHitmarker = function(state, action)
            return action.hitmarkerShown
        end
    });
    Inventory = Rodux.createReducer({}, {
        UpdatedInventory = function(_, action)
            return action.inventory
        end
    });
}

RoactRoduxStore.Reducer = Rodux.combineReducers(RoactRoduxStore._reducers)

RoactRoduxStore.Instance = Rodux.Store.new(RoactRoduxStore.Reducer, nil, {
    -- Rodux.loggerMiddleware
})

return RoactRoduxStore
