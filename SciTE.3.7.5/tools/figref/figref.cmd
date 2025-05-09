@echo off

rem Windows/DOS Batch version of FIGlet program: display text using a FIGfont
rem http://www.jave.de/figlet/fonts.html          http://www.figlet.org/
rem FIGBat.bat version 1.0 - Antonio Perez Ayala - May/12/2012

rem This program does not perform fitting nor smushing

setlocal EnableDelayedExpansion
set specialChar[=exclam
set specialChar["]=quote
set specialChar[*]=star
set specialChar[?]=question
set specialChar[~]=tilde
set charSet=" " exclam] quote #  $  percent "&" '  ( ")" star   +  "," -      .     /         ^
             0  1       2     3  4  5        6  7  8  9  colon ";" "<" equal ">"    question  ^
             @  A       B     C  D  E        F  G  H  I  J      K   L  M      N     O         ^
             P  Q       R     S  T  U        V  W  X  Y  Z      [   \  ]      caret _         ^
             ` _a      _b    _c _d _e       _f _g _h _i _j     _k  _l _m     _n    _o         ^
            _p _q      _r    _s _t _u       _v _w _x _y _z      {  "|" }      tilde           ^
             Ä  Ö       Ü     ä  ö  ü        ß
rem Ascii: 196  214    220  228 246 252     223     Standard German FIGChars
set lowcaseLetters=a b c d e f g h i j k l m n o p q r s t u v w x y z

set font=solid
set "dir=%~DP0"
REM set alignment=
REM set outputWidth=8190
set outputColor=
set multiColor=


rem Process switches

if "%~1" neq "/?" if "%~1" neq "-?" goto checkNextSwitch
echo Display text using a FIGfont
echo/
echo FIGBat [/f font] [/d dir] [/c^|l^|r] [/t^|w width] [/a attr] [word ...]
echo/
echo /f    select a font file.
echo /d    change the directory for fonts.
echo /c    centers the output.
echo /l    left-aligns the output.
echo /r    right-aligns the output.
echo /t    sets the output width to the terminal width.
echo /w    specifies a custom output width.
echo /a    sets the output color:
echo       /a bf   set color as attribute (see COLOR /? for more info)
echo       /a RB   set colors as Rainbow Bands
echo       /a MC   set Multi-color Characters in random order
echo/
echo word ...  Text to display. If not given, read lines to show from STDIN.
echo/
echo /c /l /r switches may include a number separated by equal-sign that define
echo a left margin at which the alignment start.
echo/
echo /t /w switches may include a S or D letter separated by equal-sign that
echo indicate to enclose the FIGure into a frame of Single or Double lines.
echo/
echo For example:
echo     figbat /c=19 /w=s 41 Text centered into a frame between columns 20 and 60
echo/
echo Multiple switches can NOT be combined in one; write each one individually.
echo/
goto :EOF

:switch/F
set "font=%~N2"
goto shift2

:switch/D
set "dir=%~2"
goto shift2

:switch/W
set outputWidth=%2
goto shift2

:switch/A
set outputColor=%2
if /I %2 equ MC (
   rem Activate Multi-color Characters
   set multiColor=1
)
if /I %2 equ RB (
   rem Define colors as Rainbow Bands
   set lastColor=0
   for %%a in (  E D C B A 9     6 5 4 3 2 1  ) do (
      set /A lastColor+=1
      set color[!lastColor!]=%%a
   )
   set outputColor=!color[1]!
   set rainbowBand=1
)
:shift2
shift
goto shift1

:switch/C
set alignment=center
goto shift1

:switch/L
set alignment=left
goto shift1

:switch/R
set alignment=right
goto shift1

:switch/T
for /F "skip=4 tokens=2" %%a in ('mode con /status') do (
   set outputWidth=%%a
   goto shift1
)
:shift1
shift

:checkNextSwitch
for %%a in (/ -) do (
   for %%b in (f d c l r t w a) do if /I "%~1" equ "%%a%%b" goto switch/%%b
)


rem Load the FIGfont file
if "%dir:~-1%" == "\" set "dir=%dir:~0,-1%"
if not exist "%dir%\%font%.flf" (
   echo FIGfont file not found: "%dir%\%font%.flf"
   goto :EOF
)
call :loadFIGfont < "%dir%\%font%.flf"

rem Show text from parameters or from input lines
if "%~1" equ "" goto readNextLine

set "line=%~1"
:getNextWord
   shift
   if "%~1" neq "" set "line=%line% %~1" & goto getNextWord
call :showFIGure line
goto :EOF

:readNextLine
   set line=
   set /P line=
   if not defined line goto :EOF
   call :showFIGure line
   goto readNextLine
:EOF


Format of HeaderLine in a FIGfont.flf file:

#Token in FOR /F "tokens=... Batch command

1 - Signature&Hardblank, for example: f1f2a$ (hard blank is usually $)
2 - Height (of FIGcharacters in lines)
3 - Baseline (height of font from baseline up)
4 - Max_Lenght (width of the widest FIGcharacter, plus a small factor)
5 - Old_Layout (default smushmode for this font)
6 - Comment_Lines (between HeaderLine and the first FIGcharacter)
7 - Print_Direction (usually 0)
8 - Full_Layout (detailed smushmode specification)
9 - Codetag_Count (number of FIGcharacters in the font minus 102)


rem Load a FIGfont.flf file

:loadFIGfont < FIGfont.flf
rem Get font parameters from Header line
set /P HeaderLine=
for /F "tokens=1,2,6" %%a in ("%HeaderLine%") do (
   set firstToken=%%a
   set Height=%%b
   set Comment_Lines=%%c
)
set Hardblank=%firstToken:~-1%
rem Skip comment lines
for /L %%a in (1,1,%Comment_Lines%) do set /P =
rem Load FIGchars in "FIG<char><line>=sub-chars" variables
for %%a in (%charSet%) do (
   for /L %%b in (1,1,%Height%) do (
      set /P "FIG%%~a%%b="
      rem Remove one or two end marks
      set "endmark=!FIG%%~a%%b:~-1!"
      set "FIG%%~a%%b=!FIG%%~a%%b:~0,-1!"
      if "!FIG%%~a%%b:~-1!" equ "!endmark!" set "FIG%%~a%%b=!FIG%%~a%%b:~0,-1!"
      rem Replace hard blanks by spaces (no smushing)
      if "!FIG%%~a%%b!" neq "" set "FIG%%~a%%b=!FIG%%~a%%b:%Hardblank%= !"
   )
)
exit /B


rem Show an Ascii string as a FIGure

:showFIGure stringVar

rem Get lenght of Ascii string (1024 characters max)
set textLen=0
for /L %%a in (9,-1,0) do (
   set /A "bit=1<<%%a, lastLen=bit+textLen"
   for %%B in (!lastLen!) do if "!%1:~%%B,1!" neq "" set textLen=%%B
   )
)
rem Convert Ascii characters into the charSet used in FIGcharacters
for /L %%a in (0,1,%textLen%) do (
   set "char=!%1:~%%a,1!"
   call :changeSpecial char="!char!"
   set char[%%a]=!char!
)
rem Randomize color order for Multicolor Characters mode
if defined multiColor (
   set "colors= F E D C B A 9 8 7 6 5 4 3 2 1 "
   set lastColor=0
   for /L %%a in (15,-1,2) do (
      set /A "lastColor+=1, randomColor=(!random!*%%a)/32768+1"
      call :moveColor !randomColor!
   )
   set /A lastColor+=1
   set color[!lastColor!]=!colors: =!
)
rem Show the equivalent FIGure
for /L %%a in (1,1,%Height%) do (
   if defined multiColor (
      set multiColor=1
      for /L %%b in (0,1,%textLen%) do (
         REM                                                                                PATCH TO AVOID ERRORS WHEN SHOW QUOTES :"='
         for /F "tokens=1,2 delims=%Hardblank%" %%C in ("!char[%%b]!%Hardblank%!multiColor!") do ColorMsg !color[%%D]! "!FIG%%~C%%a:"=""!"
         set /A multiColor+=1
         if !multiColor! gtr !lastColor! (
            set multiColor=1
         )
      )
      echo/
   ) else (
      set FIGline=
      for /L %%b in (0,1,%textLen%) do (
         for %%C in ("!char[%%b]!") do set FIGline=!FIGline!!FIG%%~C%%a!
      )
      if defined outputColor (
         REM PATCH TO AVOID ERRORS WHEN SHOW QUOTES :"='
         ColorMsg !outputColor! "!FIGline:"=""!"
         echo/
         if defined rainbowBand (
            set /A rainbowBand+=1
            if !rainbowBand! gtr !lastColor! (
               set rainbowBand=1
            )
            for %%B in (!rainbowBand!) do set outputColor=!color[%%B]!
         )
      ) else (
         echo(!FIGline!
      )
   )
)
exit /B


rem Auxiliary subroutine for Randomize colors

:moveColor index
for /F "tokens=%1" %%a in ("%colors%") do (
   set color[%lastColor%]=%%a
   set colors=!colors: %%a = !
)
exit /B


rem Change characters that can not be easily managed in a Batch file

:changeSpecial changedChar="!originalChar!"
rem Change the special characters that can be included in a variable name
set "special=!specialChar[%~2]!"
if "!special!" equ "specialChar[:]" set special=colon
if defined special set %1=%special%& exit /B
rem Change the rest of special characters
if "%~2" equ "" set special=percent
if "%~2" equ "=" set special=equal
if "%~2" equ "^^" set special=caret
if defined special set %1=%special%& exit /B
rem Change lowcase letters (mistaken for upcase letters in variable names)
for %%a in (%lowcaseLetters%) do (
   if "%~2" equ "%%a" (
      set %1=_%%a
   )
)
