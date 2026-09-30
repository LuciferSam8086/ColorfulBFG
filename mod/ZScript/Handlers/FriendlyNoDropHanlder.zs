class FriendlyNoDropHandler : StaticEventHandler
{
    override void WorldThingDied(WorldEvent e)
    {
        // If the thing that died is a friendly monster
        if (e.Thing && e.Thing.bISMONSTER && e.Thing.bFriendly)
        {
            console.printf(e.Thing.GetClassName());
			// Start the 30-second countdown on the corpse
            FriendlyCorpseTimer.Create(e.Thing, 30);
        }
    }

    // Control is kept here to stop it from dropping weapons
    override void WorldThingSpawned(WorldEvent e)
    {
        let item = Inventory(e.Thing);
        if (!item) return;

        BlockThingsIterator it = BlockThingsIterator.Create(item, 32);
        while (it.Next())
        {
            Actor mo = it.thing;
            if (mo && mo.bCORPSE && mo.bFriendly)
            {
                if (item.Distance2D(mo) <= mo.Radius + 8)
                {
                    item.Destroy();
                    return;
                }
            }
        }
    }
}