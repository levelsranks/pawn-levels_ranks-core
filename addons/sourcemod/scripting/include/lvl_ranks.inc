#if defined _levelsranks_included_
  #endinput
#endif
#define _levelsranks_included_

#define PLUGIN_VERSION "v3.0"

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
	ST_PLACEINTOP
};

/**
 * Gets the connection to the database
 * 
 * @return Handle	-	Database connection
 */
native Database LR_GetDatabase();

/**
 * Gets the type of database
 * 
 * @return bool	-	if true - SQLite, otherwise - MySQL
 */
native bool LR_GetDatabaseType();

/**
 * Get the name of the table being used in the database.
 * 
 * @noreturn
 */
native void LR_GetTableName(char[] sBuffer, int iMaxLen);

/**
 * Get the name of the title being used in the menus.
 * 
 * @noreturn
 */
native void LR_GetTitleMenu(char[] sBuffer, int iMaxLen);

/**
 * Returns param of lr_show_usualmessage
 * 
 * @return int		-	lr_show_usualmessage param
 */
native int LR_GetParamUsualMessage();

/**
 * Returns ID of statistics type
 * 
 * @return int		-	ID of stastics type
 */
native int LR_GetTypeStatistics();

/**
 * Returns count of levels
 * 
 * @return int		-	Count of levels
 */
native int LR_GetCountLevels();

/**
 * Returns count of levels
 * 
 * @param iClient	-	Client index
 * @return bool	-	Client is authorized
 */
native bool LR_GetClientStatus(int iClient);

/**
 * Checks if enough players are in this round to activate statistics
 * 
 * @return bool	-	if true - yes, otherwise - no
 */
native bool LR_CheckCountPlayers();

/**
 * Gets detailed statistics about the client
 * 
 * @param iClient	-	Client index
 * @param iStats	-	Number of selected data (enum LR_StatsType).
 * @return int		-	Obtained data
 */
native int LR_GetClientInfo(int iClient, LR_StatsType iStats);

/**
 * Changes the amount of experience points
 * 
 * @param iClient	-	Client index
 * @param iAmount	Count Exp
 * @return int		-	New count client exp.
 */
native int LR_ChangeClientValue(int iClient, int iAmount);

/**
 * Disables issuance of experience points during the round, which was used by the native
 * 
 * @noreturn
 */
native void LR_RoundWithoutValue();

/**
 * Calls up the inventory menu (necessary to go back)
 * 
 * @param iClient	-	Client index
 * @noreturn
 */
native void LR_MenuInventory(int iClient);

/**
 * Calls up the TOP-10 menu (necessary to go back)
 * 
 * @param iClient	-	Client index
 * @noreturn
 */
native void LR_MenuTopMenu(int iClient);

/**
 * Calls up the Admin's Panel menu (necessary to go back)
 * 
 * @param iClient	-	Client index
 * @noreturn
 */
native void LR_MenuAdminPanel(int iClient);

/**
 * Called when the core is ready and successfully connected to the database.
 */
forward void LR_OnCoreIsReady();

/**
 * Called when the plugin reloads the settings.
 */
forward void LR_OnSettingsModuleUpdate();

/**
 * Called when a list opens Settings
 *
 * @param iClient	-	Client index
 * @param hMenu	-	Handle of Menu
 */
forward void LR_OnMenuCreated(int iClient, Menu& hMenu);

/**
 * Called when a list opens Settings
 *
 * @param iClient	-	Client index
 * @param sInfo
 */
forward void LR_OnMenuItemSelected(int iClient, const char[] sInfo);

/**
 * Called when a list opens TOP-10
 *
 * @param iClient	-	Client index
 * @param hMenu	-	Handle of Menu
 */
forward void LR_OnMenuCreatedTop(int iClient, Menu& hMenu);

/**
 * Called when a list opens TOP-10
 *
 * @param iClient	-	Client index
 * @param sInfo
 */
forward void LR_OnMenuItemSelectedTop(int iClient, const char[] sInfo);

/**
 * Called when a list opens Admin's Panel
 *
 * @param iClient	-	Client index
 * @param hMenu	-	Handle of Menu
 */
forward void LR_OnMenuCreatedAdmin(int iClient, Menu& hMenu);

/**
 * Called when a list opens Admin's Panel
 *
 * @param iClient	-	Client index
 * @param sInfo
 */
forward void LR_OnMenuItemSelectedAdmin(int iClient, const char[] sInfo);

/**
 * Called when the customer's rank changes
 *
 * @param iClient	-	Client index
 * @param iNewLevel	New level
 * @param bUp	-	If true, the level has risen, otherwise it has gone down.
 */
forward void LR_OnLevelChanged(int iClient, int iNewLevel, bool bUp);

/**
 * Called when the murder was committed
 *
 * @param hEvent	-	Handle of the Event ("player_death")
 * @param iExpGive	-	Amount of experience points a killer gets
 * @param iExpVictim	-	Exp. points of Victim
 * @param iExpAttacker	-	Exp. points of Attacker
 */
forward void LR_OnPlayerKilled(Event hEvent, int& iExpGive, int iExpVictim, int iExpAttacker);

