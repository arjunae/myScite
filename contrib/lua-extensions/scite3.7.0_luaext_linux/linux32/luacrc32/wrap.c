#include <stddef.h>
#include <stdint.h>

#include "lua.h"
#include "lauxlib.h"

#define VERSION "1.00"


/* -----copied from bit32.c: ----- */

/* ----- adapted from lua-5.2.0 luaconf.h: ----- */

/*
@@ LUA_UNSIGNED is the integral type used by lua_pushunsigned/lua_tounsigned.
** It must have at least 32 bits.
*/
#define LUA_UNSIGNED    unsigned LUAI_INT32

#if defined(LUA_NUMBER_DOUBLE) && !defined(LUA_ANSI)    /* { */

/* On a Microsoft compiler on a Pentium, use assembler to avoid clashes
   with a DirectX idiosyncrasy */
#if defined(LUA_WIN) && defined(_MSC_VER) && defined(_M_IX86)	/* { */

#define MS_ASMTRICK

#else                           /* }{ */
/* the next definition uses a trick that should work on any machine
   using IEEE754 with a 32-bit integer type */

#define LUA_IEEE754TRICK

/*
@@ LUA_IEEEENDIAN is the endianness of doubles in your machine
** (0 for little endian, 1 for big endian); if not defined, Lua will
** check it dynamically.
*/
/* check for known architectures */
#if defined(__i386__) || defined(__i386) || defined(__X86__) || \
    defined (__x86_64)
#define LUA_IEEEENDIAN  0
#elif defined(__POWERPC__) || defined(__ppc__)
#define LUA_IEEEENDIAN  1
#endif

#endif                          /* } */

#endif                  /* } */

/* ----- from lua-5.2.0 lua.h: ----- */

/* unsigned integer type */
typedef LUA_UNSIGNED lua_Unsigned;

/* ----- adapted from lua-5.2.0 llimits.h: ----- */

/* lua_number2unsigned is a macro to convert a lua_Number to a lua_Unsigned.
** lua_unsigned2number is a macro to convert a lua_Unsigned to a lua_Number.
*/

#if defined(MS_ASMTRICK)        /* { */
/* trick with Microsoft assembler for X86 */

#define lua_number2unsigned(i,n)  \
  {__int64 l; __asm {__asm fld n   __asm fistp l} i = (unsigned int)l;}

#elif defined(LUA_IEEE754TRICK)         /* }{ */
/* the next trick should work on any machine using IEEE754 with
   a 32-bit integer type */

union luai_Cast2 { double l_d; LUAI_INT32 l_p[2]; };

#if !defined(LUA_IEEEENDIAN)    /* { */
#define LUAI_EXTRAIEEE  \
  static const union luai_Cast2 ieeeendian = {-(33.0 + 6755399441055744.0)};
#define LUA_IEEEENDIAN          (ieeeendian.l_p[1] == 33)
#else
#define LUAI_EXTRAIEEE          /* empty */
#endif                          /* } */

#define lua_number2int32(i,n,t) \
  { LUAI_EXTRAIEEE \
    volatile union luai_Cast2 u; u.l_d = (n) + 6755399441055744.0; \
    (i) = (t)u.l_p[LUA_IEEEENDIAN]; }

#define lua_number2unsigned(i,n)        lua_number2int32(i, n, lua_Unsigned)

#endif                          /* } */

#if !defined(lua_number2unsigned)       /* { */
/* the following definition assures proper modulo behavior */
#if defined(LUA_NUMBER_DOUBLE)
#include <math.h>
#define SUPUNSIGNED     ((lua_Number)(~(lua_Unsigned)0) + 1)
#define lua_number2unsigned(i,n)  \
        ((i)=(lua_Unsigned)((n) - floor((n)/SUPUNSIGNED)*SUPUNSIGNED))
#else
#define lua_number2unsigned(i,n)        ((i)=(lua_Unsigned)(n))
#endif
#endif                          /* } */

/* on several machines, coercion from unsigned to double is slow,
   so it may be worth to avoid */
#define lua_unsigned2number(u)  \
    (((u) <= (lua_Unsigned)INT_MAX) ? (lua_Number)(int)(u) : (lua_Number)(u))

/* ----- adapted from lua-5.2.0 lapi.c: ----- */

static void lua_pushunsigned (lua_State *L, lua_Unsigned u) {
  lua_Number n;
  n = lua_unsigned2number(u);
  lua_pushnumber(L, n);
}

/* ----- adapted from lua-5.2.0-work3 lbitlib.c getuintarg(): ----- */

static lua_Unsigned luaL_checkunsigned (lua_State *L, int arg) {
  lua_Unsigned r;
  lua_Number x = lua_tonumber(L, arg);
  if (x == 0) luaL_checktype(L, arg, LUA_TNUMBER);
  lua_number2unsigned(r, x);
  return r;
}

/* -----End of copied from bit32.c ----- */



#include "crc32.h"


