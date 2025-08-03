# X16 Game Development Framework

**🤖 AI ASSISTANTS: READ [`AI_DEVELOPMENT_GUIDE.md`](AI_DEVELOPMENT_GUIDE.md) FIRST! 🤖**

A comprehensive framework for creating authentic retro games on the Commander X16, featuring automated development tools and reusable components.

## Project Overview

This project demonstrates modern development practices applied to retro game development, combining the authenticity of 6502 assembly programming with contemporary software engineering approaches.

### Key Features

- **Reusable Framework**: Core X16 system and VERA graphics abstraction
- **Automated Development**: AI-assisted development loops and analysis tools
- **Game Templates**: Ready-to-use templates for rapid game creation
- **Reference Validation**: Automated comparison with original implementations
- **Comprehensive Documentation**: Detailed architecture and development guides

## Project Structure

```
pacman_x16/
├── README.md                 # This file
├── Makefile                  # Build system for games and framework
├── .gitignore               # Git ignore patterns
├── cx16-custom.cfg          # Linker configuration
├── init                     # Initialization script
│
├── framework/               # Reusable game development framework
│   ├── README.md           # Framework documentation
│   ├── core/               # Core framework components
│   │   ├── x16_constants.inc    # Hardware constants
│   │   ├── x16_system.asm       # System utilities
│   │   └── vera_graphics.asm    # VERA graphics routines
│   ├── templates/          # Game templates
│   │   └── game_template.asm    # Basic game template
│   ├── generators/         # Code generators (future)
│   └── analyzers/          # Analysis tools (future)
│
├── games/                   # Individual game implementations
│   └── pacman/             # Pac-Man recreation
│       ├── README.md       # Game-specific documentation
│       ├── pacman_x16.asm  # Main game code
│       ├── pacman_data.asm # Game data and graphics
│       ├── docs/           # Game documentation
│       └── reference/      # Reference materials
│
├── tools/                   # Development and analysis tools
│   ├── README.md           # Tools documentation
│   ├── development_loop.py      # Basic development automation
│   ├── enhanced_dev_loop.py     # Advanced development loop
│   ├── comparison_analyzer.py   # Reference comparison
│   └── project_execution_plan.py # Phase execution planning
│
└── docs/                    # Project documentation
    ├── plan.md             # Development plan
    ├── README.md           # Documentation index
    └── x16_*.md           # X16 hardware documentation
```

## Quick Start

### Prerequisites

- **CC65 Toolchain**: 6502 cross-development suite
- **X16 Emulator**: Commander X16 emulator for testing
- **Python 3.8+**: For development tools
- **Make**: Build automation

### Building and Running

1. **Build the current game** (Pac-Man by default):
   ```bash
   make
   ```

2. **Run the game**:
   ```bash
   make run
   ```

3. **Create a new game**:
   ```bash
   make new GAME=mygame
   ```

4. **Build specific game**:
   ```bash
   make GAME=pacman
   ```

### Development Tools

- **Automated Development Loop**:
  ```bash
  make enhanced-dev
  ```

- **Progress Analysis**:
  ```bash
  make analyze
  ```

- **Framework Validation**:
  ```bash
  make framework
  ```

## Framework Architecture

### Core Components

The framework provides three main components:

1. **x16_constants.inc**: Hardware definitions and standard constants
2. **x16_system.asm**: System initialization and utilities
3. **vera_graphics.asm**: VERA graphics abstraction layer

### Game Template

New games start from a comprehensive template that includes:

- Standard game loop structure
- State management system
- Input handling framework
- Graphics loading pipeline
- Audio integration points

### Development Workflow

1. **Generate**: Create new game from template
2. **Customize**: Implement game-specific logic
3. **Build**: Compile with framework integration
4. **Test**: Run on emulator or hardware
5. **Analyze**: Compare with reference implementations

## Current Games

### Pac-Man Recreation

A faithful recreation of the classic Pac-Man arcade game, demonstrating:

- **Tilemap-based maze rendering**
- **Multi-sprite character animation**
- **AI-driven ghost behavior**
- **Score and level progression**
- **Authentic game mechanics**

**Status**: In development  
**Location**: `games/pacman/`  
**Documentation**: `games/pacman/README.md`

