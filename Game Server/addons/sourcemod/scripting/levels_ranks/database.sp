#define SQL_CreateTable \
"CREATE TABLE IF NOT EXISTS `%s` \
(\
	`steam` varchar(22)%s NOT NULL PRIMARY KEY DEFAULT '', \
	`name` varchar(32)%s NOT NULL DEFAULT '', \
	`value` int NOT NULL DEFAULT 0, \
	`rank` int NOT NULL DEFAULT 0, \
	`kills` int NOT NULL DEFAULT 0, \
	`deaths` int NOT NULL DEFAULT 0, \
	`shoots` int NOT NULL DEFAULT 0, \
	`hits` int NOT NULL DEFAULT 0, \
	`headshots` int NOT NULL DEFAULT 0, \
	`assists` int NOT NULL DEFAULT 0, \
	`round_win` int NOT NULL DEFAULT 0, \
	`round_lose` int NOT NULL DEFAULT 0, \
	`playtime` int NOT NULL DEFAULT 0, \
	`lastconnect` int NOT NULL DEFAULT 0\
);"

#define SQL_CreateData \
"INSERT INTO `%s` \
(\
	`steam`, \
	`name`, \
	`value`, \
	`lastconnect`\
) \
VALUES ('STEAM_%i:%i:%i', '%s', %i, %i);"

#define SQL_LoadData \
"SELECT \
	`value`, \
	`rank`, \
	`kills`, \
	`deaths`, \
	`shoots`, \
	`hits`, \
	`headshots`, \
	`assists`, \
	`round_win`, \
	`round_lose`, \
	`playtime`, \
	(SELECT COUNT(`steam`) FROM `%s` WHERE `value` >= `player`.`value` AND `lastconnect`) AS `exppos`, \
	(SELECT COUNT(`steam`) FROM `%s` WHERE `playtime` >= `player`.`playtime` AND `lastconnect`) AS `timepos` \
FROM \
	`%s` `player` \
WHERE \
	`steam` = '%s';"

#define SQL_GetCountPlayers "SELECT COUNT(`steam`) FROM `%s` WHERE `lastconnect`;"

#define SQL_UpdateData \
"UPDATE `%s` SET \
	`value` = %i, \
	`name` = '%s', \
	`rank` = %i, \
	`kills` = %i, \
	`deaths` = %i, \
	`shoots` = %i, \
	`hits` = %i, \
	`headshots` = %i, \
	`assists` = %i, \
	`round_win` = %i, \
	`round_lose` = %i, \
	`playtime` = %i, \
	`lastconnect` = %i \
WHERE \
	`steam` = 'STEAM_%i:%i:%i';"

#define SQL_UpdateCleanBanClient \
"UPDATE `%s` SET\
	`lastconnect` = 0 \
WHERE \
	`steam` = '%s';"

#define SQL_UpdateCleanDays \
"UPDATE `%s` SET\
	`lastconnect` = 0 \
WHERE \
	`lastconnect` < %d AND `lastconnect`;"

#define SQL_UpdateResetData \
"UPDATE `%s` SET \
	`value` = 0, \
	`rank` = 0, \
	`kills` = 0, \
	`deaths` = 0, \
	`shoots` = 0, \
	`hits` = 0, \
	`headshots` = 0, \
	`assists` = 0, \
	`round_win` = 0, \
	`round_lose` = 0, \
	`playtime` = 0, \
	`lastconnect` = 0 \
WHERE \
	`steam` = '%s';"

#define SQL_GetPlace \
"SELECT \
(\
	SELECT COUNT(`steam`) FROM `%s` WHERE `value` >= %d AND `lastconnect`\
) AS `exppos`, \
(\
	SELECT COUNT(`steam`) FROM `%s` WHERE `playtime` >= %d AND `lastconnect`\
) AS `timepos`;"

static const char g_sConnectionError[] = "Lost connection";

