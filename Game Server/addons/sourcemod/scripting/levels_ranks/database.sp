void ConnectDB()
{
	char sIdent[16], sError[256], sQuery[640], sQueryFast[256];

	if(SQL_CheckConfig("levels_ranks"))
	{
		g_hDatabase = SQL_Connect("levels_ranks", false, sError, 256);
	}
	else g_hDatabase = SQLite_UseDatabase("lr_base", sError, 256);

	g_hDatabase.Driver.GetIdentifier(sIdent, sizeof(sIdent));
	if(sIdent[0] == 's')
	{
		g_bDatabaseSQLite = true;
	}

	if(!g_hDatabase)
	{
		delete g_hDatabase;
		CrashLR("Could not connect to the database (%s)", sError);
	}

	SQL_LockDatabase(g_hDatabase);

	FormatEx(sQuery, 640, "CREATE TABLE IF NOT EXISTS `%s` (`steam` varchar(32) NOT NULL PRIMARY KEY default '', `name` varchar(128) NOT NULL default '', `value` NUMERIC, `rank` NUMERIC, `kills` NUMERIC, `deaths` NUMERIC, `shoots` NUMERIC, `hits` NUMERIC, `headshots` NUMERIC, `assists` NUMERIC, `round_win` NUMERIC, `round_lose` NUMERIC, `playtime` NUMERIC, `lastconnect` NUMERIC)%s", g_sTableName, g_bDatabaseSQLite ? ";" : " CHARSET=utf8 COLLATE utf8_general_ci");
	if(!SQL_FastQuery(g_hDatabase, sQuery)) CrashLR("ConnectDB - could not create table");

	FormatEx(sQueryFast, 256, "ALTER TABLE `%s` DROP COLUMN `id`;", g_sTableName);
	SQL_FastQuery(g_hDatabase, sQueryFast);

	FormatEx(sQueryFast, 256, "ALTER TABLE `%s` MODIFY COLUMN `steam` varchar(32) NOT NULL default '' FIRST;", g_sTableName);
	SQL_FastQuery(g_hDatabase, sQueryFast);

	FormatEx(sQueryFast, 256, "ALTER TABLE `%s` MODIFY COLUMN `name` varchar(128) NOT NULL default '' AFTER steam;", g_sTableName);
	SQL_FastQuery(g_hDatabase, sQueryFast);

	SQL_UnlockDatabase(g_hDatabase);

	g_hDatabase.SetCharset("utf8");
	GetCountPlayers();

	Call_StartForward(g_hForward_OnCoreIsReady);
	Call_Finish();
}

void GetCountPlayers()
{
	if(!g_hDatabase)
	{
		LogLR("GetCountPlayers - database is invalid");
		return;
	}
	else
	{
		char sQuery[128];
		FormatEx(sQuery, 128, "SELECT COUNT(`steam`) FROM `%s` WHERE `lastconnect` > 0;", g_sTableName);
		g_hDatabase.Query(GetCountPlayers_Callback, sQuery);
	}
}

