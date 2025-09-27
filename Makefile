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
EMULATOR = bin/x16emu

# Build flags
CFLAGS = -t cx16 -O -Cl
AFLAGS = -t cx16
LDFLAGS = -C tests/simple.cfg

# Directories
GAME_DIR = games/$(GAME)
FRAMEWORK_DIR = framework
BUILD_DIR = build
TOOLS_DIR = tools
BIN_DIR = bin
LOG_DIR = $(BIN_DIR)/logs
LOG_FILE = $(LOG_DIR)/x16emu_log.txt
ABS_LOG_FILE := $(abspath $(LOG_FILE))
TIMEOUT ?= 10

# Source files
GAME_MAIN = $(GAME_DIR)/$(GAME)_x16.asm
GAME_DATA = $(GAME_DIR)/$(GAME)_data.asm
FRAMEWORK_CORE = $(FRAMEWORK_DIR)/core/x16_system.asm $(FRAMEWORK_DIR)/core/vera_graphics.asm

# Output files
PROGRAM = $(BIN_DIR)/$(GAME).prg
OBJECTS = $(BUILD_DIR)/$(GAME)_x16.o $(BUILD_DIR)/$(GAME)_data.o

# ==============================================================================
# MAIN TARGETS
# ==============================================================================

.PHONY: all clean run framework new help

# Default target
all: $(PROGRAM)

# Build the game program
$(PROGRAM): $(BUILD_DIR) $(BIN_DIR) $(OBJECTS)
	$(LD65) $(LDFLAGS) -o $@ $(OBJECTS)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Create bin directory
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Compile game main file
$(BUILD_DIR)/$(GAME)_x16.o: $(GAME_MAIN) $(FRAMEWORK_CORE)
	$(CA65) $(AFLAGS) -I $(FRAMEWORK_DIR) -o $@ $<

# Compile game data file
$(BUILD_DIR)/$(GAME)_data.o: $(GAME_DATA)
	$(CA65) $(AFLAGS) -I $(FRAMEWORK_DIR) -o $@ $<

# ==============================================================================
# UTILITY TARGETS
# ==============================================================================

# Build and run the game - both -prg and BASIC LOAD work consistently
run: $(PROGRAM)
	@if [ ! -f "$(EMULATOR)" ]; then \
		echo "❌ Emulator not found at $(EMULATOR)"; \
		echo "💡 Run 'make emulator' first to build the emulator to bin/"; \
		exit 1; \
	fi
	@# Create game-specific build directory
	@mkdir -p "$(BUILD_DIR)/$(GAME)/logs"
	@mkdir -p "$(BUILD_DIR)/$(GAME)/screenshots"
	@# Copy game executable to game-specific build directory  
	@cp "$(PROGRAM)" "$(BUILD_DIR)/$(GAME)/$(GAME).prg"
	@# Copy game-specific logging file if it exists
	@if [ -f "$(GAME_DIR)/$(GAME)log.def" ]; then \
		cp "$(GAME_DIR)/$(GAME)log.def" "$(BUILD_DIR)/$(GAME)/$(GAME)log.def"; \
		echo "📋 Using game-specific logging: $(GAME_DIR)/$(GAME)log.def"; \
	else \
		echo "📋 No game-specific logging found, using generic"; \
		cp "logging.def" "$(BUILD_DIR)/$(GAME)/$(GAME)log.def" 2>/dev/null || true; \
	fi
	@echo "🎮 Running $(GAME) with clean filesystem structure"
	@echo "   → Game sandbox: $(BUILD_DIR)/$(GAME)/"
	@echo "   → Both -prg and BASIC LOAD\"$(GAME).PRG\",8,1 work"
	@echo "   → Logs: $(BUILD_DIR)/$(GAME)/logs/"
	$(EMULATOR) -fsroot "$(BUILD_DIR)/$(GAME)" -startin "$(BUILD_DIR)/$(GAME)" \
		-log-file "$(BUILD_DIR)/$(GAME)/logs/x16emu_log.txt" \
		-prg "$(GAME).prg" -run

