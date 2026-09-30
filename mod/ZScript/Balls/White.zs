class WhiteBFGBall : ColorlessBFGBall
{
    Default
    {
        Damage 0;
        Translation "112:127=80:95";
    }

    // =========================================================================
    // Funzione dedicata: Resurrezione / Sostituzione Archvile
    // Può essere chiamata OVUNQUE (in questo proiettile o in altri contesti).
    // Parametri:
    // - corpse: Il puntatore al cadavere dell'Archvile
    // - instigator: Chi ha sparato / il giocatore (diventerà il master)
    // =========================================================================
    virtual Actor ReviveNonRaisableEnemyAsFriendly(Actor corpse, Actor instigator)
    {
        if (!corpse) return null;

        Vector3 spawnPos = corpse.Pos;
        class<Actor> nonRaisableClass = corpse.GetClass();
        double defHeight = GetDefaultByType(nonRaisableClass).Height;

        // 1. Controllo verticale: verifica che il soffitto non schiacci il nuovo mostro
        if (corpse.CeilingZ - corpse.FloorZ < defHeight)
        {
            return null; // Spazio insufficiente per rialzarsi in piedi
        }

        // 2. Rimuove il vecchio cadavere dal mondo di gioco
        corpse.Destroy();

        // 3. Spawna una nuova istanza pulita
        Actor newArch = Spawn(nonRaisableClass, spawnPos, ALLOW_REPLACE);
        if (newArch)
        {
            // Imposta lo stato di alleanza
            newArch.bFriendly = true;

            // Se chi lo ha resuscitato esiste, lo imposta come padrone e sveglia l'IA
            if (instigator)
            {
                newArch.master = instigator;
                newArch.LastHeard = instigator;
                // Imposta l'angolo verso la stessa direzione del giocatore o dell'impatto
                newArch.Angle = instigator.Angle;
            }

            // 4. Riproduce lo stato "See" per farlo partire subito attivo
            State seeState = newArch.FindState("See");
            if (seeState)
            {
                newArch.SetState(seeState);
            }

            // 5. Effetto grafico visivo centrato sul busto
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
            // Controllo inventario UNA SOLA VOLTA a monte del ciclo (se l'oggetto è passivo)
            // Esempio: bool hasItem = (target && target.FindInventory("Talismano") != null);

            // =============================================================
            // MODIFY THIS VALUE: numero massimo di nemici resuscitati per palla
            // =============================================================
            int maxRevives = 1;
            int revivedCount = 0;

            BlockThingsIterator it = BlockThingsIterator.Create(self, 256);
            
            while (it.Next())
            {
                // Interrompe la scansione quando il limite di resurrezioni è raggiunto
                if (revivedCount >= maxRevives) break;

                Actor mo = it.thing;
                
                // Controlli di sicurezza: valido, cadavere, altezza > 0 (non schiacciato), raggio euclideo
                if (!mo || !mo.bCORPSE || mo.Height <= 0 || Distance3D(mo) > 256)
                {
                    continue;
                }

                // =============================================================
                // CASO SPECIALE: Archvile
                // La funzione è separata: puoi racchiuderla in una tua condizione,
                // controlli di inventario o disattivarla a piacimento.
                // =============================================================
                if (!mo.FindState("Raise"))
                {
                    // Chiamata alla funzione autonoma
                    if (ReviveNonRaisableEnemyAsFriendly(mo, target))
                    {
                        revivedCount++;
                    }
                    continue;
                }

                // =============================================================
                // CASO NORMALE: Mostri comuni (con stato "Raise")
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