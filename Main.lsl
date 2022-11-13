// Variables that don't need to transfer between keys
key ChristinaID = "42c7aaec-38bc-4b0c-94dd-ae562eb67e6d";
key mainwinder = "64d26535-f390-4dc4-a371-a712b946daf8";
string dollname;
string wardrobeURL;
key dollID;

integer channel_dialog;
integer key_listen;
integer key_listen_time;
integer key_startup;
string key_size;

// assuming a clock interval of 10
integer windamount = 360; //1 hour
integer keylimit =   1800; //5 hours
integer poselimit =  30;  //5 minutes

list dialogUsers; // [key, listenhandle, timestamp, menu]

string newanimation;
integer posetime;
integer phrasetime;

key kQueryBody;
key kQueryState;
key kQueryStateLen;
key kQueryStartup;
key transformer;
integer num_phrases;
integer bodyLine;
integer startupLine;

key carrierID;

// Variables to transfer between keys
key MistressID;
integer visible = TRUE;
integer detachable = TRUE;
integer alwaysavailable;
integer pleasuredoll;
integer stuck;
integer canfly = TRUE;
integer winddown = TRUE;
integer afk;
integer wardrobelocked;

integer candress = TRUE;
integer canbecomemistress;

integer needsagree;
integer seesphrases = TRUE;

string currentstate;
string currentbody;

integer timeleftonkey = 360;
string currentanimation;

integer create_or_get_listen(key id)
{
    integer pos = llListFindList(dialogUsers, [id]);
    if (~pos)
    {
        update_dialog_timestamp(id, "main");
        return TRUE;
    }
    else if (llGetListLength(dialogUsers) >= 8)
    {
        return FALSE;
    }
    dialogUsers += [id, llListen(channel_dialog, "", id, ""), llGetUnixTime(), "main"];
    return TRUE;
}

update_dialog_timestamp(key id, string menu)
{
    integer pos = llListFindList(dialogUsers, [id]);
    if (~pos)
    {
        dialogUsers = llListReplaceList(dialogUsers, [llGetUnixTime(), menu], pos+2, pos+3);
    }
}

delete_listener(key id)
{
    integer pos = llListFindList(dialogUsers, [id]);
    if (~pos)
    {
        llListenRemove(llList2Integer(dialogUsers,pos+1));
        dialogUsers = llListReplaceList(dialogUsers, [], pos, pos+3);
    }
}

clear_old_dialogs(integer clearAll)
{
    integer numDialogs = llGetListLength(dialogUsers)/4;
    integer curTime = llGetUnixTime();
    integer i;
    for (i = 0; i < numDialogs; ++i)
    {
        if (clearAll || curTime - llList2Integer(dialogUsers, i*4+2)  > 60)
        {
            key oldListen = llList2Key(dialogUsers, i*4);
            if (!clearAll)
            {
                llRegionSayTo(oldListen, PUBLIC_CHANNEL, "Menu timed out.");
            }
            delete_listener(oldListen);
        }
    }
}

string checkbox(integer checkVar)
{
    if (checkVar)
    {
        return "☑";
    }
    return "☐";
}

start_key_listen()
{
    if (!key_listen)
    {
        key_listen = llListen(channel_dialog-1, "", NULL_KEY, "");
        key_listen_time = llGetUnixTime();
    }
}

stop_key_listen()
{
    if (!key_listen)
    {
        return;
    }
    llListenRemove(key_listen);
    key_listen = 0;
    key_listen_time = 0;
}

load_phrases()
{
    if (llGetInventoryType("State-"+currentstate) == INVENTORY_NOTECARD)
    {
        kQueryStateLen = llGetNumberOfNotecardLines("State-"+currentstate);
    }
    else
    {
        num_phrases = 0;
    }
}

send_key_settings(key id)
{
    stop_key_listen();
    llRegionSayTo(id, channel_dialog-1, (string)MistressID+","+currentstate+","+(string)visible+","+(string)detachable+","+(string)alwaysavailable
                                        +","+(string)pleasuredoll+","+(string)stuck+","+(string)canfly+","+(string)winddown+","+(string)afk
                                        +","+(string)needsagree+","+(string)seesphrases+","+(string)candress+","+(string)canbecomemistress
                                        +","+(string)timeleftonkey+","+currentanimation+","+currentbody+","+(string)wardrobelocked);
    clear_old_dialogs(TRUE);
    currentstate = "";
    llOwnerSay("@clear");
    llSleep(1);
    llRequestPermissions(dollID, PERMISSION_ATTACH);
}

