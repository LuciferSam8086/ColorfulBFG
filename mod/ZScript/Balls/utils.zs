mixin class BFGUtilityMethods
{
    void A_SafeBFGSpray(class<Actor> spraytype = "BFGExtra", int numrays = 40, int damagecnt = 15, double ang = 90, double distance = 16 * 64, double vrange = 32, int defdamage = 0, int flags = 0, string damType = "BFGSplash")
    {
        int damage;
        FTranslatedLineTarget t;

        if (spraytype == null) spraytype = "BFGExtra";
        if (numrays <= 0) numrays = 40;
        if (damagecnt <= 0) damagecnt = 15;
        if (ang == 0) ang = 90.0;
        if (distance <= 0) distance = 16 * 64;
        if (vrange == 0) vrange = 32.0;

        if (!target) return;

        Actor originator = target;
        if (flags & BFGF_MISSILEORIGIN)
        {
            originator = self;
        }

        for (int i = 0; i < numrays; i++)
        {
            double an = angle - ang / 2.0 + (ang / numrays) * i;
            originator.AimLineAttack(an, distance, t, vrange);

            if (t.linetarget != null)
            {
                bool hurtsSelf = !(flags & BFGF_HURTSOURCE) && (t.linetarget == originator || t.linetarget == target);
                bool isFriend = t.linetarget.bFriendly || (target && t.linetarget.IsFriend(target));

                if (hurtsSelf || isFriend) continue;

                Actor spray = Spawn(spraytype, t.linetarget.Pos + (0, 0, t.linetarget.Height / 4.0), ALLOW_REPLACE);
                int dmgFlags = 0;
                Name dmgType = damType;

                if (spray != null)
                {
                    if ((spray.bMThruSpecies && target && target.GetSpecies() == t.linetarget.GetSpecies()) ||
                        (!(flags & BFGF_HURTSOURCE) && target == t.linetarget))
                    {
                        spray.Destroy();
                        continue;
                    }

                    if (spray.bPuffGetsOwner) spray.target = target;
                    if (spray.bFoilInvul) dmgFlags |= DMG_FOILINVUL;
                    if (spray.bFoilBuddha) dmgFlags |= DMG_FOILBUDDHA;
                    dmgType = spray.DamageType;
                }

                if (defdamage == 0)
                {
                    damage = 0;
                    for (int j = 0; j < damagecnt; ++j) damage += Random[BFGSpray](1, 8);
                }
                else
                {
                    damage = defdamage;
                }

                int dealtDamage = t.linetarget.DamageMobj(originator, target, damage, dmgType, dmgFlags | DMG_USEANGLE, t.angleFromSource);
                t.TraceBleed(dealtDamage > 0 ? dealtDamage : damage, self);
            }
        }
    }
}


class FriendlyCorpseTimer : Thinker
{
    Actor corpse;
    int lifetime;

    static FriendlyCorpseTimer Create(Actor targetCorpse, int durationInSeconds = 30)
    {
        let timer = new("FriendlyCorpseTimer");
        timer.corpse = targetCorpse;
        timer.lifetime = durationInSeconds * 35; // 35 tics per second
        return timer;
    }

    override void Tick()
    {
        Super.Tick();

        // In case the corpse was destroyed by other events in the meantime
        if (!corpse)
        {
            Destroy();
            return;
        }

        // In case the corpse was revived in the meantime (it is no longer a corpse!)
        if (!corpse.bCORPSE)
        {
            Destroy();
            return;
        }

        // Decrement the timer
        lifetime--;
		if(lifetime%35==0)
		{
			console.printf("attore %s sta per scomparire tra %i secondi", corpse.GetClassName(),lifetime/35);
		}
		

        // When the 30 seconds run out (last 35 tics = final second)
        if (lifetime <= 35)
        {
            // Gradual fade-out during the last second
            corpse.A_FadeOut(0.03);

            if (lifetime <= 0)
            {
                // If it has not fully disappeared yet, force its removal
                if (corpse)
                {
                    corpse.Destroy();
                }
                Destroy();
            }
        }
    }
}