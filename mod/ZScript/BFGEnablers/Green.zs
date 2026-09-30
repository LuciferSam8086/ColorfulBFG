class GreenBFGEnabler : ColorlessEnabler
{
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();
        A_AttachLight('greenGlow', DynamicLight.PointLight, 0x00FF00, 64, 0,
            DynamicLight.LF_ATTENUATE, (0, 0, 10));
    }

    override void AttachToOwner(Actor other)
    {
        A_RemoveLight('greenGlow');
        Super.AttachToOwner(other);
    }

    States
    {
    Spawn:
        TBGR ABCDEF 8 Bright;
        Loop;
    }
}