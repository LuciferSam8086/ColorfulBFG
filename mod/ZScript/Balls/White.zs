class WhiteBFGBall : ColorlessBFGBall
{
    Default
    {
        Damage 0;
        Translation "112:127=80:95";
    }

    // =========================================================================
    // Dedicated function: Archvile resurrection / replacement
    // Can be called from ANYWHERE (in this projectile or in other contexts).
    // Parameters:
    // - corpse: Pointer to the Archvile's corpse
    // - instigator: Whoever fired / the player (will become the master)
    // =========================================================================
    virtual Actor ReviveNonRaisableEnemyAsFriendly(Actor corpse, Actor instigator)
    {
        if (!corpse) return null;

        Vector3 spawnPos = corpse.Pos;
        class<Actor> nonRaisableClass = corpse.GetClass();
        double defHeight = GetDefaultByType(nonRaisableClass).Height;

        // 1. Vertical check: make sure the ceiling does not crush the new monster
        if (corpse.CeilingZ - corpse.FloorZ < defHeight)
        {
            return null; // Not enough room to stand back up
        }

        // 2. Remove the old corpse from the game world
        corpse.Destroy();

        // 3. Spawn a clean new instance
        Actor newArch = Spawn(nonRaisableClass, spawnPos, ALLOW_REPLACE);
        if (newArch)
        {
            // Set the friendly (allied) state
            newArch.bFriendly = true;

            // If the reviver exists, set it as master and wake up the AI
            if (instigator)
            {
                newArch.master = instigator;
                newArch.LastHeard = instigator;
                // Set the angle to the same direction as the player or the impact
                newArch.Angle = instigator.Angle;
            }

            // 4. Play the "See" state so it starts active immediately
            State seeState = newArch.FindState("See");
            if (seeState)
            {
                newArch.SetState(seeState);
            }

            // 5. Visual effect centered on the torso
            Vector3 effectPos = (newArch.Pos.X, newArch.Pos.Y, newArch.Pos.Z + (defHeight * 0.5));
            Spawn("WhiteArchvileFire", effectPos, ALLOW_REPLACE);
        }

        return newArch;
    }

    States
    {
    Death:
        BFE1 A 0
        {
            // Inventory check ONLY ONCE before the loop (if the item is passive)
            // Example: bool hasItem = (target && target.FindInventory("Talisman") != null);

            // =============================================================
            // MODIFY THIS VALUE: maximum number of enemies revived per ball
            // =============================================================
            int maxRevives = 1;
            int revivedCount = 0;

            BlockThingsIterator it = BlockThingsIterator.Create(self, 256);
            
            while (it.Next())
            {
                // Stop scanning once the revival limit has been reached
                if (revivedCount >= maxRevives) break;

                Actor mo = it.thing;
                
                // Safety checks: valid, corpse, height > 0 (not crushed), euclidean radius
                if (!mo || !mo.bCORPSE || mo.Height <= 0 || Distance3D(mo) > 256)
                {
                    continue;
                }

                // =============================================================
                // SPECIAL CASE: Archvile
                // The function is standalone: you may wrap it in your own condition,
                // add inventory checks, or disable it at will.
                // =============================================================
                if (!mo.FindState("Raise"))
                {
                    // Call the standalone function
                    if (ReviveNonRaisableEnemyAsFriendly(mo, target))
                    {
                        revivedCount++;
                    }
                    continue;
                }

                // =============================================================
                // NORMAL CASE: common monsters (they have a "Raise" state)
                // =============================================================
                State raiseState = mo.FindState("Raise");
                if (!raiseState)
                {
                    continue;
                }

                double defHeight = GetDefaultByType(mo.GetClass()).Height;
                if (mo.CeilingZ - mo.FloorZ < defHeight)
                {
                    continue;
                }

                mo.Revive();
                mo.SetState(raiseState);
                mo.bFriendly = true;
				mo.Height = defHeight;

                if (target)
                {
                    mo.master = target;
                    mo.LastHeard = target;
                }

                Vector3 effectPos = (mo.Pos.X, mo.Pos.Y, mo.Pos.Z + (defHeight * 0.5));
                Spawn("WhiteArchvileFire", effectPos, ALLOW_REPLACE);

                revivedCount++;
            }
        }
        BFE1 ABCDEF 8 Bright;
        Stop;
    }
}

class WhiteArchvileFire : ArchvileFire
{
	default
	{
		Translation "160:167=80:95";
	
	}
}