read_key_settings(string settings)
{
    stop_key_listen();
    list oldkey = llParseStringKeepNulls(settings, [","], []);
    MistressID = llList2String(oldkey, 0);
    currentstate = llList2String(oldkey, 1);
    visible = llList2Integer(oldkey, 2);
    detachable = llList2Integer(oldkey, 3);
    alwaysavailable = llList2Integer(oldkey, 4);
    pleasuredoll = llList2Integer(oldkey, 5);
    stuck = llList2Integer(oldkey, 6);
    canfly = llList2Integer(oldkey, 7);
    winddown = llList2Integer(oldkey, 8);
    afk = llList2Integer(oldkey, 9);
    needsagree = llList2Integer(oldkey, 10);
    seesphrases = llList2Integer(oldkey, 11);
    candress = llList2Integer(oldkey, 12);
    canbecomemistress = llList2Integer(oldkey, 13);
    timeleftonkey = llList2Integer(oldkey, 14);
    currentanimation = llList2String(oldkey, 15);
    currentbody = llList2String(oldkey, 16);
    wardrobelocked = llList2Integer(oldkey, 17);

    llMessageLinked(LINK_ALL_CHILDREN, 17, currentstate, "");
    load_phrases();
    if (llGetInventoryType("Body-"+currentbody) == INVENTORY_NOTECARD)
    {
        bodyLine = 0;
        kQueryBody = llGetNotecardLine("Body-"+currentbody,0);
    }

    llSleep(2);
    llMessageLinked(LINK_THIS, 4110, (string)wardrobelocked, "-1");
}

handlemenuchoices(string choice, key ToucherID)
{
    string name = "secondlife:///app/agent/" + (string)ToucherID + "/displayname";
    if (choice == "Exit" || choice == "-")
    {
        delete_listener(ToucherID);
    }
    else if (choice == "Carry")
    {
        delete_listener(ToucherID);
        if (carrierID)
        {
            uncarry();
            llSleep(0.5);
        }
        carrierID = ToucherID;
        RefreshRLV();
        llSay(PUBLIC_CHANNEL, dollname + " has been picked up by " + name);
        llOwnerSay("@adjustheight:25=force");
        if (currentanimation == "")
        {
            animate("beautystand");
        }
    }
    else if (choice == "Place Down")
    {
        delete_listener(ToucherID);
        uncarry();
    }
    else if (choice == "Body")
    {
        llOwnerSay(name + " is looking at your Transform options.");
        string mode = "";
        if (currentstate == "Bimbo")
        {
            mode = ".Candi";
        }
        show_transform_dialog(mode, ToucherID);
    }
    else if (choice == "Mode")
    {
        update_dialog_timestamp(ToucherID, "state");
        string msg = "These change the personality of " + dollname + " She is currently a " + currentstate + " doll. What type of doll do you want her to be?";
        llOwnerSay(name + " is looking at your Modes.");
        integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
        list choices = [];
        while(n)
        {
            list note = llParseStringKeepNulls(llGetInventoryName(INVENTORY_NOTECARD, --n), ["-"], []);
            if (llList2String(note, 0) == "State")
            {
                string mode = llList2String(note, 1);
                if (mode != "Regular" || ToucherID == dollID || ToucherID == MistressID)
                {
                    choices += mode;
                }
            }
        }

        llDialog(ToucherID, msg, choices, channel_dialog);
    }
    else if (choice == "Pose")
    {
        update_dialog_timestamp(ToucherID, "pose");
        list poses = [];
        integer n = llGetInventoryNumber(INVENTORY_ANIMATION);
        if (n > 11)
        {
            n = 11;
        }
        while(n)
        {
            string thispose = llGetInventoryName(INVENTORY_ANIMATION, --n);
            if (thispose != "collapse")
            {
                poses += thispose;
            }
        }

        llDialog(ToucherID, "Choose a pose", poses , channel_dialog);
    }
    else if (choice == "Unpose")
    {
        delete_listener(ToucherID);
        if (timeleftonkey)
        {
            llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
        }
    }
    else if (choice == "☑ Takeover")
    {
        llOwnerSay("There is no option for someone to become your controller.");
        canbecomemistress = FALSE;
    }
    else if (choice == "☐ Takeover")
    {
        llOwnerSay("Anyone carrying you can choose to be your controller.");
        canbecomemistress = TRUE;
    }
    else if (choice == "Wind")
    {
        delete_listener(ToucherID);
        if (!timeleftonkey)
        {
            // Uncollapsing
            timeleftonkey = windamount;
            RefreshRLV();

            if (currentstate == "Display")
            {
                newanimation = "beautystand";
            }
            llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
        }
        else
        {
            timeleftonkey += windamount;
            if (timeleftonkey > keylimit)
            {
                timeleftonkey = keylimit;
                llSay(PUBLIC_CHANNEL, dollname + "'s time has reached her limit");
            }
        }
        llSay(PUBLIC_CHANNEL, " -- " + name + " has given " + dollname + " 1 hour of life.");

        windanimate(3);
    }

    else if (choice == "Dress")
    {
        dressmenu(ToucherID);
        llOwnerSay(name + " is looking at your dress menu");
    }

    else if (choice == "Strip" && carrierID == ToucherID)
    {
        update_dialog_timestamp(ToucherID, "strip");
        llDialog(ToucherID, "Take off:",["Top","Bra","Bottom","Panties","Shoes"], channel_dialog);
    }

    else if (choice == "Be Controller" && MistressID == NULL_KEY && canbecomemistress && carrierID == ToucherID)
    {
        delete_listener(ToucherID);
        canbecomemistress = FALSE;
        MistressID = ToucherID;
        llOwnerSay("The person carrying you has taken over as your controller.");
        string msg = "You are now " + dollname + "'s controller. See http://CommunityDolls.com/controller.htm";
        RefreshRLV();
        llDialog(ToucherID,msg,["Exit"] , 9999);
    }
    else if (choice == "Options")
    {
        string msg = "See http://CommunityDolls.com/controller.htm Choose what you want to happen";
        list pluslist;
        integer ToucherIsOwner = FALSE;
        if (ToucherID == dollID)
        {
            // We're accessing our own options
            msg = "See http://CommunityDolls.com/keychoices.htm for explanation.";
            pluslist = [checkbox(!needsagree) + " Automatic", checkbox(seesphrases) + " Phrases", checkbox(candress) + " Dressing", "ResetCTS"];
        }
        else if (ToucherID == MistressID || ToucherID == ChristinaID)
        {
            // Owner is accessing our options
            pluslist = ["Drop control"];
            ToucherIsOwner = TRUE;
        }
        update_dialog_timestamp(ToucherID, "options");
        pluslist += [checkbox(afk) + " AFK"];

        if (ToucherIsOwner || (carrierID == NULL_KEY && ToucherID == dollID))
        {
            if (detachable)
            {
                pluslist += ["☑ Detachable", "Take off key"];
            }
            else if (ToucherIsOwner)
            {
                pluslist += ["☐ Detachable", "Take off key"];
            }

            if (!alwaysavailable)
            {
                pluslist += "☐ Auto TP";
            }
            else if (ToucherIsOwner)
            {
                pluslist += "☑ Auto TP";
            }

            if (!stuck)
            {
                pluslist += "☑ Self TP";
            }
            else if (ToucherIsOwner)
            {
                pluslist += "☐ Self TP";
            }

            if (canfly)
            {
                pluslist += "☑ Flying";
            }
            else if (ToucherIsOwner)
            {
                pluslist += "☐ Flying";
            }

            pluslist += [checkbox(pleasuredoll) + " Pleasure"];
        }
        pluslist += [checkbox(visible) + " Visible"];
        llDialog(ToucherID, msg, pluslist, channel_dialog);
    }
}

