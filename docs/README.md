# Commander X16 Pac-Man Port

This project is a faithful recreation of the classic Pac-Man arcade game for the Commander X16 retro computer, implemented in 6502 assembly language.

## Project Structure

- `pacman_x16.asm` - Main assembly code file containing initialization, VERA setup, and game logic
- `pacman_data.asm` - Data file containing all game assets (tiles, sprites, colors, audio)
- `cx16-custom.cfg` - Custom linker configuration for the Commander X16
- `Makefile` - Build automation for compiling and running the game

## Building and Running

```bash
# Build the game
make

# Run in the emulator
make run

# Run with debugger
make debug
```

## Technical Details

### Memory Map

- Zero Page: Used for frequently accessed variables and pointers
- VRAM Addresses:
  - Tilemap Base: $B000
  - Sprite/Tileset Data: $A000

### VERA Configuration

The game uses VERA's bitmap mode with 8bpp color depth. Key registers:
- VERA_CTRL ($9F25) - Control register
- VERA_DC_VIDEO ($9F29) - Display Composer video settings
- VERA_L0_CONFIG ($9F2D) - Layer 0 configuration
- VERA_L0_MAPBASE ($9F2E) - Layer 0 map base address
- VERA_L0_TILEBASE ($9F2F) - Layer 0 tile base address

### Game Assets

- Tiles: 4096 bytes (64 sprites of 64 bytes each)
- Sprites: 4096 bytes (64 sprites of 64 bytes each)
- Hardware Colors: 32 bytes
- Palette Lookup Table: 256 bytes
- Wavetable: 256 bytes for audio waveform synthesis
- Sound Data: Prelude (1960 bytes) and Death sequence (360 bytes)

## Development Roadmap

1. Stage One (Current): Basic initialization, VERA setup, and asset loading
2. Stage Two: Implement player movement and collision detection
3. Stage Three: Add ghost AI and game logic
4. Stage Four: Implement sound and scoring system
