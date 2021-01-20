#if defined _levelsranks_included_
  #endinput
#endif
#define _levelsranks_included_

#define PLUGIN_VERSION "v3.1.6"
#define PLUGIN_INT_VERSION 03010600

enum LR_HookType
{
	LR_OnSettingsModuleUpdate = 0,
	LR_OnDisconnectionWithDB,
	LR_OnDatabaseCleanup,
	LR_OnLevelChangedPre,
	LR_OnLevelChangedPost,
	LR_OnPlayerKilledPre,
	LR_OnPlayerKilledPost,
	LR_OnPlayerLoaded,
	LR_OnResetPlayerStats,
	LR_OnPlayerPosInTop,
	LR_OnPlayerSaved,
	LR_OnExpChanged
};

enum LR_MenuType
{
	LR_AdminMenu = 0,
	LR_MyStatsSecondary,
	LR_SettingMenu,
	LR_TopMenu
};

enum LR_CleanupType
{
	LR_AllData,
	LR_ExpData,
	LR_StatsData
};

enum LR_SettingType
{
	LR_FlagAdminmenu = 0,
	LR_TypeStatistics,
	LR_IsLevelSound,
	LR_MinplayersCount,       /**< Use LR_CheckCountPlayers() to get is activate statistics. **/
	LR_ShowResetMyStats,
	LR_ResetMyStatsCooldown,
	LR_ShowUsualMessage,
	LR_ShowSpawnMessage,
	LR_ShowLevelUpMessage,
	LR_ShowLevelDownMessage,
	LR_ShowRankMessage,
	LR_ShowRankList,
	LR_GiveExpRoundEnd,
	LR_BlockWarmup,           /**< Use LR_CheckCountPlayers() to get is activate statistics. **/
	LR_AllAgainstAll,
	LR_CleanDB_Days,
	LR_CleanDB_BanClient,
	LR_DB_SaveDataPlayer_Mode,
	LR_DB_Allow_UTF8MB4,
	LR_DB_Charset_Type
};

enum LR_SettingStatsType
{
	LR_ExpKill = 0,           /**< If LR_TypeStatistics equal 0. **/
	LR_ExpKillIsBot,          /**< If LR_TypeStatistics equal 0. **/
	LR_ExpDeath,              /**< If LR_TypeStatistics equal 0. **/
	LR_ExpDeathIsBot,         /**< If LR_TypeStatistics equal 0. **/
	LR_ExpKillCoefficient,    /**< If LR_TypeStatistics equal 1. **/
	LR_ExpGiveHeadShot,
	LR_ExpGiveAssist,
	LR_ExpGiveSuicide,
	LR_ExpGiveTeamKill,
	LR_ExpRoundWin,
	LR_ExpRoundLose,
	LR_ExpRoundMVP,
	LR_ExpBombPlanted,
	LR_ExpBombDefused,
	LR_ExpBombDropped,
	LR_ExpBombPickup,
	LR_ExpHostageKilled,
	LR_ExpHostageRescued
};

enum LR_StatsType
{
	ST_EXP = 0,
	ST_RANK,
	ST_KILLS,
	ST_DEATHS,
	ST_SHOOTS,
	ST_HITS,
	ST_HEADSHOTS,
	ST_ASSISTS,
	ST_ROUNDSWIN,
	ST_ROUNDSLOSE,
	ST_PLAYTIME,
	ST_PLACEINTOP,
	ST_PLACEINTOPTIME
};

