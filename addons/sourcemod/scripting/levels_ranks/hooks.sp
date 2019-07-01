void MakeHooks()
{
	HookEvent("weapon_fire", LRHooks, EventHookMode_Pre);
	HookEvent("player_death", LRHooks, EventHookMode_Pre);
	HookEvent("player_hurt", LRHooks, EventHookMode_Pre);
	HookEventEx("round_mvp", LRHooks, EventHookMode_Pre);
	HookEvent("round_end", LRHooks, EventHookMode_Pre);
	HookEvent("round_start", LRHooks, EventHookMode_Pre);
	HookEvent("bomb_planted", LRHooks, EventHookMode_Pre);
	HookEvent("bomb_defused", LRHooks, EventHookMode_Pre);
	HookEvent("bomb_dropped", LRHooks, EventHookMode_Pre);
	HookEvent("bomb_pickup", LRHooks, EventHookMode_Pre);
	HookEvent("hostage_killed", LRHooks, EventHookMode_Pre);
	HookEvent("hostage_rescued", LRHooks, EventHookMode_Pre);
}

public void LRHooks(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{
	switch(sEvName[0])
	{
		case 'w':
		{
			if(!g_bWarmupPeriod)
			{
				int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
				if(g_bInitialized[iClient])
				{
					g_iClientData[iClient][ST_SHOOTS]++;
					g_iClientSessionData[iClient][3]++;
				}
			}
		}

		case 'p':
		{
			switch(sEvName[7])
			{
				case 'h':
				{
					if(!g_bWarmupPeriod)
					{
						int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
						int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

						if(iAttacker != iClient && g_bInitialized[iClient] && g_bInitialized[iAttacker])
						{
							g_iClientData[iAttacker][ST_HITS]++;
							g_iClientSessionData[iAttacker][4]++;
						}
					}
				}

				case 'd':
				{
					int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
					int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

					if(!CheckStatus(iAttacker) || !CheckStatus(iClient))
						return;

					if(!g_bWarmupPeriod)
					{
						if(iAttacker == iClient)
						{
							NotifClient(iClient, -g_iGiveSuicide, "Suicide");
						}
						else
						{
							if(!g_bAllAgainstAll && GetClientTeam(iClient) == GetClientTeam(iAttacker))
							{
								NotifClient(iAttacker, -g_iGiveTeamKill, "TeamKill");
							}
							else
							{
								Call_StartForward(g_hForward_OnPlayerKilled);
								Call_PushCell(hEvent);

								switch(g_iTypeStatistics)
								{
									case 0:
									{
										int iKillsPoint = g_iGiveKill;
										Call_PushCellRef(iKillsPoint);
										Call_PushCell(g_iClientData[iClient][ST_EXP]);
										Call_PushCell(g_iClientData[iAttacker][ST_EXP]);
										Call_Finish();

										NotifClient(iAttacker, iKillsPoint, "Kill");
										NotifClient(iClient, -g_iGiveDeath, "MyDeath");
									}

									case 1:
									{
										int iExpAttacker = RoundToNearest(float(g_iClientData[iClient][ST_EXP]) / float(g_iClientData[iAttacker][ST_EXP]) * 5.0);

										Call_PushCellRef(iExpAttacker);
										Call_PushCell(g_iClientData[iClient][ST_EXP]);
										Call_PushCell(g_iClientData[iAttacker][ST_EXP]);
										Call_Finish();

										int iExpVictim = RoundToNearest(iExpAttacker * g_fKillCoeff);

										if(iExpAttacker < 1) iExpAttacker = 1;
										if(iExpVictim < 1) iExpVictim = 1;

										NotifClient(iAttacker, iExpAttacker, "Kill");
										NotifClient(iClient, -iExpVictim, "MyDeath");
									}

									case 2:
									{
										int iExpDiff = g_iClientData[iClient][ST_EXP] - g_iClientData[iAttacker][ST_EXP];

										Call_PushCellRef(iExpDiff);
										Call_PushCell(g_iClientData[iClient][ST_EXP]);
										Call_PushCell(g_iClientData[iAttacker][ST_EXP]);
										Call_Finish();

										iExpDiff = iExpDiff < 0 ? 2 : (iExpDiff / 100) + 2;

										NotifClient(iAttacker, iExpDiff, "Kill");
										NotifClient(iClient, -iExpDiff, "MyDeath");
									}
								}

								if(GetEventBool(hEvent, "headshot"))
								{
									g_iClientData[iAttacker][ST_HEADSHOTS]++;
									g_iClientSessionData[iAttacker][5]++;
									NotifClient(iAttacker, g_iGiveHeadShot, "HeadShotKill");
								}

								int iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));

								if(CheckStatus(iAssister))
								{
									g_iClientData[iAssister][ST_ASSISTS]++;
									g_iClientSessionData[iAssister][6]++;
									NotifClient(iAssister, g_iGiveAssist, "AssisterKill");
								}

								g_iClientData[iAttacker][ST_KILLS]++;
								g_iClientSessionData[iAttacker][1]++;
								g_iKillstreak[iAttacker]++;
							}
						}

						g_iClientData[iClient][ST_DEATHS]++;
						g_iClientSessionData[iClient][2]++;
					}
					GiveExpForStreakKills(iClient);
				}
			}
		}

		case 'r':
		{
			switch(sEvName[6])
			{
				case 'm': NotifClient(GetClientOfUserId(GetEventInt(hEvent, "userid")), g_iRoundMVP, "RoundMVP");

				case 'e':
				{
					g_bRoundWithoutExp = false;
					int iTeam, iCheckteam = GetEventInt(hEvent, "winner");

					if(iCheckteam > 1)
					{
						for(int iClient = 1; iClient <= MaxClients; iClient++)
						{
							if(CheckStatus(iClient))
							{
								if(!g_bWarmupPeriod && (iTeam = GetClientTeam(iClient)) > 1)
								{
									if(iTeam == iCheckteam)
									{
										NotifClient(iClient, g_iRoundWin, "RoundWin");
										g_iClientData[iClient][ST_ROUNDSWIN]++;
										g_iClientSessionData[iClient][7]++;
									}
									else
									{
										NotifClient(iClient, -g_iRoundLose, "RoundLose");
										g_iClientData[iClient][ST_ROUNDSLOSE]++;
										g_iClientSessionData[iClient][8]++;
									}
								}

								if(IsPlayerAlive(iClient))
								{
									GiveExpForStreakKills(iClient);
								}

								if(g_iUsualMessage == 2)
								{
									if(g_iClientRoundExp[iClient])
									{
										LR_PrintToChat(iClient, "%T", g_iClientRoundExp[iClient] > 0 ? "RoundExpResultGive" : "RoundExpResultTake", iClient, g_iClientRoundExp[iClient]);
									}
									else LR_PrintToChat(iClient, "%T", "RoundExpResultNothing", iClient);

									LR_PrintToChat(iClient, "%T", "RoundExpResultAll", iClient, g_iClientData[iClient][ST_EXP]);
									g_iClientRoundExp[iClient] = 0;
								}
							}
						}
					}

					if(!g_bRoundEndGiveExpSett)
					{
						RequestFrame(NextFrameRound);
					}
				}

				case 's':
				{
					if(g_bWarmUpCheck && EngineGame == Engine_CSGO) g_bWarmupPeriod = view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
					g_iCountPlayers = 0;
					g_bRoundEndGiveExp = true;

					for(int i = 1; i <= MaxClients; i++)
					{
						if(CheckStatus(i) && GetClientTeam(i) > 1)
						{
							g_iCountPlayers++;
						}
					}

					if(g_bSpawnMessage)
					{
						bool bWarningMessage;
						if(g_iCountPlayers < g_iMinimumPlayers)
						{
							bWarningMessage = true;
						}

						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i))
							{
								if(bWarningMessage)
								{
									LR_PrintToChat(i, "%T", "RoundStartCheckCount", i, g_iCountPlayers, g_iMinimumPlayers);
								}

								LR_PrintToChat(i, "%T", "RoundStartMessageRanks", i);
							}
						}
					}
				}
			}
		}

		case 'b':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			switch(sEvName[6])
			{
				case 'l': g_bHaveBomb[iClient] = false, NotifClient(iClient, g_iBombPlanted, "BombPlanted");
				case 'e': NotifClient(iClient, g_iBombDefused, "BombDefused");
				case 'r': if(g_bHaveBomb[iClient]) {g_bHaveBomb[iClient] = false; NotifClient(iClient, -g_iBombDropped, "BombDropped");}
				case 'i': if(!g_bHaveBomb[iClient]) {g_bHaveBomb[iClient] = true; NotifClient(iClient, g_iBombPickup, "BombPickup");}
			}
		}

		case 'h':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			switch(sEvName[8])
			{
				case 'k': NotifClient(iClient, -g_iHostageKilled, "HostageKilled");
				case 'r': NotifClient(iClient, g_iHostageRescued, "HostageRescued");
			}
		}
	}
}

void NextFrameRound(any iData)
{
	g_bRoundEndGiveExp = false;
}

void GiveExpForStreakKills(int iClient)
{
	if(g_iKillstreak[iClient] > 1)
	{
		static const char sPhrases[][] = { "DoubleKill", "TripleKill", "Domination", "Rampage", "MegaKill", "Ownage", "UltraKill", "KillingSpree", "MonsterKill", "Unstoppable", "GodLike" };

		if(g_iKillstreak[iClient] < 12)
		{
			int iKS = g_iKillstreak[iClient] - 2;
			NotifClient(iClient, g_iBonus[iKS], sPhrases[iKS]);
		}
		else NotifClient(iClient, g_iBonus[10], sPhrases[10]);
	}

	g_iKillstreak[iClient] = 0;
	SaveDataPlayer(iClient, false);
}