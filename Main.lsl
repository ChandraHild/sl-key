// Variables that don't need to transfer between keys
key ChristinaID = "42c7aaec-38bc-4b0c-94dd-ae562eb67e6d";
key mainwinder = "64d26535-f390-4dc4-a371-a712b946daf8";
string dollname;
string httpstart = "See http://CommunityDolls.com/";
string wardrobeURL = "";
key dollID;

integer channel_dialog;
integer key_listen = 0;
integer key_listen_time = 0;
integer key_startup;

// assuming a clock interval of 10
integer windamount = 360; //1 hour
integer keylimit =   1800; //5 hours
integer poselimit =  30;  //5 minutes

list poses;
list types;
list currentphrases;
list dialogUsers; // [key, listenhandle, timestamp, menu]

string newanimation;
integer posetime;
integer phrasetime;

key kQuery;
key transformer;
integer notecardLine;

key carrierID;

integer firstStart;
list startupMessages = [ "Dolls are now your sisters. They understand you. Feel that.",
                         "Feel how beautiful you are. You were always beautiful. It is now just more obvious because you are a doll.",
                         "Tendrils from the key have grown into your body. The key is becoming a part of you. Imagine that as vividly as you can",
                         "You are now dependent on other people for life. Everyone is dependent. We dolls are just much more dependent. We dolls just feel it more. You now accept that.",
                         "Feel how wonderful it is to be liked. Everyone wants to be liked. We dolls just feel it more. You now accept that.",
                         "Feel how wonderful it would be to be displayed and everyone just admire you for your beauty.",
                         "The hormones are relaxing you and making you feel comfortable with being a doll. Imagine that as vividly as you can.",
                         "The tendrils are releasing doll hormones into your body. Imagine that as vividly as you can.", 
                         "Tendrils from the key are growing into your back. Imagine that as vividly as you can",
                         "You feel a key being put on your back. Imagine that as vividly as you can." ];

// Variables to transfer between keys
key MistressID;
integer visible;
integer detachable;
integer alwaysavailable;
integer pleasuredoll;
integer stuck;
integer canfly;
integer winddown;
integer afk;

integer candress;
integer canbecomemistress;

integer needsagree;
integer seesphrases;

string currentstate;

integer timeleftonkey;
string currentanimation;

