# Makefile for Commander X16 Pac-Man

# Tools
CC65 = cl65
X16EMU = x16emu

# Flags
CFLAGS = -C cx16-custom.cfg
EMUFLAGS = -run

# Files
SOURCES = pacman_x16.asm pacman_data.asm
OUTPUT = pacman.prg

# Default target
all: $(OUTPUT)

# Build the program
$(OUTPUT): $(SOURCES) cx16-custom.cfg
	$(CC65) $(CFLAGS) -o $@ $(SOURCES)

# Run in the emulator
run: $(OUTPUT)
	$(X16EMU) -prg $< $(EMUFLAGS)

# Run with debugger
debug: $(OUTPUT)
	$(X16EMU) -prg $< $(EMUFLAGS) -debug

# Clean build artifacts
clean:
	rm -f $(OUTPUT)

.PHONY: all run debug clean
