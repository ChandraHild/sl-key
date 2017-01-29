//_170129 CH18
//_
//_+ M01 : on AFK:
//_        xA: (CH06) turn AFK mode on, without halving the remaining time
//_        xB: stop winddown
//_        C: dynamic TOmega
//_+ M02 : options menu: reopen after choosing one
//_+ M03 : unwind while sitting:
//_        A: no unsit
//_        B: AFK anim.
//_+ M04 : winder script vs. dynamic dialog channel:
//_        A: if touched by 'mistress', send channel (-60946337, 'wind channel|[chn]')
//_        B: touch_start: -> _end
//_+ CH01: Capitalization of doll types
//_+ CH02: collapse() update
//_+ CH03: (M01B) Key shouldn't wind if dolly is collapsed
//_+ CH04: Don't uncarry on logon if our owner was carrying us
//_♥ CH05: Set Muniki as Chandra's owner when the script resets
//_+ CH06: Make startafk and stopafk functions
//_+ CH07: Allow unsitting while AFK, make dolly collapse if she unsits while unwound
//_+ CH08: Add ANS
//_+ CH09: Remove hover text, put in menu
//_+ CH10: Show current outfit in outfit list
//_+ CH11: Unpose after winding an unwound dolly!
//_. CH12: Turn off AO for display dollies
//_♥ M05 : A: (M01C) dynamic spin: +winding
//_        B: +sound
//_+ CH13: Make code style consistent
//_+ CH14: Make winding spin the key more
//_+ CH15: Let the dolly enter and leave AFK while carried
//_        And let her owner do it too
//_+ CH16: Clean up redundant code by letting run_time_permissions handle unposing
//_+ CH17: Use the new OC AO channel
//_+ CH18: Remove the away sensor from M01A/B, now that we have CH15
//_
//_x (CH03)M01B vs. TOmega on collapse: ("Chandra thinks that should be if(!winddown && !collapsed)")
//_x (CH07)(M03A) "If Chandra runs out of life when nobody's around, and she's stuck on a chair,
//_  people might not know she needs wound. Maybe we should get rid of the unsit, so Chandra can
//_  unsit herself when unwound?"
//_x (vs. existing code: stand alone)+ANS
//_
string optiondate = "Aug. 31";
//has afk, turns off ZHAO
// skips over adding animations, puts in change 
// changes listens
// version 36a removes the remove listens
integer visible;
string dollname;
integer detachable;
integer alwaysavailable;
integer pleasuredoll;
integer stuck;
integer canfly;
integer cantransform;
integer hascontroller;
integer winddown;
integer afk;
key ChristinaID = "42c7aaec-38bc-4b0c-94dd-ae562eb67e6d";
key MistressID;
key mainwinder = "64d26535-f390-4dc4-a371-a712b946daf8";

integer candress;
integer canbecomemistress;

string httpstart;
key dollID;
key carrierID;
key dresserID;
integer channel_dialog;
integer cd3666;
integer cd6012;
integer cd4667;
integer cd5666;

string currentstate;

// assuming a clock interval of 10
integer windamount = 180; //30 minutes
integer keylimit =   720; //2 hours
integer poselimit =  30;  //5 minutes

integer timeleftonkey;
integer posetime;
integer pose;
integer carried;
integer collapsed;
string currentanimation;
string newanimation;
string carriername;
integer listen_id_main;
integer listen_id_strip;
integer listen_id_private2;
integer listen_id_poses;
integer listen_id_plus;
integer listen_id_6011;
list poses;

