#define SQL_CREATE_TABLE \
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

#define SQL_LOAD_DATA \
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
	`steam` = '%s' \
LIMIT 1;"

#define SQL_COUNT_PLAYERS "SELECT COUNT(`steam`) FROM `%s` WHERE `lastconnect` LIMIT 1;"

#define SQL_CREATE_DATA \
"INSERT INTO `%s` \
(\
	`steam`, \
	`name`, \
	`value`, \
	`lastconnect`\
) \
VALUES ('STEAM_%i:%i:%i', '%s', %i, %i);"

#define SQL_REPLACE_DATA \
"REPLACE INTO `%s` \
(\
	`steam`, \
	`value`, \
	`name`, \
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
	`lastconnect` \
) \
VALUES ('STEAM_%i:%i:%i', %i, '%s', %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i);"

#define SQL_UPDATE_CLEAN_BAN_CLIENT \
"UPDATE `%s` SET\
	`lastconnect` = 0 \
WHERE \
	`steam` = '%s' \
LIMIT 1;"

#define SQL_UPDATE_CLEAN_DAYS \
"UPDATE `%s` SET\
	`lastconnect` = 0 \
WHERE \
	`lastconnect` < %d AND `lastconnect`;"

#define SQL_UPDATE_RESET_DATA \
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
	`steam` = '%s' \
LIMIT 1;"

#define SQL_GET_PLACE \
"SELECT \
(\
	SELECT COUNT(`steam`) FROM `%s` WHERE `value` >= %d AND `lastconnect`\
) AS `exppos`, \
(\
	SELECT COUNT(`steam`) FROM `%s` WHERE `playtime` >= %d AND `lastconnect`\
) AS `timepos` \
LIMIT 1;"

static const char s_sDBConfigName[] = "levels_ranks";

