int		g_iCountRanks,
		g_iAdminFlag,
		g_iTypeStatistics,
		g_iMinimumPlayers,
		g_iDBReconnectCount,
		g_iUsualMessage,
		g_iGiveKill,
		g_iGiveDeath,
		g_iGiveHeadShot,
		g_iGiveAssist,
		g_iGiveSuicide,
		g_iGiveTeamKill,
		g_iRoundWin,
		g_iRoundLose,
		g_iRoundMVP,
		g_iBombPlanted,
		g_iBombDefused,
		g_iBombDropped,
		g_iBombPickup,
		g_iHostageKilled,
		g_iHostageRescued,
		g_iShowExp[MAX_COUNT_RANKS+2],
		g_iBonus[11];
float		g_fKillCoeff,
		g_fDBReconnectTime;
bool		g_bSpawnMessage,
		g_bSoundRankPlay,
		g_bLevelUpMessage,
		g_bLevelDownMessage,
		g_bRankMessage,
		g_bResetRank,
		g_bRoundEndGiveExpSett,
		g_bWarmUpCheck,
		g_bAllAgainstAll;
char		g_sTableName[32],
		g_sPluginTitle[64],
		g_sSoundUp[256],
		g_sSoundDown[256],
		g_sShowRank[MAX_COUNT_RANKS+2][192];

void SetSettings(bool bReload = false)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/settings.ini");
	KeyValues hLR_Settings = new KeyValues("LR_Settings");

	if(!hLR_Settings.ImportFromFile(sPath) || !hLR_Settings.GotoFirstSubKey())
	{
		CrashLR("(%s) is not found", sPath);
	}

	hLR_Settings.Rewind();

	if(hLR_Settings.JumpToKey("MainSettings"))
	{
		char sBuffer[32];
		if(!bReload)
		{
			hLR_Settings.GetString("lr_table", g_sTableName, 32, "lvl_base");
			hLR_Settings.GetString("lr_flag_adminmenu", sBuffer, sizeof(sBuffer), "z"); g_iAdminFlag = ReadFlagString(sBuffer);
			g_iTypeStatistics = hLR_Settings.GetNum("lr_type_statistics", 0);
		}

		char sTitleBuffer[64];
		hLR_Settings.GetString("lr_plugin_title", sTitleBuffer, 64, "none");
		strcopy(g_sPluginTitle, 64, !strcmp(sTitleBuffer, "none", false) ? PLUGIN_NAME : sTitleBuffer);

		g_bSoundRankPlay = view_as<bool>(hLR_Settings.GetNum("lr_sound", 1));
		if(g_bSoundRankPlay)
		{
			hLR_Settings.GetString("lr_sound_lvlup", g_sSoundUp, 256, "levels_ranks/levelup.mp3");
			hLR_Settings.GetString("lr_sound_lvldown", g_sSoundDown, 256, "levels_ranks/leveldown.mp3");
		}

		g_iMinimumPlayers = hLR_Settings.GetNum("lr_minplayers_count", 4);
		g_bResetRank = view_as<bool>(hLR_Settings.GetNum("lr_show_resetmystats", 1));
		g_iUsualMessage = hLR_Settings.GetNum("lr_show_usualmessage", 1);
		g_bSpawnMessage = view_as<bool>(hLR_Settings.GetNum("lr_show_spawnmessage", 1));
		g_bLevelUpMessage = view_as<bool>(hLR_Settings.GetNum("lr_show_levelup_message", 1));
		g_bLevelDownMessage = view_as<bool>(hLR_Settings.GetNum("lr_show_leveldown_message", 1));
		g_bRankMessage = view_as<bool>(hLR_Settings.GetNum("lr_show_rankmessage", 1));
		g_bRoundEndGiveExpSett = view_as<bool>(hLR_Settings.GetNum("lr_giveexp_roundend", 1));
		g_bWarmUpCheck = view_as<bool>(hLR_Settings.GetNum("lr_block_warmup", 1));
		g_bAllAgainstAll = view_as<bool>(hLR_Settings.GetNum("lr_allagainst_all", 0));
		g_iDBReconnectCount = hLR_Settings.GetNum("lr_dbreconnect_count", 5);
		g_fDBReconnectTime = hLR_Settings.GetFloat("lr_dbreconnect_time", 5.0);

		if(g_iDBReconnectCount <= 0) g_iDBReconnectCount = 5;
		if(g_fDBReconnectTime <= 0.0) g_fDBReconnectTime = 5.0;
	}
	else CrashLR("Section MainSettings is not found (%s)", sPath);
	delete hLR_Settings;

	SetSettingsType();
	SetSettingsRank();
	if(bReload)
	{
		Call_StartForward(g_hForward_OnSettingsModuleUpdate);
		Call_Finish();
	}
}

