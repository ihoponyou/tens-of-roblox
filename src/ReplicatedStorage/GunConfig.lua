
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
        DeployTime = 0.7;
        HeadshotMultiplier = 2;
        BulletsPerShot = 1;
        MinSpreadAngle = 0;
        MaxSpreadAngle = 0;
        FullAuto = true;
        RoundsPerMinute = 600;
        VerticalRecoil = 10;
        HorizontalRecoil = 7;
        Ballistics = {
            BulletSpeed = 1000;
            BulletMaxDistance = 1000;
            BulletGravity = Vector3.yAxis * -workspace.Gravity;
            CanPierce = true;
        };
        SpringScales = {
            Animation = {
                Speed = 15;
                Damper = 0.7;
                Position = Vector3.new(0.1, -0.3, 1.3);
                Rotation = Vector3.new(0.2, 0.1, 0);
            },
            Camera = {
                Speed = 10;
                Damper = 1;
                Rotation = Vector3.new(0.2, 0.05, 0);
            }
        };
    },
    ["Deagle"] = {
        Damage = 40;
        DeployTime = 0.7;
        HeadshotMultiplier = 3;
        BulletsPerShot = 1;
        MinSpreadAngle = 0;
        MaxSpreadAngle = 0;
        FullAuto = false;
        RoundsPerMinute = 400;
        VerticalRecoil = 30;
        HorizontalRecoil = 7;
        Ballistics = {
            BulletSpeed = 1000;
            BulletMaxDistance = 1000;
            BulletGravity = Vector3.yAxis * -workspace.Gravity;
            CanPierce = true;
        };
        SpringScales = {
            Animation = {
                Speed = 20;
                Damper = 0.5;
                Position = Vector3.new(0, -0.5, 0.5);
                Rotation = Vector3.new(0.33, 0.1, 1);
            },
            Camera = {
                Speed = 10;
                Damper = 1;
                Rotation = Vector3.new(0.2, 0.4, 1);
            }
        };
    },
    ["Tommy"] = {
        Damage = 20;
        DeployTime = 0.7;
        HeadshotMultiplier = 2;
        BulletsPerShot = 1;
        MinSpreadAngle = 0;
        MaxSpreadAngle = 0;
        FullAuto = true;
        RoundsPerMinute = 800;
        VerticalRecoil = 10;
        HorizontalRecoil = 10;
        Ballistics = {
            BulletSpeed = 1000;
            BulletMaxDistance = 1000;
            BulletGravity = Vector3.yAxis * -workspace.Gravity;
            CanPierce = true;
        };
        SpringScales = {
            Animation = {
                Speed = 15;
                Damper = 0.7;
                Position = Vector3.new(0.1, -0.3, 1.3);
                Rotation = Vector3.new(0.2, 0.1, 0);
            },
            Camera = {
                Speed = 10;
                Damper = 1;
                Rotation = Vector3.new(0.2, 0.05, 0);
            }
        };
    },
}

return GunConfig