handlemenuchoices(string choice, string name, key ToucherID)
{
    if (choice == "Carry")
    {
        carried = TRUE;
        carriername = name;
        carrierID = ToucherID;
        if (alwaysavailable)
        {
            llOwnerSay("@accepttp=rem");
        }
        llOwnerSay("@tplm=n,tploc=n,tplure=n,tplure:" + (string) carrierID + "=add,accepttp:" + (string) carrierID + "=add,accepttp:" + (string) MistressID + "=add");
        llSay(PUBLIC_CHANNEL, dollname + " has been picked up by " + carriername);
    }
    else if (choice == "Place Down")
    {
        uncarry();
    }
    else if (choice == "Type of Doll")
    {
        llMessageLinked(-4, 17, name, ToucherID);
    }
    else if (choice == "Pose")
    {
        list poselist = poses;
        llDialog(ToucherID, "Choose a pose",poselist , cd3666);
    }
    else if (choice == "Unpose")
    {
        if (collapsed == FALSE)
        {
            llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
        }
    }
    else if (choice == "allow takeover")
    {
        canbecomemistress = TRUE;
    }
    else if (choice == "Wind")
    {
        timeleftonkey += windamount;
        if (timeleftonkey > keylimit)
        {
            timeleftonkey = keylimit;
            llSay(PUBLIC_CHANNEL, dollname + "'s time has reached her limit");
        }
        if (collapsed)
        {
            // Uncollapsing
            timeleftonkey = windamount;
            //_M01C_llTargetOmega(<0,0,1>,.3,1.0);
            if (winddown)
            {
                //_M01C
                llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 1.0);
            }
            if (canfly)
            {
                llOwnerSay("@fly=y");
            }
            if (!stuck)
            {
                llOwnerSay("@tplm=y,tploc=y");
            }
            if (!alwaysavailable)
            {
                llOwnerSay("@accepttp=y");
            }
            llOwnerSay("@temprun=y,alwaysrun=y,sendchat=y,tplure=y,sittp=y,standtp=y,unsit=y,sit=y,shownames=y,showhovertextall=y,rediremote:999=rem");
            collapsed = FALSE;
            if (currentstate == "Display")
            {
                newanimation = "beautystand";
            }

            llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
        }
        llSay(PUBLIC_CHANNEL, " -- " + name + " has given " + dollname + " 30 minutes of life.");

        //_M05A
        windanimate(3);
    }

    else if (choice == "Dress")
    {
        llMessageLinked(-4, 1, "start", ToucherID);
        llOwnerSay(name + " is looking at your dress menu");
    }

    else if (choice == "Strip")
    {
        llDialog(ToucherID, "Take off:",["Top","Bra","Bottom","Panties","Shoes"], cd4667);
    }

    else if (choice == "Be Controller")
    {
        canbecomemistress = FALSE;
        hascontroller = TRUE;
        MistressID = ToucherID;
        llOwnerSay("The person carrying you has taken over as your controller.");
        string msg = "You are now " + dollname + "'s controller. See " + httpstart + "controller.htm";
        llDialog(ToucherID,msg,["OK"] , 9999);
    }

    else if (choice == "Use Control")
    {
        list privatemenu = ["drop control","detach now"];
        if (detachable)
        {
            privatemenu += "undetachable";
        }
        else
        {
            privatemenu += "detachable";
        }

        if (alwaysavailable)
        {
            privatemenu += "no auto tp";
        }
        else
        {
            privatemenu += "auto tp";
        }

        if (stuck)
        {
            privatemenu += "can travel";
        }
        else
        {
            privatemenu += "no self trav";
        }

        if (pleasuredoll)
        {
            privatemenu += "no plsr doll";
        }
        else
        {
            privatemenu += "make plsrdll";
        }

        if (canfly)
        {
            privatemenu += "no flying";
        }
        else
        {
            privatemenu += "can fly";
        }

        //_CH15 \/
        if (afk)
        {
            privatemenu += "stop afk";
        }
        else
        {
            privatemenu += "start afk";
        }
        //_CH15 /\

        llDialog(ToucherID, "See " + httpstart + "controller.htm Choose what you want to happen",  privatemenu, cd6012);
    }
    else if (choice == "Options")
    {
        string msg = httpstart + "keychoices.htm for explanation. (" + optiondate + " version)";
        list pluslist;
        if (afk)
        {
            pluslist += "stop afk";
        }
        else
        {
            pluslist += "start afk";
        }

        if (!carried)
        {
            if (!candress)
            {
                pluslist += "can dress";
            }
            else
            {
                pluslist += "no dressing";
            }

            if (detachable)
            {
                pluslist += ["no detaching","take off now"];
            }

            if (!alwaysavailable)
            {
                pluslist += "automatic tp";
            }

            if (!stuck)
            {
                pluslist += "no self tp";
            }

            if (canfly)
            {
                pluslist += "no flying";
            }

            if (pleasuredoll)
            {
                pluslist += "not pleasure";
            }
            else
            {
                pluslist += "pleasure doll";
            }
            if (!hascontroller)
            {
                if (canbecomemistress)
                {
                    pluslist += "no takeover";
                }
                else
                {
                    pluslist += "allow takeover";
                }
            }
            if (visible)
            {
                pluslist += "Invisible";
            }
            else
            {
                pluslist += "Visible";
            }
        }
        llDialog(ToucherID,msg,pluslist , cd5666);
    }
}

