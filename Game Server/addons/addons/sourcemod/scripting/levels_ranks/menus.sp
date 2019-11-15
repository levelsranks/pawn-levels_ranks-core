public Action Call_MainMenu(int iClient, int iArgs)
{
	if(CheckStatus(iClient))
	{
		CheckRank(iClient);
		MainMenu(iClient);
	}
	else LR_PrintToChat(iClient, "[LR] You account isnt loaded. Please reconnect on the server!");
	return Plugin_Handled;
}

void MainMenu(int iClient)
{
	char sExp[32], sText[128], sRank[192], sTitleBuffer[96];
	Menu hMenu = new Menu(MainMenuHandler);
	FormatEx(sRank, 192, "%T", g_sShowRank[g_iClientData[iClient][ST_RANK]], iClient);
	FormatEx(sExp, 32, g_iClientData[iClient][ST_RANK] == g_iCountRanks ? "%i" : "%i / %i", g_iClientData[iClient][ST_EXP], g_iShowExp[g_iClientData[iClient][ST_RANK]]);
	FormatEx(sTitleBuffer, 96, !strcmp(PLUGIN_NAME, g_sPluginTitle, false) ? "%s " ... PLUGIN_VERSION : "%s", g_sPluginTitle);

	hMenu.SetTitle("%s\n \n%T\n ", sTitleBuffer, "MainMenu", iClient, sRank, sExp, g_iClientData[iClient][ST_PLACEINTOP], g_iDBCountPlayers);

	int flags = GetUserFlagBits(iClient);
	if(flags & g_iAdminFlag || flags & ADMFLAG_ROOT)
	FormatEx(sText, 128, "%T\n ", "MainMenu_IamAdmin", iClient), hMenu.AddItem("0", sText);
	FormatEx(sText, 128, "%T", "MainMenu_MyStats", iClient); hMenu.AddItem("1", sText);
	FormatEx(sText, 128, "%T\n ", "MainMenu_MyPrivilegesSettings", iClient); hMenu.AddItem("2", sText);
	FormatEx(sText, 128, "%T", "MainMenu_TopPlayers", iClient); hMenu.AddItem("3", sText);
	FormatEx(sText, 128, "%T", "MainMenu_Ranks", iClient); hMenu.AddItem("4", sText);
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{	
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sInfo[2];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(StringToInt(sInfo))
			{
				case 0: IamAdmin(iClient);
				case 1: MyStats(iClient);
				case 2: MyPrivilegesSettings(iClient);
				case 3: OverallTopPlayers(iClient);
				case 4: OverallRanks(iClient);
			}
		}
	}
}

void IamAdmin(int iClient)
{
	char sText[192];
	Menu hMenu = new Menu(IamAdminHandler);
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_IamAdmin", iClient);

	FormatEx(sText, 192, "%T", "ReloadAllConfigs", iClient);
	hMenu.AddItem("0", sText);

	if(!g_iTypeStatistics)
	{
		FormatEx(sText, 192, "%T", "GiveTakeMenuExp", iClient);
		hMenu.AddItem("1", sText);
	}

	Call_StartForward(g_hForward_OnMenuCreatedAdmin);
	Call_PushCell(iClient);
	Call_PushCellRef(hMenu);
	Call_Finish();

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int IamAdminHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iSlot == MenuCancel_ExitBack)
			{
				MainMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			char sInfo[32];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			if(!strcmp(sInfo, "0"))
			{
				SetSettings(true);
				LR_PrintToChat(iClient, "%T", "ConfigUpdated", iClient);
			}

			if(!strcmp(sInfo, "1"))
			{
				GiveTakeValue(iClient);
			}

			Call_StartForward(g_hForward_OnMenuItemSelectedAdmin);
			Call_PushCell(iClient);
			Call_PushString(sInfo);
			Call_Finish();
		}
	}
}