void ConnectDB()
{
	char sIdent[2], sError[256], sQuery[768];

	static const char sDBConfigName[] = "levels_ranks";

	if(!(g_hDatabase = SQL_CheckConfig(sDBConfigName) ? SQL_Connect(sDBConfigName, false, sError, sizeof(sError)) : SQLite_UseDatabase("lr_base", sError, sizeof(sError))))
	{
		SetFailState("Could not connect to the database - %s", sError);
	}

	g_hDatabase.Driver.GetIdentifier(sIdent, 2);

	g_bDatabaseSQLite = sIdent[0] == 's';

	SQL_LockDatabase(g_hDatabase);

	FormatEx(sQuery, sizeof(sQuery), SQL_CreateTable, g_sTableName, g_bDatabaseSQLite ? NULL_STRING : " COLLATE utf8_general_ci", g_bDatabaseSQLite ? NULL_STRING : " COLLATE utf8mb4_general_ci");
	SQL_FastQuery(g_hDatabase, sQuery);

	if(!g_bDatabaseSQLite)
	{
		FormatEx(sQuery, strlen(sQuery), "ALTER TABLE `%s` MODIFY COLUMN `name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL default '' AFTER `steam`;", g_sTableName);
		SQL_FastQuery(g_hDatabase, sQuery);
	}

	FormatEx(sQuery, sizeof(sQuery), SQL_GetCountPlayers, g_sTableName);

	DBResultSet hResult = SQL_Query(g_hDatabase, sQuery);

	if(hResult.HasResults && hResult.FetchRow())
	{
		g_iDBCountPlayers = hResult.FetchInt(0);
	}

	hResult.Close();

	SQL_UnlockDatabase(g_hDatabase);

	AuthAllPlayer();
}

Action Call_ResetData(int iArgs)
{
	if(iArgs != 1)
	{
		PrintToServer("[LR] Usage: sm_lvl_reset <all|exp|stats>");

		return Plugin_Handled;
	}

	int iType = -1;

	static char sBuffer[512];

	GetCmdArg(1, sBuffer, 8);

	if(!strcmp(sBuffer, "all"))
	{
		iType = 0;
	}
	else if(!strcmp(sBuffer, "exp"))
	{
		iType = 1;
	}
	else if(!strcmp(sBuffer, "stats"))
	{
		iType = 2;
	}

	if(iType != -1)
	{
		Transaction hTransaction = new Transaction();

		switch(iType)
		{
			case 0:
			{
				FormatEx(sBuffer, sizeof(sBuffer), "DROP TABLE `%s`;", g_sTableName);
				hTransaction.AddQuery(sBuffer);
			}

			case 1:
			{
				FormatEx(sBuffer, sizeof(sBuffer), "UPDATE `%s` SET `value` = %i, `rank` = 0;", g_sTableName, g_Settings[LR_TypeStatistics] ? 1000 : 0);
				hTransaction.AddQuery(sBuffer);
			}

			case 2:
			{
				FormatEx(sBuffer, sizeof(sBuffer), "UPDATE `%s` SET `kills` = 0, `deaths` = 0, `shoots` = 0, `hits` = 0, `headshots` = 0, `assists` = 0, `round_win` = 0, `round_lose` = 0;", g_sTableName);
				hTransaction.AddQuery(sBuffer);
			}
		}

		Call_StartForward(g_hForward_Hook[LR_OnDatabaseCleanup]);
		Call_PushCell(iType);
		Call_PushCell(hTransaction);
		Call_Finish();

		g_hDatabase.Execute(hTransaction, SQL_ResetData, SQL_TransactionFailure, iType, DBPrio_High);

		return Plugin_Handled;
	}

	PrintToServer("[LR] %s - invalid type of cleaning.", sBuffer);

	return Plugin_Handled;
}

Action Call_ResetPlayer(int iClient, int iArgs)
{
	if(iArgs != 1)
	{
		ReplyToCommand(iClient, "[LR] Usage: sm_lvl_del <#userid|name|steamid>");

		return Plugin_Handled;
	}

	bool bTargetIsMl = false;

	int iTargets = 0,
		iTargetList[MAXPLAYERS+1];

	char sBuffer[128];

	GetCmdArg(1, sBuffer, 65);

	int iAccountID = (!strncmp(sBuffer, "STEAM_", 6) && sBuffer[7] == ':') ? (StringToInt(sBuffer[10]) << 1 | sBuffer[8] - '0') : 0;

	if((iTargets = ProcessTargetString(sBuffer, iClient, iTargetList, sizeof(iTargetList), COMMAND_FILTER_NO_BOTS, sBuffer, sizeof(sBuffer), bTargetIsMl)) < 1 && !iAccountID)
	{
		ReplyToTargetError(iClient, iTargets);

		return Plugin_Handled;
	}

	for(int i = 0; i != iTargets; i++)
	{
		ResetPlayerCommand(iClient, iTargetList[i]);
	}

	if(iAccountID)
	{
		for(int i = GetMaxPlayers(); --i;)
		{
			if(g_iPlayerInfo[i].iAccountID == iAccountID && g_iPlayerInfo[i].bInitialized)
			{
				ResetPlayerCommand(iClient, i);

				return Plugin_Handled;
			}
		}

		Call_StartForward(g_hForward_Hook[LR_OnResetPlayerStats]);
		Call_PushCell(0);
		Call_PushCell(iAccountID);
		Call_Finish();

		Format(sBuffer, sizeof(sBuffer), SQL_UpdateResetData, g_sTableName, sBuffer);
		g_hDatabase.Query(SQL_Callback, sBuffer, 0);
	}

	return Plugin_Handled;
}

