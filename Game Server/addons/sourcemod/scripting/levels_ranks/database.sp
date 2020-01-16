#define SQL_CreateTable \
"CREATE TABLE IF NOT EXISTS `%s` \
(\
	`steam` varchar(22)%s PRIMARY KEY, \
	`name` varchar(32)%s, \
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
VALUES ('%s', '%s', %i, %i);"

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
	`steam` = '%s';"

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

static const char g_sConnectionError[] = "Lost connection", g_sDBConfigName[] = "levels_ranks";

void ConnectDB()
{
	if(SQL_CheckConfig(g_sDBConfigName))
	{
		Database.Connect(ConnectToDatabase, g_sDBConfigName);
	}
	else
	{
		static char sError[64];

		KeyValues hKv = new KeyValues(NULL_STRING, "driver", "sqlite");

		hKv.SetString("database", "lr_base");

		// For formatting sError. Reading function arguments from right to left about ConnectToDatabase().
		Database hDatabase = SQL_ConnectCustom(hKv, sError, sizeof(sError), false);

		ConnectToDatabase(hDatabase, sError, 0);

		hKv.Close();
	}
}

void ConnectToDatabase(Database hDatabase, const char[] sError, any NULL)
{
	static char sIdent[2], sQuery[768];

	if(sError[0])
	{
		SetFailState("Could not connect to the database - %s", sError);
	}

	(g_hDatabase = hDatabase).Driver.GetIdentifier(sIdent, 2);

	g_bDatabaseSQLite = sIdent[0] == 's';

	Transaction hTransaction = new Transaction();

	FormatEx(sQuery, sizeof(sQuery), SQL_CreateTable, g_sTableName, g_bDatabaseSQLite ? NULL_STRING : " COLLATE 'utf8_general_ci'", g_bDatabaseSQLite ? NULL_STRING : g_Settings[LR_DB_Allow_UTF8MB4] ? " COLLATE 'utf8mb4_general_ci'" : " COLLATE 'utf8_general_ci'");
	hTransaction.AddQuery(sQuery);

	FormatEx(sQuery, sizeof(sQuery), SQL_GetCountPlayers, g_sTableName);
	hTransaction.AddQuery(sQuery);

	if(!g_bDatabaseSQLite)
	{
		char sCharset[8];

		sCharset = g_Settings[LR_DB_Allow_UTF8MB4] ? "utf8mb4" : "utf8";

		if(!hDatabase.SetCharset(sCharset))
		{
			LogError("Set charset error (%s). Update dbi.mysql.ext for proper operation.", sCharset);
		}

		FormatEx(sQuery, sizeof(sQuery), "SET NAMES '%s';", sCharset);
		hTransaction.AddQuery(sQuery);

		FormatEx(sQuery, sizeof(sQuery), "SET CHARSET '%s';", sCharset);
		hTransaction.AddQuery(sQuery);

		FormatEx(sQuery, sizeof(sQuery), "ALTER TABLE `%s` CHARACTER SET '%s' COLLATE '%s_general_ci';", g_sTableName, sCharset, sCharset);
		hTransaction.AddQuery(sQuery);

		FormatEx(sQuery, sizeof(sQuery), "ALTER TABLE `%s` MODIFY COLUMN `name` varchar(32) CHARACTER SET '%s' COLLATE '%s_general_ci' NOT NULL default '' AFTER `steam`;", g_sTableName, sCharset, sCharset);
		hTransaction.AddQuery(sQuery);
	}

	hDatabase.Execute(hTransaction, SQL_TransactionCallback, SQL_TransactionFailure, LR_ConnectToDB, DBPrio_High);
}

void AuthAllPlayer()
{
	for(int i = GetMaxPlayers(); --i;)
	{
		if(IsClientAuthorized(i) && !IsFakeClient(i))
		{
			g_iPlayerInfo[i] = g_iInfoNULL;

			OnClientAuthorized(i, GetSteamID2(GetSteamAccountID(i)));
		}
	}
}

