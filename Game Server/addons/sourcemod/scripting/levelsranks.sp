/***************************************************************************
****
****		Date of creation :		November 27, 2014
****		Date of official release :	April 12, 2015
****		Last update :			June 12, 2019
****
****************************************************************************
****
****		Authors:
****
****		RoadSide Romeo
****		( main development )
****
****		Development assistance:
****
****		R1KO
****		( training - modular system, fix errors and optimization )
****
****		White Wolf (aka TiBarification)
****		( training - method of transaction, fix errors and optimization )
****
****		Wend4r
****		( fix errors and optimization )
****
****		Kruzya
****		( fix errors and optimization )
****
****		Kaneki
****		( fix errors and optimization )
****
****		M0st1ce
****		( web-interface )
****
****		Grey
****		( optimization and manual new syntax )
****
****		Pheonix
****		( function GetFixNamePlayer )
****
****		Reiko1231
****		( optimization )
****
****		Testers
****		( test of plugin )
****
***************************************************************************/

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"
#define MAX_COUNT_RANKS 128

#define LogLR(%0) LogError("[" ... PLUGIN_NAME ... " Core] " ... %0)
#define CrashLR(%0) SetFailState("[" ... PLUGIN_NAME ... " Core] " ... %0)

EngineVersion EngineGame;

int			g_iClientRoundExp[MAXPLAYERS+1],
			g_iClientSessionData[MAXPLAYERS+1][10],
			g_iClientData[MAXPLAYERS+1][LR_StatsType],
			g_iKillstreak[MAXPLAYERS+1],
			g_iCountRetryConnect,
			g_iDBCountPlayers,
			g_iCountPlayers;
char			g_sSteamID[MAXPLAYERS+1][32];
bool			g_bInitialized[MAXPLAYERS+1],
			g_bHaveBomb[MAXPLAYERS+1],
			g_bWarmupPeriod,
			g_bDatabaseSQLite,
			g_bRoundEndGiveExp,
			g_bRoundWithoutExp;
Handle		g_hForward_OnCoreIsReady,
			g_hForward_OnSettingsModuleUpdate,
			g_hForward_OnPlayerKilled,
			g_hForward_OnMenuCreated,
			g_hForward_OnMenuItemSelected,
			g_hForward_OnMenuCreatedTop,
			g_hForward_OnMenuItemSelectedTop,
			g_hForward_OnMenuCreatedAdmin,
			g_hForward_OnMenuItemSelectedAdmin,
			g_hForward_OnLevelChanged,
			g_hForward_OnPlayerLoaded,
			g_hForward_OnPlayerSaved,
			g_hForward_OnPlayerPlace;
Database	g_hDatabase = null;

#include "levels_ranks/settings.sp"
#include "levels_ranks/database.sp"
#include "levels_ranks/custom_functions.sp"
#include "levels_ranks/menus.sp"
#include "levels_ranks/hooks.sp"
#include "levels_ranks/natives.sp"

public Plugin myinfo = {name = "[" ... PLUGIN_NAME ... "] Core", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public void OnPluginStart()
{
	switch((EngineGame = GetEngineVersion()))
	{
		case Engine_CSGO, Engine_CSS, Engine_SourceSDK2006: {}
		default: CrashLR("This plugin works only on CS:GO, CS:S OB and CS:S v34");
	}

	g_hForward_OnCoreIsReady = CreateGlobalForward("LR_OnCoreIsReady", ET_Ignore);
	g_hForward_OnSettingsModuleUpdate = CreateGlobalForward("LR_OnSettingsModuleUpdate", ET_Ignore);
	g_hForward_OnMenuCreated = CreateGlobalForward("LR_OnMenuCreated", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelected = CreateGlobalForward("LR_OnMenuItemSelected", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnMenuCreatedTop = CreateGlobalForward("LR_OnMenuCreatedTop", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelectedTop = CreateGlobalForward("LR_OnMenuItemSelectedTop", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnMenuCreatedAdmin = CreateGlobalForward("LR_OnMenuCreatedAdmin", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnMenuItemSelectedAdmin = CreateGlobalForward("LR_OnMenuItemSelectedAdmin", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnLevelChanged = CreateGlobalForward("LR_OnLevelChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForward_OnPlayerKilled = CreateGlobalForward("LR_OnPlayerKilled", ET_Ignore, Param_Cell, Param_CellByRef, Param_Cell, Param_Cell);
	g_hForward_OnPlayerLoaded = CreateGlobalForward("LR_OnPlayerLoaded", ET_Ignore, Param_Cell, Param_String);
	g_hForward_OnPlayerSaved = CreateGlobalForward("LR_OnPlayerSaved", ET_Ignore, Param_Cell, Param_CellByRef);
	g_hForward_OnPlayerPlace = CreateGlobalForward("LR_OnPlayerPosInTop", ET_Ignore, Param_Cell, Param_Cell);

	LoadTranslations(EngineGame == Engine_SourceSDK2006 ? "lr_core_old.phrases" : "lr_core.phrases");

	RegAdminCmd("sm_lvl_reload", ResetSettings, ADMFLAG_ROOT);
	RegConsoleCmd("sm_lvl", Call_MainMenu);
	CreateTimer(1.0, PlayTimeCounter, _, TIMER_REPEAT);

	SetSettings();
	MakeHooks();
	ConnectDB();
}

public void OnMapStart()
{
	if(g_bSoundRankPlay)
	{
		char sBuffer[256];
		FormatEx(sBuffer, 256, "sound/%s", g_sSoundUp); AddFileToDownloadsTable(sBuffer);
		FormatEx(sBuffer, 256, "sound/%s", g_sSoundDown); AddFileToDownloadsTable(sBuffer);
		LR_PrecacheSound();
	}
}

public void OnClientPutInServer(int iClient)
{
	if(IsClientAuthorized(iClient))
	{
		LoadDataPlayer(iClient);
	}
}

public void OnClientAuthorized(int iClient)
{
	if(IsClientInGame(iClient))
	{
		LoadDataPlayer(iClient);
	}
}

public void OnClientDisconnect(int iClient)
{
	SaveDataPlayer(iClient, true);
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);	
		}
	}
}