void ResetPlayerCommand(int iClient, int iTarget)
{
	ResetPlayerStats(iTarget);
	LogAction(iClient, iTarget, "[LR] %L reset statistics at %L!", iClient, iTarget);
}

void AuthAllPlayer()
{
	static char sSteamID[22];

	for(int i = GetMaxPlayers(); --i;)
	{
		if(IsClientAuthorized(i) && !IsFakeClient(i))
		{
			g_iPlayerInfo[i] = g_iInfoNULL;

			GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
			OnClientAuthorized(i, sSteamID);
		}
	}
}

void GetPlacePlayer(int iClient)
{
	if(g_hDatabase)
	{
		static char sQuery[256];

		FormatEx(sQuery, sizeof(sQuery), SQL_GetPlace, g_sTableName, g_iPlayerInfo[iClient].iStats[ST_EXP], g_sTableName, g_iPlayerInfo[iClient].iStats[ST_PLAYTIME]);
		g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | 1, DBPrio_High);
	}
}

void OnCleanDB()
{
	if(g_Settings[LR_CleanDB_Days])
	{
		static char sQuery[256];

		FormatEx(sQuery, sizeof(sQuery), SQL_UpdateCleanDays, g_sTableName, g_Settings[LR_CleanDB_Days] * 86400);
		g_hDatabase.Query(SQL_Callback, sQuery);
	}
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	int iSteamIDType = 0;

	if(sAuth[0] == 'S' && sAuth[7] == ':')
	{
		iSteamIDType = 2;
	}
	else if(sAuth[0] == '[' && sAuth[1] == 'U')		// for CS:S v34
	{
		iSteamIDType = 3;
	}

	if(iSteamIDType && g_hDatabase && (g_iPlayerInfo[iClient].iAccountID = iSteamIDType == 2 ? (StringToInt(sAuth[10]) << 1 | sAuth[8] - '0') : StringToInt(sAuth[5])))
	{
		static char sQuery[512];

		FormatEx(sQuery, sizeof(sQuery), SQL_LoadData, g_sTableName, g_sTableName, g_sTableName, sAuth);
		g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | 3, DBPrio_High);
	}
}

public Action OnBanClient(int iClient, int iTime, int iFlags, const char[] sReason, const char[] sKickMessage, const char[] sCommand, any Source)
{
	if(g_Settings[LR_CleanDB_BanClient])
	{
		g_iPlayerInfo[iClient].iSessionStats[9] = -1;
	}
}

public Action OnBanIdentity(const char[] sIdEntity, int iTime, int iFlags, const char[] sReason, const char[] sCommand, any Source)
{
	if(g_Settings[LR_CleanDB_BanClient] && !strncmp(sIdEntity, "STEAM_", 6) && sIdEntity[7] == ':')
	{
		static char sQuery[256];

		FormatEx(sQuery, sizeof(sQuery), SQL_UpdateCleanBanClient, g_sTableName, sIdEntity);
		g_hDatabase.Query(SQL_Callback, sQuery);
	}
}

public void OnClientDisconnect(int iClient)
{
	SaveDataPlayer(iClient, true);
}

