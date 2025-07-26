# X16 Game Development Framework

A comprehensive framework for creating games on the Commander X16, designed to enable rapid development of authentic retro games with modern development practices.

## Overview

This framework provides a reusable foundation for X16 game development, including:

- **Hardware Abstraction**: Simplified VERA graphics and audio interfaces
- **Common Patterns**: Standard game loops, state management, and input handling
- **Development Tools**: Automated build systems and testing frameworks
- **Templates**: Ready-to-use game templates for quick project starts

## Framework Structure

```
framework/
├── README.md                 # This file
├── core/                     # Core framework components
│   ├── x16_constants.inc     # Hardware constants and definitions
│   ├── x16_system.asm        # System initialization and utilities
│   └── vera_graphics.asm     # VERA graphics routines
├── templates/                # Game templates
│   └── game_template.asm     # Basic game template
├── generators/               # Code generators (future)
└── analyzers/                # Analysis tools (future)
```

## Core Components

### x16_constants.inc
Comprehensive constants file containing:
- VERA register addresses and configuration values
- Memory map definitions
- Standard game constants (states, directions, etc.)
- Zero page allocations
- Useful macros for common operations

### x16_system.asm
System-level functionality:
- X16 initialization and shutdown
- Interrupt handling (VSYNC, etc.)
- Memory banking utilities
- Frame timing and synchronization
- Random number generation

### vera_graphics.asm
VERA graphics abstraction:
- Display mode setup and configuration
- Tilemap management (upload, rendering, individual tile setting)
- Sprite system (setup, positioning, animation)
- Palette management
- VRAM memory management

## Game Template

The framework includes a complete game template (`templates/game_template.asm`) that provides:

### Standard Game Structure
- Proper X16 program header and entry point
- Game state management (INIT, ATTRACT, PLAYING, GAMEOVER)
- Main game loop with VSYNC synchronization
- Input handling framework
- Graphics loading and management

### Customizable Components
- Game-specific constants and variables
- Player and game object update logic
- Collision detection and game rules
- Rendering pipeline
- Audio integration points

### Example Usage
```assembly
; Include the framework
.include "framework/core/x16_constants.inc"

; Define game-specific variables
player_x = ZP_GAME_START + 0
player_y = ZP_GAME_START + 1

; Use framework functions
jsr x16_init           ; Initialize system
jsr vera_setup_tilemap ; Set up graphics
jsr vera_set_sprite    ; Position sprites
```

## Development Workflow

### Creating a New Game

1. **Generate from Template**:
   ```bash
   make new GAME=mygame
   ```

2. **Customize the Template**:
   - Replace placeholder graphics data
   - Implement game-specific logic
   - Add custom input handling
   - Define collision rules

3. **Build and Test**:
   ```bash
   make GAME=mygame
   make run GAME=mygame
   ```

### Framework Integration

Games using this framework follow a standard pattern:

1. **Include Framework**: Import core components and constants
2. **Define Game Data**: Specify game-specific variables and constants
3. **Initialize System**: Use framework initialization routines
4. **Implement Game Logic**: Build on framework's game loop structure
5. **Handle Graphics**: Use VERA abstraction for rendering
6. **Manage Audio**: Integrate with framework's audio system

## Hardware Abstraction

### VERA Graphics
The framework abstracts VERA complexity:

```assembly
; Set up a tilemap layer
lda #0          ; Layer 0
ldx #MAP_32x32  ; 32x32 tiles
ldy #0          ; 8x8 tile size
jsr vera_setup_tilemap

; Upload tile data
lda #<tile_data
sta ZP_PTR1
lda #>tile_data
sta ZP_PTR1+1
lda #16         ; 16 tiles
jsr vera_upload_tiles

; Set individual tiles
lda #5          ; Tile index
ldx #10         ; X position
ldy #15         ; Y position
jsr vera_set_tile
```

### Sprite Management
Simplified sprite operations:

```assembly
; Position a sprite
lda #0          ; Sprite 0
ldx #100        ; X position
ldy #150        ; Y position
stz ZP_TEMP1    ; X high byte
stz ZP_TEMP2    ; Y high byte
lda #0
sta ZP_TEMP3    ; Sprite tile
jsr vera_set_sprite

; Enable the sprite
lda #0
jsr vera_enable_sprite
```

### Memory Management
Standardized memory layout:

```assembly
; Zero page allocations
game_state = ZP_GAME_START + 0
player_x   = ZP_GAME_START + 1
player_y   = ZP_GAME_START + 2

; VRAM layout
VRAM_TILES     = $10000  ; Tile graphics
VRAM_TILEMAP   = $1B000  ; Tilemap data
VRAM_SPRITES   = $1FC00  ; Sprite attributes
VRAM_PALETTE   = $1FA00  ; Color palette
```

## Performance Considerations

### Optimized for 60fps
- Efficient VERA register access patterns
- Minimal VRAM writes per frame
- Optimized sprite update routines
- Frame-synchronized timing

### Memory Efficiency
- Compact data structures
- Shared zero page variables
- Efficient VRAM layout
- Minimal dynamic allocation

### 6502 Optimization
- Zero page variable usage
- Efficient instruction selection
- Loop unrolling where beneficial
- Lookup tables for complex calculations

## Extensibility

### Adding New Components
The framework is designed for easy extension:

1. **New Graphics Routines**: Add to `vera_graphics.asm`
2. **System Utilities**: Extend `x16_system.asm`
3. **Constants**: Add to `x16_constants.inc`
4. **Templates**: Create specialized game templates

### Custom Hardware Support
Framework can be extended for:
- Custom expansion cards
- Additional audio hardware
- Network interfaces
- Storage devices

## Best Practices

### Code Organization
- Use framework constants instead of magic numbers
- Follow standard zero page allocation patterns
- Implement consistent error handling
- Document game-specific extensions

### Performance
- Minimize VERA register writes
- Use efficient sprite update patterns
- Implement frame-rate independent timing
- Profile critical code paths

### Compatibility
- Test on both emulator and hardware
- Verify timing accuracy
- Ensure proper cleanup on exit
- Handle edge cases gracefully

## Future Enhancements

### Planned Features
- **Audio Framework**: PSG and PCM audio abstraction
- **Input System**: Joystick and keyboard handling
- **File I/O**: Save game and asset loading
- **Networking**: Multi-player game support

### Code Generators
- **Tile Converter**: Automatic tile data conversion
- **Sprite Generator**: Sprite sheet processing
- **Map Editor**: Visual tilemap creation
- **Audio Tools**: Sound effect generation

### Analysis Tools
- **Performance Profiler**: Frame rate and timing analysis
- **Memory Analyzer**: VRAM and RAM usage tracking
- **Compatibility Checker**: Hardware/emulator validation
- **Reference Validator**: Accuracy comparison tools

## Contributing

### Framework Development
- Follow existing code style and patterns
- Maintain backward compatibility
- Add comprehensive documentation
- Include usage examples

### Testing
- Test on multiple X16 configurations
- Verify emulator and hardware compatibility
- Validate performance targets
- Check edge case handling

### Documentation
- Update README files for changes
- Add inline code documentation
- Provide usage examples
- Maintain architecture documentation

## License

This framework is designed for educational and development purposes. Individual games created with the framework retain their own licensing.

## Acknowledgments

- **Commander X16 Team**: Hardware platform and documentation
- **CC65 Team**: Development toolchain
- **X16 Community**: Testing, feedback, and contributions

---

**Version**: 1.0  
**Last Updated**: 2025-07-24  
**Compatibility**: Commander X16 R47+
