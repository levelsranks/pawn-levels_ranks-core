#define SQL_PRINT_TOP_MENU "SELECT `name`, SUBSTR(`steam`, 11) << 1 | SUBSTR(`steam`, 9, 1) AS `accountid`, %s FROM `%s` WHERE `lastconnect` ORDER BY %.10s DESC LIMIT 10;"

void MainMenu(int iClient)
{
	int iRank = g_iPlayerInfo[iClient].iStats[ST_RANK];

	decl char sExp[32], sText[128], sRank[192];

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

	if(g_hForward_CreatedMenu[LR_SettingMenu].FunctionCount)
	{
		FormatEx(sText, sizeof(sText), "%T\n ", "MainMenu_MyPrivilegesSettings", iClient); 
		hMenu.AddItem("2", sText);
	}

	FormatEx(sText, sizeof(sText), "%T", "MainMenu_TopPlayers", iClient); 
	hMenu.AddItem("3", sText);

	if(g_Settings[LR_ShowRankList])
	{
		FormatEx(sText, sizeof(sText), "%T", "MainMenu_Ranks", iClient); 
		hMenu.AddItem("4", sText);
	}

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MainMenu_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			decl char sInfo[2];

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
	decl char sText[192];

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

	CallForward_MenuHook(LR_AdminMenu, iClient, hMenu);
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
					SetSettings();
					LR_PrintMessage(iClient, true, false, "%T", "ConfigUpdated", iClient);

					MainMenu(iClient);
				}

				case 1:
				{
					GiveTakeValue(iClient);
				}
			}

			if(g_hForward_SelectedMenu[LR_AdminMenu].FunctionCount)
			{
				CallForward_MenuHook(LR_AdminMenu, iClient, hMenu, iSlot);
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
		decl char sUserID[8], sNickName[32];

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
		static const char sNumList[][] = 
		{
			"10",
			"100",
			"1000",
			"-1000",
			"-100",
			"-10"
		};

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
			decl char sInfo[32], sBuffer[32];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));

			int iRecipient = GetClientOfUserId(StringToInt(sInfo)),
				iBuffer = StringToInt(sBuffer);

			if(NotifClient(iRecipient, iBuffer, iBuffer > 0 ? "AdminGive" : "AdminTake", true))
			{
				int iExp = g_iPlayerInfo[iRecipient].iStats[ST_EXP];

				LogAction(iRecipient, iClient, "%L %s exp (%i) from %L", iRecipient, sBuffer, iExp, iClient);
				LR_PrintMessage(iClient, true, false, "%T", "ExpChange", iClient, iRecipient, iExp, GetSignValue(iBuffer));

				GiveTakeValue(iClient, sInfo);
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
			decl char sID[8];

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
	int iStats[LR_StatsType];

	iStats = g_iPlayerInfo[iClient].iStats;

	int iRoundsWin = iStats[ST_ROUNDSWIN],
	    iRoundsAll = iRoundsWin + iStats[ST_ROUNDSLOSE],
	    iPlayTime = iStats[ST_PLAYTIME] + GetTime(),
	    iKills = iStats[ST_KILLS],
	    iDeaths = iStats[ST_DEATHS],
	    iHeadshots = iStats[ST_HEADSHOTS],
	    iShots = iStats[ST_SHOOTS];

	decl char sText[128];

	Menu hMenu = new Menu(MyStats_Callback, MenuAction_Select);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsInfo", iClient, iPlayTime / 3600, iPlayTime / 60 % 60, iPlayTime % 60, iKills, iDeaths, iStats[ST_ASSISTS], iHeadshots, RoundToCeil(100.0 / (iKills ? iKills : 1) * iHeadshots), iKills / (iDeaths ? float(iDeaths) : 1.0), RoundToCeil(100.0 / (iShots ? float(iShots) : 1.0) * iStats[ST_HITS]), RoundToCeil(100.0 / (iRoundsAll ? float(iRoundsAll) : 1.0) * iRoundsWin));

	FormatEx(sText, sizeof(sText), "%T", "MyStatsSession", iClient);
	hMenu.AddItem("0", sText);

	if(g_hForward_CreatedMenu[LR_MyStatsSecondary].FunctionCount)
	{
		FormatEx(sText, sizeof(sText), "%T", "MyStatsSecondary", iClient);
		hMenu.AddItem("1", sText);
	}

	if(g_Settings[LR_ShowResetMyStats])
	{
		bool bIsNotCooldown = true;

		int iCooldown = 0;

		decl char sData[16];

		if(g_hLastResetMyStats)
		{
			g_hLastResetMyStats.Get(iClient, sData, sizeof(sData));

			if(!sData[0] || (iCooldown = (StringToInt(sData) + GetTime())) >= g_Settings[LR_ResetMyStatsCooldown])
			{
				FormatEx(sText, sizeof(sText), "%T", "MyStatsReset", iClient);
				hMenu.AddItem("2", sText);

				bIsNotCooldown = false;
			}
		}
		
		if(bIsNotCooldown)
		{
			iCooldown = g_Settings[LR_ResetMyStatsCooldown] - iCooldown;

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
			decl char sInfo[2];

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

	CallForward_MenuHook(LR_MyStatsSecondary, iClient, hMenu);
}

int MyStatsSecondary_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			CallForward_MenuHook(LR_MyStatsSecondary, iClient, hMenu, iSlot);
		}

		case MenuAction_Cancel: 
		{
			if(iSlot == MenuCancel_ExitBack) 
			{
				MyStats(iClient);
			}
		}

		case MenuAction_End:
		{
			hMenu.Close();
		}
	}
}

