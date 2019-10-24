public APLRes AskPluginLoad2()
{
	if((g_iEngine = GetEngineVersion()) != Engine_CSGO && g_iEngine != Engine_CSS && g_iEngine != Engine_SourceSDK2006)
	{
		SetFailState("This plugin works only on CS:GO ar CS:S OB ar CS:S v34.");
	}

	CreateNative("LR_IsLoaded", Native_LR_IsLoaded);

	CreateNative("LR_Hook", Native_LR_Hook);
	CreateNative("LR_Unhook", Native_LR_Unhook);
	CreateNative("LR_MenuHook", Native_LR_MenuHook);
	CreateNative("LR_MenuUnhook", Native_LR_MenuUnhook);

	CreateNative("LR_GetSettingsValue", Native_LR_GetSettingsValue);
	CreateNative("LR_GetDatabase", Native_LR_GetDatabase);
	CreateNative("LR_GetDatabaseType", Native_LR_GetDatabaseType);
	CreateNative("LR_GetCountPlayers", Native_LR_GetCountPlayers);
	CreateNative("LR_GetTableName", Native_LR_GetTableName);
	CreateNative("LR_GetTitleMenu", Native_LR_GetTitleMenu);
	CreateNative("LR_GetRankNames", Native_LR_GetRankNames);
	CreateNative("LR_GetRankExp", Native_LR_GetRankExp);
	CreateNative("LR_GetClientStatus", Native_LR_GetClientStatus);
	CreateNative("LR_CheckCountPlayers", Native_LR_CheckCountPlayers);
	CreateNative("LR_GetClientInfo", Native_LR_GetClientInfo);
	CreateNative("LR_RoundWithoutValue", Native_LR_RoundWithoutValue);
	CreateNative("LR_ChangeClientValue", Native_LR_ChangeClientValue);
	CreateNative("LR_ResetPlayerStats", Native_LR_ResetPlayerStats);
	CreateNative("LR_RefreshConfigs", Native_LR_RefreshConfigs);
	CreateNative("LR_ShowMenu", Native_LR_ShowMenu);
	CreateNative("LR_PrintToChat", Native_LR_PrintToChat);

	g_hForward_OnCoreIsReady = new GlobalForward("LR_OnCoreIsReady", ET_Ignore);

	g_hForward_Hook[LR_OnSettingsModuleUpdate] = new PrivateForward(ET_Ignore);
	g_hForward_Hook[LR_OnDisconnectionWithDB] = new PrivateForward(ET_Ignore, Param_CellByRef);
	g_hForward_Hook[LR_OnDatabaseCleanup] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_Hook[LR_OnLevelChangedPre] = new PrivateForward(ET_Ignore, Param_Cell, Param_CellByRef, Param_Cell);
	g_hForward_Hook[LR_OnLevelChangedPost] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForward_Hook[LR_OnPlayerKilledPre] = new PrivateForward(ET_Ignore, Param_Cell, Param_CellByRef, Param_Cell, Param_Cell);
	g_hForward_Hook[LR_OnPlayerKilledPost] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForward_Hook[LR_OnPlayerLoaded] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_Hook[LR_OnResetPlayerStats] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell);
	g_hForward_Hook[LR_OnPlayerPosInTop] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForward_Hook[LR_OnPlayerSaved] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell);

	for(int iMenuType = LR_AdminMenu; iMenuType != LR_MenuType;)
	{
		g_hForward_CreatedMenu[iMenuType] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		g_hForward_SelectedMenu[iMenuType++] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String);
	}

	RegPluginLibrary("levelsranks");
}

int Native_LR_IsLoaded(Handle hPlugin, int iNumParams)
{
	return !g_hForward_OnCoreIsReady;
}

int Native_LR_Hook(Handle hPlugin, int iNumParams)
{
	return g_hForward_Hook[GetNativeCell(1)].AddFunction(hPlugin, GetNativeCell(2));
}

int Native_LR_Unhook(Handle hPlugin, int iNumParams)
{
	return g_hForward_Hook[GetNativeCell(1)].RemoveFunction(hPlugin, GetNativeCell(2));
}

int Native_LR_MenuHook(Handle hPlugin, int iNumParams)
{
	int iMenuType = GetNativeCell(1);

	return g_hForward_CreatedMenu[iMenuType].AddFunction(hPlugin, GetNativeCell(2)) && g_hForward_SelectedMenu[iMenuType].AddFunction(hPlugin, GetNativeCell(3));
}

