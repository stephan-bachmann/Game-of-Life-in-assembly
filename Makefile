ASM = nasm
ASMFLAGS = -felf64 -g -F dwarf
LD = ld

OBJS = main.o func.o data.o util.o
TARGET = app
INCS = structs.inc

all: $(TARGET)

%.o: %.asm $(INCS)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(TARGET): $(OBJS)
	$(LD) -o $@ $(OBJS)

clean:
	rm -f $(OBJS) $(TARGET)
