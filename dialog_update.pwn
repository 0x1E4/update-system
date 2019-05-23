/*
		Update system 1.0 (D)ALpha (with dialog and much easier to do)
		By: solsticedev

		Description:
		This script can add your updates via ingame and
		no need to compile again and again on pawn, its
		easy to use and friendly (maybe lol).

    Changelog 1.0:
		* Creating the file.
		* Rework script to only use one command.
		* Improved stability.
		* Fix minor bug.

		Note:
		* Please report on issue if you found any bug
		* and thank you for downloading this filterscript.
*/

// remove this tag if you want to use this as gamemode.
#define FILTERSCRIPT

// main include.
#include <a_samp>
#include <a_mysql>
#include <easyDialog>
#include <zcmd>
#include <sscanf2>

// dheck if filterscript tag exists.
#if defined FILTERSCRIPT

// define default mysql, you can change this default setting.
#define MYSQL_HOSTNAME		"localhost"
#define MYSQL_USERNAME		"root"
#define MYSQL_PASSWORD		""
#define MYSQL_DATABASE		"test"

// declarate pipe connection.
new MySQL: Database;

// declarate filterscript main.
public OnFilterScriptInit()
{
	// put mysql connect inside Database, so we can call it in anywhere.
	Database = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE);

	// if database is invalid handle or mysql getting error.
	if(Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0)
	{
		// print error then exit.
		print("[SERVER]: MySQL Connection failed, shutting the server down!");
		SendRconCommand("exit");
		return 1;
	}

  // else, success yaay.
	print("[SERVER]: MySQL Connection was successful.");

  // create table once and if this table exists, the script not re-creating again.
	mysql_query(Database, "CREATE TABLE IF NOT EXISTS updates (`UpdateID` int(10) AUTO_INCREMENT PRIMARY KEY, `AddedBy` VARCHAR(24) NOT NULL, `Text` VARCHAR(128) NOT NULL, `Status` int(10), `DateAdded` VARCHAR(30) NOT NULL); ");
	return 1;
}

// begin creating command.
CMD:updates(playerid, params[])
{
    // check if player is not RCON admin then execute pquery (NOTE: you can change this to your server admin system or whatever).
		if(!IsPlayerAdmin(playerid))
				return mysql_pquery(Database, "SELECT * FROM `updates`", "Player_ViewUpdates", "i", playerid);

    // else if player is RCON admin, then show them Administrator dialog.
		Dialog_Show(playerid, UpdatesMenu, DIALOG_STYLE_LIST, "Updates Menu - Administator", "Add Updates\nEdit Updates\nDelete Updates\nView Updates", "Next", "Close");
		return 1;
}

// teh core of teh coooooooreeeeeeee.
Dialog:UpdatesMenu(playerid, response, listitem, inputtext[])
{
    // player pressing ESC or pressing CANCEL button? just return 0 then problem solved.
		if(!response)
			 return 0;

    // if not, check what user clicked on and show them another dialog.
		switch(listitem)
		{
				case 0: Dialog_Show(playerid, UpdatesBox, DIALOG_STYLE_INPUT, "Update Box - Add", "Please add your updates on box below.\n\nList: ADD->\nFIX->\nCHANGE->\nDELETE->\n\nExample: 'ADD->Fix changelog command.'", "Enter", "Close");
				case 1: Dialog_Show(playerid, UpdatesEdit, DIALOG_STYLE_LIST, "Update Box - List Updates", Update_List(), "View", "Close");
				case 2: Dialog_Show(playerid, UpdatesDelete, DIALOG_STYLE_MSGBOX, "Update Box - Delete Choice", "Please choose delete option below\n\nNOTE: Be careful what are you doing, because this will erase your update PERMANENTLY.", "Delete All", "Custom Delete");
		}
		return 1;
}

// if player putting text and click Enter on UpdatesBox, this will be called.
Dialog:UpdatesBox(playerid, response, listitem, inputtext[])
{
    // player pressing ESC or pressing BACK button? returning back to previous dialog.
    if(!response)
        return Dialog_Show(playerid, UpdatesMenu, DIALOG_STYLE_LIST, "Updates Menu - Administator", "Add Updates\nEdit Updates\nDelete Updates\nView Updates", "Next", "Close");

    //if not, check if string found any these string, then delete that string and put them to DBMS
		if(strfind(inputtext, "ADD->", false) != -1 || strfind(inputtext, "FIX->", false) != -1) {
				strdel(inputtext, 0, 5); // 'add->' and 'fix->' has contain 5 string.
    		mysql_format(Database, query, sizeof(query), "INSERT INTO `updates` (`AddedBy`, `Text`, `Status`, `DateAdded`) VALUES ('%e', '%e', '1', '%e')", GetName(playerid), inputtext, ReturnDate());
    		mysql_tquery(Database, query, "OnPlayerAddUpdate", "iis", playerid, status, inputtext);
		}
		else if(strfind(inputtext, "CHANGE->", false) != -1 || strfind(inputtext, "DELETE->", false) != -1) {
				strdel(inputtext, 0, 8); // 'change->' and 'delete->' has contain 8 string.
    		mysql_format(Database, query, sizeof(query), "INSERT INTO `updates` (`AddedBy`, `Text`, `Status`, `DateAdded`) VALUES ('%e', '%e', '1', '%e')", GetName(playerid), inputtext, ReturnDate());
    		mysql_tquery(Database, query, "OnPlayerAddUpdate", "iis", playerid, status, inputtext);
		}
    //if string find not found anything below ^ just tell user that is incorrect format.
		else
		{
				SendClientMessage(playerid, 0xFFFFFFAA, "Invalid format type.");
				Dialog_Show(playerid, UpdatesBox, DIALOG_STYLE_INPUT, "Update Box - Add", "Please add your updates on box below.\n\nList: ADD->\nFIX->\nCHANGE->\nDELETE->\n\nExample: 'ADD->Fix changelog command.'", "Enter", "Close");
		}
		return 1;
}