int Native_LR_MenuUnhook(Handle hPlugin, int iNumParams)
{
	int iMenuType = GetNativeCell(1);

	return g_hForward_CreatedMenu[iMenuType].RemoveFunction(hPlugin, GetNativeCell(2)) && g_hForward_SelectedMenu[iMenuType].RemoveFunction(hPlugin, GetNativeCell(3));
}

int Native_LR_GetSettingsValue(Handle hPlugin, int iNumParams)
{
	return g_Settings[GetNativeCell(1)];
}

int Native_LR_GetDatabase(Handle hPlugin, int iNumParams)
{
	if(g_hDatabase)
	{
		return view_as<int>(CloneHandle(g_hDatabase, hPlugin));
	}

	return 0;
}

int Native_LR_GetDatabaseType(Handle hPlugin, int iNumParams)
{
	return g_bDatabaseSQLite;
}

int Native_LR_GetCountPlayers(Handle hPlugin, int iNumParams)
{
    return g_iDBCountPlayers;
}

int Native_LR_GetTableName(Handle hPlugin, int iNumParams)
{
	SetNativeString(1, g_sTableName, GetNativeCell(2), false);
}

int Native_LR_GetTitleMenu(Handle hPlugin, int iNumParams)
{
	SetNativeString(1, g_sPluginTitle, GetNativeCell(2), false);
}

int Native_LR_GetClientStatus(Handle hPlugin, int iNumParams)
{
	return g_iPlayerInfo[GetNativeCell(1)].bInitialized;
}

int Native_LR_CheckCountPlayers(Handle hPlugin, int iNumParams)
{
	return !g_bWarmupPeriod && g_iCountPlayers >= g_Settings[LR_MinplayersCount] && g_bRoundAllowExp && g_bRoundEndGiveExp;
}

int Native_LR_GetRankNames(Handle hPlugin, int iNumParams)
{
	return view_as<int>(g_hRankNames);
}

int Native_LR_GetRankExp(Handle hPlugin, int iNumParams)
{
	return view_as<int>(g_hRankExp);
}

int Native_LR_GetClientInfo(Handle hPlugin, int iNumParams)
{
	int iType = GetNativeCell(2);

	if(iType == ST_PLAYTIME)
	{
		return g_iPlayerInfo[GetNativeCell(1)].iStats[ST_PLAYTIME] + GetTime();
	}

	return g_iPlayerInfo[GetNativeCell(1)].iStats[iType];
}

int Native_LR_ResetPlayerStats(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		ResetPlayerStats(iClient);
	}
}

int Native_LR_RefreshConfigs(Handle hPlugin, int iNumParams)
{
	SetSettings();
}

int Native_LR_ChangeClientValue(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		int iExpChange = GetNativeCell(2),
			iExpMin = 0;

		if(g_Settings[LR_TypeStatistics])
		{
			iExpMin = 400;
		}

		if((g_iPlayerInfo[iClient].iStats[ST_EXP] += iExpChange) < iExpMin)
		{
			g_iPlayerInfo[iClient].iRoundExp += iExpChange - (iExpMin - g_iPlayerInfo[iClient].iStats[ST_EXP]);
			g_iPlayerInfo[iClient].iStats[ST_EXP] = iExpMin;
		}
		else
		{
			g_iPlayerInfo[iClient].iRoundExp += iExpChange;
		}

		CheckRank(iClient);		// in custom_functions.sp
	}
}

int Native_LR_RoundWithoutValue(Handle hPlugin, int iNumParams)
{
	g_bRoundAllowExp = true;
}

int Native_LR_ShowMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	switch(GetNativeCell(2))
	{
		// functions in menus.sp
		case LR_AdminMenu: MenuAdmin(iClient);
		case LR_MyStatsSecondary: MyStatsSecondary(iClient);
		case LR_SettingMenu: MyPrivilegesSettings(iClient);
		case LR_TopMenu: MenuTop(iClient);
	}
}

int Native_LR_PrintToChat(Handle hPlugin, int iNumParams)
{
	LR_PrintMessage(GetNativeCell(1), GetNativeCell(2), true, NULL_STRING);		// in custom_functions.sp
}