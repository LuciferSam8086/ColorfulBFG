// =========================================================================
// BASE CLASS: PALLA BFG INCOLORE
// =========================================================================
// Questa classe base serve come genitore comune per tutte le palle BFG
// personalizzate. La sua unica responsabilita' e' quella di IGNORARE
// SEMPRE l'autoaim, indipendentemente dalle impostazioni del giocatore.
//
// PERCHE' E' NECESSARIO:
// L'engine applica l'autoaim in fase di sparo dentro P_SpawnPlayerMissile
// (vedi uzdoom_source/src/playsim/p_mobj.cpp): esso calcola un pitch/yaw
// "aggiustato" verso il nemico piu' vicino e poi imposta:
//     MissileActor->Angles.Yaw = an;
//     MissileActor->Vel3DFromAngle(pitch, MissileActor->Speed);
//
// Gli angoli REALI del giocatore (target.Angles.Yaw / Angles.Pitch) non
// vengono MAI modificati dall'autoaim. Quindi, in PostBeginPlay, possiamo
// leggere l'orientamento reale dello sparatore e ricalcolare la velocita',
// annullando di fatto l'autoaim.
// =========================================================================
class ColorlessBFGBall : BFGBall
{
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();

        // Se lo sparatore e' un giocatore, ripristina l'orientamento reale
        // della visuale, scartando qualsiasi correzione di autoaim.
        if (target && target.player)
        {
            Angle = target.Angle;
            Vel3DFromAngle(Speed, target.Angle, target.Pitch);
        }
    }
}