void GiveTakeValue(int iClient)
{
	char sID[16], sNickName[32];
	Menu hMenu = new Menu(GiveTakeValueHandler);
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "GiveTakeMenuExp", iClient);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(CheckStatus(i))
		{
			IntToString(GetClientUserId(i), sID, 16);
			sNickName[0] = '\0';
			GetClientName(i, sNickName, 32);
			hMenu.AddItem(sID, sNickName);
		}
	}
	
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int GiveTakeValueHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{	
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MyPrivilegesSettings(iClient);}
		case MenuAction_Select:
		{
			char sID[16];
			hMenu.GetItem(iSlot, sID, 16);

			int iRecipient = GetClientOfUserId(StringToInt(sID));
			if(CheckStatus(iRecipient))
			{
				GiveTakeValueEND(iClient, sID);
			}
			else GiveTakeValue(iClient);
		}
	}
}

public void GiveTakeValueEND(int iClient, char[] sID) 
{
	Menu hMenu = new Menu(ChangeExpPlayersENDHandler);
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "GiveTakeMenuExp", iClient);
	hMenu.AddItem(sID, "100");
	hMenu.AddItem(sID, "500");
	hMenu.AddItem(sID, "1000");
	hMenu.AddItem(sID, "-1000");
	hMenu.AddItem(sID, "-500");
	hMenu.AddItem(sID, "-100");
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int ChangeExpPlayersENDHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{	
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {GiveTakeValue(iClient);}
		case MenuAction_Select:
		{
			char sInfo[32], sBuffer[32];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));
			int iRecipient = GetClientOfUserId(StringToInt(sInfo));
			int iBuffer = StringToInt(sBuffer);

			if(CheckStatus(iRecipient))
			{
				GiveTakeValueEND(iClient, sInfo);
				g_iClientData[iRecipient][ST_EXP] += iBuffer;
				if(g_iClientData[iRecipient][ST_EXP] < 0) g_iClientData[iRecipient][ST_EXP] = 0;
				CheckRank(iRecipient);

				if(g_iUsualMessage == 1)
				{
					FormatEx(sBuffer, sizeof(sBuffer), iBuffer > 0 ? "+%d" : "%d", iBuffer);
					LR_PrintToChat(iRecipient, "%T", iBuffer > 0 ? "AdminGive" : "AdminTake", iRecipient, g_iClientData[iRecipient][ST_EXP], sBuffer);
				}

				LR_PrintToChat(iClient, "%T", "ExpChange", iClient, iRecipient, g_iClientData[iRecipient][ST_EXP], iBuffer > 0 ? "+" : "", iBuffer);
			}
			else GiveTakeValue(iClient);
		}
	}
}

void MyStats(int iClient)
{
	char sText[128];
	Menu hMenu = new Menu(MyStats_Callback);

	int iRoundsAll = g_iClientData[iClient][ST_ROUNDSWIN] + g_iClientData[iClient][ST_ROUNDSLOSE];
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsInfo", iClient, g_iClientData[iClient][ST_PLAYTIME] / 3600, g_iClientData[iClient][ST_PLAYTIME] / 60 % 60, g_iClientData[iClient][ST_PLAYTIME] % 60, g_iClientData[iClient][ST_KILLS], g_iClientData[iClient][ST_DEATHS], g_iClientData[iClient][ST_ASSISTS], g_iClientData[iClient][ST_HEADSHOTS], RoundToCeil((100.00 / float(g_iClientData[iClient][ST_KILLS] > 0 ? g_iClientData[iClient][ST_KILLS] : 1)) * float(g_iClientData[iClient][ST_HEADSHOTS] > 0 ? g_iClientData[iClient][ST_HEADSHOTS] : 1)), float(g_iClientData[iClient][ST_KILLS] > 0 ? g_iClientData[iClient][ST_KILLS] : 1) / float(g_iClientData[iClient][ST_DEATHS] > 0 ? g_iClientData[iClient][ST_DEATHS] : 1), RoundToCeil((100.00 / float(g_iClientData[iClient][ST_SHOOTS] > 0 ? g_iClientData[iClient][ST_SHOOTS] : 1)) * float(g_iClientData[iClient][ST_HITS] > 0 ? g_iClientData[iClient][ST_HITS] : 1)), RoundToCeil((100.00 / float(iRoundsAll > 0 ? iRoundsAll : 1)) * float(g_iClientData[iClient][ST_ROUNDSWIN] > 0 ? g_iClientData[iClient][ST_ROUNDSWIN] : 1)));

	FormatEx(sText, sizeof(sText), "%T", "MyStatsSession", iClient);
	hMenu.AddItem("0", sText);

	if(g_bResetRank)
	{
		FormatEx(sText, sizeof(sText), "%T", "MyStatsReset", iClient);
		hMenu.AddItem("1", sText);
	}

	FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
	hMenu.AddItem("2", sText);

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MyStats_Callback(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sInfo[2];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(StringToInt(sInfo))
			{
				case 0: MyStatsSession(iClient);
				case 1: MyStatsReset(iClient);
				case 2: MainMenu(iClient);
			}
		}
	}
}

