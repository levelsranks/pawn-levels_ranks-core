void NotifClient(int iClient, int iValue, char[] sTitlePhrase)
{
	if(!g_bWarmupPeriod && !g_bRoundWithoutExp && g_bRoundEndGiveExp && iValue && g_iCountPlayers >= g_iMinimumPlayers && CheckStatus(iClient))
	{
		int iExpMin = (!g_iTypeStatistics ? 0 : 400);
		g_iClientData[iClient][ST_EXP] += iValue;
		g_iClientRoundExp[iClient] += iValue;

		if(g_iClientData[iClient][ST_EXP] < iExpMin)
		{
			g_iClientData[iClient][ST_EXP] = iExpMin;
		}

		CheckRank(iClient);

		if(g_iUsualMessage == 1)
		{
			char sBuffer[64];
			FormatEx(sBuffer, sizeof(sBuffer), iValue > 0 ? "+%d" : "%d", iValue);
			LR_PrintToChat(iClient, "%T", sTitlePhrase, iClient, g_iClientData[iClient][ST_EXP], sBuffer);
		}
	}
}

bool CheckStatus(int iClient)
{
	return (iClient && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient]) || (g_bInitialized[iClient] = false);
}

void CheckRank(int iClient)
{
	if(CheckStatus(iClient))
	{
		int iRank = g_iClientData[iClient][ST_RANK];

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

		if(g_iClientData[iClient][ST_RANK] != iRank)
		{
			bool bUp = (g_iClientData[iClient][ST_RANK] > iRank);
			char sBufferRank[128];

			FormatEx(sBufferRank, 128, "%T", g_sShowRank[g_iClientData[iClient][ST_RANK]], iClient);
			LR_PrintToChat(iClient, "%T", bUp ? "LevelUp" : "LevelDown", iClient, sBufferRank);
			LR_EmitSound(iClient, bUp ? g_sSoundUp : g_sSoundDown);

			Call_StartForward(g_hForward_OnLevelChanged);
			Call_PushCell(iClient);
			Call_PushCell(g_iClientData[iClient][ST_RANK]);
			Call_PushCell(bUp);
			Call_Finish();

			if(bUp ? g_bLevelUpMessage : g_bLevelDownMessage)
			{
				char sBuffer[16];
				strcopy(sBuffer, sizeof(sBuffer), bUp ? "LevelUpAll" : "LevelDownAll");

				for(int i = 1; i <= MaxClients; i++)
				{
					if(i != iClient && g_bInitialized[i])
					{
						FormatEx(sBufferRank, 128, "%T", g_sShowRank[g_iClientData[iClient][ST_RANK]], i);
						LR_PrintToChat(i, "%T", sBuffer, i, iClient, sBufferRank);
					}
				}
			}
		}
	}
}

void LR_PrecacheSound()
{
	char sBuffer[256];
	switch(EngineGame)
	{
		case Engine_CSGO:
		{
			int iStringTable = FindStringTable("soundprecache");
			FormatEx(sBuffer, 256, "*%s", g_sSoundUp); AddToStringTable(iStringTable, sBuffer);
			FormatEx(sBuffer, 256, "*%s", g_sSoundDown); AddToStringTable(iStringTable, sBuffer);
		}

		case Engine_CSS, Engine_SourceSDK2006:
		{
			PrecacheSound(g_sSoundUp);
			PrecacheSound(g_sSoundDown);
		}
	}
}

void LR_EmitSound(int iClient, char[] sPath)
{
	if(g_bSoundRankPlay)
	{
		char sBuffer[256];
		switch(EngineGame)
		{
			case Engine_CSGO: FormatEx(sBuffer, 256, "*%s", sPath);
			case Engine_CSS, Engine_SourceSDK2006: strcopy(sBuffer, 256, sPath);
		}
		EmitSoundToClient(iClient, sBuffer, SOUND_FROM_PLAYER, 80);
	}
}

public Action PlayTimeCounter(Handle hTimer)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(CheckStatus(iClient))
		{
			g_iClientData[iClient][ST_PLAYTIME]++;
			g_iClientSessionData[iClient][9]++;
		}
	}
}