static const char *crc32_reg_name      = "ehj.crc32";

static void create_meta(lua_State *L, const char *name, const luaL_reg *lib) {
	luaL_newmetatable(L, name);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);               /* push metatable */
	lua_rawset(L, -3);                  /* metatable.__index = metatable */

	/* register metatable functions */
	luaL_register(L, NULL, lib);

	/* remove metatable from stack */
	lua_pop(L, 1);
}

static int Lcrc_reset(lua_State *L) {
	uint32_t *_crc32 = (uint32_t*) luaL_checkudata(L, 1, crc32_reg_name);
	*_crc32 = 0;
	lua_pop (L, lua_gettop(L)-1); // pop data, return userdata itself
	return 1;
}
static int Lcrc_update(lua_State *L) {
	uint32_t *_crc32 = (uint32_t*) luaL_checkudata(L, 1, crc32_reg_name);
	const uint8_t *data;
	size_t data_len;
	
	luaL_checktype(L, 2, LUA_TSTRING);
	data = lua_tolstring (L, 2, &data_len);
	*_crc32 = crc32(*_crc32, data, data_len );
	lua_pop (L, lua_gettop(L)-1); // pop data, return userdata itself
	return 1;
}

static int Lcrc_tonumber(lua_State *L) {
	uint32_t *_crc32 = (uint32_t*) luaL_checkudata(L, 1, crc32_reg_name);
	lua_pushunsigned(L, *_crc32);
	return 1;
}

static int Lcrc_tostring(lua_State *L) {
	uint32_t *_crc32 = (uint32_t*) luaL_checkudata(L, 1, crc32_reg_name);
	uint32_t crc_out = *_crc32;
	uint8_t crcout_str[4];
	int i;
	
	for (i = 3; i>=0; i--) {
		crcout_str[i] = crc_out & 0xff;
		crc_out>>=8;
	}

	lua_pushlstring (L, crcout_str, 4);
	return 1;
}

static int Lcrc_tohex(lua_State *L) {
	uint32_t *_crc32 = (uint32_t*) luaL_checkudata(L, 1, crc32_reg_name);
	uint8_t crcout_str[9];
	sprintf(crcout_str, "%8.8x", *_crc32);
	lua_pushlstring (L, crcout_str, 8);
	return 1;
}

static const luaL_reg crc32_meta_reg[] = {
	{"reset",      Lcrc_reset    },
	{"update",     Lcrc_update   },
	{"tonumber",   Lcrc_tonumber },
	{"tostring",   Lcrc_tostring },
	{"tohex",      Lcrc_tohex    },
	{NULL, NULL}
};


static int Lcrc32(lua_State *L) {
	uint32_t  crc_in, crc_out;
	const uint8_t *data;
	size_t data_len;
	
	luaL_checktype(L, 2, LUA_TSTRING);
	data = lua_tolstring (L, 2, &data_len);

	if (lua_type(L,1) == LUA_TSTRING) { 
		// input CRC as 4 byte string
		size_t crc_len;
		int i;
		const uint8_t *crcin_str = lua_tolstring(L,1, &crc_len);
		if (crc_len>4) crc_len = 4;
		crc_in = 0;
		for (i = 0; i < crc_len; i++) {
			crc_in<<=8;
			crc_in |=  crcin_str[i];
		}

		crc_out = crc32(crc_in, data, data_len );
			
		// return CRC as 4 byte string
		uint8_t crcout_str[4];

		for (i = 3; i>=0; i--) {
			crcout_str[i] = crc_out & 0xff;
			crc_out>>=8;
		}

		lua_pushlstring (L, crcout_str, 4);
	} else {
		crc_in = luaL_checkunsigned(L, 1);
		crc_out = crc32(crc_in, data, data_len );
		lua_pushunsigned(L, crc_out);
	}
	
	return 1;
}

static int Lnewcrc32(lua_State *L) {
	uint32_t *crc32 = (uint32_t *)lua_newuserdata(L, sizeof(uint32_t));
	if (luaL_newmetatable(L, crc32_reg_name)) {
		lua_pushstring(L, "__index");
		lua_pushvalue(L, -2);               /* push metatable */
		lua_rawset(L, -3);                  /* metatable.__index = metatable */

		/* register metatable functions */
		luaL_register(L, NULL, crc32_meta_reg);
	}
	lua_setmetatable(L, -2);
	*crc32 = 0;
	return 1;
}

static const luaL_reg Rcrc32[] = {
	{"crc32",     Lcrc32     },
	{"newcrc32",  Lnewcrc32  },
	{NULL, NULL}
};

LUALIB_API int luaopen_crc32(lua_State *L) {
	create_meta(L,crc32_reg_name, crc32_meta_reg);
	
	lua_newtable (L);
	luaL_register(L, NULL, Rcrc32);

	lua_pushliteral(L, VERSION);
	lua_setfield(L, -2, "version");
	return 1;
}
