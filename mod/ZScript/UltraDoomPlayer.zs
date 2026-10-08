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
		//
		// NOTE: 'damage' here is the RAW value. The engine's damage pipeline
		// (skill factor, ModifyDamage, DamageFactor, TakeSpecialDamage and the
		// virtual AbsorbDamage) only runs inside the C++ DoDamageMobj, reached via
		// super.DamageMobj(). We deliberately do NOT call it: it would drain the
		// fake 666 armor and actually hurt the player. So we replicate the
		// pre-armor pipeline here and then run AbsorbDamage ourselves.
		if (pentagramActive && damage > 0)
		{
			// An inflictor with PIERCEARMOR makes the engine set DMG_NO_ARMOR
			// (p_interaction.cpp:1150).
			int pentFlags = flags;
			if (inflictor && inflictor.bPIERCEARMOR)
			{
				pentFlags |= DMG_NO_ARMOR;
			}

			// ---- Replicate the pre-armor damage pipeline ----------------
			int eff = damage;

			// Skill damage factor (p_interaction.cpp:1176). sv_damagefactorplayer
			// is assumed to be its default of 1.0 (it is not visible to ZScript).
			if (eff > 1)
			{
				eff = int(eff * G_SkillPropertyFloat(SKILLP_DamageFactor));
			}

			// Damage dealt by the source's own multiplier (p_interaction.cpp:1219).
			if (source && eff > 0)
			{
				eff = int(eff * source.DamageMultiply);
			}

			// Active damage modifiers -- e.g. PowerDamage (p_interaction.cpp:1222).
			if (source && eff > 0 && !(pentFlags & DMG_NO_ENHANCE))
			{
				eff = source.GetModifiedDamage(mod, eff, false, inflictor, self, pentFlags, angle);
			}

			// Passive damage modifiers -- e.g. PowerProtection (p_interaction.cpp:1228).
			if (eff > 0 && !(pentFlags & DMG_NO_PROTECT))
			{
				eff = self.GetModifiedDamage(mod, eff, true, inflictor, source, pentFlags, angle);
			}

			// The target's own DamageFactor (p_interaction.cpp:1232).
			if (eff > 0 && !(pentFlags & DMG_NO_FACTOR))
			{
				eff = self.ApplyDamageFactor(mod, eff);
			}

			// TakeSpecialDamage virtual hook (p_interaction.cpp:1237).
			if (eff >= 0)
			{
				eff = self.TakeSpecialDamage(inflictor, source, eff, mod, pentFlags, angle);
			}
			if (eff < 0)
			{
				eff = 0;
			}

			// ---- Armor absorption (p_interaction.cpp:1362-1379) ---------
			// Call the virtual AbsorbDamage on the BasicArmor item directly.
			// Virtual dispatch honours custom armor subclasses, and unlike a
			// full inventory walk it cannot trip over unrelated items.
			// Then read the surviving pool back out and restore the fake display.
			if (eff > 0 && !(pentFlags & DMG_NO_ARMOR))
			{
				let armor = BasicArmor(FindInventory("BasicArmor"));
				if (armor != null && pentagramPool > 0)
				{
					// Snapshot everything AbsorbDamage (and the UseInventory swap it
					// may trigger when Amount hits 0) is allowed to touch.
					int savedAmount = armor.Amount;
					int savedAbsorbCount = armor.AbsorbCount;
					double savedSavePercent = armor.SavePercent;
					Name savedArmorType = armor.ArmorType;
					TextureID savedIcon = armor.Icon;
					int savedMaxAbsorb = armor.MaxAbsorb;
					int savedMaxFullAbsorb = armor.MaxFullAbsorb;

					// Present the real pool so the absorb logic caps correctly.
					armor.Amount = pentagramPool;

					// Call the virtual -- custom armor subclasses are honoured.
					int outDamage = eff;
					armor.AbsorbDamage(eff, mod, outDamage, inflictor, source, pentFlags, angle);
					eff = outDamage;
                    double absorbedPercent = (1.0 - (double(eff) / damage)) * 100.0;
                    console.printf("Effective protection: %.1f%%", absorbedPercent);
					// Whatever survives in the real armor is the new pool.
					pentagramPool = max(0, armor.Amount);

					// Restore the fake display and all side-effected fields.
					armor.Amount = savedAmount;
					armor.AbsorbCount = savedAbsorbCount;
					armor.SavePercent = savedSavePercent;
					armor.ArmorType = savedArmorType;
					armor.Icon = savedIcon;
					armor.MaxAbsorb = savedMaxAbsorb;
					armor.MaxFullAbsorb = savedMaxFullAbsorb;
				}
			}

			return 0;
		}

		// Return the original value
		return super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}
}
