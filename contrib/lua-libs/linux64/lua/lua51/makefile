LUALIB=-L ../../lib/ -lscite
DEFFILE=../../lib/scite.def
LDFLAG= -shared

ALL: lua5.1.a

lua5.1:
	i686-w64-mingw32-dlltool --input-def $(DEFFILE) --output-exp lua5.1

lua5.1.a: lua5.1
	ld $(LDFLAG) -o "lua5.1.so" lua5.1 $(LUALIB)
	rm -f lua5.1
	rm -f lua51 
	rm -f .s*
	
clean:
	-rm -f lua51 
	-rm -f lua5.1 
	-rm -f lua5.* 
	-rm -f .s*
