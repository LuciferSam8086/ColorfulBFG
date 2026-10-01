// =========================================================================
// BASE CLASS: COLORLESS BFG BALL
// =========================================================================
// This base class is the common parent of every custom BFG ball.
// Its only responsibility is to ALWAYS ignore autoaim, regardless of the
// player's settings.
//
// WHY IT IS NEEDED:
// The engine applies autoaim at fire time inside P_SpawnPlayerMissile
// (see uzdoom_source/src/playsim/p_mobj.cpp): it computes an "adjusted"
// pitch/yaw toward the nearest enemy and then sets:
//     MissileActor->Angles.Yaw = an;
//     MissileActor->Vel3DFromAngle(pitch, MissileActor->Speed);
//
// The player's REAL angles (target.Angles.Yaw / Angles.Pitch) are NEVER
// modified by autoaim. Therefore, in PostBeginPlay we can read the shooter's
// real orientation and recalculate the velocity, which effectively undoes
// any autoaim correction.
// =========================================================================
class ColorlessBFGBall : BFGBall
{
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();

        // If the shooter is a player, restore the real view orientation,
        // discarding any autoaim correction.
        if (target && target.player)
        {
            Angle = target.Angle;
            Vel3DFromAngle(Speed, target.Angle, target.Pitch);
        }
    }
}

// Start BFG Green Ball
class GreenBFGBall : ColorlessBFGBall
{
    // Inject all of the mixin's methods right here
    mixin BFGUtilityMethods;

    Default
    {
        Speed 25;
        Radius 13;
        Height 8;
        Damage 100;
		Translation "BFGGreen";
    }

    override void PostBeginPlay()
    {
        // MUST run first: the parent ColorlessBFGBall undoes any autoaim
        // correction by recalculating the velocity from the shooter's angles.
        Super.PostBeginPlay();

        // Attach the green glow BEFORE the first render to avoid a 1-tic delay.
        // Offset (0,0,4) is the ball's center (Height 8 / 2).
        /*A_AttachLight('greenBallGlow', DynamicLight.PointLight, 0x00FF00, 96, 0,
            DynamicLight.LF_ATTENUATE, (0, 0, 4));*/
    }

    override int SpecialMissileHit(Actor victim)
    {
        if (victim && (victim == target || victim.bFriendly || (target && victim.IsFriend(target))))
        {
            return 1;
        }
        return Super.SpecialMissileHit(victim);
    }

    States
    {
    Spawn:
        BFS1 AB 4 Bright;
        Loop;

    Death:
        BFE1 A 8 Bright
        {
            // Kill the attached light the instant the explosion starts, so it
            // does not linger on the frozen post-death actor (Stop -> tics == -1).
            //A_RemoveLight('greenBallGlow');
        }
        BFE1 B 8 Bright 
        {
            // Now it can be called natively because it has been injected!
            A_SafeBFGSpray("BFGExtra", 40, 15);
        }
        BFE1 CDEF 8 Bright;
        Stop;
    }
}
// End BFG Green ball

// Start BFG White ball
class WhiteBFGBall : ColorlessBFGBall
{
    Default
    {
        Damage 0;
        Translation "BFGWhite";
    }

    // =========================================================================
    // Dedicated function: Any monster that doesn´t have a raise state here can be revived
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
            int maxRevives = 25; // to see with bigger maps?
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
// End BFG White ball


// Start Yellow BFG Ball
// =========================================================================
// INVISIBLE INVENTORY TOKEN: acts as a counter on the player
// =========================================================================
class YellowBallInvulToken : Inventory
{
    Default
    {
        Inventory.MaxAmount 999;
        +INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
    }
}

// =========================================================================
// YELLOW BFG BALL
// =========================================================================
class YellowBFGBall : ColorlessBFGBall
{
    private bool bInvulGranted;
    private PlayerPawn realPlayer;

    double ballSpeed;
    property BallSpeed: ballSpeed;