# Build and run while tailing emulator log file
.PHONY: run-log tail-log run-log-seconds
run-log: $(PROGRAM)
	@if [ ! -f "$(EMULATOR)" ]; then \
		echo "❌ Emulator not found at $(EMULATOR)"; \
		echo "💡 Run 'make emulator' first to build the emulator to bin/"; \
		exit 1; \
	fi
	@# Create game-specific build directory
	@mkdir -p "$(BUILD_DIR)/$(GAME)/logs"
	@mkdir -p "$(BUILD_DIR)/$(GAME)/screenshots"
	@# Copy game executable and logging config
	@cp "$(PROGRAM)" "$(BUILD_DIR)/$(GAME)/$(GAME).prg"
	@if [ -f "$(GAME_DIR)/$(GAME)log.def" ]; then \
		cp "$(GAME_DIR)/$(GAME)log.def" "$(BUILD_DIR)/$(GAME)/$(GAME)log.def"; \
		echo "📋 Using game-specific logging: $(GAME_DIR)/$(GAME)log.def"; \
	else \
		echo "📋 No game-specific logging found, using generic"; \
		cp "logging.def" "$(BUILD_DIR)/$(GAME)/$(GAME)log.def" 2>/dev/null || true; \
	fi
	@GAME_LOG_FILE="$(BUILD_DIR)/$(GAME)/logs/x16emu_log.txt"; \
	: > "$$GAME_LOG_FILE"; \
	echo "📝 Tailing: $$GAME_LOG_FILE"; \
	echo "🎮 Game sandbox: $(BUILD_DIR)/$(GAME)/"; \
	TAIL_CMD="tail -n +1 -f \"$$GAME_LOG_FILE\""; \
	sh -c "$$TAIL_CMD & TAIL_PID=\$$!; trap 'kill \$$TAIL_PID 2>/dev/null || true' EXIT INT TERM; \"$(EMULATOR)\" -fsroot \"$(BUILD_DIR)/$(GAME)\" -startin \"$(BUILD_DIR)/$(GAME)\" -log-file \"$$GAME_LOG_FILE\" -prg \"$(GAME).prg\" -run; kill \$$TAIL_PID 2>/dev/null || true" || true

# Just tail the current game's emulator log
tail-log:
	@mkdir -p "$(BUILD_DIR)/$(GAME)/logs"
	@GAME_LOG_FILE="$(BUILD_DIR)/$(GAME)/logs/x16emu_log.txt"; \
	touch "$$GAME_LOG_FILE"; \
	echo "📝 Tailing: $$GAME_LOG_FILE (Ctrl-C to stop)"; \
	tail -n +1 -f "$$GAME_LOG_FILE"

# Build, run, and tail logs for TIMEOUT seconds, then auto-terminate
run-log-seconds: $(PROGRAM)
	@if [ ! -f "$(EMULATOR)" ]; then \
		echo "❌ Emulator not found at $(EMULATOR)"; \
		echo "💡 Run 'make emulator' first to build the emulator to bin/"; \
		exit 1; \
	fi
	@mkdir -p "$(LOG_DIR)"
	@if [ -f "$(GAME_DIR)/$(GAME)log.def" ]; then \
		cp "$(GAME_DIR)/$(GAME)log.def" "$(BIN_DIR)/$(GAME)log.def"; \
		echo "📋 Using game-specific logging: $(GAME_DIR)/$(GAME)log.def"; \
		echo "   → Copied to: $(BIN_DIR)/$(GAME)log.def"; \
	else \
		echo "📋 No game-specific logging found at $(GAME_DIR)/$(GAME)log.def"; \
		echo "   → Emulator will fall back to generic logging.def"; \
	fi
	@: > "$(ABS_LOG_FILE)"
	@echo "🕒 Running for $(TIMEOUT)s | Log: $(ABS_LOG_FILE)"
	@sh -c 'tail -n +1 -f "$(ABS_LOG_FILE)" & TAIL_PID=$$!; "$(EMULATOR)" -prg "$(PROGRAM)" -run -log-file "$(ABS_LOG_FILE)" & EMU_PID=$$!; sleep $(TIMEOUT); kill $$EMU_PID 2>/dev/null || true; kill $$TAIL_PID 2>/dev/null || true; wait $$EMU_PID 2>/dev/null || true'

# Build and run with GIF recording for LLM analysis
run-gif: $(PROGRAM)
	@if [ ! -f "$(EMULATOR)" ]; then \
		echo "❌ Emulator not found at $(EMULATOR)"; \
		echo "💡 Run 'make emulator' first to build the emulator to bin/"; \
		exit 1; \
	fi
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

