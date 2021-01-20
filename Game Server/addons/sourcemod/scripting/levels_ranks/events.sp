void HookEvents()
{
	if(!HookEventEx("weapon_fire", Events_Shots, EventHookMode_Pre))
	{
		SetFailState("Bug in event analysis engine!");
	}

	HookEvent("player_hurt", Events_Shots, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("bomb_planted", Events_Bomb, EventHookMode_Pre);
	HookEvent("bomb_defused", Events_Bomb, EventHookMode_Pre);
	HookEvent("bomb_dropped", Events_Bomb, EventHookMode_Pre);
	HookEvent("bomb_pickup", Events_Bomb, EventHookMode_Pre);
	HookEvent("hostage_killed", Events_Hostage, EventHookMode_Pre);
	HookEvent("hostage_rescued", Events_Hostage, EventHookMode_Pre);
	HookEvent("round_start", Events_Rounds, EventHookMode_Pre);
	HookEvent("round_end", Events_Rounds, EventHookMode_Pre);
	HookEventEx("round_mvp", Events_Rounds, EventHookMode_Pre);	// Missing in CS:S v34.
}

void Events_Shots(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if(g_bAllowStatistic && g_iPlayerInfo[iClient].bInitialized)
	{
		if(sName[0] == 'w')		// weapon_fire
		{
			g_iPlayerInfo[iClient].iStats[ST_SHOOTS]++;
			g_iPlayerInfo[iClient].iSessionStats[ST_SHOOTS]++;
		}
		else					// player_hurt
		{
			int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

			if(iAttacker != iClient && g_iPlayerInfo[iAttacker].bInitialized)
			{
				g_iPlayerInfo[iAttacker].iStats[ST_HITS]++;
				g_iPlayerInfo[iAttacker].iSessionStats[ST_HITS]++;
			}
		}
	}
}

void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid")),
	    iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")),
	    iAssister = GetClientOfUserId(hEvent.GetInt("assister"));

	if(NotifClient(iAssister, g_SettingsStats[LR_ExpGiveAssist], "AssisterKill"))
	{
		g_iPlayerInfo[iAssister].iStats[ST_ASSISTS]++;
		g_iPlayerInfo[iAssister].iSessionStats[ST_ASSISTS]++;
	}

	if(iClient && iAttacker)
	{
		if(iAttacker == iClient)
		{
			NotifClient(iClient, -g_SettingsStats[LR_ExpGiveSuicide], "Suicide");
		}
		else
		{
			if(!g_Settings[LR_AllAgainstAll] && GetClientTeam(iClient) == GetClientTeam(iAttacker))
			{
				NotifClient(iAttacker, -g_SettingsStats[LR_ExpGiveTeamKill], "TeamKill");
			}
			else
			{
				bool bFakeClient = IsFakeClient(iClient), 
				     bFakeAttacker = IsFakeClient(iAttacker);

				int iExpAttacker = 0, iExpVictim = 0;

				if(!g_Settings[LR_TypeStatistics])
				{
					iExpAttacker = g_SettingsStats[LR_ExpKill + view_as<int>(bFakeClient)];		// LR_ExpKillIsBot
					iExpVictim = g_SettingsStats[LR_ExpDeath + view_as<int>(bFakeAttacker)];		// LR_ExpDeathIsBot

					CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker);
				}
				else if(!bFakeClient && !bFakeAttacker)
				{
					if(g_Settings[LR_TypeStatistics] == 1)
					{
						iExpAttacker = RoundToNearest(float(g_iPlayerInfo[iClient].iStats[ST_EXP]) / g_iPlayerInfo[iAttacker].iStats[ST_EXP] * 5.0);

						CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker);

						if(iExpAttacker < 1) 
						{
							iExpAttacker = 1;
						}

						if((iExpVictim = RoundToNearest(iExpAttacker * view_as<float>(g_SettingsStats[LR_ExpKillCoefficient]))) < 1)
						{
							iExpVictim = 1;
						}
					}
					else
					{
						iExpAttacker = g_iPlayerInfo[iClient].iStats[ST_EXP] - g_iPlayerInfo[iAttacker].iStats[ST_EXP];

						CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker);

						iExpVictim = iExpAttacker = iExpAttacker < 3 ? 2 : (iExpAttacker / 100) + 2;
					}
				}

				if(NotifClient(iAttacker, iExpAttacker, "Kill") + NotifClient(iClient, -iExpVictim, "MyDeath"))
				{
					if(!bFakeAttacker)
					{
						if(hEvent.GetBool("headshot") && NotifClient(iAttacker, g_SettingsStats[LR_ExpGiveHeadShot], "HeadShotKill"))
						{
							g_iPlayerInfo[iAttacker].iStats[ST_HEADSHOTS]++;
							g_iPlayerInfo[iAttacker].iSessionStats[ST_HEADSHOTS]++;
						}

						g_iPlayerInfo[iAttacker].iStats[ST_KILLS]++;
						g_iPlayerInfo[iAttacker].iSessionStats[ST_KILLS]++;
						g_iPlayerInfo[iAttacker].iKillStreak++;
					}

					if(!bFakeClient)
					{
						g_iPlayerInfo[iClient].iStats[ST_DEATHS]++;
						g_iPlayerInfo[iClient].iSessionStats[ST_DEATHS]++;
					}

					CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker, false);
				}
			}
		}

		GiveExpForStreakKills(iClient);
	}
}

