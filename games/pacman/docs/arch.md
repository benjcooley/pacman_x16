# PAC-MAN X16 ARCHITECTURE

## Overview

This document defines the technical architecture for implementing a frame-perfect recreation of Pac-Man on the Commander X16. The architecture leverages the X16's VERA graphics chip, 65C02 CPU, and available memory to create an authentic Pac-Man experience while utilizing modern hardware capabilities.

## Hardware Foundation

### Commander X16 Specifications
- **CPU**: 65C02 @ 8MHz
- **Graphics**: VERA (Versatile Embedded Retro Adapter)
- **Memory**: 512KB-2MB RAM, 512KB ROM
- **Audio**: VERA PSG (16 voices) + PCM
- **Input**: PS/2 keyboard via VIA controllers

### Original Pac-Man Specifications
- **Display**: 224×288 pixels (28×36 tiles of 8×8 pixels)
- **Colors**: 16 colors from custom palette
- **Sprites**: 8 sprites (Pac-Man + 4 ghosts + bonus items)
- **Audio**: 3-voice Namco WSG sound generator
- **Framerate**: 60.6 Hz

## VERA Graphics Architecture

### Display Configuration
```
Resolution: 640×480 (VGA mode)
Effective Game Area: 224×288 (centered with border)
Scaling: 2x pixel scaling for crisp retro appearance
Color Depth: 4bpp (16 colors, perfect for Pac-Man)
```

### Layer Configuration

#### Layer 0 - Maze Tilemap
```
Mode: Tilemap
Map Size: 32×64 tiles (accommodates 28×36 maze)
Tile Size: 8×8 pixels
Color Depth: 4bpp
Map Base: $B000 (VRAM)
Tile Base: $F000 (VRAM)
Scrolling: Disabled (static maze)
```

#### Layer 1 - Reserved
```
Status: Disabled (not needed for Pac-Man)
Future Use: Potential overlay graphics, debug info
```

### Sprite System

#### Sprite Allocation
```
Sprite 0: Pac-Man (16×16, animated, 4 directions)
Sprite 1: Blinky (16×16, animated, 4 directions + frightened)
Sprite 2: Pinky (16×16, animated, 4 directions + frightened)
Sprite 3: Inky (16×16, animated, 4 directions + frightened)
Sprite 4: Clyde (16×16, animated, 4 directions + frightened)
Sprite 5: Bonus Fruit (16×16, static, 8 fruit types)
Sprite 6: Score Display (16×16, 200/400/800/1600 points)
Sprite 7: Reserved (future use)
```

#### Sprite Attributes
```
Size: 16×16 pixels (matches original)
Color Mode: 4bpp
Z-Depth: Layer 3 (in front of tilemap)
Animation: 2-4 frames per direction
Collision: Pixel-perfect using tile coordinates
```

### VRAM Memory Layout

```
Address Range    | Size    | Purpose
-----------------|---------|----------------------------------
$0000-$AFFF     | 44KB    | Reserved/Future expansion
$B000-$BFFF     | 4KB     | Tilemap data (28×36 = 1008 bytes used)
$C000-$EFFF     | 12KB    | Reserved
$F000-$F7FF     | 2KB     | Tile graphics data (256 tiles × 32 bytes)
$F800-$F9BF     | 448B    | Reserved
$F9C0-$F9FF     | 64B     | PSG registers
$FA00-$FBFF     | 512B    | Color palette (256 × 2 bytes)
$FC00-$FFFF     | 1KB     | Sprite attributes (128 × 8 bytes)
```

### Color Palette

#### Original Pac-Man Colors (16 colors)
```
Index | Color      | RGB (12-bit) | Usage
------|------------|--------------|------------------
0     | Black      | $000         | Background/transparent
1     | Red        | $F00         | Blinky, cherries
2     | Pink       | $FBB         | Pinky
3     | Cyan       | $0FF         | Inky
4     | Orange     | $FB0         | Clyde
5     | Yellow     | $FF0         | Pac-Man
6     | Blue       | $00F         | Maze walls
7     | White      | $FFF         | Dots, text
8     | Brown      | $A50         | Maze details
9     | Green      | $0F0         | Bonus items
10    | Purple     | $F0F         | Bonus items
11    | Gray       | $888         | Ghost eyes
12    | Lt Blue    | $8FF         | Frightened ghosts
13    | Lt Gray    | $CCC         | Score text
14    | Dk Blue    | $008         | Tunnel
15    | Lt Yellow  | $FF8         | Power pills
```