    Default
    {
        // [DEBUG SPEED]: change this value to tune the projectile speed
        YellowBFGBall.BallSpeed 6.0; 

        +SHOOTABLE
        +SOLID
        -NOBLOCKMAP
        +NOBLOOD
        BloodType "BulletPuff";
        
        Health 400; 
        Radius 16;
        Height 32;
        Mass 1000;
        Damage 0;
		Translation "BFGYellow";
    }

    override void PostBeginPlay()
    {
        Super.PostBeginPlay();

        // 1. Apply the speed by scaling the real velocity vector
        if (ballSpeed > 0)
        {
            Speed = ballSpeed;
            if (Vel.Length() > 0)
            {
                Vel = Vel.Unit() * ballSpeed;
            }
        }

        // 2. Store the player reference
        if (target && target.player)
        {
            realPlayer = PlayerPawn(target);
        }

        if (realPlayer)
        {
            bInvulGranted = true;

            // Grant a token to the player (or increase its Amount if already present)
            realPlayer.GiveInventoryType("YellowBallInvulToken");

            // Apply invulnerability and the stencil render style
            realPlayer.bInvulnerable = true;
            realPlayer.A_SetRenderStyle(1.0, STYLE_Stencil);
            realPlayer.SetShade("Gold");
        }

        // Attach the yellow glow BEFORE the first render to avoid a 1-tic delay.
        // Offset (0,0,16) is the ball's center (Height 32 / 2).
        /*A_AttachLight('yellowBallGlow', DynamicLight.PointLight, 0xFFFF00, 96, 0,
            DynamicLight.LF_ATTENUATE, (0, 0, 16));*/
    }

    void RemoveInvulnerability()
    {
        if (bInvulGranted)
        {
            bInvulGranted = false;

            if (realPlayer)
            {
                // Remove one token from the player's inventory
                realPlayer.TakeInventory("YellowBallInvulToken", 1);

                // Check whether the player still has other tokens (other balls in flight)
                let token = realPlayer.FindInventory("YellowBallInvulToken");

                // If no tokens are left (or Amount <= 0), reset the player!
                if (!token || token.Amount <= 0)
                {
                    realPlayer.bInvulnerable = false;
                    realPlayer.A_SetRenderStyle(1.0, STYLE_Normal);
                    realPlayer.SetShade(Color(0, 0, 0, 0));
                }
            }
        }
    }

    override void OnDestroy()
    {
        RemoveInvulnerability();
        Super.OnDestroy();
    }

    void TauntEnemies(double range = 600, int playerAggroChance = 30)
    {
        BlockThingsIterator it = BlockThingsIterator.Create(self, range);

        while (it.Next())
        {
            Actor mo = it.thing;

            if (!mo || mo == self || mo == realPlayer || mo.bCORPSE || !mo.bISMONSTER || mo.bFriendly)
            {
                continue;
            }

            if (Distance3D(mo) <= range && CheckSight(mo))
            {
                bool ignoreBall = (Random(0, 99) < playerAggroChance);

                if (ignoreBall && realPlayer && mo.CheckSight(realPlayer))
                {
                    mo.target = realPlayer;
                    mo.LastHeard = realPlayer;
                }
                else
                {
                    mo.target = self;
                    mo.LastHeard = self;
                }

                if (mo.InStateSequence(mo.CurState, mo.SpawnState))
                {
                    State seeState = mo.FindState("See");
                    if (seeState)
                    {
                        mo.SetState(seeState);
                    }
                }
            }
        }
    }

    States
    {
    Spawn:
        BFS1 AB 4 Bright 
        {
            TauntEnemies(600, 30);
        }
        Loop;

    Death:
        TNT1 A 0 
        {
            bShootable = false;
            bSolid = false;
            RemoveInvulnerability();

            // Kill the attached light the instant the ball dies, so it does not
            // linger on the frozen post-death actor (Stop -> tics == -1). A shootable
            // missile killed by a monster also takes this path:
            // Die() -> P_ExplodeMissile() -> Death state.
            //A_RemoveLight('yellowBallGlow');
        }
        BFE1 ABCDEF 8 Bright;
        Stop;
    }
}

// End Yellow BFG Ball