void MyStatsSession(int iClient)
{
	decl char sText[128];

	Menu hMenu = new Menu(MyStatsSession_Callback, MenuAction_Select);

	int iSessionStats[LR_StatsType];

	iSessionStats = g_iPlayerInfo[iClient].iSessionStats;

	int iRoundsWin = iSessionStats[ST_ROUNDSWIN],
		iRoundsAll = iRoundsWin + iSessionStats[ST_ROUNDSLOSE],
		iPlayTime = iSessionStats[ST_PLAYTIME] + GetTime(),
		iKills = iSessionStats[ST_KILLS],
		iDeaths = iSessionStats[ST_DEATHS],
		iHeadshots = iSessionStats[ST_HEADSHOTS],
		iShots = iSessionStats[ST_SHOOTS];

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsSessionInfo", iClient, GetSignValue(g_iPlayerInfo[iClient].iSessionStats[ST_EXP]), GetSignValue(iSessionStats[ST_PLACEINTOP]), iPlayTime / 3600, iPlayTime / 60 % 60, iPlayTime % 60, iKills, iDeaths, iSessionStats[ST_ASSISTS], iHeadshots, RoundToCeil(100.0 / (iKills ? iKills : 1) * iHeadshots), iKills / (iDeaths ? float(iDeaths) : 1.0), RoundToCeil(100.0 / (iShots ? iShots : 1) * iSessionStats[ST_HITS]), RoundToCeil(100.0 / (iRoundsAll ? iRoundsAll : 1) * iRoundsWin));

	FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
	hMenu.AddItem(NULL_STRING, sText);

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

int MyStatsSession_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	if(mAction == MenuAction_Select)
	{
		MyStats(iClient);
	}
	else if(mAction == MenuAction_End)
	{
		hMenu.Close();
	}
}

void MyStatsReset(int iClient)
{
	decl char sText[192];

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
	if(mAction == MenuAction_Select)
	{
		if(iSlot)		// No
		{
			MyStats(iClient);
		}
		else
		{
			if(g_hLastResetMyStats)
			{
				decl char sLastResetMyStats[16];

				IntToString(-GetTime(), sLastResetMyStats, sizeof(sLastResetMyStats));
				g_hLastResetMyStats.Set(iClient, sLastResetMyStats);
			}

			ResetPlayerStats(iClient);
		}
	}
	else if(mAction == MenuAction_End)
	{
		hMenu.Close();
	}
}

void MyPrivilegesSettings(int iClient)
{
	Menu hMenu = new Menu(MyPrivilegesSettings_Callback);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_MyPrivilegesSettings", iClient);

	CallForward_MenuHook(LR_SettingMenu, iClient, hMenu);
}

int MyPrivilegesSettings_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			CallForward_MenuHook(LR_SettingMenu, iClient, hMenu, iSlot);
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

void MenuTop(int iClient)
{
	decl char sText[128];

	Menu hMenu = new Menu(MenuTop_Callback);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_TopPlayers", iClient);

	FormatEx(sText, sizeof(sText), "%T", "OverAllTopPlayersExp", iClient);
	hMenu.AddItem("0", sText);

	FormatEx(sText, sizeof(sText), "%T", "OverAllTopPlayersTime", iClient);
	hMenu.AddItem("1", sText);

	CallForward_MenuHook(LR_TopMenu, iClient, hMenu);
}

int MenuTop_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_Select:
		{
			decl char sInfo[2];

			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(sInfo[0])
			{
				case '0', '1':
				{
					OverAllTopPlayers(iClient, sInfo[0] == '1');
				}

				default:
				{
					CallForward_MenuHook(LR_TopMenu, iClient, hMenu, iSlot);
				}
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

void OverAllTopPlayers(int iClient, bool bPlaytime = true)
{
	if(CheckStatus(iClient))
	{
		decl char sQuery[256];

		static const char sTable[][] = 
		{
			"`value`",
			"`playtime` / 3600.0"
		};

		FormatEx(sQuery, sizeof(sQuery), SQL_PRINT_TOP_MENU, sTable[view_as<int>(bPlaytime)], g_sTableName, sTable[view_as<int>(bPlaytime)]);
		g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(iClient) << 4 | LR_TopPlayersExp + view_as<int>(bPlaytime));
	}
}

int OverAllTopPlayers_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	if(mAction == MenuAction_Select)
	{ 
		MenuTop(iClient);
	}
	else if(mAction == MenuAction_End)
	{
		hMenu.Close();
	}
}

void OverAllRanks(int iClient)
{
	int iMaxRanks = g_hRankExp.Length;

	Menu hMenu = new Menu(OverAllRanks_Callback, MenuAction_Cancel);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_Ranks", iClient);

	if(iMaxRanks)
	{
		decl char sText[96], sRank[192];

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
	if(mAction == MenuAction_Cancel)
	{
		if(iSlot == MenuCancel_ExitBack)
		{
			MainMenu(iClient);
		}
	}
	else if(mAction == MenuAction_End)
	{
		hMenu.Close();
	}
}