startafk()
{
    // CH06
    winddown = FALSE;

    //_M01C
    llTargetOmega(ZERO_VECTOR, 0.0, 0.0);
    llOwnerSay("@fly=n,temprun=n,alwaysrun=n,sendchat=n,tplm=n,tploc=n,tplure=n,sittp=n,standtp=n,accepttp=n,sit=n");
}

stopafk()
{
    winddown = TRUE;

    //_M01C \/
    llTargetOmega(<0.0, 0.0, 1.0>, 3.0, 1.0);
    llSleep(2.0);
    llTargetOmega(<0.0, 0.0, 1.0>, 2.0, 1.0);
    llSleep(1.0);
    llTargetOmega(<0.0, 0.0, 1.0>, 1.0, 1.0);
    llSleep(1.0);
    llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 1.0);
    //_M01C /\

    if (canfly)
    {
        llOwnerSay("@fly=y");
    }
    if (!stuck)
    {
        llOwnerSay("@tplm=y,tploc=y");
    }
    if (!alwaysavailable)
    {
        llOwnerSay("@accepttp=y");
    }
    llOwnerSay("@temprun=y,alwaysrun=y,sendchat=y,tplure=y,sittp=y,standtp=y,sit=y");
}

collapse()
{
    llOwnerSay("@fly=n,temprun=n,alwaysrun=n,sendchat=n,tplm=n,tploc=n,sittp=n,standtp=n,accepttp=n,accepttp:" + (string) carrierID + "=add,accepttp:" + (string) mainwinder + "=add,accepttp:" + (string) MistressID + "=add,sit=n,shownames=n,showhovertextall=n");
    //_M03A_llOwnerSay("@unsit=force"); // to get me off of pole? Does it stop dancing too?
    llOwnerSay("@tplure=n,tplure:" + (string) mainwinder + "=add,tplure:" + (string) MistressID + "=add");

    //_M03B \/
    if(!(llGetAgentInfo(dollID) & AGENT_SITTING))
    {
        newanimation = "collapse";
    }
    else
    {
        newanimation = "away";
    }
    //_M03B /\

    llOwnerSay("@rediremote:999=add");
    llTargetOmega(ZERO_VECTOR, 0, 0);
    collapsed = TRUE;
    visible = TRUE;
    llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
    llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
}

aochange(string choice)
{
    integer g_iAOChannel = -782690;

    //_CH17
    integer g_iInterfaceChannel = -llAbs((integer)("0x" + llGetSubString(dollID,30,-1)));;
    if (choice == "off")
    {
        string AO_OFF = "ZHAO_STANDOFF";
        llWhisper(g_iInterfaceChannel, "CollarComand|499|" + AO_OFF);
        llWhisper(g_iAOChannel, AO_OFF);
        llMessageLinked(LINK_SET, 0, "ZHAO_AOON", NULL_KEY);
    }
    else
    {
        string AO_ON = "ZHAO_STANDON";
        llWhisper(g_iInterfaceChannel, "CollarComand|499|" + AO_ON);
        llWhisper(g_iAOChannel, AO_ON);
        llMessageLinked(LINK_SET, 0, "ZHAO_AOON", NULL_KEY);
    }
}

reloadscripts()
{
    poses = [];
    integer  n = llGetInventoryNumber(20);
    if (n > 11)
    {
        n = 11;
    }
    while(n)
    {
        string thispose = llGetInventoryName(20, --n);
        if (thispose != "collapse")
        {
            poses += thispose;
        }
    }
}

uncarry()
{
    carried = FALSE;
    llOwnerSay("@accepttp:" + (string) carrierID + "=rem,@showinv=y");
    if (!collapsed)
    {
        if (stuck)
        {
            llOwnerSay("@tplure=y,accepttp=y");
        }
        else
        {
            llOwnerSay("@tplm=y,tploc=y,tplure=y,accepttp=y");
        }
    }
    if (alwaysavailable)
    {
        llOwnerSay("@accepttp=add");
    }
    llSay(PUBLIC_CHANNEL, dollname + " has been set down.");
    carrierID = NULL_KEY;
}

