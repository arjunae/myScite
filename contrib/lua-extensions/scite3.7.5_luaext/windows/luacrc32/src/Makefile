LUA_INCLUDE = ../lua/include/
LUA_LIB =-L ../clib/-lscite

CC	= gcc
STRIP	= strip
TARGET	= crc32.so
OBJS	= crc32.o wrap.o
CFLAGS	= -I . -I $(LUA_INCLUDE) -fPIC -DLUA_COMPAT_5_1 -DLUA_COMPAT_OPENLIB
LDFLAGS	= -shared -fPIC  

default: $(TARGET)


clean:
	del $(OBJS) $(TARGET) 

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LUA_LIB)
	$(STRIP) $(TARGET)

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@
