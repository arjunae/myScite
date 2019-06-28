# simple Gnu-Makefile for dbghelper. Works for Linux, MacOS X, probably other unixen
#
# Gunnar Zötl <gz@tset.de>, 2012.
# Released under the terms of the MIT license.

# try some automatic discovery
OS = $(shell uname -s)
LUADIR = $(shell dirname `which lua`)
LUAROOT = $(shell dirname $(LUADIR))

LUA_51_SRC = ../lua-5.1.4/src
LUA_52_SRC = ../lua-5.2.0/src
LUA_SRC = $(LUA_51_SRC)

LUA_INC_DIR=-I$(LUAROOT)/include
LUA_LIB_DIR=-L$(LUAROOT)/lib

INC_DIRS=$(LUA_INC_DIR) -I$(LUA_SRC)
LIB_DIRS=$(LUA_LIB_DIR)

# Defaults
CC = gcc
DEBUG= #-g -lefence
CFLAGS=-O2 -fPIC $(DEBUG)
INCDIRS=-I$(LUAROOT)/include
LIBDIRS=-L$(LUAROOT)/lib
LDFLAGS=-shared $(DEBUG)

# OS specialities
ifeq ($(OS),Darwin)
LDFLAGS=-bundle -undefined dynamic_lookup -all_load $(DEBUG)
endif

all:	dbghelper.so

dbghelper.o: dbghelper.c
	$(CC) $(CFLAGS) ${INC_DIRS} -c $< -o $@

dbghelper.so: dbghelper.o
	$(CC) $(LDFLAGS) -o $@ ${LIB_DIRS} $<

clean:
	find . -name "*~" -exec rm {} \;
	rm -f *.o *.so *.func *.ps core
	for dir in . doc samples; \
	do \
		rm -f $dir/.DS_Store; \
		rm -f $dir/._*; \
	done