void MyStatsSession(int iClient)
{
	char sText[128], sBuffer[64];
	Menu hMenu = new Menu(MyStatsSessionHandler);

	int iRoundsAll = g_iClientSessionData[iClient][7] + g_iClientSessionData[iClient][8];
	int iDifference = g_iClientData[iClient][ST_EXP] - g_iClientSessionData[iClient][0];
	FormatEx(sBuffer, sizeof(sBuffer), iDifference > 0 ? "+%d" : "%d", iDifference);

	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsSessionInfo", iClient, sBuffer, g_iClientSessionData[iClient][9] / 3600, g_iClientSessionData[iClient][9] / 60 % 60, g_iClientSessionData[iClient][9] % 60, g_iClientSessionData[iClient][1], g_iClientSessionData[iClient][2], g_iClientSessionData[iClient][6], g_iClientSessionData[iClient][5], RoundToCeil((100.00 / float(g_iClientSessionData[iClient][1] > 0 ? g_iClientSessionData[iClient][1] : 1)) * float(g_iClientSessionData[iClient][5] > 0 ? g_iClientSessionData[iClient][5] : 1)), float(g_iClientSessionData[iClient][1] > 0 ? g_iClientSessionData[iClient][1] : 1) / float(g_iClientSessionData[iClient][2] > 0 ? g_iClientSessionData[iClient][2] : 1), RoundToCeil((100.00 / float(g_iClientSessionData[iClient][3] > 0 ? g_iClientSessionData[iClient][3] : 1)) * float(g_iClientSessionData[iClient][4] > 0 ? g_iClientSessionData[iClient][4] : 1)), RoundToCeil((100.00 / float(iRoundsAll > 0 ? iRoundsAll : 1)) * float(g_iClientSessionData[iClient][7] > 0 ? g_iClientSessionData[iClient][7] : 1)));

	FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
	hMenu.AddItem("", sText);

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MyStatsSessionHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select: MyStats(iClient);
	}
}

void MyStatsReset(int iClient)
{
	char sText[192];
	Menu hMenu = new Menu(MyStatsResetHandler);
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MyStatsResetInfo", iClient);

	FormatEx(sText, sizeof(sText), "%T", "Yes", iClient);
	hMenu.AddItem("", sText);

	FormatEx(sText, sizeof(sText), "%T", "No", iClient);
	hMenu.AddItem("", sText);

	hMenu.ExitButton = false;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MyStatsResetHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			if(!iSlot)
			{
				g_iClientData[iClient][ST_EXP] = !g_iTypeStatistics ? 0 : 1000;

				for(int i = g_iCountRanks; i >= 1; i--)
				{
					if(i == 1)
					{
						g_iClientData[iClient][ST_RANK] = 1;
					}
					else if(g_iShowExp[i-1] <= g_iClientData[iClient][ST_EXP])
					{
						g_iClientData[iClient][ST_RANK] = i;
						break;
					}
				}

				for(int i = 2; i != view_as<int>(LR_StatsType)-1; i++)
				{
					g_iClientData[iClient][i] = 0;
				}
				CheckRank(iClient);
				MainMenu(iClient);
			}
			else MainMenu(iClient);
		}
	}
}