void OnCleanDB()
{
	if(g_hDatabase && g_Settings[LR_CleanDB_Days])
	{
		static char sQuery[256];

		FormatEx(sQuery, sizeof(sQuery), SQL_UpdateCleanDays, g_sTableName, g_Settings[LR_CleanDB_Days] * 86400);
		g_hDatabase.Query(SQL_Callback, sQuery);
	}
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if(g_hDatabase)
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

		if(iSteamIDType && (g_iPlayerInfo[iClient].iAccountID = iSteamIDType == 2 ? GetAccountID(sAuth) : StringToInt(sAuth[5])))
		{
			static char sQuery[512];

			FormatEx(sQuery, sizeof(sQuery), SQL_LoadData, g_sTableName, g_sTableName, g_sTableName, sAuth);
			g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | LR_LoadDataPlayer);
		}
	}
}

public Action OnBanClient(int iClient, int iTime, int iFlags, const char[] sReason, const char[] sKickMessage, const char[] sCommand, any Source)
{
	if(g_Settings[LR_CleanDB_BanClient])
	{
		g_iPlayerInfo[iClient].iSessionStats[ST_PLAYTIME] = -1;
	}
}

public Action OnBanIdentity(const char[] sIdEntity, int iTime, int iFlags, const char[] sReason, const char[] sCommand, any Source)
{
	if(g_hDatabase && g_Settings[LR_CleanDB_BanClient] && !strncmp(sIdEntity, "STEAM_", 6) && sIdEntity[7] == ':')
	{
		static char sQuery[256];

		FormatEx(sQuery, sizeof(sQuery), SQL_UpdateCleanBanClient, g_sTableName, sIdEntity);
		g_hDatabase.Query(SQL_Callback, sQuery);
	}
}

public void OnClientDisconnect(int iClient)
{
	SaveDataPlayer(iClient, true);
	g_iPlayerInfo[iClient].bInitialized = false;
}

void SaveDataPlayer(int iClient, bool bDisconnect = false)
{
	if(CheckStatus(iClient) && (g_hDatabase || bDisconnect))
	{
		int iTime = GetTime();

		static char sQuery[1024];

		Transaction hTransaction = g_hDatabase ? new Transaction() : g_hTransactionLossDB;

		FormatEx(sQuery, sizeof(sQuery), SQL_UpdateData, g_sTableName, g_iPlayerInfo[iClient].iStats[ST_EXP], GetPlayerName(iClient), g_iPlayerInfo[iClient].iStats[ST_RANK], g_iPlayerInfo[iClient].iStats[ST_KILLS], g_iPlayerInfo[iClient].iStats[ST_DEATHS], g_iPlayerInfo[iClient].iStats[ST_SHOOTS], g_iPlayerInfo[iClient].iStats[ST_HITS], g_iPlayerInfo[iClient].iStats[ST_HEADSHOTS], g_iPlayerInfo[iClient].iStats[ST_ASSISTS], g_iPlayerInfo[iClient].iStats[ST_ROUNDSWIN], g_iPlayerInfo[iClient].iStats[ST_ROUNDSLOSE], g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] + iTime, g_iPlayerInfo[iClient].iSessionStats[ST_PLAYTIME] == -1 ? 0 : iTime, GetSteamID2(g_iPlayerInfo[iClient].iAccountID));
		hTransaction.AddQuery(sQuery);

		CallForward_OnPlayerSaved(iClient, hTransaction);

		if(g_hDatabase)
		{
			g_hDatabase.Execute(hTransaction, _, SQL_TransactionFailure, 1, DBPrio_High);
		}

		if(bDisconnect)
		{
			g_iPlayerInfo[iClient] = g_iInfoNULL;
		}
		else if(g_hDatabase)
		{
			FormatEx(sQuery, sizeof(sQuery), SQL_GetPlace, g_sTableName, g_iPlayerInfo[iClient].iStats[ST_EXP], g_sTableName, g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] + iTime);
			g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | LR_GetPlacePlayer);
		}
	}
}

