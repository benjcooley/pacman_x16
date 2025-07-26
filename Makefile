# ==============================================================================
# X16 GAME DEVELOPMENT FRAMEWORK MAKEFILE
# ==============================================================================
# Supports building individual games and the entire framework
# Usage:
#   make                    - Build current game (pacman by default)
#   make GAME=pacman        - Build specific game
#   make run                - Build and run current game
#   make clean              - Clean build files
#   make framework          - Build framework components
#   make new GAME=mygame    - Create new game from template
# ==============================================================================

# Default game to build
GAME ?= pacman

# Build tools
CC65 = cl65
CA65 = ca65
LD65 = ld65
EMULATOR = x16emu

# Build flags
CFLAGS = -t cx16 -O -Cl
AFLAGS = -t cx16
LDFLAGS = -C cx16-custom.cfg

# Directories
GAME_DIR = games/$(GAME)
FRAMEWORK_DIR = framework
BUILD_DIR = build
TOOLS_DIR = tools

# Source files
GAME_MAIN = $(GAME_DIR)/$(GAME)_x16.asm
GAME_DATA = $(GAME_DIR)/$(GAME)_data.asm
FRAMEWORK_CORE = $(FRAMEWORK_DIR)/core/x16_system.asm $(FRAMEWORK_DIR)/core/vera_graphics.asm

# Output files
PROGRAM = $(GAME).prg
OBJECTS = $(BUILD_DIR)/$(GAME)_x16.o $(BUILD_DIR)/$(GAME)_data.o

# ==============================================================================
# MAIN TARGETS
# ==============================================================================

.PHONY: all clean run framework new help

# Default target
all: $(PROGRAM)

# Build the game program
$(PROGRAM): $(BUILD_DIR) $(OBJECTS)
	$(LD65) $(LDFLAGS) -o $@ $(OBJECTS)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile game main file
$(BUILD_DIR)/$(GAME)_x16.o: $(GAME_MAIN) $(FRAMEWORK_CORE)
	$(CA65) $(AFLAGS) -I $(FRAMEWORK_DIR) -o $@ $<

# Compile game data file
$(BUILD_DIR)/$(GAME)_data.o: $(GAME_DATA)
	$(CA65) $(AFLAGS) -I $(FRAMEWORK_DIR) -o $@ $<

# ==============================================================================
# UTILITY TARGETS
# ==============================================================================

# Build and run the game
run: $(PROGRAM)
	$(EMULATOR) -prg $(PROGRAM) -run

# Build and run with GIF recording for LLM analysis
run-gif: $(PROGRAM)
	@echo "🎬 Running $(GAME) with GIF recording..."
	@GIF_FILE="$(GAME)_recording_$$(date +%Y%m%d_%H%M%S).gif"; \
	echo "📁 Recording to: $$GIF_FILE"; \
	$(EMULATOR) -prg $(PROGRAM) -run -gif "$$GIF_FILE" & \
	EMULATOR_PID=$$!; \
	echo "📍 Emulator PID: $$EMULATOR_PID"; \
	echo "⏱️  Recording for 10 seconds..."; \
	sleep 10; \
	pkill x16emu; \
	echo "✅ Recording completed"; \
	if [ -f "$$GIF_FILE" ]; then \
		GIF_SIZE=$$(stat -f%z "$$GIF_FILE" 2>/dev/null || stat -c%s "$$GIF_FILE" 2>/dev/null); \
		echo "🎬 GIF RECORDING EXPORTED:"; \
		echo "   📁 File: $$GIF_FILE"; \
		echo "   📏 Size: $$GIF_SIZE bytes"; \
		echo "   🤖 LLM VIEWING INSTRUCTIONS:"; \
		echo "      Use: browser_action -> launch -> file://$(PWD)/$$GIF_FILE"; \
		echo "      This shows exactly what the emulator displayed during execution"; \
	else \
		echo "❌ GIF file not found"; \
	fi

# Clean build files
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.prg
	rm -f *.o

# Build framework components (syntax check)
framework: $(BUILD_DIR)
	@echo "Building framework components..."
	$(CA65) $(AFLAGS) -o $(BUILD_DIR)/x16_system.o $(FRAMEWORK_DIR)/core/x16_system.asm
	$(CA65) $(AFLAGS) -o $(BUILD_DIR)/vera_graphics.o $(FRAMEWORK_DIR)/core/vera_graphics.asm
	@echo "Framework build complete."

# Create new game from template
new:
	@if [ -z "$(GAME)" ]; then \
		echo "Error: Please specify GAME name: make new GAME=mygame"; \
		exit 1; \
	fi
	@if [ -d "games/$(GAME)" ]; then \
		echo "Error: Game '$(GAME)' already exists"; \
		exit 1; \
	fi
	@echo "Creating new game: $(GAME)"
	mkdir -p games/$(GAME)
	mkdir -p games/$(GAME)/docs
	mkdir -p games/$(GAME)/reference
	sed 's/{{GAME_NAME}}/$(GAME)/g' $(FRAMEWORK_DIR)/templates/game_template.asm > games/$(GAME)/$(GAME)_x16.asm
	touch games/$(GAME)/$(GAME)_data.asm
	echo "# $(GAME) for Commander X16" > games/$(GAME)/README.md
	echo "Game '$(GAME)' created successfully in games/$(GAME)/"

# ==============================================================================
# DEVELOPMENT TOOLS
# ==============================================================================

# Run development tools
dev-loop:
	python3 $(TOOLS_DIR)/development_loop.py 5

enhanced-dev:
	python3 $(TOOLS_DIR)/enhanced_dev_loop.py 5

ai-dev:
	python3 $(TOOLS_DIR)/ai_dev_tool.py 10

analyze:
	python3 $(TOOLS_DIR)/comparison_analyzer.py

execute-plan:
	python3 $(TOOLS_DIR)/project_execution_plan.py

# ==============================================================================
# GAME-SPECIFIC TARGETS
# ==============================================================================

# Build specific games
pacman:
	$(MAKE) GAME=pacman

# Add more games here as they are created
# asteroids:
# 	$(MAKE) GAME=asteroids

# ==============================================================================
# HELP
# ==============================================================================

help:
	@echo "X16 Game Development Framework"
	@echo "=============================="
	@echo ""
	@echo "Building:"
	@echo "  make                    - Build current game ($(GAME))"
	@echo "  make GAME=name          - Build specific game"
	@echo "  make run                - Build and run current game"
	@echo "  make clean              - Clean build files"
	@echo ""
	@echo "Framework:"
	@echo "  make framework          - Build framework components"
	@echo "  make new GAME=name      - Create new game from template"
	@echo ""
	@echo "Development Tools:"
	@echo "  make dev-loop           - Run basic development loop"
	@echo "  make enhanced-dev       - Run enhanced development loop"
	@echo "  make analyze            - Analyze progress vs reference"
	@echo "  make execute-plan       - Run phase execution plan"
	@echo ""
	@echo "Available Games:"
	@echo "  pacman                  - Pac-Man recreation"
	@echo ""
	@echo "Current Settings:"
	@echo "  GAME = $(GAME)"
	@echo "  BUILD_DIR = $(BUILD_DIR)"

# ==============================================================================
# DEPENDENCIES
# ==============================================================================

# Game source depends on framework
$(GAME_MAIN): $(FRAMEWORK_CORE)

# Framework dependencies
$(FRAMEWORK_DIR)/core/x16_system.asm: $(FRAMEWORK_DIR)/core/x16_constants.inc
$(FRAMEWORK_DIR)/core/vera_graphics.asm: $(FRAMEWORK_DIR)/core/x16_constants.inc
