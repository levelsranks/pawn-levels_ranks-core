
Action Call_MainMenu(int iClient, int iArgs)
{
	if(CheckStatus(iClient) && g_hDatabase)
	{
		CheckRank(iClient);
		MainMenu(iClient);
	}
	else 
	{
		LR_PrintMessage(iClient, true, false, "You account is not loaded. Please reconnect on the server!");
	}

	return Plugin_Handled;
}

Action Call_ReloadSettings(int iClient, int iArgs)
{
	SetSettings();

	LR_PrintMessage(iClient, true, false, "%T", "ConfigUpdated", iClient);
	PrintToServer("[LR] Settings cache has been refreshed.");

	return Plugin_Handled;
}

Action Call_ResetData(int iArgs)
{
	if(iArgs != 1)
	{
		PrintToServer("[LR] Usage: sm_lvl_reset <all|exp|stats>");
	}
	else
	{
		int iType = -1;

		decl char sBuffer[256];

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
				}

				case 1:
				{
					FormatEx(sBuffer, sizeof(sBuffer), "UPDATE `%s` SET `value` = %i, `rank` = 0;", g_sTableName, g_Settings[LR_TypeStatistics] ? 1000 : 0);
				}

				case 2:
				{
					FormatEx(sBuffer, sizeof(sBuffer), "UPDATE `%s` SET `kills` = 0, `deaths` = 0, `shoots` = 0, `hits` = 0, `headshots` = 0, `assists` = 0, `round_win` = 0, `round_lose` = 0;", g_sTableName);
				}
			}

			hTransaction.AddQuery(sBuffer);

			CallForward_OnDatabaseCleanup(iType, hTransaction);

			g_hDatabase.Execute(hTransaction, SQL_TransactionCallback, SQL_TransactionFailure, iType, DBPrio_High);
		}
		else
		{
			PrintToServer("[LR] %s - invalid type of cleaning.", sBuffer);
		}
	}

	return Plugin_Handled;
}

Action Call_ResetPlayer(int iClient, int iArgs)
{
	if(iArgs != 1)
	{
		ReplyToCommand(iClient, "[LR] Usage: sm_lvl_del <#userid|name|steamid>");
	}
	else
	{
		bool bTargetIsMl = false;

		int iTargets = 0,
			iTargetList[MAXPLAYERS + 1];

		char sBuffer[256];

		GetCmdArg(1, sBuffer, 65);

		int iAccountID = (!strncmp(sBuffer, "STEAM_", 6) && sBuffer[7] == ':') ? GetAccountIDFromSteamID2(sBuffer) : 0;

		if((iTargets = ProcessTargetString(sBuffer, iClient, iTargetList, sizeof(iTargetList), COMMAND_FILTER_NO_BOTS, sBuffer, sizeof(sBuffer), bTargetIsMl)) < 1 && !iAccountID)
		{
			ReplyToTargetError(iClient, iTargets);
		}
		else
		{
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

				CallForward_OnResetPlayerStats(0, iAccountID);

				Format(sBuffer, sizeof(sBuffer), SQL_UPDATE_RESET_DATA, g_sTableName, sBuffer);
				g_hDatabase.Query(SQL_Callback, sBuffer, 0);

				LogAction(iClient, 0, "[LR] %L reset statistics request has been sent at <0><STEAM_%i:%i:%i><>", iClient, g_iEngine == Engine_CSGO, iAccountID & 1, iAccountID >>> 1);
			}
		}
	}

	return Plugin_Handled;
}

void ResetPlayerCommand(int iClient, int iTarget)
{
	ResetPlayerStats(iTarget);
	LogAction(iClient, iTarget, "[LR] %L reset statistics at %L!", iClient, iTarget);
}

public void OnClientSayCommand_Post(int iClient, const char[] sCommand, const char[] sArgs)
{
	if(CheckStatus(iClient))
	{
		if(!strcmp(sArgs, "top", false) || !strcmp(sArgs, "!top", false))
		{
			OverAllTopPlayers(iClient, false);
		}
		else if(!strcmp(sArgs, "toptime", false) || !strcmp(sArgs, "!toptime", false))
		{
			OverAllTopPlayers(iClient);
		}
		else if(!strcmp(sArgs, "session", false) || !strcmp(sArgs, "!session", false))
		{
			MyStatsSession(iClient);
		}
		else if(!strcmp(sArgs, "rank", false) || !strcmp(sArgs, "!rank", false))
		{
			int iKills = g_iPlayerInfo[iClient].iStats[ST_KILLS],
				iDeaths = g_iPlayerInfo[iClient].iStats[ST_DEATHS];

			float fKDR = iKills / (iDeaths ? float(iDeaths) : 1.0);

			if(g_Settings[LR_ShowRankMessage])
			{
				int iPlaceInTop = g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP],
					iExp = g_iPlayerInfo[iClient].iStats[ST_EXP];

				for(int i = GetMaxPlayers(); --i;)
				{
					if(CheckStatus(i)) 
					{
						LR_PrintMessage(i, true, false, "%T", "RankPlayer", i, iClient, iPlaceInTop, g_iDBCountPlayers, iExp, iKills, iDeaths, fKDR);
					}
				}
			}
			else
			{
				LR_PrintMessage(iClient, true, false, "%T", "RankPlayer", iClient, iClient, g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP], g_iDBCountPlayers, g_iPlayerInfo[iClient].iStats[ST_EXP], iKills, iDeaths, fKDR);
			}
		}
	}
}
