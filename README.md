Levels Ranks - Core Plugin
===========================

Levels Ranks Core - это плагин статистики, который для вас станет прекрасной заменой другим статистикам, как RankMe, Sod Stats и им подобные. Суть его проста, вы выполняете различные игровые действия и получаете/теряете за это очки опыта, при накоплении/потере определенного кол-ва которых, вы получаете определенный ранг.

УСТАНОВКА
------------

- Удалите прошлую версию плагина, если есть.

- Распакуйте содержимое по папкам.

- Настройте файлы:
	- addons/sourcemod/configs/databases.cfg
	- addons/sourcemod/configs/levels_ranks/settings.ini
	- addons/sourcemod/configs/levels_ranks/settings_ranks.ini
	- addons/sourcemod/configs/levels_ranks/settings_stats.ini​
	
- Перезапустить сервер

НАСТРОЙКА - databases.cfg
------------

1) Если вы собираетесь использовать БД SQLite, то ничего не нужно настраивать и добавлять

2) Если вы собираетесь использовать БД MySQL, то вы должны добавить строки, которые даны ниже, в "addons/sourcemod/configs/databases.cfg", а затем отредактировать как вам требуется:

"levels_ranks"
	{
		"driver"	"mysql" 
		"host"	"host" 
		"database"	"database" 
		"user"	"login" 
		"pass"	"password"
	}