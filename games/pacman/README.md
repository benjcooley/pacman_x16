# Pac-Man for Commander X16

A faithful recreation of the classic Pac-Man arcade game for the Commander X16, built using the X16 Game Development Framework.

## Overview

This implementation recreates the authentic Pac-Man experience on the Commander X16, featuring:

- **Authentic Gameplay**: Faithful recreation of original game mechanics
- **Tilemap-based Maze**: Efficient maze rendering using VERA tilemaps
- **Multi-sprite Animation**: Smooth character animation with VERA sprites
- **AI Ghost Behavior**: Classic ghost AI patterns and behaviors
- **Progressive Difficulty**: Increasing challenge through multiple levels
- **Score System**: Points, bonus items, and high score tracking

## Game Features

### Core Gameplay
- **Player Movement**: Smooth 4-direction movement with momentum
- **Maze Navigation**: 224 dots to collect across the classic maze layout
- **Power Pellets**: Temporary ghost vulnerability and point multipliers
- **Bonus Items**: Fruit bonuses with increasing point values
- **Lives System**: 3 lives with extra life bonuses

### Ghost AI
- **Blinky (Red)**: Aggressive direct pursuit of Pac-Man
- **Pinky (Pink)**: Ambush tactics, targets ahead of Pac-Man
- **Inky (Cyan)**: Complex behavior based on Blinky and Pac-Man positions
- **Clyde (Orange)**: Scatter/chase behavior with distance-based switching

### Visual Features
- **Authentic Graphics**: Pixel-perfect recreation of original sprites
- **Smooth Animation**: 60fps character animation
- **Color Accuracy**: Faithful color palette reproduction
- **UI Elements**: Score, lives, level indicators, and bonus displays

### Audio Features
- **Sound Effects**: Dot eating, power pellet, ghost eating, death sounds
- **Background Music**: Level start and intermission music
- **Audio Cues**: Directional audio feedback for game events

## Technical Implementation

### Architecture
Built on the X16 Game Development Framework:
- **Framework Integration**: Uses core X16 system and VERA graphics
- **Modular Design**: Separate modules for game logic, graphics, and audio
- **Efficient Memory Usage**: Optimized for X16's memory constraints
- **60fps Performance**: Smooth gameplay at full frame rate

### Graphics System
- **Tilemap Layer**: 28x31 tile maze representation
- **Sprite Layer**: Characters, dots, and bonus items
- **Palette Management**: Efficient color usage and animation
- **VRAM Layout**: Optimized memory organization

### Game Logic
- **State Machine**: Clean separation of game states
- **Collision Detection**: Efficient tile-based collision system
- **AI System**: Modular ghost behavior implementation
- **Score System**: Accurate point calculation and bonus tracking

## File Structure

```
games/pacman/
├── README.md              # This file
├── pacman_x16.asm        # Main game code
├── pacman_data.asm       # Graphics and game data
├── docs/                 # Game documentation
│   ├── arch.md          # Architecture documentation
│   └── progress.md      # Development progress
└── reference/           # Reference materials
    ├── pacman.c         # Original C reference
    ├── pacman.asm.txt   # Assembly reference
    └── sample9.asm      # X16 sample code
```

## Building and Running

### Prerequisites
- CC65 toolchain installed
- X16 emulator available
- Make utility

### Build Commands
```bash
# Build Pac-Man specifically
make GAME=pacman

# Build and run
make run GAME=pacman

# Clean build files
make clean
```

### Development Commands
```bash
# Run development loop
make enhanced-dev

# Analyze progress
make analyze

# Execute development plan
make execute-plan
```

## Game Controls

### Keyboard Controls
- **Arrow Keys**: Move Pac-Man (Up, Down, Left, Right)
- **WASD**: Alternative movement controls
- **Space**: Start game / Pause
- **Enter**: Confirm selections
- **Escape**: Exit to menu

### Gameplay
- **Objective**: Eat all dots while avoiding ghosts
- **Power Pellets**: Large dots that make ghosts vulnerable
- **Bonus Points**: Eat vulnerable ghosts for increasing points
- **Fruit Bonus**: Collect fruit for extra points
- **Level Progression**: Complete maze to advance to next level

## Development Status