optionsmenu(string choice, key id)
{
    if (id == MistressID || id == ChristinaID || id == dollID)
    {
        if (choice == "☑ Automatic" || choice == "☐ Automatic")
        {
            needsagree = !needsagree;
        }
        else if (choice == "☑ Phrases" || choice == "☐ Phrases")
        {
            seesphrases = !seesphrases;
        }
        else if (choice == "☑ Detachable")
        {
            detachable = FALSE;
            llOwnerSay("Your key cannot be detached.");
        }
        else if (choice == "☐ Detachable")
        {
            detachable = TRUE;
            llOwnerSay("Your key can be detached.");
        }
        else if (choice == "☐ Auto TP")
        {
            llOwnerSay("You must accept all tp offers.");
            alwaysavailable = TRUE;
            RefreshRLV();
        }
        else if (choice == "☑ Auto TP")
        {
            alwaysavailable = FALSE;
            RefreshRLV();
            llOwnerSay("You can reject teleport offers.");
        }
        else if (choice == "☐ Pleasure")
        {
            llOwnerSay("Your key thinks you are a pleasure doll.");
            pleasuredoll = TRUE;
        }
        else if (choice == "☑ Pleasure")
        {
            llOwnerSay("Your key does not treat you like a pleasure doll.");
            pleasuredoll = FALSE;
        }
        else if (choice == "☑ Self TP")
        {
            llOwnerSay("Helpless doll! You cannot teleport yourself.");
            stuck = TRUE;
            RefreshRLV();
        }
        else if (choice == "☐ Self TP")
        {
            stuck = FALSE;
            RefreshRLV();
            llOwnerSay("You may travel on your own initiative.");
        }
        else if (choice == "☐ Dressing")
        {
            llOwnerSay("Other people can dress you.");
            candress = TRUE;
        }
        else if (choice == "☑ Dressing")
        {
            llOwnerSay("Other people cannot dress you.");
            candress = FALSE;
        }
        else if (choice == "Drop control")
        {
            llSay(PUBLIC_CHANNEL, dollname + "'s controller has given up control.");
            llOwnerSay("@tplure:" + (string) MistressID + "=rem,accepttp:" + (string) MistressID + "=rem");
            MistressID = NULL_KEY;
            RefreshRLV();
        }
        else if (choice == "Take off key")
        {
            aochange("on");
            llOwnerSay("@clear");
            llOwnerSay("Your key has been taken off.");
            llRequestPermissions(dollID, PERMISSION_ATTACH);
            return;
        }
        else if (choice == "☑ Flying")
        {
            canfly = FALSE;
            RefreshRLV();
            llOwnerSay("You have given up your ability to fly. Helpless dolly!");
        }
        else if (choice == "☐ Flying")
        {
            canfly = TRUE;
            RefreshRLV();
            llOwnerSay("You can fly again.");
        }
    }
    if (choice == "☑ Visible")
    {
        visible = FALSE;
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    }
    else if (choice == "☐ Visible")
    {
        visible = TRUE;
        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
    }
    else if (choice == "☐ AFK")
    {
        startafk();
    }
    else if (choice == "☑ AFK")
    {
        stopafk();
        timeleftonkey =  timeleftonkey / 2;
    }
    else if (choice == "ResetCTS")
    {
        llResetOtherScript("Wear");
        llOwnerSay("CTS Wardrobe Reset");
    }

    handlemenuchoices("Options", id);
}

