void LR_PrintMessage(int iClient, bool bPrefix, bool bNative, const char[] sFormat, any ...)
{
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		// Maximum size, in CS:GO Panorama.
		decl char sMessage[2048];

		static const char sColorsBefore[][] =
		{
			"{DEFAULT}",
			"{TEAM}",
			"{GREEN}",
			"{RED}",
			"{LIME}",
			"{LIGHTGREEN}",
			"{LIGHTRED}",
			"{GRAY}",
			"{LIGHTOLIVE}",
			"{GRAYBLUE}",
			"{LIGHTBLUE}",
			"{BLUE}",
			"{PURPLE}",
			"{PINK}",
			"{BRIGHTRED}",
			"{OLIVE}"
		},

		sColors[][] = {"\x01", "\x03", "\x04", "\x02", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0A", "\x0B", "\x0C", "\x0D", "\x0E", "\x0F", "\x10"};

		if(bNative)
		{
			FormatNativeString(0, 3, 4, sizeof(sMessage), _, sMessage);
		}
		else
		{
			VFormat(sMessage, sizeof(sMessage), sFormat, 5);
		}
		
		if(sMessage[0])
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
					static const int iColorsCSSOB[] = {0xFFFFFF, 0x000000, 0x00AD00, 0xFF0000, 0x00FF00, 0x99FF99, 0xFF4040, 0xCCCCCC, 0xFFBD6B, 0xC1D1E1, 0x99CCFF, 0x3D46FF, 0xD62BD6, 0xFA00FA, 0xFF8080, 0xFA8B00};

					decl char sColor[16];

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

			Handle hMessage = StartMessageOne("SayText", iClient, USERMSG_RELIABLE);

			if(hMessage)
			{
				if(GetUserMessageType() == UM_Protobuf)
				{
					Protobuf hProtobuf = view_as<Protobuf>(hMessage);

					hProtobuf.SetInt("ent_idx", 0);
					hProtobuf.SetString("text", sMessage);
					hProtobuf.SetBool("chat", true);
				}
				else
				{
					BfWrite hMessageStack = view_as<BfWrite>(hMessage);

					hMessageStack.WriteByte(0);
					hMessageStack.WriteString(sMessage);
					hMessageStack.WriteByte(true);
				}

				EndMessage();
			}
		}
	}
}

void LogWarning(bool bNative, const char[] sFormat, any ...)
{
	static char sLogPath[PLATFORM_MAX_PATH];

	if(!sLogPath[0])
	{
		BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/lr_warnings.log");
	}

	decl char sLogContent[256];

	if(bNative)
	{
		FormatNativeString(0, 3, 4, sizeof(sLogContent), _, sLogContent);
	}
	else
	{
		VFormat(sLogContent, sizeof(sLogContent), sFormat, 5);
	}

	LogToFile(sLogPath, "%s", sLogContent);
}

int GetAccountIDFromSteamID2(const char[] sSteamID2)
{
	return StringToInt(sSteamID2[10]) << 1 | sSteamID2[8] - '0';
}

int GetMaxPlayers()
{
	int iSlots = GetMaxHumanPlayers();

	return (iSlots < MaxClients + 1 ? iSlots : MaxClients) + 1;
}

char[] GetPlayerName(int iClient)
{
	decl char sName[65];

	GetClientName(iClient, sName, 32);

	g_hDatabase.Escape(sName, sName, sizeof(sName));

	if(!g_Settings[LR_DB_Allow_UTF8MB4])
	{
		GetFixNamePlayer(sName);
	}

	return sName;
}

/**
 * Fix name by Pheonix
 */
void GetFixNamePlayer(char[] sName)
{
	for(int i = 0, iLen = strlen(sName), iCharBytes; i < iLen;)
	{
		if((iCharBytes = GetCharBytes(sName[i])) == 4)
		{
			iLen -= iCharBytes;

			for(int j = i; j <= iLen; j++)
			{
				sName[j] = sName[j + iCharBytes];
			}
		}
		else
		{
			i += iCharBytes;
		}
	}
}

char[] GetSignValue(int iValue)
{
	bool bPlus = iValue > 0;

	decl char sValue[16];

	if(bPlus)
	{
		sValue[0] = '+';
	}

	IntToString(iValue, sValue[view_as<int>(bPlus)], sizeof(sValue) - view_as<int>(bPlus));

	return sValue;
}

char[] GetSteamID2(int iAccountID)
{
	decl char sSteamID2[22] = "STEAM_";

	if(!sSteamID2[6])
	{
		sSteamID2[6] = '0' + view_as<int>(g_iEngine == Engine_CSGO);
		sSteamID2[7] = ':';
	}

	FormatEx(sSteamID2[8], 14, "%i:%i", iAccountID & 1, iAccountID >>> 1);

	return sSteamID2;
}