// if player putting text and click Enter on UpdatesList, this will be called.
Dialog:UpdatesList(playerid, response, listitem, inputtext[])
{
    // player pressing ESC or pressing BACK button? returning back to previous dialog.
    if(!response)
        return Dialog_Show(playerid, UpdatesMenu, DIALOG_STYLE_LIST, "Updates Menu - Administator", "Add Updates\nEdit Updates\nDelete Updates\nView Updates", "Next", "Close");

    // avoid getting error duplicate variable, so i'm adding 'z'.
    new
      Cache: resultz,	updateid, addedby[24], text[32], status, dateadded[30], merge[512];

    // prepare query then run it.
    mysql_format(Database, query, sizeof(query), "SELECT * FROM `updates` WHERE `Text` = '%e'", inputtext);
    resultz = mysql_query(Database, query);

    // get cache from query.
    cache_get_value_name_int(0, "UpdateID", updateid);
    cache_get_value_name(0, "AddedBy", addedby);
    cache_get_value_name(0, "Text", text);
    cache_get_value_name_int(0, "Status", status);
    cache_get_value_name(0, "DateAdded", dateadded);

    // after dat, delete remaining all cache from resultz.
    cache_delete(resultz);

    // mergeing what we get to be one string on variable 'merge'.
    format(merge, sizeof(merge), "Update Type: %s\nText: %s\nUpdated by: %s\nCreated on: %s\n\nPlease put new text below if you wish to edit the description of this update.",
        UpdateStatus(status),
        text,
        addedby,
        dateadded
    );

    // set updateid into player variable and show what we merge to dialog.
    SetPVarInt(playerid, "0x6998", updateid);
    Dialog_Show(playerid, UpdatesEdit, DIALOG_STYLE_INPUT, "Update Box - Editing Text", merge, "Confirm", "Back");
    return 1;
}

// if player putting text and click Enter on UpdatesEdit, this will be called.
Dialog:UpdatesEdit(playerid, response, listitem, inputtext[])
{
    // player pressing ESC or pressing BACK button? returning back to previous dialog.
    if(!response)
        return Dialog_Show(playerid, UpdatesList, DIALOG_STYLE_LIST, "Update Box - List Updates", Update_List(), "View", "Back");

    // declarate variable called query, prepare query command, delete player variable, then execute with mysql query.
    new query[128];
    mysql_format(Database, query, sizeof(query), "UPDATE `updates` SET `text` = '%e' WHERE `UpdateID` = '%i'", inputtext, GetPVarInt(playerid, "0x6998"));
    SetPVarInt(playerid, "0x6998", -1);

    mysql_query(Database, query, false);

    // then tell admin the job is done and going back to updates menu.
    SendClientMessage(playerid, 0xFFFFFFAA, "Successfully editing description an updates, please see /updates > View Updates.");
    Dialog_Show(playerid, UpdatesMenu, DIALOG_STYLE_LIST, "Updates Menu - Administator", "Add Updates\nEdit Updates\nDelete Updates\nView Updates", "Next", "Close");
    return 1;
}

// if player putting text and click Enter on UpdatesDelete, this will be called.
Dialog:UpdatesDelete(playerid, response, listitem, inputtext[])
{
    if(!response)
    {
        //why false? because i'm not using any cache, and i want mysql just run teh query then done.
        mysql_query(Database, "TRUNCATE TABLE `updates`", false);
        SendClientMessage(playerid, 0xFFFFFFAA, "Successfully deleting ALL updates.");
        Dialog_Show(playerid, UpdatesMenu, DIALOG_STYLE_LIST, "Updates Menu - Administator", "Add Updates\nEdit Updates\nDelete Updates\nView Updates", "Next", "Close");
    }
    else
    {
        SendClientMessage(playerid, 0xFFFFFFAA, "Click on list below to delete, be careful about what are you doing now.");
        Dialog_Show(playerid, UpdateCustomDel, DIALOG_STYLE_LIST, "Update Box - Custom Delete", Update_List(), "View", "Back");
    }
    return 1;
}