stripmenu(string choice, key id)
{
    if (choice == "Top")
    {
        llOwnerSay("@detachallthis:gloves=force,detachallthis:jacket=force,detachallthis:shirt=force");
    }
    else if (choice == "Bra")
    {
        llOwnerSay("@detachallthis:undershirt=force");
    }
    else if (choice == "Bottom")
    {
        llOwnerSay("@detachallthis:pants=force,detachallthis:skirt=force");
    }
    else if (choice == "Panties")
    {
        llOwnerSay("@detachallthis:underpants=force");
    }
    else if (choice == "Shoes")
    {
        llOwnerSay("@detachallthis:shoes=force,detachallthis:socks=force");
    }
    else
    {
        return;
    }
    update_dialog_timestamp(id, "strip");
    llDialog(id, "Take off:",["Top","Bra","Bottom","Panties","Shoes"], channel_dialog);
}

dressmenu(key id)
{
    // Open dress menu
    delete_listener(id);
    if (wardrobeURL)
    {
        llLoadURL(id, "Please choose an outfit at this website.", wardrobeURL);
    }
    else
    {
        llDialog(id, "No outfits found", ["Exit"], 9999);
    }
}

show_transform_dialog(string subtype, key id)
{
    update_dialog_timestamp(id, "transform|"+subtype);
    string msg = "These change the body of " + dollname + ". She is currently a " + currentbody + " doll. What type of doll do you want her to be?";
    integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
    list choices = [];
    while(n)
    {
        list note = llParseStringKeepNulls(llGetInventoryName(INVENTORY_NOTECARD, --n), ["-"], []);
        if (llList2String(note, 0) == "Body")
        {
            if (subtype)
            {
                if (llList2String(note, 1) == subtype)
                {
                    choices += llList2String(note, 2);
                }
            }
            else
            {
                string choice = llList2String(note, 1);
                if (!~llListFindList(choices, (list)choice) && llGetSubString(choice, 0, 0) != ".")
                {
                    choices += choice;
                }
            }
        }
    }

    llDialog(id, msg, choices, channel_dialog);
}

transformmenu(string choice, string subchoice, key id, integer confirmed)
{
    if (subchoice == "")
    {
        show_transform_dialog(choice, id);
        return;
    }

    if (id != dollID && needsagree && !confirmed)
    {
        if(!create_or_get_listen(dollID))
        {
            llDialog(id, "The doll cannot transform at this time, please try again later.", ["Exit"], 9999);
            return;
        }
        update_dialog_timestamp(id, "transform");
        update_dialog_timestamp(dollID, "transform_confirm");
        list choices = [choice,"I cannot"];
        string msg = "Can you make this change?";
        llDialog(dollID, msg, choices, channel_dialog);
        return;
    }

    string newbody = choice;
    if (subchoice)
    {
        newbody = subchoice + "-" + choice;
    }

    if (llGetInventoryType("Body-"+newbody) == INVENTORY_NOTECARD)
    {
        currentbody = newbody;
        bodyLine = 0;
        transformer = id;
        delete_listener(id);

        kQueryBody = llGetNotecardLine("Body-"+newbody,0);

        llSleep(1.0);

        llSay(0, dollname + " has changed to a " + choice + " body.");
    }
}