typeset LR_HookCB 
{
	/**
	 * LR_OnSettingsModuleUpdate
	 *
	 * Сalled when the configuration has been reloaded.
	 */
	function void ();

	/**
	 * LR_OnDisconnectionWithDB
	 *
	 * Called when a MySQL connection is lost.
	 *
	 * @param hDatabase       Empty connection. Designed to force 
	 *                        the substitution.
	 */
	function void (Database &hDatabase);

	/**
	 * LR_OnDatabaseCleanup
	 *
	 * Called when clearing tables in the database.
	 *
	 * @param CleanupType     The type of cleaning.
	 * @param hTransaction    Transaction for cleaning in thread.
	 */
	function void (LR_CleanupType CleanupType, Transaction hTransaction);

	/**
	 * LR_OnLevelChangedPre
	 *
	 * Called before processing, when a player has upped or lowered his rank.
	 *
	 * @param iClient         Client index.
	 * @param iNewLevel       New rank of the player. Can change.
	 * @param iOldLevel       Rank, which was until obtain a new.
	 */
	function void (int iClient, int &iNewLevel, int iOldLevel);

	/**
	 * LR_OnLevelChangedPost
	 *
	 * Called when a player has upped or lowered his rank.
	 *
	 * @param iClient         Client index.
	 * @param iNewLevel       New rank of the player.
	 * @param iOldLevel       Rank, which was until obtain a new.
	 */
	function void (int iClient, int iNewLevel, int iOldLevel);

	/**
	 * LR_OnPlayerKilledPre
	 *
	 * Called before processed the player_death event.
	 *
	 * @param hEvent          Handle player_death event.
	 * @param iExpCaused      Experience points given and taken
	 *                        depending on LR_TypeStatistics. Can change.
	 * @param iExpVictim      Amount of experience the victim.
	 * @param iExpAttacker    Amount of experience the attacker.
	 */
	function void (Event hEvent, int &iExpCaused, int iExpVictim, int iExpAttacker);

	/**
	 * LR_OnPlayerKilledPost
	 *
	 * Called after processing the player_death event.
	 *
	 * @param hEvent          Handle player_death event.
	 * @param iExpGive        Experience points given and taken 
	 *                        depending on LR_TypeStatistics.
	 * @param iExpVictim      Amount of experience the victim.
	 * @param iExpAttacker    Amount of experience the attacker.
	 */
	function void (Event hEvent, int iExpGive, int iExpVictim, int iExpAttacker);

	/**
	 * LR_OnPlayerLoaded
	 *
	 * Called when the player has booted.
	 *
	 * @param iClient         Client index.
	 * @param iAccountID      Client Steam Account ID.
	 */
	function void (int iClient, int iAccountID);

	/**
	 * LR_OnResetPlayerStats
	 *
	 * Called when reset statistics of player.
	 *
	 * @param iClient         Client index. Can be 0 if it
	 *                        offline reset.
	 * @param iAccountID      Client Steam AccountID.
	 */
	function void (int iClient, int iAccountID);

	/**
	 * LR_OnPlayerPosInTop
	 *
	 * Called when the updated the positions in the tops.
	 * @note The earliest getting a position in the top occurs in LR_OnPlayerLoaded.
	 *
	 * @param iClient         Client index. 
	 * @param iExpPos         Client position in the top by experiences.
	 * @param iTimePos        Client position in the top by time.
	 */
	function void (int iClient, int iExpPos, int iTimePos);

	/**
	 * LR_OnPlayerSaved
	 *
	 * Сalled when a player is saved data.
	 *
	 * @param iClient         Client index.
	 * @param hTransaction    Transaction for saved in thread.
	 */
	function void (int iClient, Transaction hTransaction);

	/**
	 * LR_OnExpChanged
	 *
	 * Called when experience points change.
	 *
	 * @param iClient         Client index.
	 * @param iGiveExp        How much was added.
	 * @param iNewExpCount    New experience count of the player.
	 */
	function void (int iClient, int iGiveExp, int iNewExpCount);
}

/**
 * Defines a LR_MenuHook Created Menu Callback.
 *
 * @param MenuType            Menu event type.
 * @param iClient             For whom the menu was created.
 * @param hMenu	              Handle menu (no copy).
 */
typedef LR_CreatedMenu = function void (LR_MenuType MenuType, int iClient, Menu hMenu);

/**
 * Defines a LR_MenuHook Selected Menu Callback.
 *
 * @param MenuType            Menu event type.
 * @param iClient             Who selected item.
 * @param sItem               Item information string.
 */
typedef LR_SelectedMenu = function void (LR_MenuType MenuType, int iClient, const char[] sItem);

/**
 * Called after the core is fully loaded.
 * @note Called not in the core startup thread.
 */
forward void LR_OnCoreIsReady();

/**
 * Return if core is loaded.
 */
native bool LR_IsLoaded();

/**
 * Return the core version
 * PLUGIN_INT_VERSION From [LR] Core.
 * Explame: 03010000 - v3.1.
 */
native int LR_GetVersion();

/**
 * Hooks an LR events.
 * 
 * @param Type                Event type.
 * @param Callback            Callback function.
 *
 * @return                    Is hook successful.
 */
native bool LR_Hook(LR_HookType Type, LR_HookCB Callback);

/**
 * Unooks an LR events.
 * 
 * @param Type                Event type.
 * @param Callback            Callback function.
 *
 * @return                    Is unhook successful.
 */
native bool LR_Unhook(LR_HookType Type, LR_HookCB Callback);

/**
 * Hooks an LR menu events.
 * 
 * @param MenuType            Menu event type.
 * @param CreatedCallback     The function that will be called 
 *                            when the menu is created.
 * @param SelectedCallback    When opening a registered 
 *                            item in the menu.
 *
 * @return                    Is hook successful.
 */
native bool LR_MenuHook(LR_MenuType MenuType, LR_CreatedMenu CreatedCallback, LR_SelectedMenu SelectedCallback);

/**
 * Unhooks an LR menu events.
 * 
 * @param MenuType            Menu event type.
 * @param CreatedCallback     The function that will be called 
 *                            when the menu is created.
 * @param SelectedCallback    When opening a registered 
 *                            item in the menu.
 *
 * @return                    Is unhook successful.
 */
native bool LR_MenuUnhook(LR_MenuType MenuType, LR_CreatedMenu CreatedCallback, LR_SelectedMenu SelectedCallback);

/**
 * Returns the value of a parameter from settings.ini.
 *
 * @param Setting             Parameter.
 */
