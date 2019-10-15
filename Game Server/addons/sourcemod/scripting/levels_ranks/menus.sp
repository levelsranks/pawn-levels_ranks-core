#define SQL_PrintMenu "SELECT `name`, %s FROM `%s` WHERE `lastconnect` != 0 ORDER BY %.10s DESC LIMIT 10;"

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

void MainMenu(int iClient)
{
	int iRank = g_iPlayerInfo[iClient].iStats[ST_RANK];

	static char sExp[32], sText[128], sRank[192];

	Menu hMenu = new Menu(MainMenu_Callback, MenuAction_Select);

	if(iRank == g_hRankExp.Length)
	{
		FormatEx(sExp, sizeof(sExp), "%i", g_iPlayerInfo[iClient].iStats[ST_EXP]);
	}
	else
	{
		FormatEx(sExp, sizeof(sExp), "%i / %i", g_iPlayerInfo[iClient].iStats[ST_EXP], g_hRankExp.Get(iRank));
	}

	g_hRankNames.GetString(iRank ? iRank - 1 : 0, sRank, sizeof(sRank));

	hMenu.SetTitle(!strcmp(g_sPluginName, g_sPluginTitle, false) ? "%s " ... PLUGIN_VERSION ... "\n \n%T\n" : "%s \n \n%T\n", g_sPluginTitle, "MainMenu", iClient, sRank, iClient, sExp, g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP], g_iDBCountPlayers);

	if(g_Settings[LR_FlagAdminmenu])
	{
		int iFlags = GetUserFlagBits(iClient);

		if(iFlags & g_Settings[LR_FlagAdminmenu] || iFlags & ADMFLAG_ROOT)
		{
			FormatEx(sText, sizeof(sText), "%T\n ", "MainMenu_Admin", iClient), 
			hMenu.AddItem("0", sText);
		}
	}

	FormatEx(sText, sizeof(sText), "%T", "MainMenu_MyStats", iClient); 
	hMenu.AddItem("1", sText);

	if(GetForwardFunctionCount(g_hForward_CreatedMenu[LR_SettingMenu]))
	{
		FormatEx(sText, sizeof(sText), "%T\n ", "MainMenu_MyPrivilegesSettings", iClient); 
		hMenu.AddItem("2", sText);
	}

	FormatEx(sText, sizeof(sText), "%T", "MainMenu_TopPlayers", iClient); 
	hMenu.AddItem("3", sText);

	FormatEx(sText, sizeof(sText), "%T", "MainMenu_Ranks", iClient); 
	hMenu.AddItem("4", sText);

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MainMenu_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			static char sInfo[2];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(sInfo[0])
			{
				case '0': MenuAdmin(iClient);
				case '1': MyStats(iClient);
				case '2': MyPrivilegesSettings(iClient);
				case '3': MenuTop(iClient);
				case '4': OverAllRanks(iClient);
			}
		}

		case MenuAction_End:
		{
			hMenu.Close();
		} 
	}
}

