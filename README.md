[Levels Ranks] Core 3.1.5
===========================

**[Levels Ranks] Core** - это плагин статистики, который для вас станет прекрасной заменой другим статистикам, как RankMe, Sod Stats и им подобные. Суть его проста, вы выполняете различные игровые действия и получаете/теряете за это очки опыта, при накоплении/потере определенного кол-ва которых, вы получаете определенный ранг.


Виды статистики:
----------------

- Накопительный ( lr_type_statistics 0 )
	- Суть в том, что вы начинаете с самого низшего звания и вы должны накапливать очки опыта, начиная с 0. И чем больше вы играете, тем выше звание.
​
- Рейтинговый :: Расширенный ( lr_type_statistics 1 )
	- Данный вид статистики является аналогом HlstatsX. Суть его в том, что вы получаете среднее звание и 1000 очков опыта. И в зависимости от того, как вы умеете играть и насколько хорошо, зависит и ваше звание.
​
- Рейтинговый :: Простой ( lr_type_statistics 2 )
	- Данный вид статистики является аналогом RankMe. Суть данного вида такая же, как и у вида статистики выше (рейтинговый расширенный), но здесь отсутствуют дополнительные бонусы, отсутствует умножающий коэффициент для регулирования статистики, а также в этом виде заложена другая формула подсчета очков опыта.

<details><summary>Скриншоты</summary>
<p>
	<a href="//levels-ranks.ru/content/core/MainMenu.jpg"><img src="https://levels-ranks.ru/content/core/MainMenu.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MenuMyStats.jpg"><img src="https://levels-ranks.ru/content/core/MenuMyStats.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MenuMySession.jpg"><img src="https://levels-ranks.ru/content/core/MenuMySession.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MenuResetStats.jpg"><img src="https://levels-ranks.ru/content/core/MenuResetStats.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MemuInventory.jpg"><img src="https://levels-ranks.ru/content/core/MemuInventory.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MenuTop.jpg"><img src="https://levels-ranks.ru/content/core/MenuTop.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MenuTop.jpg"><img src="https://levels-ranks.ru/content/core/MenuTopPoints.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MenuTop.jpg"><img src="https://levels-ranks.ru/content/core/MenuTopActivity.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/MenuTop.jpg"><img src="https://levels-ranks.ru/content/core/MenuRanks.jpg"/></a>
	<a href="//levels-ranks.ru/content/core/ChatRankStats.jpg"><img src="https://levels-ranks.ru/content/core/ChatRankStats.jpg"/></a>
</p>
</details>

Поддерживаемые игры:
--------------------
- CS: Source (v90/v34)
- CS: GO

Требования:
-----------
- SourceMod <a href="//sourcemod.net/downloads.php?branch=stable">1.10.6422</a> и выше.

Команды:
-------
- **sm_lvl** - открывает главное меню статистики.
- **sm_lvl_reload** - перезагружает все конфигурационные файлы плагина.
- **sm_lvl_reset** - сбрасывает статистику у всех игроков.
	- **all** - сбросит все данные.
	- **exp** - сбросит данные о очках опыта (`value`, `rank`).
	- **stats** - сбросит данные о статистике (`kills`, `deaths`, `shoots`, `hits`, `headshots`, `assists`, `round_win`, `round_lose`).
- **sm_lvl_del** - сбрасывает статистику у конкретного игрока.

Установка:
---------

- Удалите прошлую версию плагина, если есть.

- Распакуйте содержимое по папкам.

- Настройте файлы:
	- addons/sourcemod/configs/databases.cfg
	- addons/sourcemod/configs/levels_ranks/settings.ini
	- addons/sourcemod/configs/levels_ranks/settings_ranks.ini
	- addons/sourcemod/configs/levels_ranks/settings_stats.ini​
	
- Перезапустить сервер

Настройка - databases.cfg
-------------------------

- Если вы собираетесь использовать БД SQLite, то ничего не нужно настраивать и добавлять.

- Если вы собираетесь использовать БД MySQL, то вы должны добавить строки, которые даны ниже, в "addons/sourcemod/configs/databases.cfg", а затем отредактировать как вам требуется:

```
	"levels_ranks"
	{
		"driver"	"mysql" 
		"host"		"host" 
		"database"	"database" 
		"user"		"login" 
		"pass"		"password"
	}
```
----------------------------------------------------------------------------------

<a href="//discord.gg/Jc58wjF">Официальный Discord-канал поддержки Levels Ranks</a>
