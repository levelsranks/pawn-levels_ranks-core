void SetSettings()
{
	static int  iTypeStatistics;

	char      sBuffer[192];

	static char sPath[PLATFORM_MAX_PATH];

	KeyValues hKv = new KeyValues("LR_Settings");

	bool bFirstLoad = !sPath[0];

	if(bFirstLoad)
	{
		g_hRankNames = new ArrayList(sizeof(sBuffer) / 4 + 1);
		g_hRankExp = new ArrayList();

		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/settings.ini");
	}
	else
	{
		g_hRankNames.Clear();
		g_hRankExp.Clear();
	}

	if(!hKv.ImportFromFile(sPath))
	{
		SetFailState("%s - is not found", sPath);
	}

	hKv.GotoFirstSubKey();
	hKv.Rewind();

	hKv.JumpToKey("MainSettings"); /**/

	if(bFirstLoad)
	{
		hKv.GetString("lr_table", g_sTableName, sizeof(g_sTableName), "lvl_base");

		iTypeStatistics = (g_Settings[LR_TypeStatistics] = hKv.GetNum("lr_type_statistics", 0));
		g_Settings[LR_DB_Allow_UTF8MB4] = hKv.GetNum("lr_db_allow_utf8mb4", 1);
	}

	hKv.GetString("lr_flag_adminmenu", sBuffer, 32, "z");
	g_Settings[LR_FlagAdminmenu] = ReadFlagString(sBuffer);

	hKv.GetString("lr_plugin_title", g_sPluginTitle, sizeof(g_sPluginTitle), g_sPluginName);

	if(!strcmp(g_sPluginTitle, "none"))
	{
		g_sPluginTitle = g_sPluginName;
	}

	if((g_Settings[LR_IsLevelSound] = hKv.GetNum("lr_sound", 1)))
	{
		hKv.GetString("lr_sound_lvlup", g_sSoundUp, sizeof(g_sSoundUp), "levels_ranks/levelup.mp3");
		hKv.GetString("lr_sound_lvldown", g_sSoundDown, sizeof(g_sSoundDown), "levels_ranks/leveldown.mp3");
	}

	g_Settings[LR_MinplayersCount] = hKv.GetNum("lr_minplayers_count", 4);
	g_Settings[LR_ShowResetMyStats] = hKv.GetNum("lr_show_resetmystats", 1);

	if((g_Settings[LR_ResetMyStatsCooldown] = hKv.GetNum("lr_resetmystats_cooldown", 86400)))
	{
		if(g_hLastResetMyStats)
		{
			g_hLastResetMyStats.Close();
		}

		g_hLastResetMyStats = new Cookie("LR_LastResetMyStats", NULL_STRING, CookieAccess_Private);
	}

	g_Settings[LR_ShowUsualMessage] = hKv.GetNum("lr_show_usualmessage", 1);
	g_Settings[LR_ShowSpawnMessage] = hKv.GetNum("lr_show_spawnmessage", 1);
	g_Settings[LR_ShowLevelUpMessage] = hKv.GetNum("lr_show_levelup_message", 0);
	g_Settings[LR_ShowLevelDownMessage] = hKv.GetNum("lr_show_leveldown_message", 0);
	g_Settings[LR_ShowRankMessage] = hKv.GetNum("lr_show_rankmessage", 1);
	g_Settings[LR_ShowRankList] = hKv.GetNum("lr_show_ranklist", 1);
	g_Settings[LR_GiveExpRoundEnd] = hKv.GetNum("lr_giveexp_roundend", 1);
	g_Settings[LR_BlockWarmup] = hKv.GetNum("lr_block_warmup", 1);
	g_Settings[LR_AllAgainstAll] = hKv.GetNum("lr_allagainst_all", 0);
	g_Settings[LR_CleanDB_Days] = hKv.GetNum("lr_cleandb_days", 30);
	g_Settings[LR_CleanDB_BanClient] = hKv.GetNum("lr_cleandb_banclient", 1);
	g_Settings[LR_DB_SaveDataPlayer_Mode] = hKv.GetNum("lr_db_savedataplayer_mode", 1);

	hKv.Close();

	// settings.ini -> settings_stats.ini
	strcopy(sPath[strlen(sPath) - 4], 12, "_stats.ini");

	if(!(hKv = new KeyValues("LR_Settings")).ImportFromFile(sPath))
	{
		SetFailState("%s - is not found", sPath);
	}

	hKv.GotoFirstSubKey();
	hKv.Rewind();

	switch(iTypeStatistics)
	{
		case 0:
		{
			hKv.JumpToKey("Funded_System"); /**/

			g_SettingsStats[LR_ExpKill] = hKv.GetNum("lr_kill");
			g_SettingsStats[LR_ExpKillIsBot] = hKv.GetNum("lr_kill_is_bot");
			g_SettingsStats[LR_ExpDeath] = hKv.GetNum("lr_death");
			g_SettingsStats[LR_ExpDeathIsBot] = hKv.GetNum("lr_death_is_bot");
		}

		case 1:
		{
			hKv.JumpToKey("Rating_Extended"); /**/

			float flKillCoefficient = hKv.GetFloat("lr_killcoeff", 1.0);

			if(flKillCoefficient < 0.5)
			{
				flKillCoefficient = 0.5;
			}
			else if(flKillCoefficient > 1.5)
			{
				flKillCoefficient = 1.5;
			}

			g_SettingsStats[LR_ExpKillCoefficient] = flKillCoefficient;
		}

		case 2:
		{
			hKv.JumpToKey("Rating_Simple"); /**/
		}
	}

	g_SettingsStats[LR_ExpGiveHeadShot] = hKv.GetNum("lr_headshot", 1);
	g_SettingsStats[LR_ExpGiveAssist] = hKv.GetNum("lr_assist", 1);
	g_SettingsStats[LR_ExpGiveSuicide] = hKv.GetNum("lr_suicide", 0);
	g_SettingsStats[LR_ExpGiveTeamKill] = hKv.GetNum("lr_teamkill", 0);
	g_SettingsStats[LR_ExpRoundWin] = hKv.GetNum("lr_winround", 2);
	g_SettingsStats[LR_ExpRoundLose] = hKv.GetNum("lr_loseround", 2);
	g_SettingsStats[LR_ExpRoundMVP] = hKv.GetNum("lr_mvpround", 1);
	g_SettingsStats[LR_ExpBombPlanted] = hKv.GetNum("lr_bombplanted", 2);
	g_SettingsStats[LR_ExpBombDefused] = hKv.GetNum("lr_bombdefused", 2);
	g_SettingsStats[LR_ExpBombDropped] = hKv.GetNum("lr_bombdropped", 1);
	g_SettingsStats[LR_ExpBombPickup] = hKv.GetNum("lr_bombpickup", 1);
	g_SettingsStats[LR_ExpHostageKilled] = hKv.GetNum("lr_hostagekilled", 0);
	g_SettingsStats[LR_ExpHostageRescued] = hKv.GetNum("lr_hostagerescued", 2);

	if(iTypeStatistics != 2)
	{
		hKv.Rewind();
		hKv.JumpToKey("Special_Bonuses"); /**/

		for(int i = 0; i != 10;)
		{
			FormatEx(sBuffer, 32, "lr_bonus_%i", i + 1);
			g_iBonus[i++] = hKv.GetNum(sBuffer, 0);
		}
	}

	hKv.Close();

	// settings_stats.ini -> settings_ranks.ini
	strcopy(sPath[strlen(sPath) - 10], 12, "_ranks.ini");

	if(!(hKv = new KeyValues("LR_Settings")).ImportFromFile(sPath))
	{
		SetFailState("%s - is not found", sPath);
	}

	hKv.GotoFirstSubKey();
	hKv.Rewind();

	hKv.JumpToKey("Ranks"); /**/

	static char sValue[8] = "value_";

	hKv.GotoFirstSubKey();
	do
	{
		sValue[6] = '0' + iTypeStatistics;

		hKv.GetSectionName(sBuffer, sizeof(sBuffer));

		g_hRankNames.PushString(sBuffer);
		g_hRankExp.Push(hKv.GetNum(sValue, 0));
	}
	while(hKv.GotoNextKey());

	if(!bFirstLoad)
	{
		CallForward_OnSettingsModuleUpdate();
	}

	// settings_ranks.ini -> settings.ini
	strcopy(sPath[strlen(sPath) - 10], 5, ".ini");

	hKv.Close();
}