statemenu(string choice, key id)
{
    if (llGetInventoryType("State-"+choice) == INVENTORY_NOTECARD)
    {
        currentstate = choice;
        llMessageLinked(LINK_ALL_CHILDREN, 17, currentstate, "");
        load_phrases();
        delete_listener(id);
        // Changes over to current state being new state
        if (currentstate == "Display")
        {
            animate("beautystand");
        }
        else
        {
            animate("");
        }

        if (currentstate == "Builder" || currentstate == "Key")
        {
            winddown = FALSE;
        }
        else
        {
            winddown = TRUE;
        }

        llSleep(1.0);

        llSay(0, dollname + " has become a " + currentstate + " Doll.");
    }
}

animate(string animation)
{
    newanimation = animation;
    llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
}

startafk()
{
    winddown = FALSE;
    afk = TRUE;

    llTargetOmega(ZERO_VECTOR, 0.0, 0.0);
    RefreshRLV();
}

stopafk()
{
    winddown = TRUE;
    afk = FALSE;

    if (!timeleftonkey)
    {
        return;
    }

    llTargetOmega(<0.0, 0.0, 1.0>, 3.0, 1.0);
    llSleep(2.0);
    llTargetOmega(<0.0, 0.0, 1.0>, 2.0, 1.0);
    llSleep(1.0);
    llTargetOmega(<0.0, 0.0, 1.0>, 1.0, 1.0);
    llSleep(1.0);
    llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 1.0);

    RefreshRLV();
}

collapse()
{
    string animation;
    if(llGetAgentInfo(dollID) & AGENT_SITTING)
    {
        animation = "away";
    }
    else
    {
        animation = "collapse";
    }

    llTargetOmega(ZERO_VECTOR, 0, 0);
    visible = TRUE;
    animate(animation);
    llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
    RefreshRLV();
}

aochange(string choice)
{
    integer g_iAOChannel = -782690;

    integer g_iInterfaceChannel = -llAbs((integer)("0x" + llGetSubString(dollID,30,-1)));
    string aocmd;
    if (choice == "off")
    {
        aocmd = "ZHAO_AOOFF";
    }
    else
    {
        aocmd = "ZHAO_AOON";
    }

    llWhisper(g_iInterfaceChannel, "CollarCommand|499|" + aocmd);
    llWhisper(g_iAOChannel, aocmd);
    llMessageLinked(LINK_SET, 0, aocmd, NULL_KEY);

    if (llGetAgentInfo(dollID) & AGENT_SITTING)
    {
        // Wait a little bit so that the AO has time to process things
        llSleep(1.0);
        llStopAnimation("sit");
        llSleep(0.1);
    }
}

uncarry()
{
    if (carrierID != MistressID)
    {
        llOwnerSay("@tplure:" + (string)carrierID + "=rem,accepttp:" + (string)carrierID + "=rem");
    }
    llSay(PUBLIC_CHANNEL, dollname + " has been set down.");
    llOwnerSay("@adjustheight:0=force");
    if (currentstate != "Display")
    {
        animate("");
    }
    carrierID = NULL_KEY;
    RefreshRLV();
}

// Things to do every time the key is worn or we log in
startup()
{
    if (!llGetAttached())
    {
        llTargetOmega(ZERO_VECTOR, 0, 0);
        llSetTimerEvent(0.0);
        llOwnerSay("@detach=y");
        llOwnerSay("Please detach your key and wear it on your spine");
        return;
    }
    // Clock is accessed every ten seconds;
    llSetTimerEvent(10.0);
    dollname = llGetDisplayName(dollID);
    llOwnerSay("@detach=n");

    key_startup = TRUE;
    load_phrases();

    if (currentstate)
    {
        startup_finish();
    }
    else
    {
        currentstate = "Regular";
        start_key_listen();
        llRegionSay(channel_dialog-1, "key_init");
    }
}

startup_finish()
{
    key_startup = FALSE;

    if(afk)
    {
        startafk();
    }
    else
    {
        llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 1.0);
    }

    if (!candress)
    {
        llOwnerSay("Other people cannot dress you.");
    }

    if (carrierID != NULL_KEY && carrierID != MistressID)
    {
        uncarry();
    }

    llSleep(5.0);
    if (timeleftonkey)
    {
        animate(currentanimation);
        RefreshRLV();
    }
    else
    {
        collapse();
    }
}

