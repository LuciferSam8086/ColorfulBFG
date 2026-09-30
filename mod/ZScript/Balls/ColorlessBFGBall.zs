// =========================================================================
// BASE CLASS: COLORLESS BFG BALL
// =========================================================================
// This base class is the common parent of every custom BFG ball.
// Its only responsibility is to ALWAYS ignore autoaim, regardless of the
// player's settings.
//
// WHY IT IS NEEDED:
// The engine applies autoaim at fire time inside P_SpawnPlayerMissile
// (see uzdoom_source/src/playsim/p_mobj.cpp): it computes an "adjusted"
// pitch/yaw toward the nearest enemy and then sets:
//     MissileActor->Angles.Yaw = an;
//     MissileActor->Vel3DFromAngle(pitch, MissileActor->Speed);
//
// The player's REAL angles (target.Angles.Yaw / Angles.Pitch) are NEVER
// modified by autoaim. Therefore, in PostBeginPlay we can read the shooter's
// real orientation and recalculate the velocity, which effectively undoes
// any autoaim correction.
// =========================================================================
class ColorlessBFGBall : BFGBall
{
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();

        // If the shooter is a player, restore the real view orientation,
        // discarding any autoaim correction.
        if (target && target.player)
        {
            Angle = target.Angle;
            Vel3DFromAngle(Speed, target.Angle, target.Pitch);
        }
    }
}
