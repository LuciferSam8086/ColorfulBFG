class UltraDoomPlayer : DoomPlayer
{
	// The armor value the HUD shows while the Pentagram is active.
	const PENTAGRAM_ARMOR_DISPLAY = 666;

	// Is the Pentagram of Protection currently active?
	bool pentagramActive;

	// The REAL armor, silently depleted by incoming damage (Quake style).
	// Written by PowerPentagramOfProtection.InitEffect/EndEffect.
	int pentagramPool;

	override int DamageMobj (Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		// if the source actor is friendly, then no damage
		if (source && source.IsFriend(self))
		{
			return 0;
		}

		// Pentagram of Protection: the player is invulnerable, but every hit is
		// silently drained from the real armor pool, like in Quake. The HUD keeps
		// showing 666 the whole time.
		if (pentagramActive && damage > 0)
		{
			pentagramPool = max(0, pentagramPool - damage);
			return 0;
		}

		// Return the original value
		return super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}
}