void Events_Bomb(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	switch(sName[6])
	{
		case 'e': 	// bomb_defused
		{
			NotifClient(iClient, g_SettingsStats[LR_ExpBombDefused], "BombDefused");
		}

		case 'l': 	// bomb_planted
		{
			if(NotifClient(iClient, g_SettingsStats[LR_ExpBombPlanted], "BombPlanted"))
			{
				g_iPlayerInfo[iClient].bHaveBomb = false;
			}
		}

		case 'r': 	// bomb_dropped
		{
			if(g_iPlayerInfo[iClient].bHaveBomb && NotifClient(iClient, -g_SettingsStats[LR_ExpBombDropped], "BombDropped"))
			{
				g_iPlayerInfo[iClient].bHaveBomb = false;
			}
		}

		default: 	// bomb_pickup
		{
			if(!g_iPlayerInfo[iClient].bHaveBomb && NotifClient(iClient, g_SettingsStats[LR_ExpBombPickup], "BombPickup"))
			{
				g_iPlayerInfo[iClient].bHaveBomb = true;
			}
		}
	}
}

void Events_Hostage(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if(sName[8] == 'k')		// hostage_killed
	{
		NotifClient(iClient, -g_SettingsStats[LR_ExpHostageKilled], "HostageKilled");
	}
	else					// hostage_rescued
	{
		NotifClient(iClient, g_SettingsStats[LR_ExpHostageRescued], "HostageRescued");
	}
}

void Events_Rounds(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(sName[6] == 's')			// round_start
	{
		int iPlayers = 0;

		for(int i = GetMaxPlayers(); --i;)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
			{
				iPlayers++;
			}
		}

		bool bWarningMessage = iPlayers < g_Settings[LR_MinplayersCount];

		g_bAllowStatistic = !bWarningMessage && !(g_Settings[LR_BlockWarmup] && g_iEngine == Engine_CSGO && GameRules_GetProp("m_bWarmupPeriod", 1));

		if(g_Settings[LR_ShowSpawnMessage])
		{
			for(int i = GetMaxPlayers(); --i;)
			{
				if(IsClientInGame(i))
				{
					if(bWarningMessage)
					{
						LR_PrintMessage(i, true, false, "%T", "RoundStartCheckCount", i, iPlayers, g_Settings[LR_MinplayersCount]);
					}

					LR_PrintMessage(i, true, false, "%T", "RoundStartMessageRanks", i);
				}
			}
		}
	}
	else if(sName[6] == 'e')	// round_end
	{
		int iWinTeam = GetEventInt(hEvent, "winner");

		if(iWinTeam > 1)
		{
			for(int i = GetMaxPlayers(), iTeam; --i;)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					if((iTeam = GetClientTeam(i)) > 1)
					{
						bool bLose = iTeam != iWinTeam;

						if(bLose ? NotifClient(i, -g_SettingsStats[LR_ExpRoundLose], "RoundLose") : NotifClient(i, g_SettingsStats[LR_ExpRoundWin], "RoundWin"))
						{
							g_iPlayerInfo[i].iStats[ST_ROUNDSWIN + view_as<int>(bLose)]++;
							g_iPlayerInfo[i].iSessionStats[ST_ROUNDSWIN + view_as<int>(bLose)]++;
						}
					}

					if(IsPlayerAlive(i))
					{
						GiveExpForStreakKills(i);
					}

					if(g_Settings[LR_ShowUsualMessage] == 2)
					{
						if(g_iPlayerInfo[i].iRoundExp)
						{
							LR_PrintMessage(i, true, false, "%T", g_iPlayerInfo[i].iRoundExp > 0 ? "RoundExpResultGive" : "RoundExpResultTake", i, g_iPlayerInfo[i].iRoundExp);
						}
						else 
						{
							LR_PrintMessage(i, true, false, "%T", "RoundExpResultNothing", i);
						}

						LR_PrintMessage(i, true, false, "%T", "RoundExpResultAll", i, g_iPlayerInfo[i].iStats[ST_EXP]);

						g_iPlayerInfo[i].iRoundExp = 0;
					}
				}
			}
		}

		if(!g_Settings[LR_GiveExpRoundEnd])
		{
			RequestFrame(NextFrameRound);
		}
	}
	else	// round_mvp
	{
		NotifClient(GetClientOfUserId(hEvent.GetInt("userid")), g_SettingsStats[LR_ExpRoundMVP], "RoundMVP");
	}
}

void GiveExpForStreakKills(int iClient)
{
	int iKillStreak = g_iPlayerInfo[iClient].iKillStreak;

	if(iKillStreak > 1)
	{
		static const char sPhrases[][] =
		{
			"DoubleKill",
			"TripleKill",
			"Domination",
			"Rampage",
			"MegaKill",
			"Ownage",
			"UltraKill",
			"KillingSpree",
			"MonsterKill",
			"Unstoppable",
			"GodLike"
		};

		if((iKillStreak -= 2) > 9)
		{
			iKillStreak = 9;
		}
		
		NotifClient(iClient, g_iBonus[iKillStreak], sPhrases[iKillStreak]);
	}

	g_iPlayerInfo[iClient].iKillStreak = 0;

	if(g_Settings[LR_DB_SaveDataPlayer_Mode])
	{
		SaveDataPlayer(iClient);
	}
}

void NextFrameRound()
{
	g_bAllowStatistic = false;
}