void SetSettingsType()
{
	char sBuffer[64], sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/settings_stats.ini");
	KeyValues hLR_Settings = new KeyValues("LR_Settings");

	if(!hLR_Settings.ImportFromFile(sPath) || !hLR_Settings.GotoFirstSubKey())
	{
		CrashLR("(%s) is not found", sPath);
	}

	hLR_Settings.Rewind();

	static bool bSpecialBonuses;
	switch(g_iTypeStatistics)
	{
		case 0:
		{
			if(hLR_Settings.JumpToKey("Funded_System"))
			{
				g_iGiveKill = hLR_Settings.GetNum("lr_kill", 5);
				g_iGiveDeath = hLR_Settings.GetNum("lr_death", 5);
				g_iGiveHeadShot = hLR_Settings.GetNum("lr_headshot", 1);
				g_iGiveAssist = hLR_Settings.GetNum("lr_assist", 1);
				g_iGiveSuicide = hLR_Settings.GetNum("lr_suicide", 6);
				g_iGiveTeamKill = hLR_Settings.GetNum("lr_teamkill", 6);
				g_iRoundWin = hLR_Settings.GetNum("lr_winround", 2);
				g_iRoundLose = hLR_Settings.GetNum("lr_loseround", 2);
				g_iRoundMVP = hLR_Settings.GetNum("lr_mvpround", 3);
				g_iBombPlanted = hLR_Settings.GetNum("lr_bombplanted", 2);
				g_iBombDefused = hLR_Settings.GetNum("lr_bombdefused", 2);
				g_iBombDropped = hLR_Settings.GetNum("lr_bombdropped", 1);
				g_iBombPickup = hLR_Settings.GetNum("lr_bombpickup", 1);
				g_iHostageKilled = hLR_Settings.GetNum("lr_hostagekilled", 4);
				g_iHostageRescued = hLR_Settings.GetNum("lr_hostagerescued", 3);
			}
			else CrashLR("Section Funded_System is not found (%s)", sPath);
			bSpecialBonuses = true;
		}

		case 1:
		{
			if(hLR_Settings.JumpToKey("Rating_Extended"))
			{
				g_fKillCoeff = hLR_Settings.GetFloat("lr_killcoeff", 1.00);

				if(g_fKillCoeff < 0.80 || g_fKillCoeff > 1.20)
				{
					g_fKillCoeff = 1.00;
				}

				g_iGiveHeadShot = hLR_Settings.GetNum("lr_headshot", 1);
				g_iGiveAssist = hLR_Settings.GetNum("lr_assist", 1);
				g_iGiveSuicide = hLR_Settings.GetNum("lr_suicide", 10);
				g_iGiveTeamKill = hLR_Settings.GetNum("lr_teamkill", 5);
				g_iRoundWin = hLR_Settings.GetNum("lr_winround", 2);
				g_iRoundLose = hLR_Settings.GetNum("lr_loseround", 2);
				g_iRoundMVP = hLR_Settings.GetNum("lr_mvpround", 1);
				g_iBombPlanted = hLR_Settings.GetNum("lr_bombplanted", 3);
				g_iBombDefused = hLR_Settings.GetNum("lr_bombdefused", 3);
				g_iBombDropped = hLR_Settings.GetNum("lr_bombdropped", 2);
				g_iBombPickup = hLR_Settings.GetNum("lr_bombpickup", 2);
				g_iHostageKilled = hLR_Settings.GetNum("lr_hostagekilled", 20);
				g_iHostageRescued = hLR_Settings.GetNum("lr_hostagerescued", 5);
			}
			else CrashLR("Section Rating_Extended is not found (%s)", sPath);
			bSpecialBonuses = true;
		}

		case 2:
		{
			if(hLR_Settings.JumpToKey("Rating_Simple"))
			{
				g_iGiveHeadShot = hLR_Settings.GetNum("lr_headshot", 1);
				g_iGiveAssist = hLR_Settings.GetNum("lr_assist", 1);
				g_iGiveSuicide = hLR_Settings.GetNum("lr_suicide", 0);
				g_iGiveTeamKill = hLR_Settings.GetNum("lr_teamkill", 0);
				g_iRoundWin = hLR_Settings.GetNum("lr_winround", 2);
				g_iRoundLose = hLR_Settings.GetNum("lr_loseround", 2);
				g_iRoundMVP = hLR_Settings.GetNum("lr_mvpround", 1);
				g_iBombPlanted = hLR_Settings.GetNum("lr_bombplanted", 2);
				g_iBombDefused = hLR_Settings.GetNum("lr_bombdefused", 2);
				g_iBombDropped = hLR_Settings.GetNum("lr_bombdropped", 1);
				g_iBombPickup = hLR_Settings.GetNum("lr_bombpickup", 1);
				g_iHostageKilled = hLR_Settings.GetNum("lr_hostagekilled", 0);
				g_iHostageRescued = hLR_Settings.GetNum("lr_hostagerescued", 2);
			}
			else CrashLR("Section Rating_Simple is not found (%s)", sPath);
		}
	}

	if(bSpecialBonuses)
	{
		hLR_Settings.Rewind();
		if(hLR_Settings.JumpToKey("Special_Bonuses"))
		{
			for(int i = 0; i <= 10; i++)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "lr_bonus_%i", i + 1);
				g_iBonus[i] = hLR_Settings.GetNum(sBuffer, 0);
			}
		}
		else CrashLR("Section Special_Bonuses is not found (%s)", sPath);
	}

	delete hLR_Settings;
}

void SetSettingsRank()
{
	char sPath[PLATFORM_MAX_PATH];
	KeyValues hLR_Settings = new KeyValues("LR_Settings");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/settings_ranks.ini");

	if(!hLR_Settings.ImportFromFile(sPath) || !hLR_Settings.GotoFirstSubKey())
	{
		CrashLR("(%s) is not found", sPath);
	}

	hLR_Settings.Rewind();

	if(hLR_Settings.JumpToKey("Ranks"))
	{
		g_iCountRanks = 0;
		hLR_Settings.GotoFirstSubKey();

		do
		{
			hLR_Settings.GetSectionName(g_sShowRank[g_iCountRanks+1], sizeof(g_sShowRank[]));

			if(g_iCountRanks > 0)
			g_iShowExp[g_iCountRanks] = hLR_Settings.GetNum(!g_iTypeStatistics ? "value_0" : g_iTypeStatistics == 1 ? "value_1" : "value_2", 0);
			g_iCountRanks++;
		}
		while(hLR_Settings.GotoNextKey());
		LoadTranslations("lr_core_ranks.phrases");
	}
	else CrashLR("Section Ranks is not found (%s)", sPath);
	delete hLR_Settings;
}