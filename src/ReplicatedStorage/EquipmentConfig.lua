local Configs = {
	["AK-47"] = {
		SlotType = "Primary";
		ThirdPersonOnly = false;
		ViewportPosition = UDim2.fromScale(1.05, 0);

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
		SlotType = "Secondary";
		ThirdPersonOnly = false;

		Damage = 33;
		MaxCombo = 2;
	};
    ["Dragonslayer"] = {
        SlotType = "Primary";
		ThirdPersonOnly = true;

		Damage = 40;
		MaxCombo = 3;
    };
	["Deagle"] = {
		SlotType = "Secondary";
		ThirdPersonOnly = true;
		ViewportPosition = UDim2.fromScale(2, 0.2);

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

return Configs