class ColorfulBFG : DoomWeapon replaces BFG9000
{
	// 0 = uninitialized, 1 = green, 2 = white, 3 = yellow
	int selectedBallType;

	Default
	{
		Height 20;
		Weapon.SelectionOrder 2800;
		Weapon.AmmoUse 0; // real cost is chosen per ball type
		Weapon.AmmoGive 0;
		Weapon.AmmoType "Cell";
		+WEAPON.NOAUTOFIRE;
		+WEAPON.BFG;
		Inventory.PickupMessage "You got the powerful and mysterious Colorful BFG!";
		Tag "Colorful BFG";
		Weapon.SlotNumber 7;
	}

	States
	{
	Ready:
		BFGG A 1 A_WeaponReady;
		Loop;
	Deselect:
		BFGG A 1 A_Lower;
		Loop;
	Select:
		BFGG A 1 A_Raise;
		Loop;
	Fire:
		BFGG A 20 A_BFGsound;
		BFGG B 10 A_FireBFG;
		BFGG B 20 A_ReFire;
		Goto Ready;
	Flash:
		BFGF A 11 Bright A_Light1;
		BFGF B 6 Bright A_Light2;
		Goto LightDone;
	Spawn:
		BFUG A -1;
		Stop;
	}
}