// if player putting text and click Enter on UpdatesCustomDel, this will be called.
Dialog:UpdatesCustomDel(playerid, response, listitem, inputtext[])
{
    // player pressing ESC or pressing BACK button? show teh message.
    if(!response)
    {
        SendClientMessage(playerid, 0xFFFFFFAA, "What a nice choice");
        Dialog_Show(playerid, UpdatesMenu, DIALOG_STYLE_LIST, "Updates Menu - Administator", "Add Updates\nEdit Updates\nDelete Updates\nView Updates", "Next", "Close");
        return 1;
    }

    new
      query[128], updateid;

    format(string, sizeof(string), "You have successfully removed Update ID %d from the database.", updateid);
    SendClientMessage(playerid, -1, string);

    mysql_format(Database, query, sizeof(query), "DELETE FROM `updates` WHERE `UpdateID` = '%i'", updateid);
    mysql_query(Database, query);

    Dialog_Show(playerid, UpdatesMenu, DIALOG_STYLE_LIST, "Updates Menu - Administator", "Add Updates\nEdit Updates\nDelete Updates\nView Updates", "Next", "Close");
    return 1;
}


// This core function, do not try to edit except string format, JUST DONT!.
forward Player_ViewUpdates(playerid);
public Player_ViewUpdates(playerid)
{
  	if(cache_num_rows())
  	{
    		new
    			updateid, addedby[24], text[32], status, dateadded[30], string[1402]; // the reason this is huge is because there might be a lot of updates so it should be bigger, you can change this any time you want.

    		format(string, sizeof(string), "This is a list of the new server updates on the last revision:\n\n");
    		for(new i = 0; i < cache_num_rows(); i ++)
    		{
      			cache_get_value_name_int(i, "UpdateID", updateid);
      			cache_get_value_name(i, "AddedBy", addedby);
      			cache_get_value_name(i, "Text", text);
      			cache_get_value_name_int(i, "Status", status);
      			cache_get_value_name(i, "DateAdded", dateadded);

    			  format(string, sizeof(string), "%s[%d] %s - %s [%s] on %s\n", string, updateid, UpdateStatus(status), text, addedby, dateadded);
  		   }
  		   Dialog_Show(playerid, DIALOG_UPDATES, DIALOG_STYLE_MSGBOX, "Server new Updates", string, "Close", "");
  	}
  	else
  	{
  		  Dialog_Show(playerid, DIALOG_UPDATES, DIALOG_STYLE_MSGBOX, "Server new Updates", "There are currently no updates on the database.", "Close", "");
  	}
	  return 1;
}

forward OnPlayerAddUpdate(playerid, status, text[]);
public OnPlayerAddUpdate(playerid, status, text[])
{
  	new
  		updateid = cache_insert_id(), string[128];

  	format(string, sizeof(string), "You have successfully a new update - [ID: %d] - [Text: %s] - [Status: %s]", updateid, text, UpdateStatus(status));
  	SendClientMessage(playerid, -1, string);
  	return 1;
}

GetName(playerid)
{
  	new playerName[MAX_PLAYERS];
  	GetPlayerName(playerid, playerName, sizeof(playerName));
  	return playerName;
}

UpdateStatus(statuz)
{
    new sstatus[18];
    switch(statuz)
    {
      case 1: sstatus = "Added";
      case 2: sstatus = "Changed";
      case 3: sstatus = "Fixed";
      case 4: sstatus = "Removed";
    }
    return sstatus;
}

ReturnDate()
{
	new sendString[90], MonthStr[40], month, day, year;
	new hour, minute, second;

	gettime(hour, minute, second);
	getdate(year, month, day);
	switch(month)
	{
	    case 1:  MonthStr = "January";
	    case 2:  MonthStr = "February";
	    case 3:  MonthStr = "March";
	    case 4:  MonthStr = "April";
	    case 5:  MonthStr = "May";
	    case 6:  MonthStr = "June";
	    case 7:  MonthStr = "July";
	    case 8:  MonthStr = "August";
	    case 9:  MonthStr = "September";
	    case 10: MonthStr = "October";
	    case 11: MonthStr = "November";
	    case 12: MonthStr = "December";
	}

	format(sendString, 90, "%s %d, %d %02d:%02d:%02d", MonthStr, day, year, hour, minute, second);
	return sendString;
}

Update_List()
{
		new rows, Cache: result, out[1024], text[32];
		result = mysql_query(Database, "SELECT * FROM `updates`");

		if(cache_get_row_count(rows))
		{
				for(new i = 0; i < rows; i++)
				{
						cache_get_value_name(i, "Text", text);
						format(out, sizeof(out), "%s\n%s", out, text);
				}
		}
		cache_delete(result);
		return out;
}

#endif