RefreshRLV()
{
    llOwnerSay("@detach=n");

    if (MistressID)
    {
        // Always allow the doll's owner to TP their doll
        llOwnerSay("@tplure:" + (string) MistressID + "=add,accepttp:" + (string) MistressID + "=add");
    }
    if (carrierID)
    {
        if (carrierID != MistressID)
        {
            llOwnerSay("@tplure:" + (string) carrierID + "=add,accepttp:" + (string) carrierID + "=add");
        }
        llOwnerSay("@accepttp=rem");
    }
    else if (alwaysavailable)
    {
        llOwnerSay("@accepttp=add");
    }
    else
    {
        llOwnerSay("@accepttp=rem");
    }

    if (timeleftonkey && !afk)
    {
        llOwnerSay("@accepttp:" + (string) ChristinaID + "=rem,tplure:" + (string) ChristinaID + "=rem");
        llOwnerSay("@temprun=y,alwaysrun=y,sendchat=y,sittp=y,standtp=y,unsit=y,sit=y,shownames=y,showhovertextall=y,rediremote:999=rem,accepttp:" + (string) mainwinder + "=rem,tplure:" + (string) mainwinder + "=rem");
        if (canfly)
        {
            llOwnerSay("@fly=y");
        }
        else
        {
            llOwnerSay("@fly=n");
        }

        if (carrierID == NULL_KEY)
        {
            llOwnerSay("@tplure=y");
            if (stuck)
            {
                llOwnerSay("@tplm=n,tploc=n");
            }
            else
            {
                llOwnerSay("@tplm=y,tploc=y");
            }
        }
        else
        {
            llOwnerSay("@tplm=n,tploc=n,tplure=n");
        }
    }
    else
    {
        llOwnerSay("@fly=n,temprun=n,alwaysrun=n,sendchat=n,tplm=n,tploc=n,sittp=n,standtp=n,accepttp:" + (string) mainwinder + "=add,tplure:" + (string) mainwinder + "=add,sit=n,shownames=n,showhovertextall=n,tplure=n");
        llOwnerSay("@rediremote:999=add");
        if (MistressID == NULL_KEY)
        {
            llOwnerSay("@accepttp:" + (string) ChristinaID + "=add,tplure:" + (string) ChristinaID + "=add");
        }
    }
}

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
        llPlaySound("07af5599-8529-fb12-5891-1dcf1a33ee49", 1.0);
        //       '- [Muniki K[_Clock Key Winding Up, Free Sound Effects (YTube)]
        llTargetOmega(<0.0, 0.0,-1.0>, 120.0*DEG_TO_RAD/0.5, 1.0);
        llSleep(0.5);  //              '- 60o in 0.5s
        llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 0.0);
        llSleep(0.5);
    }
    while (--i);
    if (winddown)
    {
        llTargetOmega(<0.0, 0.0, 1.0>, 0.3, 1.0);
    }
}