void SaveDataPlayer(int iClient, bool bDisconnect = false)
{
	if(CheckStatus(iClient) && (g_hDatabase || bDisconnect))
	{
		int iAccountID = g_iPlayerInfo[iClient].iAccountID;

		static char sQuery[1024];

		Transaction hTransaction = g_hDatabase ? new Transaction() : g_hTransactionLossDB;

		FormatEx(sQuery, sizeof(sQuery), SQL_UpdateData, g_sTableName, g_iPlayerInfo[iClient].iStats[ST_EXP], GetPlayerName(iClient), g_iPlayerInfo[iClient].iStats[ST_RANK], g_iPlayerInfo[iClient].iStats[ST_KILLS], g_iPlayerInfo[iClient].iStats[ST_DEATHS], g_iPlayerInfo[iClient].iStats[ST_SHOOTS], g_iPlayerInfo[iClient].iStats[ST_HITS], g_iPlayerInfo[iClient].iStats[ST_HEADSHOTS], g_iPlayerInfo[iClient].iStats[ST_ASSISTS], g_iPlayerInfo[iClient].iStats[ST_ROUNDSWIN], g_iPlayerInfo[iClient].iStats[ST_ROUNDSLOSE], g_iPlayerInfo[iClient].iStats[ST_PLAYTIME], g_iPlayerInfo[iClient].iSessionStats[9] == -1 ? 0 : GetTime(), g_iEngine == Engine_CSGO, iAccountID & 1, iAccountID >>> 1);
		hTransaction.AddQuery(sQuery);

		Call_StartForward(g_hForward_Hook[LR_OnPlayerSaved]);
		Call_PushCell(iClient);
		Call_PushCell(hTransaction);
		Call_Finish();

		if(g_hDatabase)
		{
			g_hDatabase.Execute(hTransaction, _, SQL_TransactionFailure, 1, DBPrio_High);
		}

		if(bDisconnect)
		{
			g_iPlayerInfo[iClient] = g_iInfoNULL;

			return;
		}

		GetPlacePlayer(iClient);
	}
}

