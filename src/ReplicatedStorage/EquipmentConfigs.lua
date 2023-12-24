local Configs = {
	["AK-47"] = {
		SlotType = "Primary";
		ThirdPersonOnly = false;

		RoundsPerMinute = 600;
		MaxSpreadAngle = 1;
		BulletsPerShot = 1;
		ReserveMagazines = 4;
		BulletSpeed = 1000;
		BulletGravity = Vector3.new(0, -98.0999984741211, 0);
		ThrowsMagazine = true;
		CanPierce = false;
		BulletMaxDistance = 1000;
		MagazineCapacity = 30;
		Damage = 20;
		MinSpreadAngle = 0;
		HasBoltHoldOpen = true;
		FullyAutomatic = true;
	};
	["ClassicSword"] = {
		SlotType = "Secondary";
		ThirdPersonOnly = false;
	};
    ["DragonSlayer"] = {
        SlotType = "Primary";
		ThirdPersonOnly = true;
    }
}

return Configs