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
        BFE1 A 8 Bright;
        BFE1 B 8 Bright 
        {
            // Now it can be called natively because it has been injected!
            A_SafeBFGSpray("BFGExtra", 40, 15);
        }
        BFE1 CDEF 8 Bright;
        Stop;
    }
}