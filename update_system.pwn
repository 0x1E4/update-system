// This is a comment
// uncomment the line below if you want to write a filterscript
#define FILTERSCRIPT

#include <a_samp>
#include <a_mysql>
#include <easyDialog>
#include <zcmd>
#include <sscanf2>

#if defined FILTERSCRIPT

#define MYSQL_HOSTNAME		"localhost"
#define MYSQL_USERNAME		"root"
#define MYSQL_PASSWORD		""
#define MYSQL_DATABASE		"ablodm"

new MySQL: Database;

public OnFilterScriptInit()
{

	Database = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE);
	if(Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0)
	{
		print("[SERVER]: MySQL Connection failed, shutting the server down!");
		SendRconCommand("exit");
		return 1;
	}

	print("[SERVER]: MySQL Connection was successful.");

	mysql_query(Database, "CREATE TABLE IF NOT EXISTS updates (`UpdateID` int(10) AUTO_INCREMENT PRIMARY KEY, `AddedBy` VARCHAR(24) NOT NULL, `Text` VARCHAR(128) NOT NULL, `Status` int(10), `DateAdded` VARCHAR(30) NOT NULL); ");
	return 1;
}

CMD:addupdate(playerid, params[])
{
	new
		text[128], status, query[280]
	;

	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "You must be an admin to use this command.");
	if(sscanf(params, "is[128]", status, text)) 
	{ 
		SendClientMessage(playerid, -1, "[USAGE]: {AFAFAF}/addupdate [status] [text]");
		SendClientMessage(playerid, -1, "Use 1 if you want to display the update as added, 2 if you want to display it as changed, 3 as fixed and 4 as removed.");
		return 1;
	}

	mysql_format(Database, query, sizeof(query), "INSERT INTO `updates` (`AddedBy`, `Text`, `Status`, `DateAdded`) VALUES ('%e', '%e', '%i', '%e')", GetName(playerid), text, status, ReturnDate());
	mysql_tquery(Database, query, "OnPlayerAddUpdate", "iis", playerid, status, text);
	return 1;
}

CMD:removeupdate(playerid, params[])
{
	new 
		updateid, query[128]
	;

	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "You must be an admin to use this command.");
	if(sscanf(params, "i", updateid)) return SendClientMessage(playerid, -1, "[USAGE]: {AFAFAF}/removeupdate [updateid]");

	mysql_format(Database, query, sizeof(query), "SELECT `UpdateID` FROM `updates` WHERE `UpdateID` = '%i'", updateid);
	mysql_tquery(Database, query, "OnPlayerDeleteUpdate", "ii", playerid, updateid);
	return 1;
}

CMD:updates(playerid, params[])
{
	new 
		query[128]
	;

	mysql_format(Database, query, sizeof(query), "SELECT * FROM `updates`");
	mysql_pquery(Database, query, "Player_ViewUpdates", "i", playerid);
	return 1;
}

forward Player_ViewUpdates(playerid);
public Player_ViewUpdates(playerid)
{
	if(cache_num_rows())
	{
		new
			updateid, addedby[24], text[128], status, sstatus[128], dateadded[30], string[500] // the reason this is huge is because there might be a lot of updates so it should be bigger, you can change this any time you want.
		;

		format(string, sizeof(string), "This is a list of the new server updates on the last revision:\n\n");
		for(new i = 0; i < cache_num_rows(); i ++)
		{
			cache_get_value_name_int(i, "UpdateID", updateid);
			cache_get_value_name(i, "AddedBy", addedby);
			cache_get_value_name(i, "Text", text);
			cache_get_value_name_int(i, "Status", status);
			cache_get_value_name(i, "DateAdded", dateadded);

			switch(status)
			{
				case 1: sstatus = "Added";
				case 2: sstatus = "Changed";
				case 3: sstatus = "Fixed";
				case 4: sstatus = "Removed";
			}

			format(string, sizeof(string), "%s[%d] %s - %s [%s] on %s\n", string, updateid, sstatus, text, addedby, dateadded);
		}
		Dialog_Show(playerid, DIALOG_UPDATES, DIALOG_STYLE_MSGBOX, "Server new Updates", string, "Close", "");
	}
	else
	{
		Dialog_Show(playerid, DIALOG_UPDATES, DIALOG_STYLE_MSGBOX, "Server new Updates", "There are currently no updates on the database.", "Close", "");
	}
	return 1;
}

forward OnPlayerDeleteUpdate(playerid, updateid);
public OnPlayerDeleteUpdate(playerid, updateid)
{	
	if(cache_num_rows())
	{
		new
			string[128], query[128]
		;

		format(string, sizeof(string), "You have successfully removed UpdateID %d from the database.", updateid);
		SendClientMessage(playerid, -1, string);

		mysql_format(Database, query, sizeof(query), "DELETE FROM `updates` WHERE `UpdateID` = '%i'", updateid);
		mysql_query(Database, query);
	}
	else 
	{
		SendClientMessage(playerid, -1, "That UpdateID was not found in the database.");
	}
	return 1;
}

forward OnPlayerAddUpdate(playerid, status, text[]);
public OnPlayerAddUpdate(playerid, status, text[]) 
{
	new 
		updateid = cache_insert_id(), string[128], sstring[100]
	;

	switch(status)
	{
		case 1: sstring = "Added"; 
		case 2: sstring = "Changed";
		case 3: sstring = "Fixed";
		case 4: sstring = "Removed";
	}

	format(string, sizeof(string), "You have successfully a new update - [ID: %d] - [Text: %s] - [Status: %s]", updateid, text, sstring);
	SendClientMessage(playerid, -1, string);
	return 1;
}

GetName(playerid)
{
	new playerName[MAX_PLAYERS];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	return playerName;
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

#endif