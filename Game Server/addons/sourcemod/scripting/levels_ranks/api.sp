public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] sError, int iErrorSize)
{
	if((g_iEngine = GetEngineVersion()) != Engine_CSGO && g_iEngine != Engine_CSS && g_iEngine != Engine_SourceSDK2006)
	{
		strcopy(sError, iErrorSize, "This plugin works only on CS:GO, CS:S OB and CS:S v34.");

		return APLRes_SilentFailure;
	}

	CreateNative("LR_IsLoaded", Native_IsLoaded);
	CreateNative("LR_GetVersion", Native_GetVersion);
	CreateNative("LR_Hook", Native_Hook);
	CreateNative("LR_Unhook", Native_Unhook);
	CreateNative("LR_MenuHook", Native_MenuHook);
	CreateNative("LR_MenuUnhook", Native_MenuUnhook);
	CreateNative("LR_GetSettingsValue", Native_GetSettingsValue);
	CreateNative("LR_GetSettingsStatsValue", Native_GetSettingsStatsValue);
	CreateNative("LR_GetDatabase", Native_GetDatabase);
	CreateNative("LR_GetDatabaseType", Native_GetDatabaseType);
	CreateNative("LR_GetCountPlayers", Native_GetCountPlayers);
	CreateNative("LR_GetTableName", Native_GetTableName);
	CreateNative("LR_GetTitleMenu", Native_GetTitleMenu);
	CreateNative("LR_GetRankNames", Native_GetRankNames);
	CreateNative("LR_GetRankExp", Native_GetRankExp);
	CreateNative("LR_GetClientStatus", Native_GetClientStatus);
	CreateNative("LR_CheckCountPlayers", Native_CheckCountPlayers);
	CreateNative("LR_GetClientInfo", Native_GetClientInfo);
	CreateNative("LR_RoundWithoutValue", Native_RoundWithoutValue);
	CreateNative("LR_ChangeClientValue", Native_ChangeClientValue);
	CreateNative("LR_ResetPlayerStats", Native_ResetPlayerStats);
	CreateNative("LR_RefreshConfigs", Native_RefreshConfigs);
	CreateNative("LR_ShowMenu", Native_ShowMenu);
	CreateNative("LR_PrintToChat", Native_PrintToChat);

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
	g_hForward_Hook[LR_OnExpChanged] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	for(int iMenuType = LR_AdminMenu; iMenuType != LR_MenuType;)
	{
		g_hForward_CreatedMenu[iMenuType] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		g_hForward_SelectedMenu[iMenuType++] = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String);
	}

	RegPluginLibrary("levelsranks");

	return APLRes_Success;
}

// Natives

int Native_IsLoaded(Handle hPlugin, int iArgs)
{
	return g_bCoreIsLoaded;
}

int Native_GetVersion(Handle hPlugin, int iArgs)
{
	return PLUGIN_INT_VERSION;
}

int Native_Hook(Handle hPlugin, int iArgs)
{
	return g_hForward_Hook[GetNativeCell(1)].AddFunction(hPlugin, GetNativeCell(2));
}

int Native_Unhook(Handle hPlugin, int iArgs)
{
	return g_hForward_Hook[GetNativeCell(1)].RemoveFunction(hPlugin, GetNativeCell(2));
}

int Native_MenuHook(Handle hPlugin, int iArgs)
{
	int iMenuType = GetNativeCell(1);

	return g_hForward_CreatedMenu[iMenuType].AddFunction(hPlugin, GetNativeCell(2)) && g_hForward_SelectedMenu[iMenuType].AddFunction(hPlugin, GetNativeCell(3));
}

int Native_MenuUnhook(Handle hPlugin, int iArgs)
{
	int iMenuType = GetNativeCell(1);

	return g_hForward_CreatedMenu[iMenuType].RemoveFunction(hPlugin, GetNativeCell(2)) && g_hForward_SelectedMenu[iMenuType].RemoveFunction(hPlugin, GetNativeCell(3));
}

int Native_GetSettingsValue(Handle hPlugin, int iArgs)
{
	return g_Settings[GetNativeCell(1)];
}