public void SQL_Callback(Database hDatabase, DBResultSet hResult, const char[] sError, int iData)
{
	if(!g_hDatabase)
	{
		LogError("Miss SQL request! Data: %i", iData);
	}
	else if(!hResult)
	{
		if(StrContains(sError, g_sConnectionError, false) != -1)
		{
			TryReconnectDB();
		}
		else
		{
			LogError("SQL_Callback Error (%i): %s", iData, sError);
		}
	}
	else if(iData)
	{
		int iClient = GetClientOfUserId(iData >> 4),
			iQueryType = iData & 0xF;

		if(iClient || iQueryType == LR_GetPlacePlayer)
		{
			switch(iQueryType)
			{
				case LR_GetPlacePlayer:
				{
					if(hResult.HasResults && hResult.FetchRow())
					{
						int iOldPlaceInTop = g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP],
							iOldPlaceInTopTime = g_iPlayerInfo[iClient].iStats[ST_PLACEINTOPTIME];

						g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP] = hResult.FetchInt(0);
						g_iPlayerInfo[iClient].iStats[ST_PLACEINTOPTIME] = hResult.FetchInt(1);

						if(iOldPlaceInTop)
						{
							g_iPlayerInfo[iClient].iSessionStats[ST_PLACEINTOP] += iOldPlaceInTop - g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP];
						}

						if(iOldPlaceInTopTime)
						{
							g_iPlayerInfo[iClient].iSessionStats[ST_PLACEINTOPTIME] += iOldPlaceInTopTime - g_iPlayerInfo[iClient].iStats[ST_PLACEINTOPTIME];
						}

						CallForward_OnPlayerPosInTop(iClient);
					}
				}

				case LR_CreateDataPlayer:
				{
					if(!g_iPlayerInfo[iClient].bInitialized)
					{
						ResetPlayerData(iClient);		// custom_function.sp

						g_iDBCountPlayers++;
						g_iPlayerInfo[iClient].bInitialized = true;

						CheckRank(iClient, false);

						CallForward_OnPlayerLoaded(iClient);
					}
				}

				case LR_LoadDataPlayer:
				{
					if(!g_iPlayerInfo[iClient].bInitialized)
					{
						if(hResult.HasResults && hResult.FetchRow())
						{
							for(int i = ST_EXP; i != LR_StatsType; i++)
							{
								g_iPlayerInfo[iClient].iStats[i] = hResult.FetchInt(i);
							}

							g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] += g_iPlayerInfo[iClient].iSessionStats[ST_PLAYTIME] -= GetTime();
							g_iPlayerInfo[iClient].bInitialized = true;

							CallForward_OnPlayerLoaded(iClient);
						}
						else if(g_hDatabase)
						{
							static char sQuery[256];

							FormatEx(sQuery, sizeof(sQuery), SQL_CreateData, g_sTableName, GetSteamID2(g_iPlayerInfo[iClient].iAccountID), GetPlayerName(iClient), g_Settings[LR_TypeStatistics] ? 1000 : 0, GetTime());
							g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | LR_CreateDataPlayer);
						}
					}
				}

				case LR_TopPlayersExp, LR_TopPlayersTime:		// from menus.sp
				{
					bool bType = iQueryType == LR_TopPlayersTime;

					char sText[1024],
						 sFrase[32] = "OverAllTopPlayers";

					static char sName[32];

					strcopy(sFrase[17], 8, bType ? "Time" : "Exp");
					FormatEx(sText, sizeof(sText), "%s | %T\n \n", g_sPluginTitle, sFrase, iClient);

					strcopy(sFrase[21 - int(!bType)], 8, "_Slot");

					if(hResult.RowCount)
					{
						int iAccountID = g_iPlayerInfo[iClient].iAccountID;

						for(int j = 1; hResult.FetchRow(); j++)
						{
							hResult.FetchString(0, sName, sizeof(sName));
							FormatEx(sText[strlen(sText)], 64, hResult.FetchInt(1) == iAccountID && !(iAccountID = 0) ? "%T %T\n" : "%T\n", sFrase, iClient, j, bType ? int(hResult.FetchFloat(2)) : hResult.FetchInt(2), sName, "You", iClient);
						}

						if(iAccountID)
						{
							int iPlace = g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP + int(bType)];

							GetClientName(iClient, sName, sizeof(sName));
							FormatEx(sText[strlen(sText)], 64, "%s\n%T %T\n ", iPlace == 11 ? NULL_STRING : "...", sFrase, iClient, iPlace, bType ? int((g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] + GetTime()) / 3600.0) : g_iPlayerInfo[iClient].iStats[ST_EXP], sName, "You", iClient);
						}
						else
						{
							sText[strlen(sText)] = ' ';
						}
					}
					else
					{
						FormatEx(sText[strlen(sText)], 16, "%T\n", "NoData", iClient);
					}

					Menu hMenu = new Menu(OverAllTopPlayers_Callback, MenuAction_Select);

					hMenu.SetTitle(sText);

					FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
					hMenu.AddItem(NULL_STRING, sText);

					hMenu.Display(iClient, MENU_TIME_FOREVER);
				}
			}
		}
	}
}

