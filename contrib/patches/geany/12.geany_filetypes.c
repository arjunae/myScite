# For complete documentation of this file, please see Geany's main documentation
# 17.12.2017 - Added c89-c99 Constants, types, macros, gcc internal functions and MS Types.
[styling]
# Edit these in the colorscheme .conf file instead
default=default
comment=comment
commentline=comment_line
commentdoc=comment_doc
preprocessorcomment=comment
preprocessorcommentdoc=comment_doc
number=number_1
word=keyword_1
word2=keyword_2
string=string_1
stringraw=string_2
character=character
userliteral=other
uuid=other
preprocessor=preprocessor
operator=operator
identifier=identifier_1
stringeol=string_eol
verbatim=string_2
regex=regex
commentlinedoc=comment_line_doc
commentdockeyword=comment_doc_keyword
commentdockeyworderror=comment_doc_keyword_error
globalclass=class
# """verbatim"""
tripleverbatim=string_2
hashquotedstring=string_2
taskmarker=comment
escapesequence=string_1

[keywords]
# all items must be in one line. OK?!

#~~ Kudos to: https://en.wikibooks.org/wiki/C_Programming/Standard_libraries
#~~ isoC99 Constants, types and macros.  + MS Types
primary=and and_eq asm auto bitand bitor break case catch class compl const const_cast continue default delete do dynamic_cast else enum explicit export extern false for friend goto if inline mutable namespace new not not_eq operator or or_eq private protected public register reinterpret_cast return sizeof static static_cast struct switch template this throw true try typedef typeid typename union unsigned using virtual volatile while xor xor_eq concept requires import module bool true false EDOM EILSEQ ERANGE E2BIG EACCES EAGAIN EBADF EBADMSG EBUSY ECANCELED ECHILD EDEADLK EEXIST EFAULT EFBIG EINPROGRESS EINTR EINVAL EIO EISDIR EMFILE EMLINK EMSGSIZE ENAMETOOLONG ENFILE ENODEV ENOENT ENOEXEC ENOLCK ENOMEM ENOSPC ENOSYS ENOTDIR ENOTEMPTY ENOTSUP ENOTTY ENXIO EPERM EPIPE EROFS ESPIPE ESRCH ETIMEDOUT EXDEV fenv_t fexcept_t FE_DIVBYZERO FE_INEXACT FE_INVALID FE_OVERFLOW FE_UNDERFLOW FE_ALL_EXCEPT FE_DOWNWARD FE_UPWARD FE_TONEAREST FE_TOWARDZERO FLT_RADIX FLT_ROUNDS FLT_EVAL_METHOD DECIMAL_DIG  DBL_DIG DBL_EPSILON DBL_MANT_DIG DBL_MAX DBL_MAX_10_EXP DBL_MAX_EXP DBL_MIN DBL_MIN_10_EXP DBL_MIN_EXP  FLT_DIG FLT_EPSILON FLT_MANT_DIG FLT_MAX FLT_MAX_10_EXP FLT_MAX_EXP FLT_MIN FLT_MIN_10_EXP FLT_MIN_EXP LDBL_DIG LDBL_EPSILON LDBL_MANT_DIG LDBL_MAX LDBL_MAX_10_EXP LDBL_MAX_EXP LDBL_MIN LDBL_MIN_10_EXP LDBL_MIN_EXP PRId8 PRId16 PRId32 PRId64 PRIdFAST8 PRIdFAST16 PRIdFAST32 PRIdFAST64 PRIdLEAST8 PRIdLEAST16 PRIdLEAST32 PRIdLEAST64 PRIdMAX PRIdPTR PRIi8 PRIi16 PRIi32 PRIi64 PRIiFAST8 PRIiFAST16 PRIiFAST32 PRIiFAST64 PRIiLEAST8 PRIiLEAST16 PRIiLEAST32 PRIiLEAST64 PRIiMAX PRIiPTR PRIo8 PRIo16 PRIo32 PRIo64 PRIoFAST8 PRIoFAST16 PRIoFAST32 PRIoFAST64 PRIoLEAST8 PRIoLEAST16 PRIoLEAST32 PRIoLEAST64 PRIoMAX PRIoPTR PRIu8 PRIu16 PRIu32 PRIu64 PRIuFAST8 PRIuFAST16 PRIuFAST32 PRIuFAST64 PRIuLEAST8 PRIuLEAST16 PRIuLEAST32 PRIuLEAST64 PRIuMAX PRIuPTR PRIx8 PRIx16 PRIx32 PRIx64 PRIxFAST8 PRIxFAST16 PRIxFAST32 PRIxFAST64 PRIxLEAST8 PRIxLEAST16 PRIxLEAST32 PRIxLEAST64 PRIxMAX PRIxPTR PRIX8 PRIX16 PRIX32 PRIX64 PRIXFAST8 PRIXFAST16 PRIXFAST32 PRIXFAST64 PRIXLEAST8 PRIXLEAST16 PRIXLEAST32 PRIXLEAST64 PRIXMAX PRIXPTR SCNd8 SCNd16 SCNd32 SCNd64 SCNdFAST8 SCNdFAST16 SCNdFAST32 SCNdFAST64 SCNdLEAST8 SCNdLEAST16 SCNdLEAST32 SCNdLEAST64 SCNdMAX SCNdPTR SCNi8 SCNi16 SCNi32 SCNi64 SCNiFAST8 SCNiFAST16 SCNiFAST32 SCNiFAST64 SCNiLEAST8 SCNiLEAST16 SCNiLEAST32 SCNiLEAST64 SCNiMAX SCNiPTR SCNo8 SCNo16 SCNo32 SCNo64 SCNoFAST8 SCNoFAST16 SCNoFAST32 SCNoFAST64 SCNoLEAST8 SCNoLEAST16 SCNoLEAST32 SCNoLEAST64 SCNoMAX SCNoPTR SCNu8 SCNu16 SCNu32 SCNu64 SCNuFAST8 SCNuFAST16 SCNuFAST32 SCNuFAST64 SCNuLEAST8 SCNuLEAST16 SCNuLEAST32 SCNuLEAST64 SCNuMAX SCNuPTR SCNx8 SCNx16 SCNx32 SCNx64 SCNxFAST8 SCNxFAST16 SCNxFAST32 SCNxFAST64 SCNxLEAST8 SCNxLEAST16 SCNxLEAST32 SCNxLEAST64 SCNxMAX SCNxPTR SCNX8 SCNX16 SCNX32 SCNX64 SCNXFAST8 SCNXFAST16 SCNXFAST32 SCNXFAST64 SCNXLEAST8 SCNXLEAST16 SCNXLEAST32 SCNXLEAST64 SCNXMAX SCNXPTR LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERC LC_TIME CHAR_BIT CHAR_MAX CHAR_MIN SCHAR_MAX SCHAR_MIN UCHAR_MAX MB_LEN_MAX SHRT_MAX SHRT_MIN USHRT_MAX INT_MAX INT_MIN UINT_MAX LONG_MAX LONG_MIN ULONG_MAX LLONG_MAX LLONG_MIN ULLONG_MAX SIGABRT SIGFPE SIGILL SIGINT SIGSEGV SIGTERM SIG_DFL SIG_IGN SIG_ERR NULL ptrdiff_t int8_t int16_t int32_t int64_t int_fast8_t int_fast16_t int_fast32_t int_fast64_t int_least8_t int_least16_t int_least32_t int_least64_t uint8_t uint16_t uint32_t uint64_t uint_fast8_t uint_fast16_t uint_fast32_t uint_fast64_t uint_least8_t uint_least16_t uint_least32_t uint_least64_t intmax_t intptr_t uintmax_t uintptr_t INT8_C INT16_C INT32_C INT64_C INT8_MAX INT16_MAX INT32_MAX INT64_MAX INT8_MIN INT16_MIN INT32_MIN INT64_MIN INT_FAST8_MAX INT_FAST16_MAX INT_FAST32_MAX INT_FAST64_MAX INT_FAST8_MIN INT_FAST16_MIN INT_FAST32_MIN INT_FAST64_MIN INT_LEAST8_MAX INT_LEAST16_MAX INT_LEAST32_MAX INT_LEAST64_MAX INT_LEAST8_MIN INT_LEAST16_MIN INT_LEAST32_MIN INT_LEAST64_MIN UINT8_C UINT16_C UINT32_C UINT64_C UINTMAX_C UINT8_MAX UINT16_MAX UINT32_MAX UINT64_MAX UINT_FAST8_MAX UINT_FAST16_MAX UINT_FAST32_MAX UINT_FAST64_MAX UINT_LEAST8_MAX UINT_LEAST16_MAX UINT_LEAST32_MAX UINT_LEAST64_MAX INTMAX_C INTMAX_MAX INTMAX_MIN INTPTR_MAX INTPTR_MIN PTRDIFF_MAX PTRDIFF_MIN SIG_ATOMIC_MAX SIG_ATOMIC_MIN SIZE_MAX WCHAR_MAX WCHAR_MIN WINT_MAX WINT_MIN UINTMAX_MAX UINTPTR_MAX  char16_t size_t wchar_t WCHAR_MAX WCHAR_MIN WEOF APIENTRY ATOM BOOL BOOLEAN BYTE CALLBACK CCHAR CHAR COLORREF CONST DWORD DWORDLONG DWORD_PTR DWORD32 DWORD64 FLOAT HACCEL HALF_PTR HANDLE HBITMAP HBRUSH HCOLORSPACE HCONV HCONVLIST HCURSOR HDC HDDEDATA HDESK HDROP HDWP HENHMETAFILE HFILE HFONT HGDIOBJ HGLOBAL HHOOK HICON HINSTANCE HKEY HKL HLOCAL HMENU HMETAFILE HMODULE HMONITOR HPALETTE HPEN HRESULT HRGN HRSRC HSZ HWINSTA HWND INT INT_PTR INT8 INT16 INT32 INT64 LANGID LCID LCTYPE LGRPID LONG LONGLONG LONG_PTR LONG32 LONG64 LPARAM LPBOOL LPBYTE LPCOLORREF LPCSTR LPCTSTR LPCVOID LPCWSTR LPDWORD LPHANDLE LPINT LPLONG LPSTR LPTSTR LPVOID LPWORD LPWSTR LRESULT PBOOL PBOOLEAN PBYTE PCHAR PCSTR PCTSTR PCWSTR PDWORD PDWORDLONG PDWORD_PTR PDWORD32 PDWORD64 PFLOAT PHALF_PTR PHANDLE PHKEY PINT PINT_PTR PINT8 PINT16 PINT32 PINT64 PLCID PLONG PLONGLONG PLONG_PTR PLONG32 PLONG64 POINTER_32 POINTER_64 POINTER_SIGNED POINTER_UNSIGNED PSHORT PSIZE_T PSSIZE_T PSTR PTBYTE PTCHAR PTSTR PUCHAR PUHALF_PTR PUINT PUINT_PTR PUINT8 PUINT16 PUINT32 PUINT64 PULONG PULONGLONG PULONG_PTR PULONG32 PULONG64 PUSHORT PVOID PWCHAR PWORD PWSTR QWORD SC_HANDLE SC_LOCK SERVICE_STATUS_HANDLE SHORT SIZE_T SSIZE_T TBYTE TCHAR UCHAR UHALF_PTR UINT UINT_PTR UINT8 UINT16 UINT32 UINT64 ULONG ULONGLONG ULONG_PTR ULONG32 ULONG64 UNICODE_STRING USHORT USN VOID WCHAR WINAPI WORD WPARAM FILE fpos_t size_t stdin stdout stderr EOF BUFSIZ FILENAME_MAX FOPEN_MAX _IOFBF _IOLBF _IONBF L_tmpnam NULL SEEK_CUR SEEK_END SEEK_SET TMP_MAX __FILE__ __LINE__ __func__