int Native_GetSettingsStatsValue(Handle hPlugin, int iArgs)
{
	return g_SettingsStats[GetNativeCell(1)];
}

int Native_GetDatabase(Handle hPlugin, int iArgs)
{
	return g_hDatabase ? view_as<int>(CloneHandle(g_hDatabase, hPlugin)) : 0;
}

int Native_GetDatabaseType(Handle hPlugin, int iArgs)
{
	return g_bDatabaseSQLite;
}

int Native_GetCountPlayers(Handle hPlugin, int iArgs)
{
	return g_iDBCountPlayers;
}

int Native_GetTableName(Handle hPlugin, int iArgs)
{
	SetNativeString(1, g_sTableName, GetNativeCell(2), false);
}

int Native_GetTitleMenu(Handle hPlugin, int iArgs)
{
	SetNativeString(1, g_sPluginTitle, GetNativeCell(2), false);
}

int Native_GetClientStatus(Handle hPlugin, int iArgs)
{
	return g_iPlayerInfo[GetNativeCell(1)].bInitialized;
}

int Native_CheckCountPlayers(Handle hPlugin, int iArgs)
{
	return g_bAllowStatistic;
}

int Native_GetRankNames(Handle hPlugin, int iArgs)
{
	return view_as<int>(g_hRankNames);
}

int Native_GetRankExp(Handle hPlugin, int iArgs)
{
	return view_as<int>(g_hRankExp);
}

int Native_GetClientInfo(Handle hPlugin, int iArgs)
{
	int iType = GetNativeCell(2);

	return (iArgs == 3 && GetNativeCell(3) ? g_iPlayerInfo[GetNativeCell(1)].iSessionStats[iType] : g_iPlayerInfo[GetNativeCell(1)].iStats[iType]) + (iType == ST_PLAYTIME ? GetTime() : 0);
}

int Native_ResetPlayerStats(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		ResetPlayerStats(iClient);
	}
}

int Native_RefreshConfigs(Handle hPlugin, int iArgs)
{
	SetSettings();
}

int Native_ChangeClientValue(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient) && g_bAllowStatistic)
	{
		int iExpChange = GetNativeCell(2),
			iExpMin = 0,
			iOldExp = g_iPlayerInfo[iClient].iStats[ST_EXP];

		if(g_Settings[LR_TypeStatistics])
		{
			iExpMin = 400;
		}

		if((g_iPlayerInfo[iClient].iStats[ST_EXP] += iExpChange) < iExpMin)
		{
			g_iPlayerInfo[iClient].iStats[ST_EXP] = iExpMin;
		}

		g_iPlayerInfo[iClient].iRoundExp += iExpChange = iOldExp - g_iPlayerInfo[iClient].iStats[ST_EXP];
		g_iPlayerInfo[iClient].iSessionStats[ST_EXP] += iExpChange;

		CheckRank(iClient);
		CallForward_OnExpChanged(iClient, iExpChange, g_iPlayerInfo[iClient].iStats[ST_EXP]);

		return true;
	}

	return false;
}

int Native_RoundWithoutValue(Handle hPlugin, int iArgs)
{
	g_bAllowStatistic = false;
}

int Native_ShowMenu(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);

	switch(GetNativeCell(2))
	{
		case LR_AdminMenu: MenuAdmin(iClient);
		case LR_MyStatsSecondary: MyStatsSecondary(iClient);
		case LR_SettingMenu: MyPrivilegesSettings(iClient);
		case LR_TopMenu: MenuTop(iClient);
	}
}

int Native_PrintToChat(Handle hPlugin, int iArgs)
{
	LR_PrintMessage(GetNativeCell(1), GetNativeCell(2), true, NULL_STRING);
}

// Forwards

void CallForward_OnCoreIsReady()
{
	g_bCoreIsLoaded = true;

	Profiler hProfiler = new Profiler();

	hProfiler.Start();

	Call_StartForward(g_hForward_OnCoreIsReady);
	Call_Finish();

	hProfiler.Stop();

	float fTime = hProfiler.Time;

	if(fTime > 0.25)
	{
		LogWarning(false, "Warning: Lag occurred from LR modules in %f sec.", fTime);
	}

	hProfiler.Close();
}