void ConnectDB()
{
	if(SQL_CheckConfig(s_sDBConfigName))
	{
		Database.Connect(ConnectToDatabase, s_sDBConfigName);
	}
	else
	{
		decl char sError[64];

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
	decl char sIdent[2], sQuery[768];

	if(sError[0])
	{
		SetFailState("Could not connect to the database - %s", sError);
	}

	(g_hDatabase = hDatabase).Driver.GetIdentifier(sIdent, 2);

	g_bDatabaseSQLite = sIdent[0] == 's';

	Transaction hTransaction = new Transaction();

	FormatEx(sQuery, sizeof(sQuery), SQL_CREATE_TABLE, g_sTableName, g_bDatabaseSQLite ? NULL_STRING : " COLLATE 'utf8_unicode_ci'", g_bDatabaseSQLite ? NULL_STRING : g_Settings[LR_DB_Allow_UTF8MB4] ? " COLLATE 'utf8mb4_unicode_ci'" : " COLLATE 'utf8_unicode_ci'");
	hTransaction.AddQuery(sQuery);

	FormatEx(sQuery, sizeof(sQuery), SQL_COUNT_PLAYERS, g_sTableName);
	hTransaction.AddQuery(sQuery);

	if(!g_bDatabaseSQLite)
	{
		decl char sCharset[8], 
		          sCharsetType[16];

		sCharset = g_Settings[LR_DB_Allow_UTF8MB4] ? "utf8mb4" : "utf8";
		sCharsetType = g_Settings[LR_DB_Charset_Type] ? "_unicode_ci" : "_general_ci";

		if(!hDatabase.SetCharset(sCharset))
		{
			LogError("Set charset error (%s). Update dbi.mysql.ext for proper operation.", sCharset);
		}

		FormatEx(sQuery, sizeof(sQuery), "SET NAMES '%s';", sCharset);
		hTransaction.AddQuery(sQuery);

		FormatEx(sQuery, sizeof(sQuery), "SET CHARSET '%s';", sCharset);
		hTransaction.AddQuery(sQuery);

		FormatEx(sQuery, sizeof(sQuery), "ALTER TABLE `%s` CHARACTER SET '%s' COLLATE '%s%s';", g_sTableName, sCharset, sCharset, sCharsetType);
		hTransaction.AddQuery(sQuery);

		FormatEx(sQuery, sizeof(sQuery), "ALTER TABLE `%s` MODIFY COLUMN `name` varchar(%i) CHARACTER SET '%s' COLLATE '%s%s' NOT NULL default '' AFTER `steam`;", g_sTableName, MAX_NAME_LENGTH, sCharset, sCharset, sCharsetType);
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
		decl char sQuery[256];

		FormatEx(sQuery, sizeof(sQuery), SQL_UPDATE_CLEAN_DAYS, g_sTableName, GetTime() - g_Settings[LR_CleanDB_Days] * 86400);
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

		if(iSteamIDType && (g_iPlayerInfo[iClient].iAccountID = iSteamIDType == 2 ? GetAccountIDFromSteamID2(sAuth) : StringToInt(sAuth[5])))
		{
			decl char sQuery[512];

			FormatEx(sQuery, sizeof(sQuery), SQL_LOAD_DATA, g_sTableName, g_sTableName, g_sTableName, sAuth);
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
		decl char sQuery[256];

		FormatEx(sQuery, sizeof(sQuery), SQL_UPDATE_CLEAN_BAN_CLIENT, g_sTableName, sIdEntity);
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
		int iAccountID = g_iPlayerInfo[iClient].iAccountID, 
		    iTime = GetTime();

		decl char sQuery[1024];

		Transaction hTransaction = new Transaction();

		FormatEx(sQuery, sizeof(sQuery), SQL_REPLACE_DATA, g_sTableName, g_iEngine == Engine_CSGO, iAccountID & 1, iAccountID >>> 1, g_iPlayerInfo[iClient].iStats[ST_EXP], GetPlayerName(iClient), g_iPlayerInfo[iClient].iStats[ST_RANK], g_iPlayerInfo[iClient].iStats[ST_KILLS], g_iPlayerInfo[iClient].iStats[ST_DEATHS], g_iPlayerInfo[iClient].iStats[ST_SHOOTS], g_iPlayerInfo[iClient].iStats[ST_HITS], g_iPlayerInfo[iClient].iStats[ST_HEADSHOTS], g_iPlayerInfo[iClient].iStats[ST_ASSISTS], g_iPlayerInfo[iClient].iStats[ST_ROUNDSWIN], g_iPlayerInfo[iClient].iStats[ST_ROUNDSLOSE], g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] + iTime, g_iPlayerInfo[iClient].iSessionStats[ST_PLAYTIME] == -1 ? 0 : iTime);
		hTransaction.AddQuery(sQuery);

		CallForward_OnPlayerSaved(iClient, hTransaction);

		g_hDatabase.Execute(hTransaction, _, SQL_TransactionFailure, 1, DBPrio_High);

		if(bDisconnect)
		{
			g_iPlayerInfo[iClient] = g_iInfoNULL;
		}
		else
		{
			FormatEx(sQuery, sizeof(sQuery), SQL_GET_PLACE, g_sTableName, g_iPlayerInfo[iClient].iStats[ST_EXP], g_sTableName, g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] + iTime);
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
		LogError("SQL_Callback Error (%i): %s", iData, sError);
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
						else
						{
							int iAccountID = g_iPlayerInfo[iClient].iAccountID;

							decl char sQuery[1024];

							FormatEx(sQuery, sizeof(sQuery), SQL_CREATE_DATA, g_sTableName, g_iEngine == Engine_CSGO, iAccountID & 1, iAccountID >>> 1, GetPlayerName(iClient), g_Settings[LR_TypeStatistics] ? 1000 : 0, GetTime());
							g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | LR_CreateDataPlayer);
						}
					}
				}

				case LR_TopPlayersExp, LR_TopPlayersTime:		// from menus.sp
				{
					bool bType = iQueryType == LR_TopPlayersTime;

					char sText[1024],
					     sFrase[32] = "OverAllTopPlayers";

					decl char sName[32];

					strcopy(sFrase[17], 8, bType ? "Time" : "Exp");
					FormatEx(sText, sizeof(sText), "%s | %T\n \n", g_sPluginTitle, sFrase, iClient);

					strcopy(sFrase[21 - view_as<int>(!bType)], 8, "_Slot");

					if(hResult.RowCount)
					{
						int iAccountID = g_iPlayerInfo[iClient].iAccountID;

						for(int j = 1; hResult.FetchRow(); j++)
						{
							hResult.FetchString(0, sName, sizeof(sName));
							FormatEx(sText[strlen(sText)], 64, hResult.FetchInt(1) == iAccountID && !(iAccountID = 0) ? "%T %T\n" : "%T\n", sFrase, iClient, j, bType ? view_as<int>(hResult.FetchFloat(2)) : hResult.FetchInt(2), sName, "You", iClient);
						}

						if(iAccountID)
						{
							int iPlace = g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP + view_as<int>(bType)];

							GetClientName(iClient, sName, sizeof(sName));
							FormatEx(sText[strlen(sText)], 64, "%s\n%T %T\n ", iPlace == 11 ? NULL_STRING : "...", sFrase, iClient, iPlace, bType ? view_as<int>((GetTime() + g_iPlayerInfo[iClient].iStats[ST_PLAYTIME]) / 3600.0) : g_iPlayerInfo[iClient].iStats[ST_EXP], sName, "You", iClient);
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

void SQL_TransactionCallback(Database hDatabase, int iType, int iQueries, DBResultSet[] hResults, int[] iQueryData)
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

			CallForward_OnCoreIsReady();
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

void SQL_TransactionFailure(Database hDatabase, int iData, int iNumQueries, const char[] sError, int iFailIndex, int[] iQueryData)
{
	if(iFailIndex)
	{
		LogError("SQL_TransactionFailure (%i): %s (%i)", iData, sError, iFailIndex);
	}
}
