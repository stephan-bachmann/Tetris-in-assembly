ASM = nasm
ASMFLAGS = -felf64 -g -F dwarf
LD = ld

OBJS = main.o func.o data.o util.o graphic.o
TARGET = app

all: $(TARGET)

%.o: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

$(TARGET): $(OBJS)
	$(LD) -o $@ $(OBJS)

clean:
	rm -f $(OBJS) $(TARGET)
