//Oct. 1. Adds everything in ~normalself folder, if oldoutfit began with a +. adds channel dialog or id to screen listen
//Nov. 17, moves listen to cd2667 so it gets turned off
//Nov. 25, puts in dress menu
//Aug 1, redoes closing

string bigsubfolder = "Dressup"; //name of subfolder in RLV to always use if available. But also checks for outfits.

integer candresstemp;
integer candresstimeout;

key dollID;
key dresserID;
key setupID;

integer listen_id_outfitrequest3;
string newoutfitname;

integer channel_dialog;
integer cd2667;

string newoutfit;
string oldoutfit;
string oldoutfitname;

string clothingprefix;
string bigprefix;

integer listen_id_2667;
integer listen_id_outfitrequest;
integer listen_id_2555;
integer listen_id_2668;
integer listen_id_2669;

integer pagesize = 12;
integer page = 0;
string NEXT = ">>";
string PREV = "<<";

list newoutfits;
string oldattachmentpoints;
integer newoutfitwordend;

setup()
{
    dollID =   llGetOwner();
    candresstemp = TRUE;
    llOwnerSay("@getinv=2555");

    //from dollkey36

    integer ncd = ( -1 * (integer)("0x"+llGetSubString((string)llGetKey(),-5,-1)) ) -1;
    if (channel_dialog != ncd)
    {
        llListenRemove(listen_id_2667);
        channel_dialog = ncd;
        cd2667 = channel_dialog - 2667;
        llListenRemove(listen_id_2667);
        listen_id_2667 = llListen( cd2667, "", "", "");
    }

    if (dollID != setupID)
    {
        llListenRemove(listen_id_2555);
        llListenRemove(listen_id_outfitrequest3);
        llListenRemove(listen_id_outfitrequest);
        llListenRemove(listen_id_2668); 
        llListenRemove(listen_id_2669); 
        llSleep(2.0);
        listen_id_2555 = llListen(2555, "", dollID, "");
        listen_id_outfitrequest3 = llListen(2665, "", dollID, "");
        listen_id_outfitrequest = llListen(2666, "", dollID, "");
        listen_id_2668 = llListen(2668, "", dollID, "");
        listen_id_2669 = llListen(2669, "", dollID, "");
        setupID = dollID;
    }
}

dressmenu(string choice)
{
    list Outfits = llParseString2List(choice, [","], []); //what are brackets at end?
    newoutfits = [];
    integer n;
    integer iStop = llGetListLength(Outfits);
    string itemname;
    for (n = 0; n < iStop; n++)
    {
        itemname = llList2String(Outfits, n);
        if (llGetSubString(itemname,0,0) != "~"  && llGetSubString(itemname,0,0) != "*"&& itemname != oldoutfitname)
        {
            newoutfits += itemname;
        }
    }
    newoutfits = llListSort(newoutfits, 1, TRUE);
    page = 0;
    dressdialog();
}

randomdress(string choice)
{
    // gets random outfit
    list Outfits = llParseString2List(choice, [","], []); //what are brackets at end? 
    list newoutfits = [];
    integer n;
    integer iStop = llGetListLength(Outfits);
    if (iStop == 0)
    {
        //folder is empty, switching to regular folder
        llOwnerSay("There are no outfits in your " + clothingprefix + " folder.");
        if (bigprefix)
        {
            clothingprefix = bigprefix + "/";
        }
        else
        {
            clothingprefix = "";
        }
    }
    else {
        string itemname;
        string prefix;
        integer total = 0;
        for (n = 0; n < iStop; n++)
        {
            itemname = llList2String(Outfits, n);
            prefix = llGetSubString(itemname,0,0);
            if (prefix != "~" && prefix != "*")
            {
                total += 1;
                newoutfits += itemname;
            }
        }
        integer i = (integer) llFrand(total);
        string nextoutfit  = llList2String(newoutfits, i);
        dress(nextoutfit);
    }
}

dressdialog()
{
    //picks out
    list newoutfits2;
    integer numoutfits = llGetListLength(newoutfits);
    integer curpagesize = pagesize;
    integer start;
    list outfitlist;
    string pages = "";
    if (numoutfits > pagesize)
    {
        curpagesize = curpagesize-2;
        start = page*curpagesize;
        integer end = start + curpagesize - 1;
        newoutfits2 = llList2List(newoutfits, start, end);
        outfitlist = [PREV, NEXT];
        pages = "\nPage " + (string)(page+1) + " of " + (string)llCeil((float)numoutfits/(float)curpagesize);
    }
    else
    {
        start = 0;
        newoutfits2 = newoutfits;
    }
    string msgg = "You may choose any outfit.";
    if (dresserID == dollID)
    {
        msgg =     "See http://communitydolls.com/outfits.htm for information on outfits.";
    }
    msgg += pages + "\n\n";
    integer x = 0;
    for (x = 0; x < llGetListLength(newoutfits2); x++)
    {
        msgg += (string)(start+x+1) + ". " + llList2String(newoutfits2, x) + "\n";
        outfitlist += (string)(start+x+1);
    }
    llDialog(dresserID, msgg,outfitlist, cd2667);
}