### Completed Features
- [x] Framework integration and project structure
- [x] Basic game loop and state management
- [x] VERA graphics initialization
- [x] Tilemap and sprite system setup
- [x] Development tools and automation

### In Progress
- [ ] Maze rendering and collision detection
- [ ] Player movement and animation
- [ ] Ghost AI implementation
- [ ] Dot collection and scoring
- [ ] Audio system integration

### Planned Features
- [ ] Power pellet mechanics
- [ ] Bonus fruit system
- [ ] Level progression
- [ ] High score system
- [ ] Attract mode and menus
- [ ] Sound effects and music

## Technical Details

### Memory Usage
- **Zero Page**: Game state variables (starting at $10)
- **Main RAM**: Game logic and temporary data
- **VRAM Layout**:
  - `$10000-$13FFF`: Tile graphics data
  - `$14000-$17FFF`: Sprite graphics data
  - `$1B000-$1BFFF`: Tilemap data
  - `$1FA00-$1FBFF`: Color palette
  - `$1FC00-$1FFFF`: Sprite attributes

### Performance Targets
- **Frame Rate**: 60 FPS consistent
- **Input Latency**: < 1 frame delay
- **Memory Usage**: < 32KB main RAM
- **VRAM Usage**: < 64KB total

### Compatibility
- **Hardware**: Commander X16 R47+
- **Emulator**: Official X16 emulator
- **ROM**: Compatible with standard X16 ROM

## Reference Accuracy

### Gameplay Mechanics
- **Movement Speed**: Matches original timing
- **Ghost Behavior**: Authentic AI patterns
- **Scoring System**: Accurate point values
- **Level Progression**: Original difficulty curve

### Visual Accuracy
- **Sprite Graphics**: Pixel-perfect recreation
- **Color Palette**: Authentic color reproduction
- **Animation Timing**: Original frame rates
- **UI Layout**: Faithful screen layout

### Audio Accuracy
- **Sound Effects**: Original waveforms and timing
- **Music**: Faithful melody and rhythm reproduction
- **Audio Cues**: Proper spatial and temporal audio

## Reference Fidelity Method

To ensure high fidelity with the original arcade game (source of truth: `games/pacman/reference/pacman_z80_annotated.asm`), we follow this process:

- **Subsystem map (ROM → X16)**
  - **Command buffer/system**: ROM uses RST #28 queue processed at 0x238D with jump table at 0x23A8. X16 build executes subsystems directly per frame in `game_update` without a queue. Target: preserve ROM call ordering where it affects results (movement → collision → scoring → UI → audio).
  - **State machine**: ROM main state at 0x03C8 (attract, start, level start, gameplay, death, level complete, game over). X16 uses `game_state` with `update_attract`, `update_playing`, death and gameover handlers. Target: align transitions and freezes (READY, death, round-won).
  - **Ghost AI**: ROM per-ghost targeting/avoidance and scatter/chase via commands 0x08–0x0F and routines ~0x1BC0–0x1EE0. X16 implements dossier-accurate targets including Pinky up-quirk and Inky vector; intersection choice priority U,L,D,R with reverse disallowed except schedule reversals. Target: match target-tile math and intersection rules.
  - **Scatter/Chase schedule**: ROM timers at ~0x13DD etc. X16 `game_scatter_chase_phase` implements 7/20, 7/20, 5/20, 5/∞ (per level rules). Target: verify phase boundaries and reversal triggers.
  - **Ghost release (house)**: ROM mixes dot-limits and timers per ghost at ~0x101F–0x10B4. X16 has per-ghost `ghost_dot_limit` plus timed fallback; Pinky timer-based. Target: audit per-level limits/timers to ROM.
  - **Frightened mode**: ROM power-pellet system ~0x0AC3; blink timings and scoring chain. X16 sets freeze durations (dot=1, pill=3), frightened timer and chain popups 200/400/800/1600. Target: finalize frightened duration/slowdown, blink cadence, and reverse-on-enter.
  - **Fruit**: ROM spawn/timeout and scoring around 0x19CD.. and command 0x09. X16 spawns at 70/170 dots, 10s timeout, correct sprite and score popup. Target: confirm per-level fruit type and visibility rules.
  - **RNG**: ROM LCG at 0x2A23 (next = current*5+1 mod 8192). X16 uses `random_byte` for frightened randomness. Target: switch to ROM-equivalent LCG for path tie-breaks.
  - **Self-test & service**: ROM ROM/RAM/DIP tests 0x3031..0x32C4+ and service loop. X16 has cosmetic self-test only. Target: keep minimal cosmetic version.
  - **Attract/demo & intermissions**: ROM attract handler at 0x03DC and scripted demo/interstitial system ~0x21C1+. X16: attract checks start only. Target: add demo playback and three intermissions (coffee breaks) via a small script interpreter.