public void SQL_Callback(Database hDatabase, DBResultSet hResult, const char[] sError, int iData)
{
	if(!g_hDatabase)
	{
		LogError("Miss SQL request! Data: %i", iData);

		return;
	}

	if(!hResult)
	{
		if(StrContains(sError, g_sConnectionError, false) != -1)
		{
			TryReconnectDB();

			return;
		}

		LogError("SQL_Callback Error (%i): %s", iData, sError);

		return;
	}

	if(iData)
	{
		int iClient = GetClientOfUserId(iData >> 4),
			iQueryType = iData & 0xF;

		if(iClient || iQueryType == 1)
		{
			switch(iQueryType)
			{
				case 1:		// GetPlacePlayer
				{
					if(hResult.HasResults && hResult.FetchRow())
					{
						int iExpPos = hResult.FetchInt(0),
							iTimePos = hResult.FetchInt(1);

						g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP] = iExpPos;
						g_iPlayerInfo[iClient].iStats[ST_PLACEINTOPTIME] = iTimePos;

						Call_StartForward(g_hForward_Hook[LR_OnPlayerPosInTop]);
						Call_PushCell(iClient);
						Call_PushCell(iExpPos);
						Call_PushCell(iTimePos);
						Call_Finish();
					}
				}

				case 2:		// CreateDataPlayer
				{
					static char sLastResetMyStats[12];

					ResetPlayerData(iClient);		// custom_function.sp

					IntToString(g_iPlayerInfo[iClient].iStats[ST_PLAYTIME], sLastResetMyStats, sizeof(sLastResetMyStats));
					g_hResetMyStats.Set(iClient, sLastResetMyStats);

					g_iDBCountPlayers++;

					CheckRank(iClient);

					Call_StartForward(g_hForward_Hook[LR_OnPlayerLoaded]);
					Call_PushCell(iClient);
					Call_PushCell(g_iPlayerInfo[iClient].iAccountID);
					Call_Finish();
				}

				case 3:		// OnClientAuthorized
				{
					if(hResult.HasResults && hResult.FetchRow())
					{
						for(int i = ST_EXP; i != LR_StatsType; i++)
						{
							g_iPlayerInfo[iClient].iStats[i] = hResult.FetchInt(i);
						}

						g_iPlayerInfo[iClient].iSessionStats[0] = g_iPlayerInfo[iClient].iStats[ST_EXP];
						g_iPlayerInfo[iClient].bInitialized = true;

						Call_StartForward(g_hForward_Hook[LR_OnPlayerLoaded]);
						Call_PushCell(iClient);
						Call_PushCell(g_iPlayerInfo[iClient].iAccountID);
						Call_Finish();

						return;
					}

					if(g_hDatabase)		// CreateDataPlayer
					{
						int iAccountID = g_iPlayerInfo[iClient].iAccountID;

						static char sQuery[512];

						FormatEx(sQuery, sizeof(sQuery), SQL_CreateData, g_sTableName, g_iEngine == Engine_CSGO, iAccountID & 1, iAccountID >>> 1, GetPlayerName(iClient), g_Settings[LR_TypeStatistics] ? 1000 : 0, GetTime());
						g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | 2);
					}
				}

				case 4, 5:		// OverAllTopPlayers in menus.sp
				{
					bool bType = (iData & 0xF) == 5;

					char sText[1024],
						 sFrase[32] = "OverAllTopPlayers";

					static char sName[32];

					strcopy(sFrase[17], 8, bType ? "Exp" : "Time");
					FormatEx(sText, sizeof(sText), "%s | %T\n \n", g_sPluginTitle, sFrase, iClient);

					strcopy(sFrase[21 - view_as<int>(bType)], 8, "_Slot");

					if(hResult.HasResults)
					{
						for(int j = 1; hResult.FetchRow(); j++)
						{
							hResult.FetchString(0, sName, sizeof(sName));

							FormatEx(sText[strlen(sText)], 64, "%T\n", sFrase, iClient, j, bType ? hResult.FetchInt(1) : view_as<int>(hResult.FetchFloat(1)), sName);
						}
					}

					strcopy(sText[strlen(sText)], 4, "\n ");

					if(g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP + view_as<int>(!bType)] > 10)
					{
						GetClientName(iClient, sName, sizeof(sName));

						FormatEx(sText[strlen(sText)], 64, "...\n%T\n ", sFrase, iClient, g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP + view_as<int>(bType)], g_iPlayerInfo[iClient].iStats[ST_EXP], sName);
					}

					Menu hMenu = new Menu(OverAllTopPlayers_Callback, MenuAction_Select);		// in menus.sp

					hMenu.SetTitle(sText);

					FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
					hMenu.AddItem(NULL_STRING, sText);

					hMenu.Display(iClient, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

public void SQL_ResetData(Database hDatabase, int iType, int iQueries, DBResultSet[] hResults, int[] iQueryData)
{
	static const char sTypes[][] = {"all", "exp", "stats"};

	if(iType)
	{
		AuthAllPlayer();
	}
	else
	{
		g_hDatabase.Close();
		ConnectDB();
	}

	LogMessage("[LR] Successful clearing %s data in the database!", sTypes[iType]);
}

public void SQL_TransactionFailure(Database hDatabase, int iData, int iNumQueries, const char[] sError, int iFailIndex, int[] iQueryData)
{
	if(iFailIndex)
	{
		if(StrContains(sError, g_sConnectionError, false) != -1)
		{
			TryReconnectDB();

			return;
		}

		LogError("SQL_TransactionFailure (%i): %s (%i)", iData, sError, iFailIndex);
	}
}

void TryReconnectDB()
{
	delete g_hDatabase;

	if(GetForwardFunctionCount(g_hForward_Hook[LR_OnDisconnectionWithDB]))
	{
		Call_StartForward(g_hForward_Hook[LR_OnDisconnectionWithDB]);
		Call_PushCellRef(g_hDatabase);
		Call_Finish();

		if(g_hDatabase)
		{
			return;
		}

		char sIdent[2];

		g_hDatabase.Driver.GetIdentifier(sIdent, 2);

		g_bDatabaseSQLite = sIdent[0] == 's';
	}

	g_iCountRetryConnect = 0;
	g_hTransactionLossDB = new Transaction();	

	LogError("Reconnect to the Database!");
	CreateTimer(5.0, TryReconnectDBTimer, _, TIMER_REPEAT);
}

Action TryReconnectDBTimer(Handle hTimer)
{
	static char sError[4];

	if((g_hDatabase = SQL_Connect("levels_ranks", false, sError, sizeof(sError))))
	{
		LogError("Successfully! Attempt #%i.", g_iCountRetryConnect);

		g_hDatabase.Execute(g_hTransactionLossDB, _, SQL_TransactionFailure, 2, DBPrio_High);

		AuthAllPlayer();

		return Plugin_Stop;
	}

	LogError("\nReconnecting (%i) #%i ...", sError, ++g_iCountRetryConnect);

	return Plugin_Continue;
}