void CallForward_OnSettingsModuleUpdate()
{
	Call_StartForward(g_hForward_Hook[LR_OnSettingsModuleUpdate]);
	Call_Finish();
}

void CallForward_OnDatabaseCleanup(int iType, Transaction hTransaction)
{
	Call_StartForward(g_hForward_Hook[LR_OnDatabaseCleanup]);
	Call_PushCell(iType);
	Call_PushCell(hTransaction);
	Call_Finish();
}

void CallForward_OnLevelChanged(int iClient, int& iNewRank, int iOldRank, bool bRef = true)
{
	Call_StartForward(g_hForward_Hook[LR_OnLevelChangedPre + view_as<int>(!bRef)]);
	Call_PushCell(iClient);

	if(bRef)
	{
		Call_PushCellRef(iNewRank);
	}
	else
	{
		Call_PushCell(iNewRank);
	}

	Call_PushCell(iOldRank);
	Call_Finish();
}

void CallForward_OnPlayerKilled(Event hEvent, int& iExpCaused, int iClient, int iAttacker, bool bRef = true)
{
	Call_StartForward(g_hForward_Hook[LR_OnPlayerKilledPre + view_as<int>(!bRef)]);
	Call_PushCell(hEvent);

	if(bRef)
	{
		Call_PushCellRef(iExpCaused);
	}
	else
	{
		Call_PushCell(iExpCaused);
	}

	Call_PushCell(g_iPlayerInfo[iClient].iStats[ST_EXP]);
	Call_PushCell(g_iPlayerInfo[iAttacker].iStats[ST_EXP]);
	Call_Finish();
}

void CallForward_OnPlayerLoaded(int iClient)
{
	Call_StartForward(g_hForward_Hook[LR_OnPlayerLoaded]);
	Call_PushCell(iClient);
	Call_PushCell(g_iPlayerInfo[iClient].iAccountID);
	Call_Finish();
}

void CallForward_OnResetPlayerStats(int iClient, int iAccountID)
{
	Call_StartForward(g_hForward_Hook[LR_OnResetPlayerStats]);
	Call_PushCell(iClient);
	Call_PushCell(iAccountID);
	Call_Finish();
}

void CallForward_OnPlayerPosInTop(int iClient)
{
	Call_StartForward(g_hForward_Hook[LR_OnPlayerPosInTop]);
	Call_PushCell(iClient);
	Call_PushCell(g_iPlayerInfo[iClient].iStats[ST_PLACEINTOP]);
	Call_PushCell(g_iPlayerInfo[iClient].iStats[ST_PLACEINTOPTIME]);
	Call_Finish();
}

void CallForward_OnPlayerSaved(int iClient, Transaction hTransaction)
{
	Call_StartForward(g_hForward_Hook[LR_OnPlayerSaved]);
	Call_PushCell(iClient);
	Call_PushCell(hTransaction);
	Call_Finish();
}


void CallForward_OnExpChanged(int iClient, int iGiveExp, int iNewExpCount)
{
	Call_StartForward(g_hForward_Hook[LR_OnExpChanged]);
	Call_PushCell(iClient);
	Call_PushCell(iGiveExp);
	Call_PushCell(iNewExpCount);
	Call_Finish();
}

void CallForward_MenuHook(int iMenuType, int iClient, Menu hMenu, int iSlot = -1)
{
	static int iSelectPosition = 0;

	Call_StartForward(iSlot == -1 ? g_hForward_CreatedMenu[iMenuType] : g_hForward_SelectedMenu[iMenuType]);
	Call_PushCell(iMenuType);
	Call_PushCell(iClient);

	if(iSlot == -1)
	{
		Call_PushCell(hMenu);
		Call_Finish();

		hMenu.ExitBackButton = true;
		hMenu.DisplayAt(iClient, iSelectPosition, MENU_TIME_FOREVER);
	}
	else
	{
		decl char sInfo[64];

		hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

		iSelectPosition = hMenu.Selection;

		Call_PushString(sInfo);
		Call_Finish();

		iSelectPosition = 0;
	}
}