integer create_or_get_listen(key id)
{
    integer pos = llListFindList(dialogUsers, [id]);
    if (~pos)
    {
        update_dialog_timestamp(id, "main");
        return TRUE;
    }
    else if (llGetListLength(dialogUsers) >= 12)
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
    for (i = 0; i < numDialogs; i++)
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

send_key_settings(key id)
{
    stop_key_listen();
    llRegionSayTo(id, channel_dialog-1, (string)MistressID+","+currentstate+","+(string)visible+","+(string)detachable+","+(string)alwaysavailable
                                        +","+(string)pleasuredoll+","+(string)stuck+","+(string)canfly+","+(string)winddown+","+(string)afk
                                        +","+(string)needsagree+","+(string)seesphrases+","+(string)candress+","+(string)canbecomemistress
                                        +","+(string)timeleftonkey+","+currentanimation);
    clear_old_dialogs(TRUE);
    llSleep(1.0);
    llOwnerSay("@clear,detachme=force");
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

    if (~llListFindList(types, (list)currentstate))
    {
        notecardLine = 0;
        kQuery = llGetNotecardLine(currentstate,0);
    }
}

handlemenuchoices(string choice, key ToucherID)
{
    string name = "secondlife:///app/agent/" + (string)ToucherID + "/displayname";
    if (choice == "Carry")
    {
        delete_listener(ToucherID);
        if (carrierID)
        {
            uncarry();
            llSleep(0.5);
        }
        carrierID = ToucherID;
        if (alwaysavailable)
        {
            // Disable auto TP while we're carried
            llOwnerSay("@accepttp=rem");
        }
        if (carrierID != MistressID)
        {
            llOwnerSay("@tplure:" + (string) carrierID + "=add,accepttp:" + (string) carrierID + "=add");
        }
        llOwnerSay("@tplm=n,tploc=n,tplure=n");
        llSay(PUBLIC_CHANNEL, dollname + " has been picked up by " + name);
    }
    else if (choice == "Place Down")
    {
        delete_listener(ToucherID);
        uncarry();
    }
    else if (choice == "Type of Doll")
    {
        update_dialog_timestamp(ToucherID, "transform");
        string msg = "These change the personality of " + dollname + " She is currently a " + currentstate + ". What type of doll do you want her to be?";
        llOwnerSay(name + " is looking at your Transform options.");
        list choices = types;
        if (ToucherID == dollID)
        {
            choices += "CHOICES";
        }

        llDialog(ToucherID, msg, choices, channel_dialog);
    }
    else if (choice == "Pose")
    {
        update_dialog_timestamp(ToucherID, "pose");
        list poselist = poses;
        llDialog(ToucherID, "Choose a pose", poselist , channel_dialog);
    }
    else if (choice == "Unpose")
    {
        delete_listener(ToucherID);
        if (timeleftonkey)
        {
            llRequestPermissions(dollID, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
        }
    }
    else if (choice == "allow takeover")
    {
        delete_listener(ToucherID);
        canbecomemistress = TRUE;
    }
    else if (choice == "Wind")
    {
        delete_listener(ToucherID);
        if (!timeleftonkey)
        {
            // Uncollapsing
            timeleftonkey = windamount;
            //_M01C_llTargetOmega(<0,0,1>,.3,1.0);
            if (canfly)
            {
                llOwnerSay("@fly=y");
            }
            if (carrierID == NULL_KEY)
            {
                if (!stuck)
                {
                    llOwnerSay("@tplm=y,tploc=y");
                }
                llOwnerSay("@tplure=y");
            }
            llOwnerSay("@temprun=y,alwaysrun=y,sendchat=y,sittp=y,standtp=y,unsit=y,sit=y,shownames=y,showhovertextall=y,rediremote:999=rem,accepttp:" + (string) mainwinder + "=rem,tplure:" + (string) mainwinder + "=rem");
            if (MistressID == NULL_KEY)
            {
                llOwnerSay("@accepttp:" + (string) ChristinaID + "=rem,tplure:" + (string) ChristinaID + "=rem");
            }

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

        //_M05A
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
        llOwnerSay("@tplure:" + (string) MistressID + "=add,accepttp:" + (string) MistressID + "=add");
        llOwnerSay("The person carrying you has taken over as your controller.");
        string msg = "You are now " + dollname + "'s controller. See " + httpstart + "controller.htm";
        llDialog(ToucherID,msg,["OK"] , 9999);
    }

    else if (choice == "Use Control" && (ToucherID == MistressID || ToucherID == ChristinaID))
    {
        update_dialog_timestamp(ToucherID, "control");
        list privatemenu = ["Drop control","Take off key"];
        if (detachable)
        {
            privatemenu += "☑ Detachable";
        }
        else
        {
            privatemenu += "☐ Detachable";
        }

        if (alwaysavailable)
        {
            privatemenu += "☑ Auto TP";
        }
        else
        {
            privatemenu += "☐ Auto TP";
        }

        if (stuck)
        {
            privatemenu += "☐ Self TP";
        }
        else
        {
            privatemenu += "☑ Self TP";
        }

        if (pleasuredoll)
        {
            privatemenu += "☑ Pleasure";
        }
        else
        {
            privatemenu += "☐ Pleasure";
        }

        if (canfly)
        {
            privatemenu += "☑ Flying";
        }
        else
        {
            privatemenu += "☐ Flying";
        }

        //_CH15 \/
        if (afk)
        {
            privatemenu += "☑ AFK";
        }
        else
        {
            privatemenu += "☐ AFK";
        }
        //_CH15 /\

        llDialog(ToucherID, "See " + httpstart + "controller.htm Choose what you want to happen",  privatemenu, channel_dialog);
    }
    else if (choice == "Options")
    {
        update_dialog_timestamp(ToucherID, "options");
        string msg = httpstart + "keychoices.htm for explanation.";
        list pluslist;
        if (afk)
        {
            pluslist += "☑ AFK";
        }
        else
        {
            pluslist += "☐ AFK";
        }

        if (carrierID == NULL_KEY)
        {
            if (candress)
            {
                pluslist += "☑ Dressing";
            }
            else
            {
                pluslist += "☐ Dressing";
            }

            if (detachable)
            {
                pluslist += ["☑ Detachable","Take off key"];
            }

            if (!alwaysavailable)
            {
                pluslist += "☐ Auto TP";
            }

            if (!stuck)
            {
                pluslist += "☑ Self TP";
            }

            if (canfly)
            {
                pluslist += "☑ Flying";
            }

            if (pleasuredoll)
            {
                pluslist += "☑ Pleasure";
            }
            else
            {
                pluslist += "☐ Pleasure";
            }
            if (MistressID == NULL_KEY)
            {
                if (canbecomemistress)
                {
                    pluslist += "☑ Takeover";
                }
                else
                {
                    pluslist += "☐ Takeover";
                }
            }
            if (visible)
            {
                pluslist += "☑ Visible";
            }
            else
            {
                pluslist += "☐ Visible";
            }
        }
        llDialog(ToucherID, msg, pluslist, channel_dialog);
    }
}

optionsmenu(string choice, key id)
{
    if (choice == "☑ Detachable")
    {
        detachable = FALSE;
        llOwnerSay("Your key cannot be detached.");
    }
    else if (choice == "☐ Auto TP")
    {
        llOwnerSay("You must accept all tp offers.");
        alwaysavailable = TRUE;
        llOwnerSay("@accepttp=add");
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
        llOwnerSay("@tplm=n,tploc=n");
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
    else if (choice == "Take off key")
    {
        aochange("on");
        llOwnerSay("@clear,detachme=force");
        llOwnerSay("Your key has been taken off.");
        return;
    }
    else if (choice == "☑ Flying")
    {
        canfly = FALSE;
        llOwnerSay("@fly=n");
        llOwnerSay("You have given up your ability to fly. Helpless dolly!");
    }
    else if (choice == "☑ Visible")
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
        afk = TRUE;
    }
    else if (choice == "☑ AFK")
    {
        stopafk();
        afk = FALSE;
        timeleftonkey =  timeleftonkey / 2;
    }

    //_M02
    handlemenuchoices("Options", id);
}

controlmenu(string choice, key id)
{
    if (choice == "☐ Detachable")
    {
        detachable = TRUE;
        llSay(PUBLIC_CHANNEL, dollname + "'s key can be detached.");
    }
    else if (choice == "☑ Detachable")
    {
        detachable = FALSE;
        llSay(PUBLIC_CHANNEL, dollname + "'s key cannot be detached.");
    }
    else if (choice == "☑ Auto TP")
    {
        alwaysavailable = FALSE;
        if (carrierID == NULL_KEY)
        {
            llOwnerSay("@accepttp=rem");
        }
        llSay(PUBLIC_CHANNEL, dollname + " can reject teleport offers.");
    }
    else if (choice == "☐ Auto TP")
    {
        alwaysavailable = TRUE;
        llSay(PUBLIC_CHANNEL, dollname + " cannot reject teleport offers.");
        if (carrierID == NULL_KEY)
        {
            llOwnerSay("@accepttp=add");
        }
    }
    else if (choice == "☐ Self TP")
    {
        stuck = FALSE;
        if (carrierID == NULL_KEY)
        {
            llOwnerSay("@tplm=y,tploc=y");
        }
        llSay(PUBLIC_CHANNEL, dollname + " may travel on her own initiative.");
    }
    else if (choice == "☑ Self TP")
    {
        llSay(PUBLIC_CHANNEL, dollname + " is now a helpless doll and cannot travel on her own initiative.");
        llOwnerSay("@tplm=n,tploc=n");
        stuck = TRUE;
    }
    else if (choice == "Drop control")
    {
        llSay(PUBLIC_CHANNEL, dollname + "'s controller has given up control.");
        llOwnerSay("@tplure:" + (string) MistressID + "=rem,accepttp:" + (string) MistressID + "=rem");
        MistressID = NULL_KEY;
    }
    else if (choice == "☑ Pleasure")
    {
        llSay(PUBLIC_CHANNEL, dollname + " is not a pleasure doll.");
        pleasuredoll = FALSE;
    }
    else if (choice == "☐ Pleasure")
    {
        llSay(PUBLIC_CHANNEL, dollname + " has been made into a pleasure doll.");
        pleasuredoll = TRUE;
    }
    else if (choice =="Take off key")
    {
        aochange("on");
        llOwnerSay("@clear,detachme=force");
        return;
    }

    else if (choice == "☐ Flying")
    {
        canfly = TRUE;
        llOwnerSay("@fly=y");
        llSay(PUBLIC_CHANNEL, dollname + " can fly.");
    }
    else if (choice == "☑ Flying")
    {
        canfly = FALSE;
        llOwnerSay("@fly=n");
        llSay(PUBLIC_CHANNEL, dollname + " cannot fly.");
    }
    else if (choice == "☐ AFK")
    {
        llRegionSayTo(id, PUBLIC_CHANNEL, dollname + " is now in AFK mode and won't unwind.");
        startafk();
        afk = TRUE;
    }
    else if (choice == "☑ AFK")
    {
        llRegionSayTo(id, PUBLIC_CHANNEL, dollname + " is no longer in AFK mode and will wind down again.");
        stopafk();
        afk = FALSE;
        timeleftonkey =  timeleftonkey / 2;
    }
    handlemenuchoices("Use Control", id);
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
    update_dialog_timestamp(ToucherID, "strip");
    llDialog(id, "Take off:",["Top","Bra","Bottom","Panties","Shoes"], channel_dialog);
}

dressmenu(key id)
{
    // Open dress menu
    delete_listener(id);
    if (wardrobeURL == "")
    {
        llDialog(id, "No outfits found", ["OK"], 9999);
    }
    llLoadURL(id, "Please choose an outfit at this website.", wardrobeURL);
}

transformmenu(string choice, key id, integer confirmed)
{
    if (id == dollID)
    {
        if (choice == "CHOICES")
        {
            list choices;
            if (needsagree)
            {
                choices = ["☐ Automatic"];
            }
            else
            {
                choices = ["☑ Automatic"];
            }
            if (seesphrases)
            {
                choices += "☑ Phrases";
            }
            else
            {
                choices += "☐ Phrases";
            }
            update_dialog_timestamp(id, "transform");
            llDialog(id, "Options", choices, channel_dialog);
            return;
        }
        else if (choice == "☑ Automatic" || choice == "☐ Automatic")
        {
            needsagree = !needsagree;
            return;
        }
        else if (choice == "☑ Phrases" || choice == "☐ Phrases")
        {
            seesphrases = !seesphrases;
            return;
        }
    }
    else if (needsagree && !confirmed)
    {
        if(!create_or_get_listen(dollID))
        {
            llDialog(id, "The doll cannot transform at this time, please try again later.", ["OK"], 9999);
            return;
        }
        update_dialog_timestamp(id, "transform");
        update_dialog_timestamp(dollID, "transform_confirm");
        list choices = [choice,"I cannot"];
        string msg = "Can you make this change?";
        llDialog(dollID, msg, choices, channel_dialog);
        return;
    }

    if (~llListFindList(types, (list)choice))
    {
        currentstate = choice;
        currentphrases = [];
        notecardLine = 0;
        transformer = id;
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

        kQuery = llGetNotecardLine(choice,0);

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
    // CH06
    winddown = FALSE;

    //_M01C
    llTargetOmega(ZERO_VECTOR, 0.0, 0.0);
    llOwnerSay("@fly=n,temprun=n,alwaysrun=n,sendchat=n,tplm=n,tploc=n,tplure=n,sittp=n,standtp=n,sit=n");
}

stopafk()
{
    winddown = TRUE;

    if (!timeleftonkey)
    {
        return;
    }
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
    if (!stuck && carrierID == NULL_KEY)
    {
        llOwnerSay("@tplm=y,tploc=y");
    }
    llOwnerSay("@temprun=y,alwaysrun=y,sendchat=y,tplure=y,sittp=y,standtp=y,sit=y");
}

collapse()
{
    llOwnerSay("@fly=n,temprun=n,alwaysrun=n,sendchat=n,tplm=n,tploc=n,sittp=n,standtp=n,accepttp:" + (string) mainwinder + "=add,tplure:" + (string) mainwinder + "=add,sit=n,shownames=n,showhovertextall=n,tplure=n");
    if (MistressID == NULL_KEY)
    {
        llOwnerSay("@accepttp:" + (string) ChristinaID + "=add,tplure:" + (string) ChristinaID + "=add");
    }

    //_M03B \/
    string animation;
    if(llGetAgentInfo(dollID) & AGENT_SITTING)
    {
        animation = "away";
    }
    else
    {
        animation = "collapse";
    }
    //_M03B /\

    llOwnerSay("@rediremote:999=add");
    llTargetOmega(ZERO_VECTOR, 0, 0);
    visible = TRUE;
    animate(animation);
    llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
}

aochange(string choice)
{
    integer g_iAOChannel = -782690;

    //_CH17
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


    //_CH23 \/
    if (llGetAgentInfo(dollID) & AGENT_SITTING)
    {
        // Wait a little bit so that the AO has time to process things
        llSleep(1.0);
        llStopAnimation("sit");
        llSleep(0.1);
    }
    //_CH23 \/
}

reloadscripts()
{
    poses = [];
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

    types = [];
    n = llGetInventoryNumber(INVENTORY_NOTECARD);
    while(n)
    {
        types += llGetInventoryName(INVENTORY_NOTECARD, --n);
    }
}

uncarry()
{
    if (carrierID != MistressID)
    {
        llOwnerSay("@accepttp:" + (string)carrierID + "=rem,tplure:" + (string)carrierID + "=rem");
    }
    if (timeleftonkey)
    {
        if (stuck)
        {
            llOwnerSay("@tplure=y");
        }
        else
        {
            llOwnerSay("@tplm=y,tploc=y,tplure=y");
        }
    }
    if (alwaysavailable)
    {
        llOwnerSay("@accepttp=add");
    }
    llSay(PUBLIC_CHANNEL, dollname + " has been set down.");
    carrierID = NULL_KEY;
}

say_key_phrase()
{
    integer i = (integer) llFrand(llGetListLength(currentphrases));
    string phrase  = llList2String(currentphrases, i);
    if (llGetSubString(phrase,0,0) == "*")
    {
        phrase = llGetSubString(phrase,1,-1);
        float r = llFrand(3);
        if (r < 1.0)
        {
            phrase = "*** feel your need to " + phrase;
        }
        else if (r < 2.0)
        {
            phrase = "*** feel your desire to " + phrase;
        }
        else
        {
            if (currentstate  == "Domme")
            {
                phrase = "*** You like to " + phrase;
            }
            else
            {
                phrase = "*** feel how people like you to " + phrase;
            }
        }
    }
    else
    {
        phrase = "*** " + phrase;
    }
    if (currentstate == "Regular")
    {
        phrase += " ***";
    }
    else
    {
        phrase += ", " + currentstate + "Doll ***";
    }
    llOwnerSay(phrase);
}

// First time script setup
init()
{
    dollID = llGetOwner();
    channel_dialog = -llAbs((integer)("0x" + llGetSubString(dollID,30,-1))) -1;
    firstStart = llGetListLength(startupMessages);
    posetime = 0;
    carrierID = NULL_KEY;
    detachable = TRUE;
    alwaysavailable = FALSE;
    pleasuredoll = FALSE;
    needsagree = FALSE;
    seesphrases = TRUE;
    stuck = FALSE; //problem with being stuck on private land -- no way to get off.
    candress = TRUE;
    canbecomemistress = FALSE;
    canfly = TRUE;
    winddown = TRUE;
    afk = FALSE;
    MistressID = NULL_KEY;
    timeleftonkey = 360;
    visible = TRUE;
    currentstate = "Regular";

    reloadscripts();
}

// Things to do every time the key is worn or we log in
startup()
{
    if (llGetAttached() != ATTACH_BACK)
    {
        llTargetOmega(ZERO_VECTOR, 0, 0);
        llSetTimerEvent(0.0);
        llOwnerSay("@detach=y");
        llOwnerSay("Please detach your key and wear it on your spine");
        return;
    }
    key_startup = TRUE;
    start_key_listen();
    llRegionSay(channel_dialog-1, "key_init");
    // Clock is accessed every ten seconds;
    llSetTimerEvent(10.0);
    dollname = llGetDisplayName(dollID);

    // Locks key
    llOwnerSay("@detach=n");
    llOwnerSay("@acceptpermission=add");
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

    if (MistressID)
    {
        // Always allow the doll's owner to TP their doll
        llOwnerSay("@tplure:" + (string) MistressID + "=add,accepttp:" + (string) MistressID + "=add");
    }
    if (carrierID != NULL_KEY && carrierID != MistressID)
    {
        uncarry();
    }

    if (timeleftonkey)
    {
        animate(currentanimation);
    }
    else
    {
        collapse();
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
        llPlaySound("07af5599-8529-fb12-5891-1dcf1a33ee49", 1.0);
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
        init();
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
        if (change & CHANGED_INVENTORY)
        {
            reloadscripts();
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

        if (llGetAttached() != ATTACH_BACK)
        {
            llRegionSayTo(ToucherID, PUBLIC_CHANNEL, "The key must be attached to the doll's back before you can use it.");
            return;
        }

        if (!create_or_get_listen(ToucherID))
        {
            llRegionSayTo(ToucherID, PUBLIC_CHANNEL, "The key is too busy to be played with, please try again in a little bit.");
            return;
        }

        //_M04B
        integer displaytime = (integer) ((timeleftonkey+5) / 6);
        string timeleft = "Time Left on key is " + (string)displaytime + " minutes. ";

        string msg;
        list menu =  ["Wind"];

        if (ToucherID == dollID)
        {
            if (!timeleftonkey)
            {
                msg = "You need winding.";
                menu = ["OK"];
            }
            else if (carrierID)
            {
                msg = "You are currently being carried";
                menu = ["OK", "Options"];
                if (MistressID == NULL_KEY && !canbecomemistress)
                {
                    menu += "allow takeover";
                }
            }
            else
            {
                msg = httpstart + "dollkeyselfinfo.htm\nYou are a " + currentstate + " doll.";
                menu = ["Dress", "Options"];
                if (!posetime)
                {
                    menu += "Pose";
                }
                menu += "Type of Doll";
            }
        }
        else if (carrierID)
        {
            if (ToucherID == carrierID)
            {
                msg = "Place Down frees " + dollname + " when you are done with her";
                menu += ["Place Down", "Pose"];
                if (candress)
                {
                    menu += ["Dress", "Type of Doll"];
                }
                if (posetime)
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
            else if (ToucherID == MistressID || ToucherID == ChristinaID)
            {
                menu += "Carry";
            }
            else
            {
                msg = dollname + " is currently being carried. Sorry.";
                menu += "OK";
            }
        }
        else if (timeleftonkey)
        {
            // Not being carried, not collapsed
            msg = dollname + " is a " + currentstate + " doll and likes to be treated like a doll. So feel free to use these options. The Carry option picks up " + dollname + " and temporarily makes her exclusively yours. " + httpstart + "communitydoll.htm for more info.";
            if (afk)
            {
                msg += " She is currently marked AFK.";
            }
            menu += "Carry";
            if (candress)
            {
                menu += ["Dress", "Type of Doll"];
            }
            if (posetime)
            {
                menu += "Unpose";
            }
            menu += "Pose";
        }
        if (ToucherID == MistressID || ToucherID == ChristinaID)
        {
            menu = llListInsertList(menu, ["Use Control"], 3);

            //_M04A
            llWhisper(-60946337, "wind channel|" + (string)channel_dialog);
        }
        llDialog(ToucherID, timeleft + msg,  menu, channel_dialog);
        if(ToucherID != dollID)                                                         //_M06 \/
        {
            llPlaySound("07af5599-8529-fb12-5891-1dcf1a33ee49", 0.0);
        }                                                                               //_M06 /\
    }

    timer()
    {
        if (firstStart)
        {
            llOwnerSay(llList2String(startupMessages, --firstStart));
            if(!firstStart)
            {
                startupMessages = [];
            }
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
            timeleftonkey--;
            if (!timeleftonkey)
            {
                collapse();
                llSay(PUBLIC_CHANNEL, dollname + " has run out of life");
            }
        }
        if (posetime)
        {
            if (timeleftonkey && currentstate != "Display")
            {
                posetime--;
                if (!posetime)
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
                say_key_phrase();
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
            string menu = llList2Key(dialogUsers, pos+3);

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
                transformmenu(choice, id, FALSE);
            }
            else if (menu == "transform_confirm")
            {
                transformmenu(choice, id, TRUE);
            }
            else if (menu == "control")
            {
                controlmenu(choice, id);
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
        if (query_id == kQuery)
        {
            if (data != EOF)
            {
                if (llStringLength(data) > 1)
                {
                    if (notecardLine == 0)
                    {
                        // Set wardrobe URL
                        wardrobeURL = data;
                        if (!key_startup)
                        {

                            start_key_listen();
                        }
                    }
                    else if (notecardLine == 1)
                    {
                        if (!key_startup)
                        {
                            llOwnerSay("@detachallthis:"+data+"=n");
                            llOwnerSay("@remoutfit=force,detach=force");
                            llOwnerSay("@attachover:"+data+"=force");
                            llOwnerSay("@detachallthis:"+data+"=y");
                        }
                    }
                    else
                    {
                        currentphrases += data;
                    }
                }
                notecardLine++;
                kQuery = llGetNotecardLine(currentstate,notecardLine);
            }
            else
            {
                if (key_startup)
                {
                    startup_finish();
                }
                else
                {
                    dressmenu(transformer);
                }
            }
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            if (llStringLength(currentanimation) > 0)
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
    }
}