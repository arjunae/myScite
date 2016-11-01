LUALIB=-L ..\..\lib\ -lscite
DEFFILE=scite.def
LDFLAG= -shared

ALL: lua51.dll lua5.1.dll

$(DEFFILE):..\..\_clib_bin\SciTE.exe
	..\..\bin\pexports ..\..\_clib_bin\SciTE.exe > $(DEFFILE)

lua51:$(DEFFILE)
	dlltool --input-def $(DEFFILE) --output-exp lua51

lua5.1:$(DEFFILE)
	dlltool --input-def $(DEFFILE) --output-exp lua5.1

lua51.dll: lua51
	ld.exe $(LDFLAG) -o "lua51.dll" lua51 $(LUALIB)

lua5.1.dll: lua5.1
	ld.exe $(LDFLAG) -o lua5.1.dll  lua51 $(LUALIB)
	del lua5.1 2>NUL
	del lua51 2>NUL
	del *s 2>NUL
	
clean:
	-del $(DEFFILE) 2>NUL
	-del lua51 2>NUL
	-del lua5.1 2>NUL
	-del lua5.* 2>NUL
	-del .s* 2>NUL
