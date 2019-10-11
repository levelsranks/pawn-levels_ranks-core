void MakeHookEvents()
{
	HookEvent("weapon_fire", Events, EventHookMode_Pre);
	HookEvent("player_hurt", Events, EventHookMode_Pre);
	HookEvent("player_death", Events, EventHookMode_Pre);

	HookEventEx("round_mvp", Events, EventHookMode_Pre);
	HookEvent("round_end", Events, EventHookMode_Pre);
	HookEvent("round_start", Events, EventHookMode_Pre);

	HookEvent("bomb_planted", Events, EventHookMode_Pre);
	HookEvent("bomb_defused", Events, EventHookMode_Pre);
	HookEvent("bomb_dropped", Events, EventHookMode_Pre);
	HookEvent("bomb_pickup", Events, EventHookMode_Pre);

	HookEvent("hostage_killed", Events, EventHookMode_Pre);
	HookEvent("hostage_rescued", Events, EventHookMode_Pre);
}

void Events(Event hEvent, char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid")),
		iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	switch(sName[0])
	{
		case 'w':			// weapon_fire
		{
			if(!g_bWarmupPeriod && g_iCountPlayers >= g_Settings[LR_MinplayersCount] && g_iPlayerInfo[iClient].bInitialized)
			{
				g_iPlayerInfo[iClient].iStats[ST_SHOOTS]++;
				g_iPlayerInfo[iClient].iSessionStats[3]++;
			}
		}

		case 'p':
		{
			switch(sName[7])
			{
				case 'h':	// player_hurt
				{
					if(!g_bWarmupPeriod && g_iCountPlayers >= g_Settings[LR_MinplayersCount] && iAttacker != iClient && g_iPlayerInfo[iClient].bInitialized && g_iPlayerInfo[iAttacker].bInitialized)
					{
						g_iPlayerInfo[iAttacker].iStats[ST_HITS]++;
						g_iPlayerInfo[iAttacker].iSessionStats[4]++;
					}
				}

				case 'd':	// player_death
				{
					if(CheckStatus(iAttacker) && CheckStatus(iClient))
					{
						if(!g_bWarmupPeriod)
						{
							if(iAttacker == iClient)
							{
								NotifClient(iClient, -g_Settings[LR_ExpGiveSuicide], "Suicide");
								return;
							}

							g_iPlayerInfo[iClient].iStats[ST_DEATHS]++;
							g_iPlayerInfo[iClient].iSessionStats[2]++;

							if(!g_Settings[LR_AllAgainstAll] && GetClientTeam(iClient) == GetClientTeam(iAttacker))
							{
								NotifClient(iAttacker, -g_Settings[LR_ExpGiveTeamKill], "TeamKill");
								return;
							}

							int iExpAttacker, iExpVictim;

							Call_StartForward(g_hForward_Hook[LR_OnPlayerKilledPre]);
							Call_PushCell(hEvent);

							switch(g_Settings[LR_TypeStatistics])
							{
								case 0:
								{
									iExpAttacker = g_Settings[LR_ExpKill];
									iExpVictim = g_Settings[LR_ExpDeath];

									Call_PushCellRef(iExpAttacker);
									Call_PushCell(g_iPlayerInfo[iClient].iStats[ST_EXP]);
									Call_PushCell(g_iPlayerInfo[iAttacker].iStats[ST_EXP]);
									Call_Finish();
								}

								case 1:
								{
									iExpAttacker = RoundToNearest(float(g_iPlayerInfo[iClient].iStats[ST_EXP]) / g_iPlayerInfo[iAttacker].iStats[ST_EXP] * 5.0);

									Call_PushCellRef(iExpAttacker);
									Call_PushCell(g_iPlayerInfo[iClient].iStats[ST_EXP]);
									Call_PushCell(g_iPlayerInfo[iAttacker].iStats[ST_EXP]);
									Call_Finish();

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

									Call_PushCellRef(iExpAttacker);
									Call_PushCell(g_iPlayerInfo[iClient].iStats[ST_EXP]);
									Call_PushCell(g_iPlayerInfo[iAttacker].iStats[ST_EXP]);
									Call_Finish();

									iExpVictim = (iExpAttacker = iExpAttacker < 2 ? 2 : (iExpAttacker / 100) + 2);
								}
							}

							if(NotifClient(iAttacker, iExpAttacker, "Kill") && NotifClient(iClient, -iExpVictim, "MyDeath"))
							{
								if(hEvent.GetBool("headshot") && NotifClient(iAttacker, g_Settings[LR_ExpGiveHeadShot], "HeadShotKill"))
								{
									g_iPlayerInfo[iAttacker].iStats[ST_HEADSHOTS]++;
									g_iPlayerInfo[iAttacker].iSessionStats[5]++;
								}

								int iAssister = GetClientOfUserId(hEvent.GetInt("assister"));

								if(NotifClient(iAssister, g_Settings[LR_ExpGiveAssist], "AssisterKill"))
								{
									g_iPlayerInfo[iAssister].iStats[ST_ASSISTS]++;
									g_iPlayerInfo[iAssister].iSessionStats[6]++;
								}

								g_iPlayerInfo[iAttacker].iStats[ST_KILLS]++;
								g_iPlayerInfo[iAttacker].iSessionStats[1]++;
								g_iPlayerInfo[iAttacker].iKillStreak++;

								Call_StartForward(g_hForward_Hook[LR_OnPlayerKilledPost]);
								Call_PushCell(hEvent);
								Call_PushCell(iExpAttacker);
								Call_PushCell(g_iPlayerInfo[iClient].iStats[ST_EXP]);
								Call_PushCell(g_iPlayerInfo[iAttacker].iStats[ST_EXP]);
								Call_Finish();
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
					NotifClient(GetClientOfUserId(GetEventInt(hEvent, "userid")), g_Settings[LR_ExpRoundMVP], "RoundMVP");
				}

				case 'e':	// round_end
				{
					g_bRoundAllowExp = true;

					int iWinTeam = GetEventInt(hEvent, "winner");

					if(iWinTeam > 1)
					{
						for(int i = GetMaxPlayers(), iTeam; --i;)
						{
							if(IsClientInGame(i) && !IsFakeClient(i))
							{
								if(!g_bWarmupPeriod && (iTeam = GetClientTeam(i)) > 1)
								{
									bool bLose = iTeam != iWinTeam;

									if(bLose ? NotifClient(i, -g_Settings[LR_ExpRoundLose], "RoundLose") : NotifClient(i, g_Settings[LR_ExpRoundLose], "RoundWin"))
									{
										g_iPlayerInfo[i].iStats[ST_ROUNDSLOSE + view_as<int>(bLose)]++;
										g_iPlayerInfo[i].iSessionStats[7 + view_as<int>(bLose)]++;
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
					if(g_Settings[LR_BlockWarmup] && g_iEngine == Engine_CSGO) 
					{
						g_bWarmupPeriod = view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
					}

					g_iCountPlayers = 0;
					g_bRoundEndGiveExp = true;

					for(int i = GetMaxPlayers(); --i;)
					{
						if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
						{
							g_iCountPlayers++;
						}
					}

					if(g_Settings[LR_ShowSpawnMessage])
					{
						bool bWarningMessage = g_iCountPlayers < g_Settings[LR_MinplayersCount];

						for(int i = GetMaxPlayers(); --i;)
						{
							if(IsClientInGame(i))
							{
								if(bWarningMessage)
								{
									LR_PrintMessage(i, true, false, "%T", "RoundStartCheckCount", i, g_iCountPlayers, g_Settings[LR_MinplayersCount]);
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
				case 'l': 	// bomb_planted
				{
					if(NotifClient(iClient, g_Settings[LR_ExpBombPlanted], "BombPlanted"))
					{
						g_iPlayerInfo[iClient].bHaveBomb = false;
					}
				}

				case 'e': 	// bomb_defused
				{
					NotifClient(iClient, g_Settings[LR_ExpBombDefused], "BombDefused");
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
		static const char sPhrases[][] = {"DoubleKill", "TripleKill", "Domination", "Rampage", "MegaKill", "Ownage", "UltraKill", "KillingSpree", "MonsterKill", "Unstoppable", "GodLike"};

		if(iKillStreak < 12)
		{
			int iKS = iKillStreak - 2;

			NotifClient(iClient, g_iBonus[iKS], sPhrases[iKS]);
		}
		else 
		{
			NotifClient(iClient, g_iBonus[10], sPhrases[10]);
		}
	}

	g_iPlayerInfo[iClient].iKillStreak = 0;

	SaveDataPlayer(iClient);
}