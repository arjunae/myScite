@for /f %%f IN ('dir /B') do  @echo %%f && @lua list_defines.lua %%f >>_defines.list
