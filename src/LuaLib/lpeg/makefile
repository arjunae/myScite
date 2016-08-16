INCLUDES  = -I../lua/5.1/include
LIBS      = -L../lib -lscite -L../_clib_bin/5.1/ -llua51
DEFINES   = -DNDEBUG
CFLAGS    = -O3 $(DEFINES) $(INCLUDES)
LDFLAGS   = -s -shared

CC        = gcc
RM        = del

SRC       = lpeg.c
TARGET    = lpeg.dll
OBJECTS   = lpeg.o

all: $(TARGET)

$(OBJECTS): $(SRC)
	$(CC) $(CFLAGS) -o $@ -c $<

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJECTS) $(LIBS)

clean:
	-$(RM) $(OBJECTS)