public void GetCountPlayers_Callback(Database db, DBResultSet dbRs, const char[] sError, any iClient)
{
	if(!dbRs)
	{
		LogLR("GetCountPlayers - %s", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	if(dbRs.HasResults && dbRs.FetchRow())
	{
		g_iDBCountPlayers = dbRs.FetchInt(0);
	}
}

void GetPlacePlayer(int iClient)
{
	if(!g_hDatabase)
	{
		LogLR("GetPlacePlayer - database is invalid");
	}
	else
	{
		char sQuery[256];
		FormatEx(sQuery, 256, "SELECT COUNT(*) AS `position` FROM (SELECT DISTINCT `value` FROM `%s` WHERE `value` >= %d AND `lastconnect` > 0) t;", g_sTableName, g_iClientData[iClient][ST_EXP]);
		g_hDatabase.Query(GetPlacePlayer_Callback, sQuery, iClient);
	}
}

public void GetPlacePlayer_Callback(Database db, DBResultSet dbRs, const char[] sError, any iClient)
{
	if(!dbRs)
	{
		LogLR("GetPlacePlayer - %s", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	if(dbRs.HasResults && dbRs.FetchRow())
	{
		int iPos = dbRs.FetchInt(0);
		g_iClientData[iClient][ST_PLACEINTOP] = iPos;
		Call_StartForward(g_hForward_OnPlayerPlace);
		Call_PushCell(iClient);
		Call_PushCell(iPos);
		Call_Finish();
	}
}

void CreateDataPlayer(int iClient)
{
	if(!g_hDatabase)
	{
		LogLR("CreateDataPlayer - database is invalid");
	}
	else
	{
		if(IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient))
		{
			char sQuery[512];
			g_hDatabase.Format(sQuery, sizeof(sQuery), "INSERT INTO `%s` (`value`, `steam`, `name`, `lastconnect`) VALUES ('%d', '%s', '%s', '%d');", g_sTableName, !g_iTypeStatistics ? 0 : 1000, g_sSteamID[iClient], GetFixNamePlayer(iClient), GetTime());
			g_hDatabase.Query(CreateDataPlayer_Callback, sQuery, iClient, DBPrio_High);
		}
	}
}

public void CreateDataPlayer_Callback(Database db, DBResultSet dbRs, const char[] sError, any iClient)
{
	if(!dbRs)
	{
		LogLR("CreateDataPlayer - %s", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		g_iClientData[iClient][ST_EXP] = !g_iTypeStatistics ? 0 : 1000;
		for(int i = 1; i != view_as<int>(LR_StatsType)-1; i++)
		{
			g_iClientData[iClient][i] = 0;
		}
		g_iClientSessionData[iClient][0] = g_iClientData[iClient][ST_EXP];
		g_bInitialized[iClient] = true;
		g_iDBCountPlayers++;

		GetPlacePlayer(iClient);
		CheckRank(iClient);
		Call_StartForward(g_hForward_OnPlayerLoaded);
		Call_PushCell(iClient);
		Call_PushString(g_sSteamID[iClient]);
		Call_Finish();
	}
}

void LoadDataPlayer(int iClient)
{
	if(!g_hDatabase)
	{
		LogLR("LoadDataPlayer - database is invalid");
	}
	else
	{
		if(!IsFakeClient(iClient) && !g_bInitialized[iClient])
		{
			char sQuery[256];
			GetClientAuthId(iClient, AuthId_Steam2, g_sSteamID[iClient], 32);
			FormatEx(sQuery, sizeof(sQuery), "SELECT `value`, `rank`, `kills`, `deaths`, `shoots`, `hits`, `headshots`, `assists`, `round_win`, `round_lose`, `playtime` FROM `%s` WHERE `steam` = '%s';", g_sTableName, g_sSteamID[iClient]);
			g_hDatabase.Query(LoadDataPlayer_Callback, sQuery, iClient, DBPrio_High);
		}
	}
}

public void LoadDataPlayer_Callback(Database db, DBResultSet dbRs, const char[] sError, any iClient)
{
	if(!dbRs)
	{
		LogLR("LoadDataPlayer - %s", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}
	
	if(dbRs.HasResults && dbRs.FetchRow())
	{
		if(IsClientConnected(iClient) && IsClientInGame(iClient))
		{
			for(int i = 0; i != view_as<int>(LR_StatsType)-1; i++)
			{
				g_iClientData[iClient][i] = dbRs.FetchInt(i);
			}
			g_iClientSessionData[iClient][0] = g_iClientData[iClient][ST_EXP];
			g_bInitialized[iClient] = true;

			GetPlacePlayer(iClient);
			CheckRank(iClient);
			Call_StartForward(g_hForward_OnPlayerLoaded);
			Call_PushCell(iClient);
			Call_PushString(g_sSteamID[iClient]);
			Call_Finish();
		}
	}
	else CreateDataPlayer(iClient);
}

void SaveDataPlayer(int iClient, bool bDisconnect)
{
	if(!g_hDatabase)
	{
		LogLR("SaveDataPlayer - database is invalid");
	}
	else
	{
		if(CheckStatus(iClient))
		{
			char sQuery[1024];
			Transaction hQuery = new Transaction();

			g_hDatabase.Format(sQuery, 1024, "UPDATE `%s` SET `value` = %d, `name` = '%s', `rank` = %d, `kills` = %d, `deaths` = %d, `shoots` = %d, `hits` = %d, `headshots` = %d, `assists` = %d, `round_win` = %d, `round_lose` = %d, `playtime` = %d, `lastconnect` = %d WHERE `steam` = '%s';", g_sTableName, g_iClientData[iClient][ST_EXP], GetFixNamePlayer(iClient), g_iClientData[iClient][ST_RANK], g_iClientData[iClient][ST_KILLS], g_iClientData[iClient][ST_DEATHS], g_iClientData[iClient][ST_SHOOTS], g_iClientData[iClient][ST_HITS], g_iClientData[iClient][ST_HEADSHOTS], g_iClientData[iClient][ST_ASSISTS], g_iClientData[iClient][ST_ROUNDSWIN], g_iClientData[iClient][ST_ROUNDSLOSE], g_iClientData[iClient][ST_PLAYTIME], GetTime(), g_sSteamID[iClient]);
			hQuery.AddQuery(sQuery);

			Call_StartForward(g_hForward_OnPlayerSaved);
			Call_PushCell(iClient);
			Call_PushCellRef(hQuery);
			Call_Finish();

			if(bDisconnect)
			{
				for(int i = 0; i != view_as<int>(LR_StatsType); i++)
				{
					g_iClientData[iClient][i] = 0;
				}

				for(int i = 0; i < 10; i++)
				{
					g_iClientSessionData[iClient][i] = 0;
				}

				g_iKillstreak[iClient] = 0;
				g_iClientRoundExp[iClient] = 0;
				g_bHaveBomb[iClient] = false;
				g_bInitialized[iClient] = false;
			}
			g_hDatabase.Execute(hQuery, _, SaveDataPlayer_ErrorCallback, _, DBPrio_High);
		}
	}
}

public void SaveDataPlayer_ErrorCallback(Database db, any data, int numQueries, const char[] sError, int failIndex, any[] queryData)
{
	LogLR("SaveDataPlayer - %s", sError);
	if(StrContains(sError, "Lost connection to MySQL", false) != -1)
	{
		TryReconnectDB();
	}
	return;
}

void TryReconnectDB()
{
	delete g_hDatabase;
	g_iCountRetryConnect = 0;
	LogLR("Reconnect to the Database");
	CreateTimer(g_fDBReconnectTime, TryReconnectDBTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TryReconnectDBTimer(Handle hTimer)
{
	char sError[256];
	g_hDatabase = SQL_Connect("levels_ranks", false, sError, 256);

	if(!g_hDatabase)
	{
		g_iCountRetryConnect++;
		if(g_iCountRetryConnect >= g_iDBReconnectCount)
		{
			CrashLR("The attempt to restore the connection was failed, plugin disabled (%s)", sError);
		}
		else LogLR("The attempt to restore the connection was failed #%i", g_iCountRetryConnect);
	}
	else
	{
		g_hDatabase.SetCharset("utf8");
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

/*
* Fix name by Pheonix
*/
char[] GetFixNamePlayer(int iClient)
{
	char sName[MAX_NAME_LENGTH * 2 + 1];
	GetClientName(iClient, sName, sizeof(sName));

	for(int i = 0, len = strlen(sName), CharBytes; i < len;)
	{
		if((CharBytes = GetCharBytes(sName[i])) >= 4)
		{
			len -= CharBytes;
			for(int u = i; u <= len; u++)
			{
				sName[u] = sName[u + CharBytes];
			}
		}
		else i += CharBytes;
	}
	return sName;
}