#~~ isoC99 API + GCC special functions
secondary=assert cacos cacosf cacosl cacosh cacoshf cacoshl carg cargf cargl casin casinf casinl casinh cainhf casinhl catan catanf catanl ccos ccosf ccosl ccosh ccoshf ccoshl cexp cexpf cexpl cimag cimagf cimagl clog clogf clogl coj conjf conjl cpow cpowf cpowl cproj cprojl creal crealf creall csin csinf csinl csinh csinhf csinhl csqrt csqrtf csqrtl ctan ctanf ctanl ctanh ctanhf ctanhl isalnum isalpha iscntrl isdigit isgraph islower isprint ispunct isspace isupper isxdigit isascii tolower toupper toascii errno fegetenv feholdexcept fesetenv feupdateenv feclearexcept fegetexceptflag feraiseexcept fesetexceptflag fetestexcept fegetround fesetround abs div imaxabs imaxdiv imaxdiv_t strtoimax strtoumax wcstoimax wcstoumax decimal_point thousands_sep grouping int_curr_symbol currency_symbol mon_decimal_point mon_thousands_sep mon_grouping positive_sign negative_sign int_frac_digits frac_digits p_cs_precedes int_p_cs_precedes p_sep_by_space int_p_sep_by_space n_cs_precedes int_n_cs_precedes p_sign_posn n_sign_posn int_n_sign_posn (const) acos acosh asin asinh atan atan atanh cbrt ceil copysign cos cosh erf erfc exp exp expm fabs fdim floor fma fmax fmin fmod fpclassify frexp hypot ilogb isfinite isgreater isgreaterequal isinf isless islessequal islessgreater isnan isnormal isunordered ldexp lgamma llrint llround logp log log log logb lrint lround modf nan nearbyint nextafter nexttoward pow remainder remquo rint round scalbln scalbn signbit sin sinh sqrt tan tanh tgamma trunc longjmp setjmp raise va_list va_start va_arg va_end va_copy offsetof clearerr fclose feof ferror fflush fgetc fgetpos fgets fopen fprintf fputc fputs fread freopen fscanf fseek fsetpos ftell fwrite vfprintf vsprintf getc vfscanf getchar gets perror printf putc putchar puts remove rename rewind scanf setbuf setvbuf snprintf sprintf sscanf tmpfile tmpnam ungetc vprintf vsnprintf vscanf vsscanf abort abs atexit atof atoi atol atoll bsearch calloc div Exit exit free getenv labs ldiv llabs lldiv malloc mblen mbstowcs mbtowc qsort rand realloc srand strtod strtof strtol strtold strtoll strtoul strtoull system wctomb wcstombs toupper tolower strxfrm strtoull strtoul strtold strtol strtol strtok strtof strtod strstr strstr strspn strspn strrchr strpbrk strok (strncpy) strncmp strncat strncat strlen strlen strerror strcspn strcpy strcoll strcmp strchr strcat memset memmove memcpy memcmp memchr mbtowc mbstowcs mblen asctime clock ctime difftime gmtime localeconf localtime mktime setlocale strftime time c16rtomb c32rtomb mbrtoc16 mbrtoc32 btowc fgetwc fgetws fputwc fputws fwide fwprintf fwscanf getwc getwchar mbrlen mbrtowc mbsinit mbsrtowcs mbstate_t putwc putwchar (size_t) swprintf swscanf tm ungetwc vfwprintf vfwscanf vswprintf vswscanf vwprintf vwscanf (wchar_t) wcrtomb wcscat wcschr wcscmp wcscoll wcscpy wcscspn wcsftime wcslen wcsncat wcsncmp wcsncpy wcspbrk wcsrchr wcsrtombs wcsspn wcsstr wcstod wcstof wcstok wcstold wcstol wcstoll wcstoul wcstoull wcsxfrm wctob wint_t wmemchr wmemcmp wmemcpy wmemmove wmemset wprintf wscanf iswalnum iswalpha iswblank iswcntrl iswdigit iswgraph iswlower iswprint iswpunct iswspace iswupper iswxdigit towlower _Exit acoshf acoshl acosh asinhf asinhl asinh atanhf atanhl atanh cabsf cabsl cabs cacosf cacoshf cacoshl cacosh cacosl cacos cargf cargl carg casinf casinhf casinhl casinh casinl casin catanf catanhf catanhl catanh catanl catan cbrtf cbrtl cbrt ccosf ccoshf ccoshl ccosh ccosl ccos cexpf cexpl cexp cimagf cimagl cimag clogf clogl clog conjf conjl conj copysignf copysignl copysign cpowf cpowl cpow cprojf cprojl cproj crealf creall creal csinf csinhf csinhl csinh csinl csin csqrtf csqrtl csqrt ctanf ctanhf ctanhl ctanh ctanl ctan erfcf erfcl erfc erff erfl erf exp2f exp2l exp2 expm1f expm1l expm1 fdimf fdiml fdim fmaf fmal fmaxf fmaxl fmax fma fminf fminl fmin hypotf hypotl hypot ilogbf ilogbl ilogb imax abs isblank iswblank lgammaf lgammal lgamma llabs llrintf llrintl llrint llroundf llroundl llround log1pf log1pl log1p log2f log2l log2 logbf logbl logb lrintf lrintl lrint lroundf lroundl lround nearbyintf nearbyintl nearbyint nextafterf nextafterl nextafter nexttowardf nexttowardl nexttoward remainderf remainderl remainder remquof remquol remquo rintf rintl rint roundf roundl round scalblnf scalblnl scalbln scalbnf scalbnl scalbn snprintf tgammaf tgammal tgamma truncf truncl trunc vfscanf vscanf vsnprintf vsscanf _exit alloca bcmp bzero dcgettext dgettext dremf dreml drem exp10f exp10l exp10 ffsll ffsl ffs fprintf_unlocked fputs_unlocked gammaf gammal gamma gammaf_r gammal_r gamma_r gettext index isascii j0f j0l j0 j1f j1l j1 jnf jnl jn lgammaf_r lgammal_r lgamma_r mempcpy pow10f pow10l pow10 printf_unlocked rindex scalbf scalbl scalb signbit signbitf signbitl signbitd32 signbitd64 signbitd128 significandf significandl significand sincosf sincosl sincos stpncpy strcasecmp strdup strfmon strncasecmp strndup toascii y0f y0l y0 y1f y1l y1 ynf ynl yn

