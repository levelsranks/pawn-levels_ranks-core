#if defined _levelsranks_included_
  #endinput
#endif
#define _levelsranks_included_

#define PLUGIN_VERSION "v3.1"

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
	LR_OnPlayerSaved
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
	LR_MinplayersCount,			/**< Use LR_CheckCountPlayers() to get is activate statistics. **/
	LR_ShowResetMyStats,
	LR_ResetMyStatsCooldown,
	LR_ShowUsualMessage,
	LR_ShowSpawnMessage,
	LR_ShowLevelUpMessage,
	LR_ShowLevelDownMessage,
	LR_ShowRankMessage,
	LR_GiveExpRoundEnd,
	LR_BlockWarmup,				/**< Use LR_CheckCountPlayers() to get is activate statistics. **/
	LR_AllAgainstAll,

	LR_ExpKill,					/**< If LR_TypeStatistics equal 0. **/
	LR_ExpDeath,				/**< If LR_TypeStatistics equal 0. **/
	LR_KillCoefficient,			/**< If LR_TypeStatistics equal 1. **/
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
	// LR_OnSettingsModuleUpdate
	function void ();

	// LR_OnDisconnectionWithDB
	function void (Database& hDatabase);

	// LR_OnDatabaseCleanup
	function void (LR_CleanupType Type, Transaction hTransaction);

	// LR_OnLevelChangedPre
	function void (int iClient, int& iNewLevel, int iOldLevel);

	// LR_OnLevelChangedPost
	function void (int iClient, int iNewLevel, int iOldLevel);

	// LR_OnPlayerKilledPre
	function void (Event hEvent, int& iExpGive, int iExpVictim, int iExpAttacker);

	// LR_OnPlayerKilledPost
	function void (Event hEvent, int iExpGive, int iExpVictim, int iExpAttacker);

	// LR_OnPlayerLoaded
	// LR_OnResetPlayerStats
	function void (int iClient, int iAccountID);

	// LR_OnPlayerPosInTop
	function void (int iClient, int iExpPos, int iTimePos);

	// LR_OnPlayerSaved
	function void (int iClient, Transaction hTransaction);
}

/**
 * Defines a LR_MenuHook Created Menu Callback.
 *
 * @param MenuType			Menu event type.
 * @param iClient       	For whom the menu was created.
 * @param hMenu          	Handle menu (no copy).
 */
typedef LR_CreatedMenu = function void (LR_MenuType MenuType, int iClient, Menu hMenu);

/**
 * Defines a LR_MenuHook Selected Menu Callback.
 *
 * @param MenuType			Menu event type.
 * @param iClient       	Who selected item.
 * @param sItem          	Item information string.
 */
typedef LR_SelectedMenu = function void (LR_MenuType MenuType, int iClient, const char[] sItem);

/**
 * Called after the core is fully loaded.
 */
forward void LR_OnCoreIsReady();

/**
 * Hooks an LR events.
 * 
 * @param Type				Event type.
 * @param Callback			Callback function.
 *
 * @return 					Is hook successful.
 */
native bool LR_Hook(LR_HookType Type, LR_HookCB Callback);

/**
 * Unooks an LR events.
 * 
 * @param Type				Event type.
 * @param Callback			Callback function.
 *
 * @return 					Is unhook successful.
 */
native bool LR_Unhook(LR_HookType Type, LR_HookCB Callback);

/**
 * Hooks an LR menu events.
 * 
 * @param MenuType			Menu event type.
 * @param CreatedCallback	The function that will be called 
 * 							when the menu is created.
 * @param SelectedCallback	When opening a registered 
 *							item in the menu.
 *
 * @return 					Is hook successful.
 */
native bool LR_MenuHook(LR_MenuType MenuType, LR_CreatedMenu CreatedCallback, LR_SelectedMenu SelectedCallback);

/**
 * Unhooks an LR menu events.
 * 
 * @param MenuType			Menu event type.
 * @param CreatedCallback	The function that will be called 
 * 							when the menu is created.
 * @param SelectedCallback	When opening a registered 
 *							item in the menu.
 *
 * @return 					Is unhook successful.
 */
native bool LR_MenuUnhook(LR_MenuType MenuType, LR_CreatedMenu CreatedCallback, LR_SelectedMenu SelectedCallback);

/**
 * Returns the value of a parameter from config.
 *
 * @param Setting			Parameter.
 */
native any LR_GetSettingsValue(LR_SettingType Setting);

/**
 * Returns the connection to the database.
 * 
 * @return					Database connection (copy). 0 if no connection.
 */
native Database LR_GetDatabase();

/**
 * Returns the type of database.
 * 
 * @return					True on SQLite, false if MySQL.
 */
native bool LR_GetDatabaseType();

/**
 * Returns the count of players in the database.
 */
native int LR_GetCountPlayers();

/**
 * Get the name of the table being used in the database.
 * 
 * @param sBuffer			Destination string buffer.
 * @param iMaxLen			Maximum length of output string buffer.
 */
native void LR_GetTableName(char[] sBuffer, int iMaxLen);

/**
 * Get the name of the title being used in the menus.
 * 
 * @param sBuffer			Destination string buffer.
 * @param iMaxLen			Maximum length of output string buffer.
 */
native void LR_GetTitleMenu(char[] sBuffer, int iMaxLen);

/**
 * Returns ArrayList with data about rank names (copy).
 */
native ArrayList LR_GetRankNames();

/**
 * Returns ArrayList with data about rank experiences (no copy).
 * Use to get the number of ranks by means LR_GetRankExp().Length.
 */
native ArrayList LR_GetRankExp();

/**
 * Returns client status.
 * 
 * @param iClient			Client index.
 */
native bool LR_GetClientStatus(int iClient);

/**
 * Checks if enough players are in this round to activate statistics.
 * 
 * @return 					Is allow.
 */
native bool LR_CheckCountPlayers();

/**
 * Gets detailed statistics about the client.
 * 
 * @param iClient			Client index.
 * @param Stats				Type data.
 *
 * @return 					Data value.
 */
native int LR_GetClientInfo(int iClient, LR_StatsType Stats);

/**
 * Does not allow the core to issue experience 
 * during the current round.
 */
native void LR_RoundWithoutValue();

/**
 * Changes the amount of experience.
 * 
 * @param iClient			Client index.
 * @param iExp				Count Exp.
 */
native void LR_ChangeClientValue(int iClient, int iExp);

/**
 * Resets player stats. 
 * DO NOT CALL IF YOU DO NOT UNDERSTAND THE CONSEQUENCES!
 *
 * @param iClient			Client index.
 */
native void LR_ResetPlayerStats(int iClient);

/**
 * Refresh core and modules configuration files.
 */
native void LR_RefreshConfigs();

/**
 * Shows a specific menu to the client.
 * 
 * @param iClient			Client index.
 * @param MenuType			Menu type.
 */
native void LR_ShowMenu(int iClient, LR_MenuType MenuType);

/**
 * Print a chat message to the client.
 * Not sensitive to the number of arguments in formatting.
 *
 * @param iClient			Client index.
 * @param bPrefix			Whether to add [LR] prefix to message.
 * @param sFormat			Formatting rules and color (https://levels-ranks.ru/wiki/sp_colors.php).
 * @param ...				Variable number of format parameters.
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
	MarkNativeAsOptional("LR_Hook");
	MarkNativeAsOptional("LR_Unhook");
	MarkNativeAsOptional("LR_MenuHook");
	MarkNativeAsOptional("LR_MenuUnhook");

	MarkNativeAsOptional("LR_GetSettingsValue");
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