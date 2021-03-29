[Levels Ranks] Core 3.1.6
===========================

** [Levels Ranks] Core ** is a statistics plugin that will be a great replacement for other statistics like RankMe, Sod Stats and the like. The essence of it is simple, you perform various game actions and gain / lose experience points for it, at accumulation / loss of a certain number of which, you receive a certain rank.


Types of statistics:
----------------

- Accumulative (lr_type_statistics 0)
- The point is that you start from the lowest rank and you have to accumulate experience points starting from 0. And the more you play, the higher the rank.
- Rating :: Advanced (lr_type_statistics 1)
- This type of statistics is analogous to HlstatsX. The essence of it is that you get an average rank and 1000 experience points. And depending on how well you can play and how well you play, your title also depends.
The
- Rating :: Simple (lr_type_statistics 2)
- This type of statistics is an analogue of RankMe. The essence of this type is the same as in the type of statistics above (extended rating), but there are no additional bonuses, there is no multiplier to regulate the statistics, and also in this form there is a different calculation formula.

<details> <summary> Screenshots </summary>
<p>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MainMenu.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MainMenu.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MenuMyStats.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MenuMyStats.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MenuMySession.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MenuMySession.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MenuResetStats.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MenuResetStats.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MemuInventory.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MemuInventory.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MenuTop.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MenuTop.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MenuTop.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MenuTopPoints.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MenuTop.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MenuTopActivity.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/MenuTop.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / MenuRanks.jpg "/> </a>
<ahref="//raw.githubusercontent.com/levelsranks/levels-ranks-core/master/.github/img/ChatRankStats.jpg"> <img src = "https://raw.githubusercontent.com/levelsranks/ levels-ranks-core / master / .github / img / ChatRankStats.jpg "/> </a>
</p>
</details>

Supported games:
--------------------
- CS: Source (v90 / v34)
- CS: GO

Requirements:
-----------
- SourceMod  [1.10.6422](//sourcemod.net/downloads.php?branch=stable) and above.

Teams:
-------
- ** sm_lvl ** - opens the main statistics menu.
- ** sm_lvl_reload ** - reloads all plug-in configuration files.
- ** sm_lvl_reset ** - resets statistics for all players.
- ** all ** - will reset all data.
- ** exp ** - will reset the experience points data (`value`,` rank`).
- ** stats ** - reset statistics data (`kills`,` deaths`, `shoots`,` hits`, `headshots`,` assists`, `round_win`,` round_lose`).
- ** sm_lvl_del ** - resets statistics for a specific player.

Installation:
---------

- Remove the previous version of the plugin, if any.

- Unpack the contents in folders.

- Configure files:
- addons / sourcemod / configs / databases.cfg
- addons / sourcemod / configs / levels_ranks / settings.ini
- addons / sourcemod / configs / levels_ranks / settings_ranks.ini
- addons / sourcemod / configs / levels_ranks / settings_stats.ini

- Restart the server

Setup - databases.cfg
-------------------------

- If you are going to use DB SQLite, then you do not need to configure and add anything.

- If you are going to use a MySQL database, you need to add the lines given below to "addons / sourcemod / configs / databases.cfg", and then edit as you need:

```
"levels_ranks"
{
"driver" "mysql"
"host" "host"
"database" "database"
"user" "login"
"pass" "password"
}
```
-----
