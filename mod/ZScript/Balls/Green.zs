class GreenBFGBall : ColorlessBFGBall
{
    // Inietti tutti i metodi del mixin qui dentro
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
            // Ora puoi chiamarla nativamente perché è stata iniettata!
            A_SafeBFGSpray("BFGExtra", 40, 15);
        }
        BFE1 CDEF 8 Bright;
        Stop;
    }
}