# these are the Doxygen keywords
docComment=a addindex addtogroup anchor arg attention author authors b brief bug c callergraph callgraph category cite class code cond copybrief copydetails copydoc copyright date def defgroup deprecated details dir dontinclude dot dotfile e else elseif em endcode endcond enddot endhtmlonly endif endinternal endlatexonly endlink endmanonly endmsc endrtfonly endverbatim endxmlonly enum example exception extends file fn headerfile hideinitializer htmlinclude htmlonly if ifnot image implements include includelineno ingroup interface internal invariant latexonly li line link mainpage manonly memberof msc mscfile n name namespace nosubgrouping note overload p package page par paragraph param post pre private privatesection property protected protectedsection protocol public publicsection ref related relatedalso relates relatesalso remark remarks result return returns retval rtfonly sa section see short showinitializer since skip skipline snippet struct subpage subsection subsubsection tableofcontents test throw throws todo tparam typedef union until var verbatim verbinclude version warning weakgroup xmlonly xrefitem

[lexer_properties]
styling.within.preprocessor=1
lexer.cpp.track.preprocessor=0

[settings]
# default extension used when saving files
extension=c

# MIME type
mime_type=text/x-csrc

# the following characters are these which a "word" can contains, see documentation
#wordchars=_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789

# single comments, like # in this file
comment_single=//
# multiline comments
comment_open=/*
comment_close=*/

# set to false if a comment character/string should start at column 0 of a line, true uses any
# indentation of the line, e.g. setting to true causes the following on pressing CTRL+d
	#command_example();
# setting to false would generate this
#	command_example();
# This setting works only for single line comments
comment_use_indent=true

# context action command (please see Geany's main documentation for details)
context_action_cmd=

[indentation]
#width=4
# 0 is spaces, 1 is tabs, 2 is tab & spaces
#type=1

[build-menu]
# %f will be replaced by the complete filename
# %e will be replaced by the filename without extension
# (use only one of it at one time)
FT_00_LB=_Compile
FT_00_CM=gcc -Wall -c "%f"
FT_00_WD=
FT_01_LB=_Build
FT_01_CM=gcc -Wall -o "%e" "%f"
FT_01_WD=
FT_02_LB=_Lint
FT_02_CM=cppcheck --language=c --enable=warning,style --template=gcc "%f"
FT_02_WD=
EX_00_LB=_Execute
EX_00_CM="./%e"
EX_00_WD=
