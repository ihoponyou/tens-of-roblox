
export type StatBlock = {
    DeployTime: number,
    MaxCombo: number
}

-- max combo is the amount of possible successive m1s; a weapon with 1 m1 would have a maxcombo of 0

local MeleeStats: {[string]: StatBlock} = {
    ["Dragonslayer"] = {
        DeployTime = 2;
        MaxCombo = 2;
    },
    ["Classic Knife"] = {
        DeployTime = 0;
        MaxCombo = 3;
    },
    ["Buster"] = {
        DeployTime = 1;
        MaxCombo = 2;
    },
    ["Classic Sword"] = {
        DeployTime = 0;
        MaxCombo = 1;
    }
}

return MeleeStats
