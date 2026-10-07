//===========================================================================
//
// Pentagram of Protection (Quake style)
//
// The power itself. Activation/deactivation is event-driven: InitEffect pins
// the HUD armor to 666 and stashes the real armor pool, EndEffect restores it.
// UltraDoomPlayer.DamageMobj silently drains the pool on each hit.
//
//===========================================================================

class PowerPentagramOfProtection : Powerup
{

    // The real armor icon, stashed while the fake DOOMA0 icon is shown.
    // TextureID (not String) so we can restore it verbatim without re-resolving.
    TextureID oldArmorIcon;
	Default
	{
		Powerup.Duration -30;			// negative value = seconds
		Inventory.Icon "DOOMA0";		
	}

	//===========================================================================
	//
	// Called exactly once when the power is given to the player.
	// Pin the HUD armor to 666 and stash the real armor pool behind it.
	//
	//===========================================================================

	override void InitEffect()
	{
		Super.InitEffect();

		let p = UltraDoomPlayer(Owner);
		if (p == null) return;

		let armor = BasicArmor(Owner.FindInventory("BasicArmor"));
		if (armor == null) return;

		// Stash the real armor icon, then show the fake DOOMA0 icon.
		oldArmorIcon = armor.Icon;
		armor.Icon = TexMan.CheckForTexture("DOOMA0", TexMan.TYPE_Any);

		p.pentagramActive = true;
		p.pentagramPool = armor.Amount;
		armor.Amount = p.PENTAGRAM_ARMOR_DISPLAY;
       
	}

	//===========================================================================
	//
	// Called exactly once when the power expires or is removed.
	// Reveal the armor that actually survived the hits taken while invulnerable.
	//
	//===========================================================================

	override void EndEffect()
	{
		Super.EndEffect();

		let p = UltraDoomPlayer(Owner);
		if (p == null) return;

		p.pentagramActive = false;

		let armor = BasicArmor(Owner.FindInventory("BasicArmor"));
		if (armor != null)
		{
			armor.Amount = max(0, p.pentagramPool);
			// Restore the previous armor icon (if any).
			armor.Icon = oldArmorIcon;
		}
		p.pentagramPool = 0;
	}
}

//===========================================================================
//
// The pickup artifact.
//
//===========================================================================

class PentagramOfProtection : PowerupGiver
{
	Default
	{
		+COUNTITEM
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
		+INVENTORY.BIGPOWERUP
		Inventory.MaxAmount 0;
		Powerup.Type "PowerPentagramOfProtection";
		Powerup.Color "RedMap";
		Inventory.PickupMessage "Picked up the Pentagram of Protection!";
		Tag "Pentagram of Protection";
	}
	States
	{
      Spawn:
        DOOM A 10 Bright;
        DOOM B 15 Bright;
        DOOM C 8 Bright;
        DOOM B 6 Bright;
        Loop;
	}
}