void MyPrivilegesSettings(int iClient)
{
	char sText[128];
	Menu hMenu = new Menu(MyPrivilegesSettingsHandler);
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_MyPrivilegesSettings", iClient);
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;

	Call_StartForward(g_hForward_OnMenuCreated);
	Call_PushCell(iClient);
	Call_PushCellRef(hMenu);
	Call_Finish();

	if(!hMenu.ItemCount)
	{
		FormatEx(sText, sizeof(sText), "%T", "MyPrivilegesSettingsNone", iClient), hMenu.AddItem("", sText, ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MyPrivilegesSettingsHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
		case MenuAction_Select:
		{
			char sInfo[64];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			Call_StartForward(g_hForward_OnMenuItemSelected);
			Call_PushCell(iClient);
			Call_PushString(sInfo);
			Call_Finish();
		}
	}
}

void OverallTopPlayers(int iClient)
{
	char sText[128];
	Menu hMenu = new Menu(OverallTopPlayersHandler);
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_TopPlayers", iClient);

	FormatEx(sText, sizeof(sText), "%T", "OverallTopPlayersExp", iClient);
	hMenu.AddItem("0", sText);

	FormatEx(sText, sizeof(sText), "%T", "OverallTopPlayersTime", iClient);
	hMenu.AddItem("1", sText);

	Call_StartForward(g_hForward_OnMenuCreatedTop);
	Call_PushCell(iClient);
	Call_PushCellRef(hMenu);
	Call_Finish();

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int OverallTopPlayersHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
		case MenuAction_Select:
		{
			char sInfo[32];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			if(!strcmp(sInfo, "0"))
			{
				OverallTopPlayersExp(iClient);
			}

			if(!strcmp(sInfo, "1"))
			{
				OverallTopPlayersTime(iClient);
			}

			Call_StartForward(g_hForward_OnMenuItemSelectedTop);
			Call_PushCell(iClient);
			Call_PushString(sInfo);
			Call_Finish();
		}
	}
}

void OverallTopPlayersExp(int iClient)
{
	if(CheckStatus(iClient))
	{
		char sQuery[128];
		FormatEx(sQuery, sizeof(sQuery), "SELECT `name`, `value` FROM `%s` WHERE `lastconnect` > 0 ORDER BY `value` DESC LIMIT 10 OFFSET 0", g_sTableName);
		g_hDatabase.Query(OverallTopPlayersExp_Callback, sQuery, iClient);
	}
}