void MenuAdmin(int iClient)
{
	static char sText[192];

	Menu hMenu = new Menu(MenuAdmin_Callback, MenuAction_Select);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_Admin", iClient);

	FormatEx(sText, sizeof(sText), "%T", "ReloadAllConfigs", iClient);
	hMenu.AddItem(NULL_STRING, sText);

	// DON'T TOUCH !!!
	if(!g_Settings[LR_TypeStatistics])
	{
		FormatEx(sText, sizeof(sText), "%T", "GiveTakeMenuExp", iClient);
		hMenu.AddItem(NULL_STRING, sText);
	}

	CreatedMenu_CallForward(LR_AdminMenu, iClient, hMenu);

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MenuAdmin_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			switch(iSlot)
			{
				case 0:
				{
					SetSettings(true);
					LR_PrintMessage(iClient, true, false, "%T", "ConfigUpdated", iClient);

					MainMenu(iClient);
				}

				case 1:
				{
					GiveTakeValue(iClient);
				}
			}

			if(GetForwardFunctionCount(g_hForward_SelectedMenu[LR_AdminMenu]))
			{
				static char sInfo[64];

				hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

				SelectedMenu_CallForward(LR_AdminMenu, iClient, sInfo);
			}
		}

		case MenuAction_Cancel:
		{
			if(iSlot == MenuCancel_ExitBack)
			{
				MainMenu(iClient);
			}
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void GiveTakeValue(int iClient, const char sID[] = NULL_STRING)
{
	Menu hMenu = new Menu(sID[0] == '\0' ? GiveTakeValue_Callback : ChangeExpPlayers_Callback, MenuAction_Select);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "GiveTakeMenuExp", iClient);

	if(sID[0] == '\0')
	{
		static char sUserID[8], sNickName[32];

		for(int i = GetMaxPlayers(); --i;)
		{
			if(CheckStatus(i))
			{
				IntToString(GetClientUserId(i), sUserID, sizeof(sUserID));

				GetClientName(i, sNickName, sizeof(sNickName));
				hMenu.AddItem(sUserID, sNickName);
			}
		}
	}
	else
	{
		static const char sNumList[][] = {"10", "100", "1000", "-1000", "-100","-10"};

		for(int j = 0; j != sizeof(sNumList);)
		{
			hMenu.AddItem(sID, sNumList[j++]);
		}
	}

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int ChangeExpPlayers_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{	
	switch(mAction)
	{
		case MenuAction_Select:
		{
			static char sInfo[32], sBuffer[32];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));

			int iRecipient = GetClientOfUserId(StringToInt(sInfo)),
				iBuffer = StringToInt(sBuffer);

			if(CheckStatus(iRecipient))
			{
				GiveTakeValue(iClient, sInfo);

				if((g_iPlayerInfo[iRecipient].iStats[ST_EXP] += iBuffer) < 0) 
				{
					g_iPlayerInfo[iRecipient].iStats[ST_EXP] = 0;
				}

				CheckRank(iRecipient);

				int iExp = g_iPlayerInfo[iRecipient].iStats[ST_EXP];

				FormatEx(sBuffer, sizeof(sBuffer), iBuffer > 0 ? "+%d" : "%d", iBuffer);

				if(iClient != iRecipient)
				{
					LR_PrintMessage(iRecipient, true, false, "%T", iBuffer > 0 ? "AdminGive" : "AdminTake", iRecipient, iExp, sBuffer);
				}

				LogAction(iRecipient, iClient, "%L %s exp (%i) from %L", iRecipient, sBuffer, iExp, iClient);
				LR_PrintMessage(iClient, true, false, "%T", "ExpChange", iClient, iRecipient, iExp, sBuffer);
			}
			else 
			{
				GiveTakeValue(iClient);
			}
		}

		case MenuAction_Cancel: 
		{
			if(iSlot == MenuCancel_ExitBack)
			{
				GiveTakeValue(iClient);
			}
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

int GiveTakeValue_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{	
	switch(mAction)
	{
		case MenuAction_Select:
		{
			static char sID[8];

			hMenu.GetItem(iSlot, sID, sizeof(sID));
			GiveTakeValue(iClient, sID);
		}

		case MenuAction_Cancel: 
		{
			if(iSlot == MenuCancel_ExitBack) 
			{
				MenuAdmin(iClient);
			}
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void MyStats(int iClient)
{
	int iRoundsWin = g_iPlayerInfo[iClient].iStats[ST_ROUNDSWIN],
		iRoundsAll = iRoundsWin + g_iPlayerInfo[iClient].iStats[ST_ROUNDSLOSE],
		iPlayTime = g_iPlayerInfo[iClient].iStats[ST_PLAYTIME],
		iKills = g_iPlayerInfo[iClient].iStats[ST_KILLS],
		iDeaths = g_iPlayerInfo[iClient].iStats[ST_DEATHS],
		iHeadshots = g_iPlayerInfo[iClient].iStats[ST_HEADSHOTS],
		iShots = g_iPlayerInfo[iClient].iStats[ST_SHOOTS],
		iHits = g_iPlayerInfo[iClient].iStats[ST_HITS];

	static char sText[128];

	Menu hMenu = new Menu(MyStats_Callback, MenuAction_Select);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsInfo", iClient, iPlayTime / 3600, iPlayTime / 60 % 60, iPlayTime % 60, iKills, iDeaths, g_iPlayerInfo[iClient].iStats[ST_ASSISTS], iHeadshots, RoundToCeil(100.0 / (iKills ? iKills : 1) * iHeadshots), iKills / (iDeaths ? float(iDeaths) : 1.0), RoundToCeil(100.0 / (iShots ? float(iShots) : 1.0) * iHits), RoundToCeil(100.00 / (iRoundsAll ? float(iRoundsAll) : 1.0) * iRoundsWin));

	FormatEx(sText, sizeof(sText), "%T", "MyStatsSession", iClient);
	hMenu.AddItem("0", sText);

	if(GetForwardFunctionCount(g_hForward_CreatedMenu[LR_MyStatsSecondary]))
	{
		FormatEx(sText, sizeof(sText), "%T", "MyStatsSecondary", iClient);
		hMenu.AddItem("1", sText);
	}

	if(g_Settings[LR_ShowResetMyStats])
	{
		int iCooldown = 0;

		static char sData[12];

		g_hResetMyStats.Get(iClient, sData, sizeof(sData));

		if(!sData[0] || (iCooldown = (StringToInt(sData) - g_iPlayerInfo[iClient].iStats[ST_PLAYTIME])) < 1)
		{
			FormatEx(sText, sizeof(sText), "%T", "MyStatsReset", iClient);
			hMenu.AddItem("2", sText);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%T", "MyStatsResetCooldown", iClient, iCooldown / 3600, iCooldown / 60 % 60, iCooldown % 60);
			hMenu.AddItem("2", sText, ITEMDRAW_DISABLED);
		}
	}

	FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
	hMenu.AddItem("3", sText);

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MyStats_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			char sInfo[2];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(sInfo[0])
			{
				case '0': MyStatsSession(iClient);
				case '1': MyStatsSecondary(iClient);
				case '2': MyStatsReset(iClient);
				case '3': MainMenu(iClient);
			}
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void MyStatsSecondary(int iClient)
{
	Menu hMenu = new Menu(MyStatsSecondary_Callback);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsSecondary", iClient);

	CreatedMenu_CallForward(LR_MyStatsSecondary, iClient, hMenu);

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MyStatsSecondary_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Cancel: 
		{
			if(iSlot == MenuCancel_ExitBack) 
			{
				MyStats(iClient);
			}
		}

		case MenuAction_Select:
		{
			static char sInfo[64];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			Call_StartForward(g_hForward_SelectedMenu[LR_MyStatsSecondary]);
			Call_PushCell(LR_MyStatsSecondary);
			Call_PushCell(iClient);
			Call_PushString(sInfo);
			Call_Finish();
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void MyStatsSession(int iClient)
{
	static char sText[128], sBuffer[64];

	Menu hMenu = new Menu(MyStatsSession_Callback, MenuAction_Select);

	int iKills = g_iPlayerInfo[iClient].iSessionStats[1],
		iDeaths = g_iPlayerInfo[iClient].iSessionStats[2],
		iShots = g_iPlayerInfo[iClient].iSessionStats[3],
		iHits = g_iPlayerInfo[iClient].iSessionStats[4],
		iHeadshots = g_iPlayerInfo[iClient].iSessionStats[5],
		iRoundsWin = g_iPlayerInfo[iClient].iSessionStats[7],
		iRoundsAll = iRoundsWin + g_iPlayerInfo[iClient].iSessionStats[8],
		iPlayTime = g_iPlayerInfo[iClient].iSessionStats[9],
		iDifference = g_iPlayerInfo[iClient].iStats[ST_EXP] - g_iPlayerInfo[iClient].iSessionStats[0];

	FormatEx(sBuffer, sizeof(sBuffer), iDifference > 0 ? "+%d" : "%d", iDifference);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsSessionInfo", iClient, sBuffer, iPlayTime / 3600, iPlayTime / 60 % 60, iPlayTime % 60, iKills, iDeaths, g_iPlayerInfo[iClient].iSessionStats[6], iHeadshots, RoundToCeil(100.0 / (iKills ? iKills : 1) * iHeadshots), iKills / (iDeaths ? float(iDeaths) : 1.0), RoundToCeil(100.0 / (iShots ? iShots : 1) * iHits), RoundToCeil(100.0 / (iRoundsAll ? iRoundsAll : 1) * iRoundsWin));

	FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
	hMenu.AddItem(NULL_STRING, sText);

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MyStatsSession_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			MyStats(iClient);
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void MyStatsReset(int iClient)
{
	char sText[192];

	Menu hMenu = new Menu(MyStatsReset_Callback);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsResetInfo", iClient);

	FormatEx(sText, sizeof(sText), "%T", "Yes", iClient);
	hMenu.AddItem(NULL_STRING, sText);

	FormatEx(sText, sizeof(sText), "%T", "No", iClient);
	hMenu.AddItem(NULL_STRING, sText);

	hMenu.ExitButton = false;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MyStatsReset_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			if(iSlot)		// No
			{
				MyStats(iClient);

				return 0;
			}

			static char sLastResetMyStats[12];

			IntToString(g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] + g_Settings[LR_ResetMyStatsCooldown], sLastResetMyStats, sizeof(sLastResetMyStats));
			g_hResetMyStats.Set(iClient, sLastResetMyStats);

			ResetPlayerStats(iClient);
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}

	return 0;
}

void MyPrivilegesSettings(int iClient)
{
	Menu hMenu = new Menu(MyPrivilegesSettings_Callback);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_MyPrivilegesSettings", iClient);

	CreatedMenu_CallForward(LR_SettingMenu, iClient, hMenu);

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MyPrivilegesSettings_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Cancel: 
		{
			if(iSlot == MenuCancel_ExitBack) 
			{
				MainMenu(iClient);
			}
		}

		case MenuAction_Select:
		{
			static char sInfo[64];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			SelectedMenu_CallForward(LR_SettingMenu, iClient, sInfo);
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void MenuTop(int iClient)
{
	static char sText[128];

	Menu hMenu = new Menu(MenuTop_Callback);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_TopPlayers", iClient);

	FormatEx(sText, sizeof(sText), "%T", "OverallTopPlayersExp", iClient);
	hMenu.AddItem("0", sText);

	FormatEx(sText, sizeof(sText), "%T", "OverallTopPlayersTime", iClient);
	hMenu.AddItem("1", sText);

	CreatedMenu_CallForward(LR_TopMenu, iClient, hMenu);

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MenuTop_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Cancel: 
		{
			if(iSlot == MenuCancel_ExitBack) 
			{
				MainMenu(iClient);
			}
		}

		case MenuAction_Select:
		{
			static char sInfo[64];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(sInfo[0])
			{
				case '0':
				{
					OverAllTopPlayers(iClient);
				}

				case '1':
				{
					OverAllTopPlayers(iClient, false);
				}
			}

			SelectedMenu_CallForward(LR_TopMenu, iClient, sInfo);
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void OverAllTopPlayers(int iClient, bool bType = true)
{
	if(CheckStatus(iClient))
	{
		static char sQuery[128];
		static const char sTable[][] = {"`playtime` / 3600.0", "`value`"};

		FormatEx(sQuery, sizeof(sQuery), SQL_PrintMenu, sTable[bType], g_sTableName, sTable[bType]);
		g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | 4 + view_as<int>(bType));		// in database.sp
	}
}

int OverAllTopPlayers_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select: 
		{
			MenuTop(iClient);
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void OverAllRanks(int iClient)
{
	int iMaxRanks = g_hRankExp.Length;

	Menu hMenu = new Menu(OverAllRanks_Callback, MenuAction_Cancel);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_Ranks", iClient);

	if(iMaxRanks)
	{
		static char sText[96], sRank[192];

		g_hRankNames.GetString(0, sRank, sizeof(sRank));

		FormatEx(sText, sizeof(sText), "%T", sRank, iClient);
		hMenu.AddItem(NULL_STRING, sText, ITEMDRAW_DISABLED);

		for(int i = 1; i != iMaxRanks; i++)
		{
			g_hRankNames.GetString(i, sRank, sizeof(sRank));

			FormatEx(sText, sizeof(sText), "[%i] %T", g_hRankExp.Get(i), sRank, iClient);
			hMenu.AddItem(NULL_STRING, sText, ITEMDRAW_DISABLED);
		}
	}

	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int OverAllRanks_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Cancel:
		{
			if(iSlot == MenuCancel_ExitBack)
			{
				MainMenu(iClient);
			}
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void SelectedMenu_CallForward(int iMenuType, int iClient, char[] sInfo)
{
	Call_StartForward(g_hForward_SelectedMenu[iMenuType]);
	Call_PushCell(iMenuType);
	Call_PushCell(iClient);
	Call_PushString(sInfo);
	Call_Finish();
}

void CreatedMenu_CallForward(int iMenuType, int iClient, Menu hMenu)
{
	Call_StartForward(g_hForward_CreatedMenu[iMenuType]);
	Call_PushCell(iMenuType);
	Call_PushCell(iClient);
	Call_PushCell(hMenu);
	Call_Finish();
}

public void OnClientSayCommand_Post(int iClient, const char[] sCommand, const char[] sArgs)
{
	if(CheckStatus(iClient))
	{
		int iValue = 0;

		static StringMap hCommands;

		if(!hCommands)
		{
			(hCommands = new StringMap()).SetValue("top", 0);
			hCommands.SetValue("!top", 0);
			hCommands.SetValue("toptime", 1);
			hCommands.SetValue("!toptime", 1);
			hCommands.SetValue("session", 2);
			hCommands.SetValue("!session", 2);
			hCommands.SetValue("rank", 3);
			hCommands.SetValue("!rank", 3);
		}

		if(hCommands.GetValue(sArgs, iValue))
		{
			switch(iValue)
			{
				case 0: OverAllTopPlayers(iClient);
				case 1: OverAllTopPlayers(iClient, false);
				case 2: MyStatsSession(iClient);
				case 3: 
				{
					int iKills = g_iPlayerInfo[iClient].iStats[ST_KILLS],
						iDeaths = g_iPlayerInfo[iClient].iStats[ST_DEATHS];

					if(g_Settings[LR_ShowRankMessage])
					{
						int iPlaceInTop = g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP],
							iExp = g_iPlayerInfo[iClient].iStats[ST_EXP];

						for(int i = GetMaxPlayers(); --i;)
						{
							if(CheckStatus(i)) 
							{
								LR_PrintMessage(i, true, false, "%T", "RankPlayer", i, iClient, iPlaceInTop, g_iDBCountPlayers, iExp, iKills, iDeaths, iKills / (iDeaths ? float(iDeaths) : 1.0));
							}
						}

						return;
					}

					LR_PrintMessage(iClient, true, false, "%T", "RankPlayer", iClient, iClient, g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP], g_iDBCountPlayers, g_iPlayerInfo[iClient].iStats[ST_EXP], iKills, iDeaths, iKills / (iDeaths ? float(iDeaths) : 1.0));
				}
			}
		}
	}
}