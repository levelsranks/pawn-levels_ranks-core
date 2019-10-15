void LR_PrintMessage(int iClient, bool bPrefix, bool bNative, const char[] sFormat, any ...)
{
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		static char 		sMessage[254];

		static const char	sColorsBefore[][] = {"{DEFAULT}", "{TEAM}", "{GREEN}", "{RED}", "{LIME}", "{LIGHTGREEN}", "{LIGHTRED}", "{GRAY}", "{LIGHTOLIVE}", "{OLIVE}", "{LIGHTBLUE}", "{BLUE}", "{PURPLE}", "{BRIGHTRED}"},
							sColors[][] = {"\x01", "\x03", "\x04", "\x02", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0C", "\x0E", "\x0F"};

		if(bNative)
		{
			FormatNativeString(0, 3, 4, sizeof(sMessage), _, sMessage);
		}
		else
		{
			VFormat(sMessage, sizeof(sMessage), sFormat, 5);
		}
		
		if(sMessage[0] != '\0')
		{
			if(bPrefix)
			{
				Format(sMessage, sizeof(sMessage), g_iEngine == Engine_CSGO ? " %T %s" : "%T %s", "Prefix", iClient, sMessage);
			}
			else if(g_iEngine == Engine_CSGO)
			{
				Format(sMessage, sizeof(sMessage), " %s", sMessage);
			}

			if(g_iEngine != Engine_SourceSDK2006)
			{
				ReplaceString(sMessage, sizeof(sMessage), "{WHITE}", "{DEFAULT}");
			}

			switch(g_iEngine)
			{
				case Engine_CSGO:
				{
					for(int i = 0; i != sizeof(sColorsBefore); i++)
					{
						ReplaceString(sMessage, sizeof(sMessage), sColorsBefore[i], sColors[i]);
					}
				}

				case Engine_CSS:
				{
					static const int iColorsCSSOB[] = {0xFFFFFF, 0x000000, 0x00AD00, 0xFF0000, 0x00FF00, 0x99FF99, 0xFF4040, 0xCCCCCC, 0xFFBD6B, 0xFA8B00, 0x99CCFF, 0x3D46FF, 0xFA00FA, 0xFF6055};

					static char sColor[16];

					static const char sFormatColor[] = "\x07%06X";

					int iLen = StrContains(sMessage, sColorsBefore[1], false);

					if(iLen != -1)
					{
						static const int iColorTeamCSSOB[] = {0xFFFFFF, 0xCCCCCC, 0xFF4040, 0x99CCFF};

						FormatEx(sColor, sizeof(sColor), sFormatColor, iColorTeamCSSOB[GetClientTeam(iClient)]);
						ReplaceString(sMessage[iLen], sizeof(sMessage) - iLen, sColorsBefore[1], sColor);
					}

					for(int i = 0; i != sizeof(sColorsBefore); i++)
					{
						if((iLen = StrContains(sMessage, sColorsBefore[i], false)) != -1)
						{
							FormatEx(sColor, sizeof(sColor), sFormatColor, iColorsCSSOB[i]);
							ReplaceString(sMessage[iLen], sizeof(sMessage) - iLen, sColorsBefore[i], sColor);
						}
					}
				}

				case Engine_SourceSDK2006:
				{
					for(int j = 0; j != 3; j++)
					{
						ReplaceString(sMessage, sizeof(sMessage), sColorsBefore[j], sColors[j]);
					}
				}
			}

			Handle hMessage = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE);

			if(hMessage)
			{
				if(GetUserMessageType() == UM_Protobuf)
				{
					Protobuf hProtobuf = view_as<Protobuf>(hMessage);

					hProtobuf.SetInt("ent_idx", iClient);
					hProtobuf.SetBool("chat", true);
					hProtobuf.SetString("msg_name", sMessage);

					for(int i = 0; i != 4; i++)
					{
						hProtobuf.AddString("params", NULL_STRING);
					}
				}
				else
				{
					BfWrite hMessageStack = view_as<BfWrite>(hMessage);

					hMessageStack.WriteByte(iClient);
					hMessageStack.WriteByte(true);
					hMessageStack.WriteString(sMessage);
				}

				EndMessage();
			}
		}
	}
}

int GetMaxPlayers()
{
	int iSlots = GetMaxHumanPlayers();

	return (iSlots < MaxClients + 1 ? iSlots : MaxClients) + 1;
}

char[] GetPlayerName(int iClient)
{
	static char sName[65];

	GetClientName(iClient, sName, 32);
	g_hDatabase.Escape(sName, sName, sizeof(sName));

	return sName;
}

