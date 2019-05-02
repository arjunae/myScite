LUA_INCLUDE = ../lua/5.1/src/
LUA_LIB =-L ../clib/ -lscite

CC	= gcc
STRIP	= strip
TARGET	= crc32.so
OBJS	=  crc32.o wrap.o
CFLAGS	= -I . -I $(LUA_INCLUDE) -fPIC
LDFLAGS	= -shared -fPIC  

default: $(TARGET)


clean:
	del $(OBJS) $(TARGET) 

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LUA_LIB)
	$(STRIP) $(TARGET)

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@