# Clean everything including emulator
clean-all: clean
	rm -rf $(BIN_DIR)
	$(MAKE) -C emulator clean

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
# EMULATOR BUILD
# ==============================================================================

# Build emulator and MCP server to bin directory
emulator: $(BIN_DIR)
	@echo "Building emulator and MCP server to bin directory..."
	$(MAKE) -C emulator
	cp emulator/x16emu $(BIN_DIR)/
	cp emulator/mcp $(BIN_DIR)/
	cp emulator/rom.bin $(BIN_DIR)/
	cp emulator/makecart $(BIN_DIR)/
	cp logging.def $(BIN_DIR)/
	mkdir -p $(LOG_DIR)
	mkdir -p $(BIN_DIR)/screenshots
	@echo "Emulator and MCP server built to $(BIN_DIR)/"
	@echo "Files copied: x16emu, mcp, rom.bin, makecart, logging.def"

# Build only MCP binary and copy to bin directory
.PHONY: mcp
mcp: $(BIN_DIR)
	@echo "Building only MCP binary and copying to $(BIN_DIR)/..."
	$(MAKE) -C emulator mcp
	cp emulator/mcp $(BIN_DIR)/
	@echo "MCP binary copied to $(BIN_DIR)/mcp"

# Force rebuild of emulator
rebuild-emulator: $(BIN_DIR)
	@echo "Rebuilding emulator and MCP server..."
	$(MAKE) -C emulator clean
	$(MAKE) -C emulator
	cp emulator/x16emu $(BIN_DIR)/
	cp emulator/mcp $(BIN_DIR)/
	cp emulator/rom.bin $(BIN_DIR)/
	cp emulator/makecart $(BIN_DIR)/
	cp logging.def $(BIN_DIR)/
	mkdir -p $(LOG_DIR)
	mkdir -p $(BIN_DIR)/screenshots
	@echo "Emulator and MCP server rebuilt to $(BIN_DIR)/"
	@echo "Files copied: x16emu, mcp, rom.bin, makecart, logging.def"

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
	@echo "  make clean-all          - Clean everything including emulator"
	@echo ""
	@echo "Emulator:"
	@echo "  make emulator           - Build emulator to bin directory"
	@echo "  make rebuild-emulator   - Force rebuild emulator"
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
	@echo "Testing:"
	@echo "  make test-mcp           - Run MCP protocol compliance tests"
	@echo "  make test-mcp-full      - Run full MCP test suite with dependencies"
	@echo ""
	@echo "Available Games:"
	@echo "  pacman                  - Pac-Man recreation"
	@echo ""
	@echo "Current Settings:"
	@echo "  GAME = $(GAME)"
	@echo "  BUILD_DIR = $(BUILD_DIR)"
	@echo "  BIN_DIR = $(BIN_DIR)"
	@echo "  EMULATOR = $(EMULATOR)"

# ==============================================================================
# TESTING TARGETS
# ==============================================================================

# MCP Protocol Compliance Tests
.PHONY: test-mcp test-mcp-full

test-mcp: $(BIN_DIR)/mcp
	@echo "🧪 Running MCP Protocol Compliance Tests"
	@echo "========================================"
	python3 tests/run_mcp_tests.py

test-mcp-full: $(BIN_DIR)/mcp
	@echo "🧪 Running Full MCP Test Suite"
	@echo "=============================="
	@echo "📋 Checking Python dependencies..."
	@python3 -c "import requests, jsonschema" 2>/dev/null || \
		(echo "❌ Missing Python dependencies. Install with: pip install requests jsonschema" && exit 1)
	@echo "✓ Python dependencies OK"
	@echo ""
	python3 tests/mcp_protocol_tests.py

# ==============================================================================
# DEPENDENCIES
# ==============================================================================

# Game source depends on framework
$(GAME_MAIN): $(FRAMEWORK_CORE)

# Framework dependencies
$(FRAMEWORK_DIR)/core/x16_system.asm: $(FRAMEWORK_DIR)/core/x16_constants.inc
$(FRAMEWORK_DIR)/core/vera_graphics.asm: $(FRAMEWORK_DIR)/core/x16_constants.inc