bool NotifClient(int iClient, int iValue, char[] sTitlePhrase)
{
	if(!g_bWarmupPeriod && g_bRoundAllowExp && g_bRoundEndGiveExp && iValue && g_iCountPlayers >= g_Settings[LR_MinplayersCount] && CheckStatus(iClient))
	{
		int iExpMin = 0;

		if(g_Settings[LR_TypeStatistics])
		{
			iExpMin = 400;
		}

		g_iPlayerInfo[iClient].iRoundExp += iValue;

		if((g_iPlayerInfo[iClient].iStats[ST_EXP] += iValue) < iExpMin)
		{
			g_iPlayerInfo[iClient].iStats[ST_EXP] = iExpMin;
		}

		CheckRank(iClient);

		if(g_Settings[LR_ShowUsualMessage] == 1)
		{
			static char sBuffer[64];

			FormatEx(sBuffer, sizeof(sBuffer), iValue > 0 ? "+%d" : "%d", iValue);
			LR_PrintMessage(iClient, true, false, "%T", sTitlePhrase, iClient, g_iPlayerInfo[iClient].iStats[ST_EXP], sBuffer);
		}

		return true;
	}

	return false;
}

bool CheckStatus(int iClient)
{
	return (iClient && IsClientAuthorized(iClient) && !IsFakeClient(iClient) && g_iPlayerInfo[iClient].bInitialized) || (g_iPlayerInfo[iClient].bInitialized = false);
}

void CheckRank(int iClient)
{
	if(CheckStatus(iClient))
	{
		int iExp = g_iPlayerInfo[iClient].iStats[ST_EXP],
			iMaxRanks = g_hRankExp.Length,
			iRank = iMaxRanks + 1, 
			iOldRank = g_iPlayerInfo[iClient].iStats[ST_RANK];

		static char sRank[192];

		while(--iRank && g_hRankExp.Get(iRank - 1) > iExp) {}

		if(iRank != iOldRank)
		{
			if(GetForwardFunctionCount(g_hForward_Hook[LR_OnLevelChangedPre]))
			{
				int iNewRank = iRank;

				Call_StartForward(g_hForward_Hook[LR_OnLevelChangedPre]);
				Call_PushCell(iClient);
				Call_PushCellRef(iNewRank);
				Call_PushCell(iOldRank);
				Call_Finish();

				if(0 < iNewRank && iNewRank < iMaxRanks && iNewRank != iOldRank)
				{
					iRank = iNewRank;
				}
				else
				{
					LogError("%i - invalid number rank.", iNewRank);
				}
			}

			bool bUp = (g_iPlayerInfo[iClient].iStats[ST_RANK] = iRank) > iOldRank;

			g_hRankNames.GetString(iRank - 1, sRank, sizeof(sRank));

			FormatEx(sRank, sizeof(sRank), "%T", sRank, iClient);
			LR_PrintMessage(iClient, true, false, "%T", bUp ? "LevelUp" : "LevelDown", iClient, sRank);

			if(IsClientInGame(iClient) && g_Settings[LR_IsLevelSound])
			{
				EmitSoundToClient(iClient, bUp ? g_sSoundUp : g_sSoundDown, SOUND_FROM_PLAYER, 80);
			}

			if(g_Settings[LR_ShowLevelUpMessage + view_as<int>(bUp)])
			{
				for(int i = GetMaxPlayers(); --i;)
				{
					if(g_iPlayerInfo[i].bInitialized && i != iClient)
					{
						LR_PrintMessage(i, true, false, "%T", bUp ? "LevelUpAll" : "LevelDownAll", i, iClient, sRank);
					}
				}
			}

			SaveDataPlayer(iClient);		// in database.sp

			Call_StartForward(g_hForward_Hook[LR_OnLevelChangedPost]);
			Call_PushCell(iClient);
			Call_PushCell(iRank);
			Call_PushCell(iOldRank);
			Call_Finish();
		}
	}
}

void ResetPlayerData(int iClient)
{
	int iAccountID = g_iPlayerInfo[iClient].iAccountID;

	g_iPlayerInfo[iClient] = g_iInfoNULL;
	g_iPlayerInfo[iClient].iAccountID = iAccountID;
	g_iPlayerInfo[iClient].iSessionStats[0] = (g_iPlayerInfo[iClient].iStats[ST_EXP] = g_Settings[LR_TypeStatistics] ? 1000 : 0);
	g_iPlayerInfo[iClient].bInitialized = true;
}

void ResetPlayerStats(int iClient)
{
	ResetPlayerData(iClient);

	CheckRank(iClient);

	Call_StartForward(g_hForward_Hook[LR_OnResetPlayerStats]);
	Call_PushCell(iClient);
	Call_PushCell(g_iPlayerInfo[iClient].iAccountID);
	Call_Finish();
}

Action PlayTimeCounter(Handle hTimer)
{
	for(int i = GetMaxPlayers(); --i;)
	{
		if(CheckStatus(i))
		{
			g_iPlayerInfo[i].iStats[ST_PLAYTIME]++;
			g_iPlayerInfo[i].iSessionStats[9]++;
		}
	}
}