dress(string choice)
{
    llSay(0, llGetDisplayName(dollID) + " is being dressed in " + choice + ".");
    candresstemp = FALSE;
    newoutfitname = choice;
    if (clothingprefix == "")
    {
        newoutfit = choice;
    }
    else
    {
        newoutfit = clothingprefix + "/" + choice;
    }
    newoutfitwordend = llStringLength(newoutfit) - 1;
    llOwnerSay("@detach=force");
    llOwnerSay("@remoutfit=force");
    llSleep(5.0);
    if (llGetSubString(oldoutfitname,0,0) == "+" && llGetSubString(newoutfitname,0,0) != "+")
    {
        // only works well assuming in regular
        llOwnerSay("@attach:~normalself=force");
    }
    llOwnerSay("@attachallover:" + newoutfit + "=force");
    oldattachmentpoints = choice;
    oldoutfit = newoutfit;
    oldoutfitname = newoutfitname;
    llSleep(8.0);
    candresstimeout = 2;
}

default
{
    state_entry()
    {
        channel_dialog = 0;
        setup();
        llSetTimerEvent(10.0);  //clock is accessed every ten seconds;
        clothingprefix = "";
    }

    on_rez(integer iParam)
    {
        setup();
    }

    timer()
    {
        //called everytimeinterval
        if (candresstimeout-- == 0)
        {
            candresstemp = TRUE;
        }
    }

    link_message(integer source, integer num, string choice, key id)
    {
        // need to disallow dressing while dressing is happening
        if (num == 1)
        {
            if (!candresstemp)
            {
                llSay(0, "She cannot be dressed right now; she is already dressing");
            }
            else if (choice == "start")
            {
                dresserID = id;

                candresstimeout = 8;
                if (clothingprefix == "")
                {
                    llOwnerSay("@getinv=2666");
                }
                else
                {
                    llOwnerSay("@getinv:" + clothingprefix + "=2666");
                }
            }
            else if (choice == "random")
            {
                //candresstemp = FALSE;
                dresserID = id;
                candresstimeout = 8;
                if (clothingprefix == "")
                {
                    llOwnerSay("@getinv=2665");
                }
                else
                {
                    llOwnerSay("@getinv:" + clothingprefix + "=2665");
                }
            }
        }
        if (num == 2)
        {
            //probably should have been in transformer
            string oldclothingprefix = clothingprefix;
            if (bigprefix)
            {
                clothingprefix = bigprefix + "/" +  choice;
            }
            else
            {
                clothingprefix = choice;
            }
            if (clothingprefix != oldclothingprefix)
            {
                llOwnerSay("@detach:" + oldclothingprefix + "/~AO=force");
                llOwnerSay("@attach:" + clothingprefix + "/~AO=force");
                if (oldclothingprefix != "")
                {
                    //remove tatoo");
                    llOwnerSay("@remoutfit:" + clothingprefix + "/tatoo=force");
                    llOwnerSay("@attach:~normalself=force");
                    llSleep(4.0);
                }

                llOwnerSay("@attach:" + clothingprefix + "/~normalself=force");
            }
            //puts on ~normalself
        }
    }
    // First, all clothes are taken off except for skull and anything that might be revealing.
    // Then the new outfit is put on. It uses replace, so it should take off any old clothes.
    // Then there is an 8 second wait and then the new outfit is put on again! In case something was locked. This I think explains the double put-on.
    // Then the places are checked where there could be old clothes still on. If anything is there, according to whatever is returned, the id is checked and it is taken off if they are old.
    // This last step takes off all the clothes that weren't replaced.

    //There is one place where the old outfit is removed.

    listen(integer channel, string name, key id, string choice)
    {
        if (channel == 2555)
        { // looks for one folder at start
            string oldbigprefix = bigprefix;
            list Outfits = llParseString2List(choice, [","], []); //what are brackets at end? 
            integer n;
            integer iStop = llGetListLength(Outfits);
            string itemname;
            bigprefix = "";
            for (n = 0; n < iStop; n++)
            {
                itemname = llList2String(Outfits, n);
                if (itemname == bigsubfolder)
                {
                    bigprefix = bigsubfolder;
                }
                else if (itemname == "outfits")
                {
                    bigprefix = "outfits";
                }
                else if (itemname == "Outfits")
                {
                    bigprefix = "Outfits";
                }
            }
            if (bigprefix != oldbigprefix)
            {
                //outfits-don't-match-type bug only occurs when big prefix is changed
                clothingprefix = bigprefix;
            }
        }
        if (channel == 2665)
        {
            dressmenu(choice);
        }

        if (channel == 2666)
        {
            dressmenu(choice);
        }

        else if (channel == cd2667  && choice != "OK")
        {
            //the random outfit from 2665 didn't work with the above
            if (choice == NEXT)
            {
                integer numoutfits = llGetListLength(newoutfits);
                integer curpagesize = pagesize-2;
                if (page >= numoutfits/curpagesize)
                {
                    page = 0;
                }
                else
                {
                    page++;
                }
                dressdialog();
            }
            else if (choice == PREV)
            {
                if (page > 0)
                {
                    page--;
                }
                else
                {
                    integer numoutfits = llGetListLength(newoutfits);
                    integer curpagesize = pagesize-2;
                    page = numoutfits/curpagesize;
                }
                dressdialog();
            }
            else
            {
                dress(llList2String(newoutfits, (integer)choice-1));
            }
        }
    }
}