default
{
    state_entry()
    {
        // First time script setup
        dollID = llGetOwner();
        channel_dialog = -llAbs((integer)("0x" + llGetSubString(dollID,30,-1))) -1;
        startup();
    }

    on_rez(integer start_param)
    {
        startup();
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            llResetScript();
        }
        if (change & CHANGED_TELEPORT)
        {
            RefreshRLV();
        }
    }

    touch_end(integer total_number)
    {
        // Detects user UUID
        key ToucherID = llDetectedKey(0);

        if (key_listen)
        {
            // Abort immediately if we're in key setup phase
            llRegionSayTo(ToucherID, PUBLIC_CHANNEL, "Please wait a minute, the key is starting up.");
            return;
        }

        if (!llGetAttached())
        {
            llRegionSayTo(ToucherID, PUBLIC_CHANNEL, "The key must be attached to the doll's back before you can use it.");
            return;
        }

        vector pos = llDetectedPos(0);
        float dist = llVecDist(pos, llGetPos());
        if (dist > 10.0)
        {
            llRegionSayTo(ToucherID, PUBLIC_CHANNEL, "You are too far away to use the key. Please get closer and try again.");
            return;
        }
        if (!create_or_get_listen(ToucherID))
        {
            llRegionSayTo(ToucherID, PUBLIC_CHANNEL, "The key is too busy to be played with, please try again in a little bit.");
            return;
        }

        integer displaytime = (integer) ((timeleftonkey+5) / 6);
        string timeleft = "Time Left on key is " + (string)displaytime + " minutes. ";

        string msg;
        list menu = ["-", "Exit", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-"];

        if (ToucherID == dollID)
        {
            if (!timeleftonkey)
            {
                msg = "You need winding.";
            }
            else if (carrierID)
            {
                msg = "You are currently being carried";
                menu = llListReplaceList(menu, ["Options"], 2, 2);
            }
            else if (wardrobelocked)
            {
                msg = "You are locked out of your wardrobe";
                menu = llListReplaceList(menu, ["Options"], 2, 2);
            }
            else
            {
                msg = "See http://CommunityDolls.com/dollkeyselfinfo.htm\nYou are a " + currentstate + " doll with a " + currentbody + " body.";
                menu = llListReplaceList(menu, ["Options", "Body", "Dress", "Mode"], 2, 5);
                if (!posetime)
                {
                    menu = llListReplaceList(menu, ["Pose"], 8, 8);
                }
            }
            if (MistressID == NULL_KEY)
            {
                menu = llListReplaceList(menu, [checkbox(!canbecomemistress) + " Takeover"], 10, 10);
            }
        }
        else if (carrierID)
        {
            if (ToucherID == carrierID)
            {
                msg = "Place Down frees " + dollname + " when you are done with her";
                menu = llListReplaceList(menu, ["Wind"], 0, 0);
                menu = llListReplaceList(menu, ["Options"], 2, 2);
                menu = llListReplaceList(menu, ["Mode"], 5, 5);
                menu = llListReplaceList(menu, ["Pose", "Place Down"], 8, 9);
                if (candress)
                {
                    menu = llListReplaceList(menu, ["Body", "Dress"], 3, 4);
                }
                if (canbecomemistress)
                {
                    menu = llListReplaceList(menu, ["Be Controller"], 10, 10);
                }
                if (pleasuredoll || currentstate == "Slut")
                {
                    menu = llListReplaceList(menu, ["Strip"], 7, 7);
                }
            }
            else if (ToucherID == MistressID || ToucherID == ChristinaID)
            {
                menu = llListReplaceList(menu, ["Carry"], 6, 6);
            }
            else
            {
                msg = dollname + " is currently being carried. Sorry.";
            }
        }
        else if (timeleftonkey)
        {
            // Not being carried, not collapsed
            msg = dollname + " is a " + currentstate + " doll with a " + currentbody + " body and likes to be treated like a doll. So feel free to use these options. The Carry option picks up " + dollname + " and temporarily makes her exclusively yours. See http://CommunityDolls.com/communitydoll.htm for more info.";
            if (afk)
            {
                msg += " She is currently marked AFK.";
            }
            menu = llListReplaceList(menu, ["Wind"], 0, 0);
            menu = llListReplaceList(menu, ["Options"], 2, 2);
            menu = llListReplaceList(menu, ["Mode", "Carry"], 5, 6);
            menu = llListReplaceList(menu, ["Pose"], 8, 8);
            if (candress)
            {
                menu = llListReplaceList(menu, ["Body", "Dress"], 3, 4);
            }
            if (posetime)
            {
                menu = llListReplaceList(menu, ["Unpose"], 11, 11);
            }
        }
        else
        {
            menu = llListReplaceList(menu, ["Wind"], 0, 0);
            menu = llListReplaceList(menu, ["Options"], 2, 2);
        }

        llDialog(ToucherID, timeleft + msg,  menu, channel_dialog);
        if(ToucherID != dollID)
        {
            llPlaySound("07af5599-8529-fb12-5891-1dcf1a33ee49", 0.0);
        }
    }

    timer()
    {
        if (startupLine != -1)
        {
            kQueryStartup = llGetNotecardLine("Startup-Messages",startupLine);
        }
        if (key_listen)
        {
            if (llGetUnixTime()-key_listen_time > 60)
            {
                stop_key_listen();

                if (key_startup)
                {
                    startup_finish();
                }
            }
            else if (key_startup)
            {
                llRegionSay(channel_dialog-1, "key_init");
            }
            return;
        }

        // Called every time interval
        if (winddown && timeleftonkey)
        {
            if (!--timeleftonkey)
            {
                collapse();
                llSay(PUBLIC_CHANNEL, dollname + " has run out of life");
            }
        }
        if (posetime)
        {
            if (timeleftonkey && currentstate != "Display" && carrierID == NULL_KEY)
            {
                if (!--posetime)
                {
                    animate("");
                }
            }
        }
        if (carrierID)
        {
            if (!posetime)
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
        if (!timeleftonkey)
        {
            if(!(llGetAgentInfo(dollID) & AGENT_SITTING) && currentanimation == "away")
            {
                animate("collapse");
            }
        }
        if (llGetListLength(dialogUsers) > 0)
        {
            clear_old_dialogs(FALSE);
        }
        if (seesphrases)
        {
            if (++phrasetime >= 12)
            {
                phrasetime = 0;
                integer i = (integer) llFrand(num_phrases);
                if (currentstate)
                {
                    kQueryState = llGetNotecardLine("State-"+currentstate,i);
                }
            }
        }
     }

     link_message(integer source, integer num, string choice, key id)
     {
        if (num == 2060)
        {
            if (~llSubStringIndex(choice, "CTS/!Full Avatars"))
            {
                start_key_listen();
            }
        }
        else if (num == 4110)
        {
            // Wardrobe locking
            if (choice == "1")
            {
                wardrobelocked = TRUE;
            }
            else
            {
                wardrobelocked = FALSE;
            }
        }

    }

    listen(integer channel, string name, key id, string choice)
    {
        if (channel == channel_dialog)
        {
            integer pos = llListFindList(dialogUsers, [id]);
            if (pos == -1)
            {
                return;
            }
            list menulist = llParseStringKeepNulls(llList2Key(dialogUsers, pos+3), ["|"], []);
            string menu = llList2String(menulist, 0);
            string submenu = "";
            if (llGetListLength(menulist) > 1)
            {
                submenu = llList2String(menulist, 1);
            }

            if (menu == "main")
            {
                handlemenuchoices(choice, id);
            }
            else if (menu == "pose")
            {
                if (timeleftonkey)
                {
                    animate(choice);
                    llOwnerSay("You are being posed");
                }
            }
            else if (menu == "transform")
            {
                transformmenu(choice, submenu, id, FALSE);
            }
            else if (menu == "transform_confirm")
            {
                transformmenu(choice, submenu, id, TRUE);
            }
            else if (menu == "state")
            {
                statemenu(choice, id);
            }
            else if (menu == "options")
            {
                optionsmenu(choice, id);
            }
            else if (menu == "strip")
            {
                stripmenu(choice, id);
            }
        }
        else if (channel == channel_dialog-1)
        {
            // Communication between two keys
            if (llGetOwnerKey(id) != dollID)
            {
                // Abort if it's not from something the doll owns
                return;
            }
            if (key_startup)
            {
                read_key_settings(choice);
            }
            else if (choice == "key_init")
            {
                send_key_settings(id);
            }
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id == kQueryBody)
        {
            if (data != EOF)
            {
                if (data)
                {
                    list curline = llParseStringKeepNulls(data, ["="], []);
                    string curopt = llList2String(curline, 0);
                    string curdata = llList2String(curline, 1);
                    if (curopt == "URL")
                    {
                        // Set wardrobe URL
                        wardrobeURL = llGetSubString(data, llSubStringIndex(data, "=")+1, -1);
                    }
                    else if (curopt == "Outfit")
                    {
                        if (!key_startup)
                        {
                            llOwnerSay("@sharedwear=y,sharedunwear=y,unsharedwear=y,unsharedunwear=y");
                            llOwnerSay("@detachallthis:"+curdata+"=n");
                            llOwnerSay("@remoutfit=force,detach=force");
                            llOwnerSay("@attachover:"+curdata+"=force");
                            llOwnerSay("@detachallthis:"+curdata+"=y");
                        }
                    }
                    else if (curopt == "Folders")
                    {
                        llMessageLinked(LINK_THIS, 52, curdata, NULL_KEY);
                    }
                    else if (curopt == "KeySize")
                    {
                        if (key_size != curdata)
                        {
                            key_size = curdata;
                            if (!key_startup)
                            {
                                start_key_listen();
                            }
                        }
                    }
                }
                ++bodyLine;
                kQueryBody = llGetNotecardLine("Body-"+currentbody,bodyLine);
            }
            else
            {
                if (key_startup)
                {
                    startup_finish();
                }
                else
                {
                    if (!key_listen)
                    {
                        llSleep(15.0);
                        if (timeleftonkey)
                        {
                            animate(currentanimation);
                        }
                        else
                        {
                            collapse();
                        }
                    }
                    dressmenu(transformer);
                }
            }
        }
        else if (query_id == kQueryState)
        {
            if (data != EOF)
            {
                if (llGetSubString(data,0,0) == "*")
                {
                    data = llGetSubString(data,1,-1);
                    float r = llFrand(3);
                    if (r < 1.0)
                    {
                        data = "*** feel your need to " + data;
                    }
                    else if (r < 2.0)
                    {
                        data = "*** feel your desire to " + data;
                    }
                    else
                    {
                        if (currentstate  == "Domme")
                        {
                            data = "*** You like to " + data;
                        }
                        else
                        {
                            data = "*** feel how people like you to " + data;
                        }
                    }
                }
                else
                {
                    data = "*** " + data;
                }
                if (currentstate == "Regular")
                {
                    data += " ***";
                }
                else
                {
                    data += ", " + currentstate + " Doll ***";
                }
                llOwnerSay(data);
            }
        }
        else if (query_id == kQueryStartup)
        {
            if (data == EOF)
            {
                startupLine = -1;
            }
            else
            {
                ++startupLine;
                llOwnerSay(data);
            }
        }
        else if (query_id == kQueryStateLen)
        {
            num_phrases = (integer)data;
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            if (currentanimation)
            {
                llStopAnimation(currentanimation);
                llSleep(0.1);
            }
            if (newanimation)
            {
                aochange("off");
                llStartAnimation(newanimation);
                currentanimation = newanimation;
                newanimation = "";
                posetime = poselimit;
            }
            else
            {
                aochange("on");
                posetime = 0;
                currentanimation = "";
            }
        }
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT |
                           CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN | CONTROL_LBUTTON, TRUE, timeleftonkey && !posetime);
        }
        if(perm & PERMISSION_ATTACH)
        {
            llDetachFromAvatar();
            return;
        }
    }
}