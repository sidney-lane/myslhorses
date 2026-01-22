// ========================================
// HORSE HARD LOCK — ANTI-ACCIDENT SCRIPT
// ========================================

default
{
    state_entry()
    {
        // Prevent delete, return, take
        llSetObjectPermMask(MASK_OWNER, FALSE, PERM_MOVE);
        llSetObjectPermMask(MASK_NEXT,  FALSE, PERM_MOVE);

        // Lock position + rotation
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);

        // Optional: visual confirmation
        llSetText("🔒 LOCKED", <1,0,0>, 1.0);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}