setup()
{
    if (dollID != llGetOwner())
    {
        dollID = llGetOwner();
        pose = FALSE;
        collapsed = FALSE;
        carried = FALSE;
        detachable = TRUE;
        alwaysavailable = FALSE;
        pleasuredoll = FALSE;
        stuck = FALSE; //problem with being stuck on private land -- no way to get off.
        candress = TRUE;
        canbecomemistress = FALSE;
        canfly = TRUE;
        cantransform = FALSE;
        winddown = TRUE;
        afk = FALSE;
        if (dollID == "27f02017-bf33-49f9-b7b9-9317b7791fc0")
        {
            // CH05 Set Muniki as owner if we're Chandra!
            hascontroller = TRUE;
            // Muniki's ID
            MistressID = "ac80e0b5-04ab-44a9-8a79-2d85c85da247";
        }
        else
        {
            hascontroller = FALSE;
            MistressID = ChristinaID;
        }
        timeleftonkey = 180; 
        llMessageLinked(-4, 200, "start", dollID);
        visible = TRUE;
        currentstate = "Regular";
    }
    dollname = llGetDisplayName(dollID);
    if (llGetAttached() == ATTACH_BACK)
    {
        // Locks key
        llOwnerSay("@detach=n");
        llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
    }
    else
    {
        llOwnerSay("@detach=y");
        llOwnerSay("Please detach your key and wear it on your spine"); 
    }
    integer ncd = ( -1 * (integer)("0x"+llGetSubString((string)llGetKey(),-5,-1)) ) -1;
    if (channel_dialog != ncd)
    {
        llListenRemove(listen_id_main);
        llListenRemove(listen_id_strip);
        llListenRemove(listen_id_poses);
        llListenRemove(listen_id_plus);
        llListenRemove(listen_id_private2);
        llListenRemove(listen_id_6011);
        channel_dialog = ncd;
        cd3666 = channel_dialog - 3666;
        cd6012 = channel_dialog - 6012;
        cd4667 = channel_dialog - 4667;
        cd5666 = channel_dialog - 5666;
        listen_id_main = llListen(channel_dialog, "", "", "");
        listen_id_private2 = llListen(cd6012, "", "", "");
        listen_id_poses = llListen(cd3666, "", "", "");
        listen_id_strip = llListen(cd4667, "", "", "");
        listen_id_plus = llListen(cd5666, "", "", "");
        listen_id_6011 = llListen(6011, "", "", "");
    }

    llOwnerSay("@acceptpermission=add");
    aochange("on");

    if (alwaysavailable)
    {
        llOwnerSay("@accepttp=add");
    }
    if (stuck)
    {
        llOwnerSay("@tplm=n,tploc=n");
    }
    if (!candress)
    {
        llOwnerSay("Other people cannot dress you.");
    }
    if (!canfly)
    {
        llOwnerSay("@fly=n");
    }
}

//_M05A \/
windanimate(integer i)
{
    if (i < 1)
    {
        return;
    }
    llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 0.0);
    llSleep(0.5);
    do
    {
        //_M05B
        llSound("07af5599-8529-fb12-5891-1dcf1a33ee49", 1.0, 0, 1);
        //       '- [Muniki K[_Clock Key Winding Up, Free Sound Effects (YTube)]
        llTargetOmega(<0.0, 0.0,-1.0>, 120.0*DEG_TO_RAD/0.5, 1.0);
        llSleep(0.5);  //              '- 60o in 0.5s
        llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 0.0);
        llSleep(0.5);
        i--;
    } while (i);
    if (winddown)
    {
        llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 1.0);
    }
}
//_M05A /\

