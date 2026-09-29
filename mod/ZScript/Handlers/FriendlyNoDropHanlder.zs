class FriendlyNoDropHandler : StaticEventHandler
{
    override void WorldThingDied(WorldEvent e)
    {
        // Se a morire è un mostro alleato
        if (e.Thing && e.Thing.bISMONSTER && e.Thing.bFriendly)
        {
            console.printf(e.Thing.GetClassName());
			// Avvia il countdown di 30 secondi sul cadavere
            FriendlyCorpseTimer.Create(e.Thing, 30);
        }
    }

    // Qui mantieni il controllo per evitare che droppi le armi
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