## CPU Memory Architecture

### Zero Page Variables ($00-$FF)
```
Address | Size | Purpose
--------|------|----------------------------------
$00-$01 | 2B   | Banking registers
$02     | 1B   | game_state (INIT/ATTRACT/GAME/OVER)
$03     | 1B   | pacman_x (pixel position)
$04     | 1B   | pacman_y (pixel position)
$05     | 1B   | pacman_dir (0=RIGHT,1=DOWN,2=LEFT,3=UP)
$06-$08 | 3B   | score (24-bit BCD)
$09     | 1B   | lives (remaining lives)
$0A     | 1B   | level (current level)
$0B-$0E | 4B   | ghost_x[4] (ghost X positions)
$0F-$12 | 4B   | ghost_y[4] (ghost Y positions)
$13-$16 | 4B   | ghost_dir[4] (ghost directions)
$17-$1A | 4B   | ghost_state[4] (AI states)
$1B     | 1B   | dots_remaining
$1C     | 1B   | pill_timer (energizer effect)
$1D     | 1B   | bonus_fruit_type
$1E     | 1B   | game_timer (60Hz tick counter)
$1F     | 1B   | input_state (current input)
$20-$7F | 96B  | Available for additional variables
$80-$FF | 128B | System reserved
```

### Main Memory Layout
```
Address Range | Size  | Purpose
--------------|-------|----------------------------------
$0200-$03FF   | 512B  | Core game routines
$0400-$07FF   | 1KB   | Game logic and AI
$0800-$9EFF   | 37KB  | Extended game code (if needed)
$A000-$BFFF   | 8KB   | Banked RAM (future expansion)
```

### Banking Strategy
```
Bank 0: System (KERNAL variables)
Bank 1: Game data (default)
Banks 2-255: Available for expansion
```

## Audio Architecture

### VERA PSG Configuration
```
Voice 0: Pac-Man sounds (eating, movement)
Voice 1: Ghost sounds (siren, frightened)
Voice 2: Game events (death, bonus, start)
Voices 3-15: Reserved for future expansion
```

### Sound Effect Implementation

#### Procedural Sounds (Real-time generation)
```
Dot Eating: Alternating frequency sweep (voices 0)
Ghost Eating: Rising frequency with noise (voice 2)
Fruit Bonus: Complex frequency pattern (voice 2)
Siren: Continuous up/down sweep (voice 1)
Frightened: Rapid frequency modulation (voice 1)
```

#### Register Dump Sounds (Pre-recorded sequences)
```
Game Start: Multi-voice musical sequence
Death: Complex descending pattern
Level Complete: Victory fanfare
```

### Audio Parameters
```
Sample Rate: 48.828 kHz (25MHz ÷ 512)
Bit Depth: 4-bit volume, 20-bit frequency
Waveforms: Pulse, Sawtooth, Triangle, Noise
Voices Used: 3 of 16 available
```

## Input System

### Keyboard Mapping
```
Arrow Keys / WASD: Directional movement
Space: Pause/Resume
Enter: Start game
Escape: Return to attract mode
1: One player game
2: Two player game (future)
```

### Input Processing
```
Scan Rate: 60Hz (synchronized with game tick)
Debouncing: 2-frame minimum press duration
Buffering: 1-frame lookahead for smooth movement
Priority: Most recent input takes precedence
```

## Game Loop Architecture

### Master Timing
```
Game Tick: 60Hz (16.67ms intervals)
Display Sync: VSync locked
Audio Sync: Sample-accurate timing
Input Sync: Polled each game tick
```

### State Machine
```
States: INIT → ATTRACT → GAME → GAMEOVER → ATTRACT
Transitions: Input-driven and timer-based
Persistence: High score saved to NVRAM
```

