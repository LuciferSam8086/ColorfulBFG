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
    }

    override void PostBeginPlay()
    {
        // MUST run first: the parent ColorlessBFGBall undoes any autoaim
        // correction by recalculating the velocity from the shooter's angles.
        Super.PostBeginPlay();

        // Attach the green glow BEFORE the first render to avoid a 1-tic delay.
        // Offset (0,0,4) is the ball's center (Height 8 / 2).
        A_AttachLight('greenBallGlow', DynamicLight.PointLight, 0x00FF00, 96, 0,
            DynamicLight.LF_ATTENUATE, (0, 0, 4));
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
            A_RemoveLight('greenBallGlow');
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