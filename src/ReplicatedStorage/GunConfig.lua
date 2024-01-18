
export type StatBlock = {
    Damage: number,
    DeployTime: number,
    HeadshotMultiplier: number,
    FullAuto: boolean,
    Hitscan: boolean,
}

local GunConfig = {
    ["AK-47"] = {
        Damage = 34;
        DeployTime = 0.5;
        HeadshotMultiplier = 2;
        BulletsPerShot = 1;
        MinSpreadAngle = 0;
        MaxSpreadAngle = 0;
        FullAuto = true;
        Ballistics = {
            RoundsPerMinute = 600;
            BulletSpeed = 1000;
            BulletMaxDistance = 1000;
            BulletGravity = Vector3.yAxis * -workspace.Gravity;
            CanPierce = true;
        }
    },
    ["Deagle"] = {
        Damage = 40;
        DeployTime = 0.7;
        HeadshotMultiplier = 3;
        BulletsPerShot = 1;
        MinSpreadAngle = 0;
        MaxSpreadAngle = 0;
        FullAuto = false;
        Ballistics = {
            RoundsPerMinute = 250;
            BulletSpeed = 1000;
            BulletMaxDistance = 1000;
            BulletGravity = Vector3.yAxis * -workspace.Gravity;
            CanPierce = true;
        }
    }
}

return GunConfig