/**
 * Called when data is loaded.
 *
 * @param iClient	-	Client index
 * @param sSteamID	-	Client's SteamID2
 */
forward void LR_OnPlayerLoaded(int iClient, const char[] sSteamID);

/**
 * Called when data saving is initiated.
 *
 * @param iClient	-	Client index
 * @param hQuery	-	Handle of the Transaction
 */
forward void LR_OnPlayerSaved(int iClient, Transaction& hQuery);

/**
 * Called when a player's place in the TOP is received.
 *
 * @param iClient	-	Client index
 * @param iPos	-	Client place in TOP
 */
forward void LR_OnPlayerPosInTop(int iClient, int iPos);

stock void LR_PrintToChat(int iClient, char[] szMessage, any ...)
{
	static int			iEngine = -1;
	static const int	g_iColorsCSSOB[] = {0xFFFFFF, 0xFF0000, 0x00AD00, 0x00FF00, 0x99FF99, 0xFF4040, 0xCCCCCC, 0xFFBD6B, 0xFA8B00, 0x99CCFF, 0x3D46FF, 0xFA00FA};
	static const char	g_sColorsOldBefore[][] = {"{DEFAULT}", "{TEAM}", "{GREEN}"},
					g_sColorsOldCSS[][] = {"\x01", "\x03", "\x04"},
					g_sColorsBefore[][] = {"{WHITE}", "{RED}", "{GREEN}", "{LIME}", "{LIGHTGREEN}", "{LIGHTRED}", "{GRAY}", "{LIGHTOLIVE}", "{OLIVE}", "{LIGHTBLUE}", "{BLUE}", "{PURPLE}"},
					g_sColorsCSGO[][] = {"\x01", "\x02", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0C", "\x0E"};


	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];

		if(iEngine == -1)
		{
			switch(GetEngineVersion())
			{
				case Engine_CSGO: iEngine = 0;
				case Engine_CSS: iEngine = 1;
				case Engine_SourceSDK2006: iEngine = 2;
			}
		}

		Format(szBuffer, sizeof(szBuffer), !iEngine ? " \x01%s" : "\x01%s", szMessage);
		VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

		if(!iEngine)
		{
			for(int i = 0; i < 12; i++)
			{
				ReplaceString(szNewMessage, sizeof(szNewMessage), g_sColorsBefore[i], g_sColorsCSGO[i]);
			}
			ReplaceString(szNewMessage, sizeof(szNewMessage), "{TEAM}", "\x03");
		}
		else
		{
			if(iEngine == 1)
			{
				char sBuff[64];
				switch(GetClientTeam(iClient))
				{
					case 1: Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[6]);
					case 2: Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[5]);
					case 3: Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[9]);
				}
				ReplaceString(szNewMessage, sizeof(szNewMessage), "{TEAM}", sBuff);

				for(int i = 0; i < 12; i++)
				{
					Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[i]);
					ReplaceString(szNewMessage, sizeof(szNewMessage), g_sColorsBefore[i], sBuff);
				}
			}
			else
			{
				for(int i = 0; i < 3; i++)
				{
					ReplaceString(szNewMessage, sizeof(szNewMessage), g_sColorsOldBefore[i], g_sColorsOldCSS[i]);
				}
			}
		}

		Handle hBf = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
		if(hBf)
		{
			if(GetUserMessageType() == UM_Protobuf)
			{
				Protobuf hProtoBuffer = UserMessageToProtobuf(hBf);
				hProtoBuffer.SetInt("ent_idx", iClient);
				hProtoBuffer.SetBool("chat", true);
				hProtoBuffer.SetString("msg_name", szNewMessage);
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
			}
			else
			{
				BfWrite hBfBuffer = UserMessageToBfWrite(hBf);
				hBfBuffer.WriteByte(iClient);
				hBfBuffer.WriteByte(true);
				hBfBuffer.WriteString(szNewMessage);
			}
		}
		EndMessage();
	}
}

public SharedPlugin __pl_levelsranks = 
{
	name = "levelsranks",
	file = "levelsranks.smx",

	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_levelsranks_SetNTVOptional()
{
	MarkNativeAsOptional("LR_GetDatabase");
	MarkNativeAsOptional("LR_GetDatabaseType");
	MarkNativeAsOptional("LR_GetTableName");
	MarkNativeAsOptional("LR_GetTitleMenu");
	MarkNativeAsOptional("LR_GetParamUsualMessage");
	MarkNativeAsOptional("LR_GetTypeStatistics");
	MarkNativeAsOptional("LR_GetCountLevels");
	MarkNativeAsOptional("LR_GetClientStatus");
	MarkNativeAsOptional("LR_CheckCountPlayers");
	MarkNativeAsOptional("LR_GetClientInfo");
	MarkNativeAsOptional("LR_ChangeClientValue");
	MarkNativeAsOptional("LR_RoundWithoutValue");
	MarkNativeAsOptional("LR_MenuInventory");
	MarkNativeAsOptional("LR_MenuTopMenu");
	MarkNativeAsOptional("LR_MenuAdminPanel");
}
#endif