bool NotifClient(int iClient, int iValue, const char[] sTitlePhrase, bool bAllow = false)
{
	if(CheckStatus(iClient) && (bAllow || g_bAllowStatistic))
	{
		if(iValue)
		{
			int iExpBuffer = 0,
			    iOldExp = g_iPlayerInfo[iClient].iStats[ST_EXP];

			if(g_Settings[LR_TypeStatistics])
			{
				iExpBuffer = 400;
			}

			if((g_iPlayerInfo[iClient].iStats[ST_EXP] += iValue) < iExpBuffer)
			{
				g_iPlayerInfo[iClient].iStats[ST_EXP] = iExpBuffer;
			}

			g_iPlayerInfo[iClient].iRoundExp += iExpBuffer = g_iPlayerInfo[iClient].iStats[ST_EXP] - iOldExp;
			g_iPlayerInfo[iClient].iSessionStats[ST_EXP] += iExpBuffer;

			CheckRank(iClient);
			CallForward_OnExpChanged(iClient, iExpBuffer, g_iPlayerInfo[iClient].iStats[ST_EXP]);

			if(g_Settings[LR_ShowUsualMessage] == 1)
			{
				LR_PrintMessage(iClient, true, false, "%T", sTitlePhrase, iClient, g_iPlayerInfo[iClient].iStats[ST_EXP], GetSignValue(iValue));
			}
		}

		return true;
	}

	return false;
}

bool CheckStatus(int iClient)
{
	return (iClient && IsClientAuthorized(iClient) && !IsFakeClient(iClient) && g_iPlayerInfo[iClient].bInitialized) || (g_iPlayerInfo[iClient].bInitialized = false);
}

void CheckRank(int iClient, bool bActive = true)
{
	if(CheckStatus(iClient))
	{
		int iExp = g_iPlayerInfo[iClient].iStats[ST_EXP],
		    iMaxRanks = g_hRankExp.Length;

		if(iMaxRanks)
		{
			int iRank = iMaxRanks + 1, 
			    iOldRank = g_iPlayerInfo[iClient].iStats[ST_RANK];

			decl char sRankName[192];

			while(--iRank && g_hRankExp.Get(iRank - 1) > iExp) {}

			if(iRank != iOldRank)
			{
				g_iPlayerInfo[iClient].iStats[ST_RANK] = iRank;

				if(g_hForward_Hook[LR_OnLevelChangedPre].FunctionCount)
				{
					int iNewRank = iRank;

					CallForward_OnLevelChanged(iClient, iNewRank, iOldRank);

					if(0 < iNewRank < iMaxRanks && iNewRank != iOldRank)
					{
						g_iPlayerInfo[iClient].iStats[ST_RANK] = iRank = iNewRank;
					}
					else
					{
						LogError("%i - invalid number rank.", iNewRank);
					}
				}

				if(bActive)
				{
					bool bIsUp = iRank > iOldRank;

					g_iPlayerInfo[iClient].iSessionStats[ST_RANK] += iRank - iOldRank;

					g_hRankNames.GetString(iRank ? iRank - 1 : iRank, sRankName, sizeof(sRankName));

					if(TranslationPhraseExists(sRankName))
					{
						FormatEx(sRankName, sizeof(sRankName), "%T", sRankName, iClient);
					}

					LR_PrintMessage(iClient, true, false, "%T", bIsUp ? "LevelUp" : "LevelDown", iClient, sRankName);

					if(IsClientInGame(iClient) && g_Settings[LR_IsLevelSound])
					{
						EmitSoundToClient(iClient, bIsUp ? g_sSoundUp : g_sSoundDown, SOUND_FROM_PLAYER, 80);
					}

					if(g_Settings[LR_ShowLevelUpMessage + view_as<int>(!bIsUp)])
					{
						for(int i = GetMaxPlayers(); --i;)
						{
							if(g_iPlayerInfo[i].bInitialized && i != iClient)
							{
								LR_PrintMessage(i, true, false, "%T", bIsUp ? "LevelUpAll" : "LevelDownAll", i, iClient, sRankName);
							}
						}
					}

					if(g_Settings[LR_DB_SaveDataPlayer_Mode])
					{
						SaveDataPlayer(iClient);
					}
				}

				CallForward_OnLevelChanged(iClient, iRank, iOldRank, false);
			}
		}
		else
		{
			LogWarning(false, "settings_ranks.ini: MaxRanks = %s", iMaxRanks);
		}
	
	}
}

void ResetPlayerData(int iClient)
{
	g_iPlayerInfo[iClient].iStats = g_iInfoNULL.iStats;
	g_iPlayerInfo[iClient].iSessionStats = g_iInfoNULL.iSessionStats;
	g_iPlayerInfo[iClient].iKillStreak = 0;
	
	g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] = g_iPlayerInfo[iClient].iSessionStats[ST_PLAYTIME] -= GetTime();
	g_iPlayerInfo[iClient].iStats[ST_EXP] = g_Settings[LR_TypeStatistics] ? 1000 : 0;
}

void ResetPlayerStats(int iClient)
{
	ResetPlayerData(iClient);
	CheckRank(iClient, false);
	CallForward_OnResetPlayerStats(iClient, g_iPlayerInfo[iClient].iAccountID);
}
