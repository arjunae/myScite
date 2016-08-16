INCLUDES  = -I../lua/5.1/include
LIBS      = ..\lib\lua5.1.dll ..\lib\libscite.a
DEFINES   = -DNDEBUG
CFLAGS    = -O2 $(DEFINES) $(INCLUDES)
LDFLAGS   = -s -shared -static-libgcc -static-libstdc++ 

CC        = gcc
RM        = del

SRC       = lfs.c
TARGET    = lfs.dll
OBJECTS   = lfs.o

all: $(TARGET)

$(OBJECTS): $(SRC)
	$(CC) $(CFLAGS) -o $@ -c $<

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJECTS) $(LIBS)

clean:
	-$(RM) $(OBJECTS)