public void SQL_TransactionCallback(Database hDatabase, int iType, int iQueries, DBResultSet[] hResults, int[] iQueryData)
{
	if(iType > 9)		// LR_ConnectToDB, LR_ReconnectToDB
	{
		AuthAllPlayer();

		if(iType == LR_ConnectToDB)
		{
			DBResultSet hResult = hResults[1];

			if(hResult.HasResults && hResult.FetchRow())
			{
				g_iDBCountPlayers = hResult.FetchInt(0);
			}

			Call_StartForward(g_hForward_OnCoreIsReady);
			Call_Finish();


			delete g_hForward_OnCoreIsReady;
		}
	}
	else
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
}

public void SQL_TransactionFailure(Database hDatabase, int iData, int iNumQueries, const char[] sError, int iFailIndex, int[] iQueryData)
{
	if(iFailIndex)
	{
		if(StrContains(sError, g_sConnectionError, false) != -1)
		{
			TryReconnectDB();
		}
		else
		{
			LogError("SQL_TransactionFailure (%i): %s (%i)", iData, sError, iFailIndex);
		}
	}
}

void TryReconnectDB()
{
	delete g_hDatabase;

	if(GetForwardFunctionCount(g_hForward_Hook[LR_OnDisconnectionWithDB]))
	{
		CallForward_OnDisconnectionWithDB();

		if(g_hDatabase)
		{
			char sIdent[2];

			g_hDatabase.Driver.GetIdentifier(sIdent, sizeof(sIdent));
			g_bDatabaseSQLite = sIdent[0] == 's';

			return;
		}
	}

	g_iCountRetryConnect = 0;
	g_hTransactionLossDB = new Transaction();	

	LogError("Reconnect to the Database!");

	Database.Connect(ReconnectToDatabase, g_sDBConfigName);
}

void ReconnectToDatabase(Database hDatabase, const char[] sError, any NULL)
{
	if((g_hDatabase = hDatabase))
	{
		LogError("Successfully! Attempt #%i.", g_iCountRetryConnect);

		g_hDatabase.Execute(g_hTransactionLossDB, SQL_TransactionCallback, SQL_TransactionFailure, LR_ReconnectToDB, DBPrio_High);
	}
	else
	{
		Database.Connect(ReconnectToDatabase, g_sDBConfigName);

		LogError("Reconnecting #%i (%s)", ++g_iCountRetryConnect, sError);
	}
}