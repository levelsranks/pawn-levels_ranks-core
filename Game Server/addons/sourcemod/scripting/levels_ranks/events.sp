// Hook events in api.sp -> AskPluginLoad2().
void Events(Event hEvent, char[] sName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")),
		iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	switch(sName[0])
	{
		case 'w':			// weapon_fire
		{
			if(g_bAllowStatistic && g_iPlayerInfo[iClient].bInitialized)
			{
				g_iPlayerInfo[iClient].iStats[ST_SHOOTS]++;
				g_iPlayerInfo[iClient].iSessionStats[ST_SHOOTS]++;
			}
		}

		case 'p':
		{
			switch(sName[7])
			{
				case 'h':	// player_hurt
				{
					if(g_bAllowStatistic && iAttacker != iClient && g_iPlayerInfo[iClient].bInitialized && g_iPlayerInfo[iAttacker].bInitialized)
					{
						g_iPlayerInfo[iAttacker].iStats[ST_HITS]++;
						g_iPlayerInfo[iAttacker].iSessionStats[ST_HITS]++;
					}
				}

				case 'd':	// player_death
				{
					if(CheckStatus(iAttacker) && CheckStatus(iClient))
					{
						if(iAttacker == iClient)
						{
							NotifClient(iClient, -g_Settings[LR_ExpGiveSuicide], "Suicide");
						}
						else
						{
							if(!g_Settings[LR_AllAgainstAll] && GetClientTeam(iClient) == GetClientTeam(iAttacker))
							{
								NotifClient(iAttacker, -g_Settings[LR_ExpGiveTeamKill], "TeamKill");
							}
							else
							{
								int iExpAttacker, iExpVictim;

								switch(g_Settings[LR_TypeStatistics])
								{
									case 0:
									{
										iExpAttacker = g_Settings[LR_ExpKill];
										iExpVictim = g_Settings[LR_ExpDeath];

										CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker);
									}

									case 1:
									{
										iExpAttacker = RoundToNearest(float(g_iPlayerInfo[iClient].iStats[ST_EXP]) / g_iPlayerInfo[iAttacker].iStats[ST_EXP] * 5.0);

										CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker);

										if(iExpAttacker < 1) 
										{
											iExpAttacker = 1;
										}

										if((iExpVictim = RoundToNearest(iExpAttacker * view_as<float>(g_Settings[LR_KillCoefficient]))) < 1)
										{
											iExpVictim = 1;
										}
									}

									case 2:
									{
										iExpAttacker = g_iPlayerInfo[iClient].iStats[ST_EXP] - g_iPlayerInfo[iAttacker].iStats[ST_EXP];

										CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker);

										iExpVictim = iExpAttacker = iExpAttacker < 2 ? 2 : (iExpAttacker / 100) + 2;
									}
								}

								if(NotifClient(iAttacker, iExpAttacker, "Kill") && NotifClient(iClient, -iExpVictim, "MyDeath"))
								{
									if(hEvent.GetBool("headshot") && NotifClient(iAttacker, g_Settings[LR_ExpGiveHeadShot], "HeadShotKill"))
									{
										g_iPlayerInfo[iAttacker].iStats[ST_HEADSHOTS]++;
										g_iPlayerInfo[iAttacker].iSessionStats[ST_HEADSHOTS]++;
									}

									int iAssister = GetClientOfUserId(hEvent.GetInt("assister"));

									if(NotifClient(iAssister, g_Settings[LR_ExpGiveAssist], "AssisterKill"))
									{
										g_iPlayerInfo[iAssister].iStats[ST_ASSISTS]++;
										g_iPlayerInfo[iAssister].iSessionStats[ST_ASSISTS]++;
									}

									g_iPlayerInfo[iAttacker].iStats[ST_KILLS]++;
									g_iPlayerInfo[iAttacker].iSessionStats[ST_KILLS]++;
									g_iPlayerInfo[iAttacker].iKillStreak++;

									g_iPlayerInfo[iClient].iStats[ST_DEATHS]++;
									g_iPlayerInfo[iClient].iSessionStats[ST_DEATHS]++;

									CallForward_OnPlayerKilled(hEvent, iExpAttacker, iClient, iAttacker, false);
								}
							}
						}

						GiveExpForStreakKills(iClient);
					}
				}
			}
		}

		case 'r':
		{
			switch(sName[6])
			{
				case 'm': 	// round_mvp
				{
					NotifClient(iClient, g_Settings[LR_ExpRoundMVP], "RoundMVP");
				}

				case 'e':	// round_end
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

									if(bLose ? NotifClient(i, -g_Settings[LR_ExpRoundLose], "RoundLose") : NotifClient(i, g_Settings[LR_ExpRoundWin], "RoundWin"))
									{
										g_iPlayerInfo[i].iStats[ST_ROUNDSWIN + int(bLose)]++;
										g_iPlayerInfo[i].iSessionStats[ST_ROUNDSWIN + int(bLose)]++;
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

				case 's':	// round_start
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
					g_bRoundEndGiveExp = g_bRoundAllowExp = true;

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
			}
		}

		case 'b':
		{
			switch(sName[6])
			{
				case 'e': 	// bomb_defused
				{
					NotifClient(iClient, g_Settings[LR_ExpBombDefused], "BombDefused");
				}

				case 'l': 	// bomb_planted
				{
					if(NotifClient(iClient, g_Settings[LR_ExpBombPlanted], "BombPlanted"))
					{
						g_iPlayerInfo[iClient].bHaveBomb = false;
					}
				}

				case 'r': 	// bomb_dropped
				{
					if(g_iPlayerInfo[iClient].bHaveBomb && NotifClient(iClient, -g_Settings[LR_ExpBombDropped], "BombDropped"))
					{
						g_iPlayerInfo[iClient].bHaveBomb = false;
					}
				}

				case 'i': 	// bomb_pickup
				{
					if(!g_iPlayerInfo[iClient].bHaveBomb && NotifClient(iClient, g_Settings[LR_ExpBombPickup], "BombPickup"))
					{
						g_iPlayerInfo[iClient].bHaveBomb = true;
					}
				}
			}
		}

		case 'h':
		{
			if(sName[8] == 'k')		// hostage_killed
			{
				NotifClient(iClient, -g_Settings[LR_ExpHostageKilled], "HostageKilled");
			}
			else					// hostage_rescued
			{
				NotifClient(iClient, g_Settings[LR_ExpHostageRescued], "HostageRescued");
			}
		}
	}
}

void NextFrameRound()
{
	g_bRoundEndGiveExp = false;
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

		if((iKillStreak -= 2) > 10)
		{
			iKillStreak = 10;
		}
		
		NotifClient(iClient, g_iBonus[iKillStreak], sPhrases[iKillStreak]);
	}

	g_iPlayerInfo[iClient].iKillStreak = 0;

	SaveDataPlayer(iClient);
}