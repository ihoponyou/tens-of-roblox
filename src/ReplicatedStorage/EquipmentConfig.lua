
-- melee sound pitches can be bounded by attributes on the pitchshiftsoundeffect on their attacksound
-- positions in viewports can be changed by 

local EquipmentConfig = {
	["AK-47"] = {
		Type = "Gun";
		SlotType = "Primary";
		ThirdPersonOnly = false;
		Viewport = {
			ElementPosition = UDim2.fromScale(1.05, 0);
			ModelCFrame = CFrame.new(1, 0, -2) * CFrame.Angles(0, 0, 0)
		};

		Damage = 20;
		RoundsPerMinute = 600;
		MaxSpreadAngle = 1;
		BulletsPerShot = 1;
		ReserveMagazines = 4;
		-- BulletSpeed = 1000;
		-- BulletGravity = Vector3.new(0, -98.0999984741211, 0);
		-- CanPierce = false;
		BulletMaxDistance = 1000;
		MagazineCapacity = 30;
		MinSpreadAngle = 0;
		HasBoltHoldOpen = true;
		FullyAutomatic = true;
	};
	["ClassicSword"] = {
		Type = "Melee";
		SlotType = "Secondary";
		ThirdPersonOnly = false;
		Viewport = {
			ElementPosition = nil;
			ModelCFrame = CFrame.new(0.6, 0, -2) * CFrame.Angles(0, math.rad(-90), math.rad(90))
		};

		Damage = 33;
		MaxCombo = 2;
	};
    ["Dragonslayer"] = {
		Type = "Melee";
        SlotType = "Primary";
		ThirdPersonOnly = true;
		Viewport = {
			ElementPosition = nil;
			ModelCFrame = CFrame.new(2, 0, -2) * CFrame.Angles(0, math.rad(-90), math.rad(90))
		};

		Damage = 100;
		MaxCombo = 3;
    };
	["Deagle"] = {
		Type = "Gun";
		SlotType = "Secondary";
		ThirdPersonOnly = true;
		Viewport = {
			ElementPosition = UDim2.fromScale(2, 0.2);
			ModelCFrame = CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(90), 0)
		};

		Damage = 35;
		FullyAutomatic = false;
		HasBoltHoldOpen = true;
		BulletsPerShot = 1;
		BulletMaxDistance = 1000;
		MinSpreadAngle = 0;
		MaxSpreadAngle = 3;
		MagazineCapacity = 7;
		ReserveMagazines = 7;
		RoundsPerMinute = 200;
		-- BulletSpeed = 1000;
		-- BulletGravity = Vector3.new(0, -98.0999984741211, 0);
		-- CanPierce = false;
	};
}

return EquipmentConfig