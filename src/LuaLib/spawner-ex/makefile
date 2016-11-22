all: spawner-ex.dll

spawner-ex.dll: win32-spawner-ex.c
	gcc -shared -o spawner-ex.dll -I..\\lua\\5.1\\include win32-spawner-ex.c -L ../lib/ -lscite
