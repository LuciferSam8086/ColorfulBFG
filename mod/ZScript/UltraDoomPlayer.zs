class UltraDoomPlayer : DoomPlayer
{
	override int DamageMobj (Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{

		// if the source actor is friendly, then no damage
		if (source && source.IsFriend(self))
		{
			return 0;
		}
		
		// Return the original value
		return super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}
}