default
{
    state_entry()
    {
        llTargetOmega(<0,0,1>,.3,1.0);
        setup();
        reloadscripts();
        // Clock is accessed every ten seconds;
        llSetTimerEvent(10.0);
        httpstart = "See http://CommunityDolls.com/";
    }

    on_rez(integer iParam)
    {
        // When key is put on, or when logging back on
        setup();
        if (carried && carrierID != MistressID)
        {
            uncarry();
        }
        if (collapsed)
        {
            collapse();
        }
     }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            reloadscripts();
        }
    }

    touch_end(integer total_number)
    {
        //_M04B
        integer displaytime = (integer) ((timeleftonkey+5) / 6);
        string timeleft = "Time Left on key is " + (string)displaytime + " minutes. ";

        // Detects user UUID
        key ToucherID = llDetectedKey(0);

        // Detects user name
        string ToucherName = llDetectedName(0);
        string msg;
        list menu =  ["Wind"];
        if (candress)
        {
            menu += "Dress";
        }
        if (cantransform)
        {
            menu += "Type of Doll";
        }
        if (carried)
        {
            if (ToucherID == dollID)
            {
                msg = "You are currently being carried";
                menu = ["OK", "Options"];
                if (MistressID == ChristinaID && !canbecomemistress)
                {
                    menu += "allow takeover";
                }
            }
            else if (ToucherID == carrierID)
            {
                msg = "Place Down frees " + dollname + " when you are done with her";
                menu += ["Place Down","Pose"];
                if (pose)
                {
                    menu += "Unpose";
                }
                if (canbecomemistress)
                {
                    menu += "Be Controller";
                }
                if (pleasuredoll || currentstate == "Slut")
                {
                    menu += "Strip";
                }
            }
            else
            {
                msg = dollname + " is currently being carried. Sorry.";
                menu = ["OK"];
            }
        }
        else if (collapsed)
        {
            if (ToucherID == dollID)
            {
                msg = "You need winding.";
                menu = ["OK"];
            }
        }
        else
        {
            // Not being carried, not collapsed
            if (ToucherID == dollID)
            {
                msg = httpstart + "dollkeyselfinfo.htm\nYou are a " + currentstate + " doll.";
                menu = ["Dress","Options"];
                if (!pose)
                {
                    menu += "Pose";
                }
                if (cantransform)
                {
                    menu += "Type of Doll";
                }
            }
            else
            {
                msg = dollname + " is a " + currentstate + " doll and likes to be treated like a doll. So feel free to use these options. The Carry option picks up " + dollname + " and temporarily makes her exclusively yours. " + httpstart + "communitydoll.htm for more info.";
                if (afk || llGetAgentInfo(dollID) & AGENT_AWAY)
                {
                    msg += " She is currently marked AFK.";
                }
                menu += "Carry";
                if (pose)
                {
                    menu += "Unpose";
                }
                menu += "Pose";
            }
        }
        if ((ToucherID == MistressID || ToucherID == ChristinaID) && ToucherID != dollID)
        {
            menu += ["Carry","Use Control"];

            //_M04A
            llWhisper(-60946337, "wind channel|" + (string)channel_dialog);
        }
        llDialog(ToucherID, timeleft + msg,  menu, channel_dialog);
    }

    timer()
    {
        // Called every time interval
        if (winddown && !collapsed)
        {
            timeleftonkey -= 1;
            if (timeleftonkey < 0)
            {
                collapse();
                llSay(PUBLIC_CHANNEL, dollname + " has run out of life");
            }
        }
        if (pose)
        {
            if (!collapsed && currentstate != "Display")
            {
                posetime -= 1;
                if (posetime == 0)
                {
                    llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
                }
            }
        }
        if (carried)
        {
            if (!pose)
            {
                vector carrierposition = llList2Vector(llGetObjectDetails(carrierID, [OBJECT_POS]), 0);
                if (carrierposition)
                {
                    vector dollposition = llList2Vector(llGetObjectDetails(dollID, [OBJECT_POS]), 0);
                    float d = llFabs(carrierposition.x - dollposition.x) + llFabs(carrierposition.y - dollposition.y) + llFabs(carrierposition.z - dollposition.z);
                    if (d > 8.0)
                    {
                        llMoveToTarget(<0.0, 1.0, 0.0> + carrierposition, 1.0);
                        llSleep(2.0);
                        llStopMoveToTarget();
                    }
                }
            }
        }
        if (collapsed)
        {
            if(!(llGetAgentInfo(dollID) & AGENT_SITTING) && currentanimation == "away")
            {
                newanimation = "collapse";
                llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
            }
        }
     }

     link_message(integer source, integer num, string choice, key id)
     {
        if (num == 16)
        {
            if (currentstate == "Key" || currentstate == "Builder")
            {
                winddown = TRUE;
            }
            if (currentstate == "Display")
            {
                if (choice != "Display")
                {
                    llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
                }
            }

            // Changes over to current state being new state
            currentstate = choice;
            if (currentstate == "Display")
            {
                newanimation = "beautystand";
                llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
            }
            if (currentstate == "Builder" || currentstate == "Key")
            {
                winddown = FALSE;
            }
        }
        if (num == 18)
        {
            cantransform = TRUE;
        }
    }

    listen(integer channel, string name, key id, string choice)
    {
        if (channel == cd3666)
        {
            if (!collapsed)
            {
                newanimation = choice;
                llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
                llOwnerSay("You are being posed");
            }
        }
        else if (channel == cd5666 && id == dollID)
        {
            if (choice == "no detaching")
            {
                detachable = FALSE;
                llOwnerSay("Your key cannot be detached.");
            }
            else if (choice == "automatic tp")
            {
                llOwnerSay("You must accept all tp offers.");
                alwaysavailable = TRUE;
                llOwnerSay("@accepttp=add");
            }
            else if (choice == "pleasure doll")
            {
                llOwnerSay("Your key thinks you are a pleasure doll.");
                pleasuredoll = TRUE;
            }
            else if (choice == "not pleasure")
            {
                llOwnerSay("Your key does not treat you like a pleasure doll.");
                pleasuredoll = FALSE;
            }
            else if (choice == "no self tp")
            {
                llOwnerSay("Helpless doll! You cannot teleport yourself.");
                stuck = TRUE;
                llOwnerSay("@tplm=n,tploc=n");
            }
            else if (choice == "can dress")
            {
                llOwnerSay("Other people can dress you.");
                candress = TRUE;
            }
            else if (choice == "no dressing")
            {
                llOwnerSay("Other people cannot dress you.");
                candress = FALSE;
            }

            else if (choice == "no takeover")
            {
                llOwnerSay("There is no option for someone to become your controller.");
                canbecomemistress = FALSE;
            }
            else if (choice == "allow takeover")
            {
                llOwnerSay("Anyone carrying you can choose to be your controller.");
                canbecomemistress = TRUE;
            }
            else if (choice == "take off now")
            {
                aochange("on");
                llOwnerSay("@clear,detachme=force");
                llOwnerSay("Your key has been taken off.");
                return;
            }
            else if (choice == "no flying")
            {
                canfly = FALSE;
                llOwnerSay("@fly=n");
                llOwnerSay("You have given up your ability to fly. Helpless dolly!");
            }
            else if (choice == "Invisible")
            {
                visible = FALSE;
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
            }
            else if (choice == "Visible")
            {
                visible = TRUE;
                llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
            }
            else if (choice == "start afk")
            {
                startafk();
                afk = TRUE;
            }
            else if (choice == "stop afk")
            {
                stopafk();
                afk = FALSE;
                timeleftonkey =  timeleftonkey / 2;
            }

            //_M02
            handlemenuchoices("Options", name, id);
        }

        else if (channel == 6011 && choice == "detach")
        {
            vector dollposition = llList2Vector(llGetObjectDetails(dollID, [OBJECT_POS]), 0);
            float d = llFabs(153.9 - dollposition.x) + llFabs(16.5 - dollposition.y);

            if (d < 4.0 && id != dollID)
            {
                llDialog(id, "For the key of " + dollname,  ["detach now"], cd6012);
            }
        }
        else if (channel == cd6012 && choice =="detach now")
        {
            aochange("on");
            llOwnerSay("@clear,detachme=force");
            return;
        }

        else if (channel == cd6012 && (id == MistressID || id == ChristinaID) && id != dollID)
        {
            if (choice == "detachable")
            {
                detachable = TRUE;
                llSay(PUBLIC_CHANNEL, dollname + "'s key can be detached.");
            }
            else if (choice == "undetachable")
            {
                detachable = FALSE;
                llSay(PUBLIC_CHANNEL, dollname + "'s key cannot be detached.");
            }
            else if (choice == "no auto tp")
            {
                alwaysavailable = FALSE;
                llOwnerSay("@accepttp=rem");
                llSay(PUBLIC_CHANNEL, dollname + " can reject teleport offers.");
            }
            else if (choice == "auto tp")
            {
                alwaysavailable = TRUE;
                llSay(PUBLIC_CHANNEL, dollname + " cannot reject teleport offers.");
                llOwnerSay("@accepttp=add");
            }
            else if (choice == "can travel")
            {
                stuck = FALSE;
                llOwnerSay("@tplm=y,tploc=y");
                llSay(PUBLIC_CHANNEL, dollname + " may travel on her own initiative.");
            }
            else if (choice == "no self trav")
            {
                llSay(PUBLIC_CHANNEL, dollname + " is now a helpless doll and cannot travel on her own initiative.");
                llOwnerSay("@tplm=n,tploc=n");
                stuck = TRUE;
            }
            else if (choice == "drop control")
            {
                llSay(PUBLIC_CHANNEL, dollname + "'s controller has given up control.");
                MistressID = ChristinaID;
                hascontroller = FALSE;
            }
            else if (choice == "no plsr doll")
            {
                llSay(PUBLIC_CHANNEL, dollname + " is not a pleasure doll.");
                pleasuredoll = FALSE;
            }
            else if (choice == "make plsrdll")
            {
                llSay(PUBLIC_CHANNEL, dollname + " has been made into a pleasure doll.");
                pleasuredoll = TRUE;    
            }
            else if (choice == "can fly")
            {
                canfly = TRUE;
                llOwnerSay("@fly=y");
                llSay(PUBLIC_CHANNEL, dollname + " can fly.");
            }
            else if (choice == "no flying")
            {
                canfly = FALSE;
                llOwnerSay("@fly=n");
                llSay(PUBLIC_CHANNEL, dollname + " cannot fly.");
            }
           else if (choice == "start afk")
            {
                startafk();
                afk = TRUE;
                llRegionSayTo(id, PUBLIC_CHANNEL, dollname + " is now in AFK mode and won't unwind.");
            }
            else if (choice == "stop afk")
            {
                stopafk();
                afk = FALSE;
                timeleftonkey =  timeleftonkey / 2;
                llRegionSayTo(id, PUBLIC_CHANNEL, dollname + " is no longer in AFK mode and will wind down again.");
            }
        }
        else if (channel == cd4667 && id == carrierID)
        {
            if (choice == "Top")
            {
                llOwnerSay("@detach:stomach=force,detach:left shoulder=force,detach:right shoulder=force,detach:left hand=force,detach:right hand=force,detach:r upper arm=force,detach:r forearm=force,detach:l upper arm=force,detach:l forearm=force,detach:chest=force,detach:left pec=force,detach:right pec=force");
                llOwnerSay("@remoutfit:gloves=force,remoutfit:jacket=force,remoutfit:shirt=force");
            }
            else if (choice == "Bra")
            {
                llOwnerSay("@remoutfit:undershirt=force");
            }
            else if (choice == "Bottom")
            {
                llOwnerSay("@detach:chin=force,detach:r lower leg=force,detach:l lower leg=force,detach:pelvis=force,detach:right hip=force,detach:left hip=force,detach");
                llOwnerSay("@remoutfit:pants=force,remoutfit:skirt=force");
            }
            else if (choice == "Panties")
            {
                llOwnerSay("@remoutfit:underpants=force");
            }
            else if (choice == "Shoes")
            {
                llOwnerSay("@detach:right foot=force,detach:left foot=force");
                llOwnerSay("@remoutfit:shoes=force,remoutfit:socks=force");
            }
            llDialog(id, "Take off:",["Top","Bra","Bottom","Panties","Shoes"], cd4667);
        }
        else if (channel == channel_dialog)
        {
            handlemenuchoices(choice, name, id);
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            if (pose && llStringLength(currentanimation) > 0)
            {
                llStopAnimation(currentanimation);
                llSleep(0.1);
            }
            if (llStringLength(newanimation) > 0)
            {
                aochange("off");
                llStartAnimation(newanimation);
                currentanimation = newanimation;
                newanimation = "";
                posetime = poselimit;
                pose = TRUE;
            }
            else
            {
                aochange("on");
                pose = FALSE;
                currentanimation = "";
            }
        }
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT |
                           CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN | CONTROL_LBUTTON, TRUE, !(pose || collapsed));
        }
    }
}