### Actor Movement System
```
Position: Pixel-accurate (224×288 coordinate system)
Speed: Variable based on game state and character
Collision: Tile-based with pixel-perfect detection
Animation: Frame-based, synchronized to movement
```

## Data Conversion Pipeline

### Tile Data Extraction
```
Source: ROM dumps from reference/pacman.c
Format: 8×8 pixels, 2bpp → 4bpp conversion
Layout: Linear tile array (256 tiles max)
Encoding: VERA-compatible 4bpp format
```

### Sprite Data Conversion
```
Source: 16×16 sprites from ROM dumps
Composition: 4×(8×8) tile blocks
Animation: Multiple frames per sprite
Storage: VRAM sprite data area
```

### Maze Layout Processing
```
Source: ASCII maze map in reference code
Output: Tile index array (28×36)
Features: Wall detection, dot placement, special tiles
Collision: Separate collision map for pathfinding
```

### Audio Data Integration
```
Source: Wavetable ROM dumps
Format: 8×32 sample wavetables
Integration: Embedded in program ROM
Usage: Real-time waveform synthesis
```

## Performance Optimization

### Target Specifications
```
Framerate: 60fps (consistent)
Input Lag: <1 frame (16.67ms)
Audio Latency: <10ms
Memory Usage: <40KB program + 8KB data
```

### Optimization Strategies

#### CPU Optimization
```
- Zero page variables for frequently accessed data
- Lookup tables for trigonometry and movement
- Unrolled loops for critical sections
- Efficient 6502 instruction selection
```

#### VERA Optimization
```
- Minimal VRAM writes per frame
- Batch sprite attribute updates
- Efficient palette management
- Optimized tile upload procedures
```

#### Memory Optimization
```
- Compact data structures
- Shared buffers where possible
- Minimal dynamic allocation
- Efficient banking usage
```

## Development Phases

### Phase 1: Foundation ✅
- VERA initialization
- Basic memory layout
- Game state framework
- Visual feedback system

### Phase 2: Graphics System
- Tile data conversion and upload
- Tilemap rendering
- Sprite system implementation
- Color palette setup

### Phase 3: Game Logic
- Maze rendering and collision
- Pac-Man movement and animation
- Dot eating mechanics
- Score system

### Phase 4: AI Implementation
- Ghost AI state machines
- Pathfinding algorithms
- Collision detection
- Game timing

### Phase 5: Audio Integration
- PSG voice allocation
- Sound effect implementation
- Music playback system
- Audio synchronization

### Phase 6: Polish & Optimization
- Performance tuning
- Bug fixes
- Attract mode
- Final testing

## Technical Constraints

### Hardware Limitations
```
CPU Speed: 8MHz 65C02 (adequate for 60fps)
VRAM: 128KB (sufficient for all graphics)
Sprites: 128 available (8 needed)
Colors: 256 from 4096 (16 needed)
```

### Compatibility Requirements
```
X16 ROM: R47 or later
RAM: Minimum 512KB
Storage: SD card for save data
Display: VGA monitor recommended
```

### Accuracy Targets
```
Timing: Frame-perfect to original
Graphics: Pixel-perfect reproduction
Audio: Waveform-accurate synthesis
Gameplay: Identical to arcade original
```

## Future Expansion Possibilities

### Enhanced Features
```
- Multiple maze layouts
- Two-player simultaneous play
- Enhanced audio with PCM samples
- Save state functionality
- Statistics tracking
```

### Technical Improvements
```
- VERA FX utilization for effects
- Banked ROM for additional content
- Network play via expansion cards
- Custom controller support
```

## Conclusion

This architecture provides a solid foundation for implementing an authentic Pac-Man experience on the Commander X16. By leveraging the X16's modern capabilities while respecting the original game's design, we can create a faithful recreation that feels both nostalgic and technically impressive.

The modular design allows for incremental development and testing, ensuring each component works correctly before integration. The performance targets are achievable within the X16's capabilities, and the architecture supports future enhancements without major restructuring.

---

*Document Version: 1.0*  
*Last Updated: 2025-07-24*  
*Next Review: After Phase 2 completion*