## Development Philosophy

### Authenticity with Modern Practices

This project combines authentic retro development with modern software engineering:

- **6502 Assembly**: Native performance and authentic feel
- **Automated Testing**: Continuous validation and regression testing
- **Reference Validation**: Accuracy comparison with original implementations
- **Modular Design**: Reusable components and clear separation of concerns

### AI-Assisted Development

The project incorporates AI assistance for:

- **Code Generation**: Framework components and game templates
- **Analysis**: Progress tracking and reference comparison
- **Documentation**: Comprehensive guides and API documentation
- **Testing**: Automated validation and edge case detection

### Educational Value

The framework serves as:

- **Learning Resource**: Example of professional retro game development
- **Reference Implementation**: Best practices for X16 development
- **Teaching Tool**: Demonstrates software engineering principles
- **Community Resource**: Reusable components for other developers

## Technical Specifications

### Target Platform

- **Hardware**: Commander X16 (R47+)
- **CPU**: 65C02 @ 8MHz
- **Graphics**: VERA (Video Enhanced Retro Adapter)
- **Memory**: 512KB RAM + 512KB ROM
- **Storage**: SD card support

### Development Environment

- **Assembler**: CA65 (CC65 suite)
- **Linker**: LD65 with custom configuration
- **Emulator**: Official X16 emulator
- **Languages**: 6502 Assembly, Python (tools)

### Performance Targets

- **Frame Rate**: 60 FPS (NTSC) / 50 FPS (PAL)
- **Memory Usage**: Efficient VRAM and RAM utilization
- **Compatibility**: Hardware and emulator compatibility
- **Accuracy**: Reference-validated game mechanics

## Contributing

### Framework Development

Contributions to the framework are welcome:

1. **Core Components**: Enhance system utilities and graphics routines
2. **Templates**: Create specialized game templates
3. **Tools**: Develop analysis and development tools
4. **Documentation**: Improve guides and examples

### Game Development

New games using the framework:

1. **Use Template**: Start with `make new GAME=yourname`
2. **Follow Patterns**: Use framework conventions and patterns
3. **Document**: Include comprehensive documentation
4. **Test**: Validate on both emulator and hardware

### Quality Standards

- **Code Quality**: Clean, documented, efficient assembly code
- **Compatibility**: Test on multiple X16 configurations
- **Documentation**: Comprehensive inline and external documentation
- **Testing**: Automated validation where possible

## Future Roadmap

### Framework Enhancements

- **Audio System**: PSG and PCM audio abstraction
- **Input Framework**: Standardized joystick and keyboard handling
- **File I/O**: Save game and asset loading systems
- **Network Support**: Multi-player game capabilities

### Development Tools

- **Visual Editors**: Tile and sprite editors
- **Asset Pipeline**: Automated graphics conversion
- **Performance Profiler**: Frame rate and memory analysis
- **Hardware Debugger**: Real-time debugging support

### Additional Games

- **Asteroids**: Vector-style space shooter
- **Frogger**: Traffic-dodging action game
- **Centipede**: Mushroom field shooter
- **Breakout**: Ball and paddle classic

## Resources

### Documentation

- **Framework Guide**: `framework/README.md`
- **Development Plan**: `docs/plan.md`
- **X16 Hardware**: `docs/x16_*.md`
- **Tools Guide**: `tools/README.md`

### External Resources

- **Commander X16**: [Official website](https://www.commanderx16.com/)
- **CC65 Documentation**: [CC65 User Guide](https://cc65.github.io/doc/)
- **X16 Community**: [Official forums](https://www.commanderx16.com/forum/)
- **VERA Documentation**: [VERA Reference](https://github.com/X16Community/x16-docs)

## License

This project is developed for educational and demonstration purposes. The framework components are available for use in other X16 projects. Individual games retain their own licensing terms.

## Acknowledgments

- **Commander X16 Team**: Hardware platform and community
- **CC65 Development Team**: Cross-development toolchain
- **X16 Community**: Testing, feedback, and support
- **Original Game Developers**: Inspiration and reference implementations

---

**Project Status**: Active Development  
**Framework Version**: 1.0  
**Last Updated**: 2025-07-24  
**Compatibility**: Commander X16 R47+