native any LR_GetSettingsValue(LR_SettingType Setting);

/**
 * Returns the value of a parameter from settings_stats.ini.
 *
 * @param Setting             Parameter.
 */
native any LR_GetSettingsStatsValue(LR_SettingStatsType Setting);

/**
 * Returns the connection to the database.
 *
 * @return                    Database connection (copy). 0 if no connection.
 */
native Database LR_GetDatabase();

/**
 * Returns the type of database.
 *
 * @return                    True on SQLite, false if MySQL.
 */
native bool LR_GetDatabaseType();

/**
 * Returns the count of players in the database.
 */
native int LR_GetCountPlayers();

/**
 * Get the name of the table being used in the database.
 *
 * @param sBuffer             Destination string buffer.
 * @param iMaxLen             Maximum length of output string buffer.
 */
native void LR_GetTableName(char[] sBuffer, int iMaxLen);

/**
 * Get the name of the title being used in the menus.
 *
 * @param sBuffer             Destination string buffer.
 * @param iMaxLen             Maximum length of output string buffer.
 */
native void LR_GetTitleMenu(char[] sBuffer, int iMaxLen);

/**
 * Returns ArrayList with data about rank names (no copy).
 */
native ArrayList LR_GetRankNames();

/**
 * Returns ArrayList with data about rank experiences (no copy).
 */
native ArrayList LR_GetRankExp();

/**
 * Returns is client loaded in core.
 *
 * @param iClient             Client index.
 *
 * @return                    Is loaded.
 */
native bool LR_GetClientStatus(int iClient);

/**
 * Checks if enough players are in this round to activate statistics.
 *
 * @return                    Is allow.
 */
native bool LR_CheckCountPlayers();

/**
 * Gets detailed statistics about the client.
 *
 * @param iClient             Client index.
 * @param StatsType           Type data.
 * @param bSession            Output data from session.
 *
 * @return                    Data value.
 */
native int LR_GetClientInfo(int iClient, LR_StatsType StatsType, bool bSession = false);

/**
 * Does not allow the core to issue experience 
 * during the current round.
 */
native void LR_RoundWithoutValue();

/**
 * Adds the amount of experience.
 *
 * @param iClient             Client index.
 * @param iGiveExp            Give experiences count.
 *
 * @return                    Is experiences have been issued.
 */
native bool LR_ChangeClientValue(int iClient, int iGiveExp);

/**
 * Resets player stats. 
 * DO NOT CALL IF YOU DO NOT UNDERSTAND THE CONSEQUENCES!
 *
 * @param iClient             Client index.
 */
native void LR_ResetPlayerStats(int iClient);

/**
 * Refresh core and modules configuration files.
 */
native void LR_RefreshConfigs();

/**
 * Shows a specific menu to the client.
 *
 * @param iClient             Client index.
 * @param MenuType            Menu type.
 */
native void LR_ShowMenu(int iClient, LR_MenuType MenuType);

/**
 * Print a chat message to the client.
 * Not sensitive to the number of arguments in formatting.
 *
 * @param iClient             Client index.
 * @param bPrefix             Whether to add [LR] prefix to message.
 * @param sFormat             Formatting rules and colors.
 * @param ...                 Variable number of format parameters.
 */
native void LR_PrintToChat(int iClient, bool bPrefix, const char[] sFormat, any ...);



public SharedPlugin __pl_levelsranks = 
{
	name = "levelsranks",
	file = "levelsranks.smx",

	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_levelsranks_SetNTVOptional()
{
	MarkNativeAsOptional("LR_IsLoaded");
	MarkNativeAsOptional("LR_GetVersion");
	MarkNativeAsOptional("LR_Hook");
	MarkNativeAsOptional("LR_Unhook");
	MarkNativeAsOptional("LR_MenuHook");
	MarkNativeAsOptional("LR_MenuUnhook");
	MarkNativeAsOptional("LR_GetSettingsValue");
	MarkNativeAsOptional("LR_GetSettingsStatsValue");
	MarkNativeAsOptional("LR_GetDatabase");
	MarkNativeAsOptional("LR_GetDatabaseType");
	MarkNativeAsOptional("LR_GetCountPlayers");
	MarkNativeAsOptional("LR_GetTableName");
	MarkNativeAsOptional("LR_GetTitleMenu");
	MarkNativeAsOptional("LR_GetRankNames");
	MarkNativeAsOptional("LR_GetRankExp");
	MarkNativeAsOptional("LR_GetClientStatus");
	MarkNativeAsOptional("LR_CheckCountPlayers");
	MarkNativeAsOptional("LR_GetClientInfo");
	MarkNativeAsOptional("LR_RoundWithoutValue");
	MarkNativeAsOptional("LR_ChangeClientValue");
	MarkNativeAsOptional("LR_ResetPlayerStats");
	MarkNativeAsOptional("LR_RefreshConfigs");
	MarkNativeAsOptional("LR_ShowMenu");
	MarkNativeAsOptional("LR_PrintToChat");
}
#endif