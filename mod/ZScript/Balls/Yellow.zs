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
		Translation "112:127=160:167";
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
        A_AttachLight('yellowBallGlow', DynamicLight.PointLight, 0xFFFF00, 96, 0,
            DynamicLight.LF_ATTENUATE, (0, 0, 16));
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
            A_RemoveLight('yellowBallGlow');
        }
        BFE1 ABCDEF 8 Bright;
        Stop;
    }
}