@for /f %%f IN ('dir /B/S *.h') do @echo %%f && @lua list_defines.lua %%f >>_defines.list
