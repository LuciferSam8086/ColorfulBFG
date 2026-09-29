// =========================================================================
// TOKEN DI INVENTARIO INVISIBILE: funge da contatore sul giocatore
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
// PALLA GIALLA BFG
// =========================================================================
class YellowBFGBall : BFGBall
{
    private bool bInvulGranted;
    private PlayerPawn realPlayer;

    double ballSpeed;
    property BallSpeed: ballSpeed;

    Default
    {
        // [DEBUG VELOCITÀ]: Modifica questo valore per regolare la velocità
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

        // 1. Applica velocità scalando il vettore reale
        if (ballSpeed > 0)
        {
            Speed = ballSpeed;
            if (Vel.Length() > 0)
            {
                Vel = Vel.Unit() * ballSpeed;
            }
        }

        // 2. Registra il giocatore
        if (target && target.player)
        {
            realPlayer = PlayerPawn(target);
        }

        if (realPlayer)
        {
            bInvulGranted = true;

            // Dà un token al player (o ne aumenta l'Amount se ne ha già)
            realPlayer.GiveInventoryType("YellowBallInvulToken");

            // Applica invulnerabilità e stencil
            realPlayer.bInvulnerable = true;
            realPlayer.A_SetRenderStyle(1.0, STYLE_Stencil);
            realPlayer.SetShade("Gold");
        }
    }

    void RemoveInvulnerability()
    {
        if (bInvulGranted)
        {
            bInvulGranted = false;

            if (realPlayer)
            {
                // Rimuove un token dall'inventario del giocatore
                realPlayer.TakeInventory("YellowBallInvulToken", 1);

                // Controlla se al giocatore sono rimasti altri token (altre palle in volo)
                let token = realPlayer.FindInventory("YellowBallInvulToken");

                // Se non ci sono più token (o amount <= 0), resetta il player!
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
        }
        BFE1 ABCDEF 8 Bright;
        Stop;
    }
}