- **Verification (per-commit quick checks)**
  - Log per-frame trace: tick, Pac-Man tile/dir, each ghost tile/dir/state, scatter/chase phase, frightened timer, Elroy stage, dots_remaining, fruit state, siren stage.
  - Deterministic input: enable scripted input (seeded), compare traces between builds when changing subsystems.
  - Golden scenarios: start-of-round first 10 seconds, first energizer sequence, first fruit window, first death, round completion hold.

- **Acceptance criteria (per subsystem)**
  - Movement and AI decisions match ROM rules at intersections, including red-zone and door rules.
  - Timers/schedules (scatter/chase, frightened, releases, siren stages) match documented boundaries.
  - Scoring and popups (dots, pills, ghosts chain, fruit) correct and timed despawn.
  - Attract/demo and intermissions reproduce original sequences (post-implementation).

### Command System Map (ROM IDs → code locations)

- CMD_01_GAME_STATE_TICK: `games/pacman/pacman_x16.asm` → dispatcher `qh_01` (seeds per-frame commands)
- CMD_06_INPUT_PROCESS: `pacman_x16.asm` → `cmd_06_input_process` (near input/game loop)
- CMD_07_SCORE_DISPLAY_UPDATE: `pacman_x16.asm` → `cmd_07_score_display_update` (near UI code)
- CMD_09_FRUIT_CONTROL: `pacman_x16.asm` → `cmd_09_fruit_control` (near UI/fruit code)
- CMD_0A_PELLET_CONSUMPTION: `pacman_x16.asm` → `cmd_0A_pellet_consumption` (near pellet helpers)
- CMD_0C..0F_GHOST*_SCATTER_TARGET: `pacman_x16.asm` → ghost AI section (near `ghost_scatter_targets`)
- CMD_08..0B_GHOST*_OBSTACLE_AVOID: `pacman_x16.asm` → ghost AI section (uses `ghost_obstacle_avoid_common`)

### Tracing (for audits)

- Enable queue trace: define `ENABLE_QUEUE_TRACE` in `pacman_x16.asm`
- Enable state trace: define `ENABLE_STATE_TRACE` in `pacman_x16.asm`
- Traces are emitted via the logging interface to the emulator logs.

## Development Tools

### Automated Development
- **Development Loop**: Automated build-test-analyze cycle
- **Progress Tracking**: Comparison with reference implementation
- **Performance Analysis**: Frame rate and memory usage monitoring
- **Regression Testing**: Automated validation of game mechanics

### Analysis Tools
- **Reference Comparison**: Pixel-perfect accuracy validation
- **Performance Profiling**: CPU and memory usage analysis
- **Compatibility Testing**: Hardware and emulator validation
- **Code Quality**: Assembly code analysis and optimization

## Contributing

### Code Contributions
- Follow framework coding standards
- Maintain 60fps performance target
- Ensure hardware compatibility
- Add comprehensive comments

### Testing
- Test on both emulator and hardware
- Validate against reference implementation
- Check edge cases and error conditions
- Verify performance targets

### Documentation
- Update progress tracking
- Document new features and changes
- Maintain architecture documentation
- Include usage examples

## Known Issues

### Current Limitations
- Audio system not yet implemented
- Ghost AI in early development
- Limited error handling
- No save game functionality

### Future Improvements
- Enhanced audio system
- Additional game modes
- Customizable controls
- Performance optimizations

## Acknowledgments

- **Original Pac-Man**: Namco (1980)
- **Reference Implementation**: Various open-source recreations
- **X16 Community**: Testing and feedback
- **Framework**: X16 Game Development Framework

---

**Game Status**: In Development  
**Framework Version**: 1.0  
**Last Updated**: 2025-07-24  
**Compatibility**: Commander X16 R47+