public void OverallTopPlayersExp_Callback(Database db, DBResultSet dbRs, const char[] sError, any iClient)
{
	if(!dbRs)
	{
		LogLR("OverallTopPlayersExp - %s", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	if(CheckStatus(iClient))
	{
		int i;
		char sText[256], sName[32], sTemp[512];

		while(dbRs.HasResults && dbRs.FetchRow())
		{
			i++;
			dbRs.FetchString(0, sName, sizeof(sName));
			FormatEx(sText, sizeof(sText), "%d - [ %d ] - %s\n", i, dbRs.FetchInt(1), sName);

			if(strlen(sTemp) + strlen(sText) < 512)
			{
				Format(sTemp, sizeof(sTemp), "%s%s", sTemp, sText);
				sText = "\0";
			}
		}

		Menu hMenu = new Menu(OverallTopPlayersExpHandler);
		hMenu.SetTitle("%s | %T\n \n%s\n ", g_sPluginTitle, "OverallTopPlayersExp", iClient, sTemp);

		FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
		hMenu.AddItem("1", sText);

		hMenu.ExitButton = true;
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int OverallTopPlayersExpHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select: OverallTopPlayers(iClient);
	}
}

void OverallTopPlayersTime(int iClient)
{
	if(CheckStatus(iClient))
	{
		char sQuery[128];
		FormatEx(sQuery, sizeof(sQuery), "SELECT `name`, `playtime` FROM `%s` WHERE `lastconnect` > 0 ORDER BY `playtime` DESC LIMIT 10 OFFSET 0", g_sTableName);
		g_hDatabase.Query(OverallTopPlayersTime_Callback, sQuery, iClient);
	}
}

public void OverallTopPlayersTime_Callback(Database db, DBResultSet dbRs, const char[] sError, any iClient)
{
	if(!dbRs)
	{
		LogLR("OverallTopPlayersTime - %s", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	if(CheckStatus(iClient))
	{
		int i;
		char sText[256], sName[32], sTemp[512];

		while(dbRs.HasResults && dbRs.FetchRow())
		{
			i++;
			dbRs.FetchString(0, sName, sizeof(sName));
			FormatEx(sText, sizeof(sText), "%T\n", "OverallTopPlayersTime_Slot", iClient, i, dbRs.FetchInt(1) / 3600.0, sName);

			if(strlen(sTemp) + strlen(sText) < 512)
			{
				Format(sTemp, sizeof(sTemp), "%s%s", sTemp, sText);
				sText = "\0";
			}
		}

		Menu hMenu = new Menu(OverallTopPlayersTimeHandler);
		hMenu.SetTitle("%s | %T\n \n%s\n ", g_sPluginTitle, "OverallTopPlayersTime", iClient, sTemp);

		FormatEx(sText, sizeof(sText), "%T", "Back", iClient);
		hMenu.AddItem("1", sText);

		hMenu.ExitButton = true;
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int OverallTopPlayersTimeHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select: OverallTopPlayers(iClient);
	}
}

void OverallRanks(int iClient)
{
	char sText[96];
	Menu hMenu = new Menu(OverallRanksHandler);
	hMenu.SetTitle("%s | %T\n ", g_sPluginTitle, "MainMenu_Ranks", iClient);

	for(int i = 1; i <= g_iCountRanks; i++)
	{
		if(i > 1)
		{
			FormatEx(sText, 96, "[%i] %T", g_iShowExp[i - 1], g_sShowRank[i], iClient);
			hMenu.AddItem("", sText, ITEMDRAW_DISABLED);
		}
		else
		{
			FormatEx(sText, 96, "%T", g_sShowRank[i], iClient);
			hMenu.AddItem("", sText, ITEMDRAW_DISABLED);
		}
	}

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int OverallRanksHandler(Menu hMenu, MenuAction mAction, int iClient, int iSlot)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
	}
}

public Action OnClientSayCommand(int iClient, const char[] command, const char[] sArgs)
{
	if(CheckStatus(iClient))
	{
		if(!strcmp(sArgs, "top", false) || !strcmp(sArgs, "!top", false))
		{
			OverallTopPlayersExp(iClient);
		}
		else if(!strcmp(sArgs, "toptime", false) || !strcmp(sArgs, "!toptime", false))
		{
			OverallTopPlayersTime(iClient);
		}
		else if(!strcmp(sArgs, "session", false) || !strcmp(sArgs, "!session", false))
		{
			MyStatsSession(iClient);
		}
		else if(!strcmp(sArgs, "rank", false) || !strcmp(sArgs, "!rank", false))
		{
			if(g_bRankMessage)
			{
				for(int i = 1; i <= MaxClients; i++)
				{
					if(CheckStatus(i)) LR_PrintToChat(i, "%T", "RankPlayer", i, iClient, g_iClientData[iClient][ST_PLACEINTOP], g_iDBCountPlayers, g_iClientData[iClient][ST_EXP], g_iClientData[iClient][ST_KILLS], g_iClientData[iClient][ST_DEATHS], float(g_iClientData[iClient][ST_KILLS] > 0 ? g_iClientData[iClient][ST_KILLS] : 1) / float(g_iClientData[iClient][ST_DEATHS] > 0 ? g_iClientData[iClient][ST_DEATHS] : 1));
				}
			}
			else LR_PrintToChat(iClient, "%T", "RankPlayer", iClient, iClient, g_iClientData[iClient][ST_PLACEINTOP], g_iDBCountPlayers, g_iClientData[iClient][ST_EXP], g_iClientData[iClient][ST_KILLS], g_iClientData[iClient][ST_DEATHS], float(g_iClientData[iClient][ST_KILLS] > 0 ? g_iClientData[iClient][ST_KILLS] : 1) / float(g_iClientData[iClient][ST_DEATHS] > 0 ? g_iClientData[iClient][ST_DEATHS] : 1));
		}
	}

	return Plugin_Continue;
}

public Action ResetSettings(int iClient, int iArgs)
{
	SetSettings(true);
	LR_PrintToChat(iClient, "%T", "ConfigUpdated", iClient);
	return Plugin_Handled;
}