# Makefile for Commander X16 Pac-Man

# Tools
CC65 = cl65
X16EMU = x16emu

# Flags
EMUFLAGS = -run

# Files
MAIN_SOURCE = pacman_x16.asm
OUTPUT = pacman.prg

# Default target
all: $(OUTPUT)

# Build the program
$(OUTPUT): $(MAIN_SOURCE)
	$(CC65) -t cx16 -o $@ $(MAIN_SOURCE)

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
