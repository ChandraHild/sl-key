//Aug 14, totally changing
//Nov. 12, adding compatibility with hypnosisHUD

string dollname;
string statename;
list types;
integer lineno;

integer minmin;
integer channel_dialog;

// 1.5 minute
integer menulimit = 9;

string currentstate;
integer winddown;
integer needsagree;
integer inchoice;
integer seesphrases;
key dollID;
string clothingprefix;

key kQuery;
key toucher;

list currentphrases;

setup()
{
    dollID = llGetOwner();
    dollname = llGetDisplayName(dollID);
    llMessageLinked(LINK_THIS, 18, "here", dollID );
    channel_dialog = -llAbs((integer)("0x" + llGetSubString(dollID,30,-1))) -1;
}

reloadscripts()
{
    types = [];
    integer  n = llGetInventoryNumber(INVENTORY_NOTECARD);
    while(n)
    {
        types += llGetInventoryName(INVENTORY_NOTECARD, --n);
    }
}

default
{
    state_entry()
    {
        setup();
        reloadscripts();
        llSetTimerEvent(120.0); 
        needsagree = FALSE;
        seesphrases = TRUE;
    }

    on_rez(integer iParam)
    {
        setup();
    }

    changed(integer change)
    {
        if ((change & CHANGED_INVENTORY) || (change & CHANGED_ALLOWED_DROP))
        {
            reloadscripts();
        }
    }

    timer()
    {
        // Called every time interval
        minmin--;

        if (seesphrases)
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
                phrase += ", " + statename + "Doll ***";
            }
            llOwnerSay(phrase);
        }
    }

    link_message(integer source, integer num, string choice, key id)
    {
        if (num == 17)
        {
            // Transform menu opened
            if (minmin > 0)
            {
                llDialog(id,dollname + "cannot be transformed right now. She was recently transformed.",["OK"], 9999);
            }
            else
            {
                inchoice = TRUE;
                string msg = "These change the personality of " + dollname + " She is currently a " + statename + ". What type of doll do you want her to be?";
                llOwnerSay(choice + " is looking at your Transform options.");
                list choices = types;
                if (id == dollID)
                {
                    choices += "CHOICES";
                }

                llDialog(id, msg, choices, channel_dialog);
            }
        }
        else if (num == 19)
        {
            // Second transform menu
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
                    llDialog(dollID,"Options",choices, channel_dialog);
            }
            else if (needsagree == TRUE && inchoice == TRUE)
            {
                inchoice = FALSE;
                list choices = [choice,"I cannot"];
                string msg = "Can you make this change?";
                llDialog(dollID, msg, choices, channel_dialog);
            }
            else
            {
                if (~llListFindList(types, (list)choice))
                {
                    statename = choice;
                    minmin = 2;
                    currentstate = choice;
                    clothingprefix = "*" + choice;
                    currentphrases = [];
                    lineno = 0;
                    toucher = id;
                    kQuery = llGetNotecardLine(choice,0);
                    llMessageLinked(LINK_THIS, 2, clothingprefix, dollID);
                    llSleep(1.0);
                    llMessageLinked(LINK_THIS, 16, currentstate, id);
                    llSay(0, dollname + " has become a " + statename + " Doll.");
                }
                else if (choice == "☑ Automatic" || choice == "☐ Automatic")
                {
                    needsagree = !needsagree;
                }
                else if (choice == "☑ Phrases" || choice == "☐ Phrases")
                {
                    seesphrases = !seesphrases;
                }
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
                    if (lineno == 0)
                    {
                        llMessageLinked(LINK_THIS, 3, data, toucher);
                    }
                    else if (lineno == 1)
                    {
                        llOwnerSay("@detachallthis:"+data+"=n");
                        llOwnerSay("@remoutfit=force,detach=force");
                        llOwnerSay("@attachover:"+data+"=force");
                        llOwnerSay("@detachallthis:"+data+"=y");
                    }
                    else
                    {
                        currentphrases += data;
                    }
                }
                lineno++;
                kQuery = llGetNotecardLine(currentstate,lineno);
            }
            else
            {
                llMessageLinked(LINK_THIS, 1, "start", toucher);
            }
         }
    }
}