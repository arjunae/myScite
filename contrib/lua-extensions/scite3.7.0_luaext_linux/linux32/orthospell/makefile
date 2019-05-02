INCLUDES  = -I../lua/5.1/include -I include
LIBS      = -L ../lib/lua5.1.so ../lib/libscite.a libhunspell.a libparser.a
DEFINES   = -DNDEBUG
CFLAGS    = -O2 $(DEFINES) $(INCLUDES) -fPIC
LDFLAGS   = -s -shared -fPIC -static-libgcc -static-libstdc++ 

CC        = gcc
RM        = del

SOURCE       = hunspell.cpp
TARGET    = hunspell.so
OBJECTS   = hunspell.o

all: $(TARGET)

$(OBJECTS): $(SOURCE)
	$(CC) $(CFLAGS) -o $@ -c $<

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJECTS) $(LIBS)

clean:
	-$(RM) $(OBJECTS)
