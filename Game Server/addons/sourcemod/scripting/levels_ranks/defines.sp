// For SourceMod 1.11.

#define LR_HookType 11

#define LR_OnSettingsModuleUpdate 0
#define LR_OnDisconnectionWithDB 1
#define LR_OnDatabaseCleanup 2
#define LR_OnLevelChangedPre 3
#define LR_OnLevelChangedPost 4
#define LR_OnPlayerKilledPre 5
#define LR_OnPlayerKilledPost 6
#define LR_OnPlayerLoaded 7
#define LR_OnResetPlayerStats 8
#define LR_OnPlayerPosInTop 9
#define LR_OnPlayerSaved 10

#define LR_MenuType 4

#define LR_AdminMenu 0
#define LR_MyStatsSecondary 1 
#define LR_SettingMenu 2
#define LR_TopMenu 3

#define LR_SettingType 19

#define LR_FlagAdminmenu 0
#define LR_TypeStatistics 1
#define LR_IsLevelSound 2
#define LR_MinplayersCount 3
#define LR_ShowResetMyStats 4
#define LR_ResetMyStatsCooldown 5
#define LR_ShowUsualMessage 6
#define LR_ShowSpawnMessage 7
#define LR_ShowLevelUpMessage 8
#define LR_ShowLevelDownMessage 9
#define LR_ShowRankMessage 10
#define LR_GiveExpRoundEnd 11
#define LR_ShowRankList 12
#define LR_BlockWarmup 13
#define LR_AllAgainstAll 14
#define LR_CleanDB_Days 15
#define LR_CleanDB_BanClient 16
#define LR_DB_SaveDataPlayer_Mode 17
#define LR_DB_Allow_UTF8MB4 18

#define LR_SettingStatsType 17

#define LR_ExpKill 1
#define LR_ExpDeath 2
#define LR_ExpKillCoefficient 3
#define LR_ExpGiveHeadShot 4
#define LR_ExpGiveAssist 5
#define LR_ExpGiveSuicide 6
#define LR_ExpGiveTeamKill 7
#define LR_ExpRoundWin 8
#define LR_ExpRoundLose 9
#define LR_ExpRoundMVP 10
#define LR_ExpBombPlanted 11
#define LR_ExpBombDefused 12
#define LR_ExpBombDropped 13
#define LR_ExpBombPickup 14
#define LR_ExpHostageKilled 15
#define LR_ExpHostageRescued 16

#define LR_StatsType 13

#define ST_EXP 0
#define ST_RANK 1
#define ST_KILLS 2
#define ST_DEATHS 3
#define ST_SHOOTS 4
#define ST_HITS 5
#define ST_HEADSHOTS 6
#define ST_ASSISTS 7
#define ST_ROUNDSWIN 8
#define ST_ROUNDSLOSE 9
#define ST_PLAYTIME 10
#define ST_PLACEINTOP 11
#define ST_PLACEINTOPTIME 12

// any(...) -> view_as<any>(...)

#define bool(%0) view_as<bool>(%0)
#define int(%0) view_as<int>(%0)

// for SQL Querys

#define LR_GetPlacePlayer 1
#define LR_CreateDataPlayer 2
#define LR_LoadDataPlayer 3
#define LR_TopPlayersExp 4
#define LR_TopPlayersTime 5
#define LR_ConnectToDB 10
#define LR_ReconnectToDB 11