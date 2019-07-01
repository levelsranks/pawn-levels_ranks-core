public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("LR_GetDatabase", Native_LR_GetDatabase);
	CreateNative("LR_GetDatabaseType", Native_LR_GetDatabaseType);
	CreateNative("LR_GetTableName", Native_LR_GetTableName);
	CreateNative("LR_GetTitleMenu", Native_LR_GetTitleMenu);
	CreateNative("LR_GetParamUsualMessage", Native_LR_GetParamUsualMessage);
	CreateNative("LR_GetTypeStatistics", Native_LR_GetTypeStatistics);
	CreateNative("LR_GetCountLevels", Native_LR_GetCountLevels);
	CreateNative("LR_GetClientStatus", Native_LR_GetClientStatus);
	CreateNative("LR_CheckCountPlayers", Native_LR_CheckCountPlayers);
	CreateNative("LR_GetClientInfo", Native_LR_GetClientInfo);
	CreateNative("LR_ChangeClientValue", Native_LR_ChangeClientValue);
	CreateNative("LR_RoundWithoutValue", Native_LR_RoundWithoutValue);
	CreateNative("LR_MenuInventory", Native_LR_MenuInventory);
	CreateNative("LR_MenuTopMenu", Native_LR_MenuTopMenu);
	CreateNative("LR_MenuAdminPanel", Native_LR_MenuAdminPanel);
	RegPluginLibrary("levelsranks");
}

public int Native_LR_GetDatabase(Handle hPlugin, int iNumParams)
{
	return view_as<int>(CloneHandle(g_hDatabase, hPlugin));
}

public int Native_LR_GetDatabaseType(Handle hPlugin, int iNumParams)
{
	return g_bDatabaseSQLite;
}

public int Native_LR_GetTableName(Handle hPlugin, int iNumParams)
{
	SetNativeString(1, g_sTableName, GetNativeCell(2), false);
}

public int Native_LR_GetTitleMenu(Handle hPlugin, int iNumParams)
{
	SetNativeString(1, g_sPluginTitle, GetNativeCell(2), false);
}

public int Native_LR_GetParamUsualMessage(Handle hPlugin, int iNumParams)
{
	return g_iUsualMessage;
}

public int Native_LR_GetTypeStatistics(Handle hPlugin, int iNumParams)
{
	return g_iTypeStatistics;
}

public int Native_LR_GetCountLevels(Handle hPlugin, int iNumParams)
{
	return g_iCountRanks;
}

public int Native_LR_GetClientStatus(Handle hPlugin, int iNumParams)
{
	return g_bInitialized[GetNativeCell(1)];
}

public int Native_LR_CheckCountPlayers(Handle hPlugin, int iNumParams)
{
	return !g_bWarmupPeriod && g_iCountPlayers >= g_iMinimumPlayers;
}

public int Native_LR_GetClientInfo(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		return g_iClientData[iClient][GetNativeCell(2)];
	}
	return 0;
}

public int Native_LR_ChangeClientValue(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iValue = GetNativeCell(2);

	if(CheckStatus(iClient))
	{
		int iExpMin = !g_iTypeStatistics ? 0 : 400;
		g_iClientData[iClient][ST_EXP] += iValue;

		if(g_iClientData[iClient][ST_EXP] < iExpMin)
		{
			g_iClientData[iClient][ST_EXP] = iExpMin;
		}

		CheckRank(iClient);
		return g_iClientData[iClient][ST_EXP];
	}
	return 0;
}

public int Native_LR_RoundWithoutValue(Handle hPlugin, int iNumParams)
{
	g_bRoundWithoutExp = true;
}

public int Native_LR_MenuInventory(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		MyPrivilegesSettings(iClient);
	}
}

public int Native_LR_MenuTopMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		OverallTopPlayers(iClient);
	}
}

public int Native_LR_MenuAdminPanel(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		IamAdmin(iClient);
	}
}