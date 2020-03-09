A Geiger-Muller counter on j304βγ tube and WiFi kit 8 board (Esp8266+0.91inch OLED) with NodeMcu Lua.

j304βγ (2 tubes totally):
	30000 counts per uSv
	280 microsecond dead-time 

ESP8266 Pins connections:
	One button power on/off  --- GPIO2
	G-M tube signal       --- GPIO14
	Power control         --- GPIO16

Usage:
	Long press button to turn on/off.
	Short press button to reset data.
	
OLED shows:
	Current accumulated counting duration (minus total G-M tube dead-time)
	Total counts	
	Current uSv/h
	CPM
	Average uSv/h (from power-on to now)
	
LFS:
	_init.lua and dummy_strings.lua should be compiled to a file flash.img,
	and download it to SPIFF 