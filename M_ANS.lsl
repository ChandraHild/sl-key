//161123 v1.1.0.4
//
//- to override 'no script' parcels
//
//+ v1.0.1  : inter script control interference -> "if accept is FALSE and pass_on is TRUE, then all controls behave normally"
//+ v1.0.1.1: no reset
//+ v1.0.2  : LButton -> Shift+A
//+ v1.1    : on_rez -> attach
//+ v1.1.0.1: events order
//            performance ('if(k != NULL_KEY)' -> 'if(k)')
//+ v1.1.0.2: TControls (256 -> 4)
//+ v1.1.0.3: TControls (CONTROL_LEFT -> CONTROL_LBUTTON (less used, no conflicts) )
//+ v1.1.0.4: state_entry's RPerms: only if attached

default
{
    state_entry()
    {
        if( llGetAttached() )
        {
            llRequestPermissions( llGetOwner(), PERMISSION_TAKE_CONTROLS);            //1104 //ANS * \/
        }
    }

    run_time_permissions(integer i)
    {
        if(i & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_LBUTTON, FALSE, TRUE);                    //1103 //1102 //102 //101
        }
    }

    attach(key k)
    {                                    //110 \/
        if(k) llRequestPermissions( llGetOwner(), PERMISSION_TAKE_CONTROLS);                    //1101 //1011
    }
}                                            //110 /\ //ANS /\