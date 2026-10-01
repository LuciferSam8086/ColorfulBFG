// Empty class, just in case the items should do something in common
// An Enabler permits the colorful BFG to shoot a specific ball
// Maybe in future I will find better sprites :)
class ColorlessEnabler : Inventory
{
    Default
    {
        Inventory.MaxAmount 1;
        +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}

// Specific enablers
// Green enabler
class GreenBFGEnabler : ColorlessEnabler
{
	default
	{
		Inventory.PickupMessage "You got the \c[Green] classic \c- BFG flavor!";
        //+INVENTORY.INVBAR
	}
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

// white enabler
class WhiteBFGEnabler : ColorlessEnabler
{

	default
	{
		Inventory.PickupMessage "Now you can \c[WHITE]make new friends\-!";
        //+INVENTORY.INVBAR
	}
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();
        A_AttachLight('whiteGlow', DynamicLight.PointLight, 0xFFFFFF, 64, 0,
            DynamicLight.LF_ATTENUATE, (0, 0, 10));
    }

    override void AttachToOwner(Actor other)
    {
        A_RemoveLight('whiteGlow');
        Super.AttachToOwner(other);
    }

    States
    {
    Spawn:
        TBWH ABCDEF 8 Bright;
        Loop;
    }
}

// Yellow enabler
class YellowBFGEnabler : ColorlessEnabler
{

	default
	{
		Inventory.PickupMessage "You got the \c[YELLOW]golden shield\c-! Let them shoot the ball!";
        //+INVENTORY.INVBAR
	}
    
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();
        A_AttachLight('yellowGlow', DynamicLight.PointLight, 0xFFFF00, 64, 0,
            DynamicLight.LF_ATTENUATE, (0, 0, 10));
    }

    override void AttachToOwner(Actor other)
    {
        A_RemoveLight('yellowGlow');
        Super.AttachToOwner(other);
    }

    States
    {
    Spawn:
        TBYE ABCDEF 8 Bright;
        Loop;
    }
}

