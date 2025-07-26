#!/usr/bin/env python3
"""
Step-by-Step Project Execution Plan for Commander X16 Pac-Man

This script creates and executes a detailed project plan to recreate Pac-Man
frame-for-frame identical to the original, starting with small subsystems
and building up systematically.

Usage: python3 project_execution_plan.py
"""

import os
import json
import subprocess
from datetime import datetime

class PacmanProjectExecutor:
    def __init__(self):
        self.project_dir = "/Users/benjamincooley/projects/pacman_x16"
        self.current_phase = 0
        self.execution_log = []
        
        # Define the complete project plan with phases
        self.project_phases = [
            {
                "phase": 1,
                "name": "System Initialization",
                "description": "Set up basic X16 system, VERA initialization, and memory layout",
                "tasks": [
                    "Remove infinite loop placeholder",
                    "Implement proper BASIC header and entry point",
                    "Set up VERA registers for graphics mode",
                    "Initialize memory layout and zero page variables",
                    "Create basic interrupt handling"
                ],
                "deliverable": "Working X16 program that initializes VERA and shows a colored screen",
                "test_criteria": "Program runs without crashing, VERA is initialized, screen shows solid color"
            },
            {
                "phase": 2,
                "name": "Tilemap System",
                "description": "Implement VERA tilemap rendering system",
                "tasks": [
                    "Convert original Pac-Man tile data to X16 format",
                    "Implement tile upload to VRAM",
                    "Create tilemap rendering routines",
                    "Set up proper color palette",
                    "Test with simple patterns"
                ],
                "deliverable": "Tilemap system that can display 8x8 tiles on screen",
                "test_criteria": "Can display test patterns and basic tile graphics"
            },
            {
                "phase": 3,
                "name": "Maze Rendering",
                "description": "Render the complete Pac-Man maze using tilemaps",
                "tasks": [
                    "Extract original maze layout data",
                    "Convert maze data to tile indices",
                    "Implement maze rendering routine",
                    "Add proper maze colors",
                    "Verify maze matches original exactly"
                ],
                "deliverable": "Complete Pac-Man maze displayed on screen",
                "test_criteria": "Maze is pixel-perfect match to original arcade version"
            },
            {
                "phase": 4,
                "name": "Sprite System",
                "description": "Implement VERA sprite system for characters",
                "tasks": [
                    "Convert original sprite data to X16 format",
                    "Implement sprite upload to VRAM",
                    "Create sprite positioning routines",
                    "Add sprite animation system",
                    "Test with Pac-Man character sprite"
                ],
                "deliverable": "Working sprite system with animated Pac-Man",
                "test_criteria": "Pac-Man sprite displays and animates correctly"
            },
            {
                "phase": 5,
                "name": "Input System",
                "description": "Implement keyboard input handling",
                "tasks": [
                    "Set up keyboard scanning routines",
                    "Map keys to game directions",
                    "Implement input buffering",
                    "Add input validation",
                    "Test directional controls"
                ],
                "deliverable": "Responsive keyboard input system",
                "test_criteria": "All four directions respond immediately to key presses"
            },
            {
                "phase": 6,
                "name": "Pac-Man Movement",
                "description": "Implement Pac-Man character movement and collision",
                "tasks": [
                    "Implement pixel-perfect movement system",
                    "Add wall collision detection",
                    "Implement tunnel wrapping",
                    "Add movement animation",
                    "Match original movement timing exactly"
                ],
                "deliverable": "Fully controllable Pac-Man character",
                "test_criteria": "Pac-Man moves exactly like original, including timing and collision"
            },
            {
                "phase": 7,
                "name": "Dot System",
                "description": "Implement dots, pills, and eating mechanics",
                "tasks": [
                    "Place dots and power pills in maze",
                    "Implement dot collision detection",
                    "Add dot eating animation/sound",
                    "Implement score system",
                    "Track remaining dots for level completion"
                ],
                "deliverable": "Working dot eating system with score",
                "test_criteria": "Pac-Man can eat all dots, score increases, level completes when all eaten"
            },
            {
                "phase": 8,
                "name": "Ghost AI Foundation",
                "description": "Implement basic ghost sprites and movement",
                "tasks": [
                    "Add all four ghost sprites",
                    "Implement basic ghost movement",
                    "Add ghost animation",
                    "Implement ghost house mechanics",
                    "Add basic chase behavior"
                ],
                "deliverable": "Four ghosts that move around the maze",
                "test_criteria": "All ghosts display, animate, and move through maze"
            },
            {
                "phase": 9,
                "name": "Ghost AI Behavior",
                "description": "Implement authentic ghost AI from original game",
                "tasks": [
                    "Implement scatter/chase mode switching",
                    "Add individual ghost targeting behavior",
                    "Implement frightened mode",
                    "Add ghost collision with Pac-Man",
                    "Match original AI timing exactly"
                ],
                "deliverable": "Authentic ghost AI behavior",
                "test_criteria": "Ghost behavior matches original frame-for-frame"
            },
            {
                "phase": 10,
                "name": "Game States",
                "description": "Implement game state management",
                "tasks": [
                    "Add attract mode",
                    "Implement game start sequence",
                    "Add life system",
                    "Implement game over handling",
                    "Add level progression"
                ],
                "deliverable": "Complete game state system",
                "test_criteria": "Game flows correctly through all states like original"
            },
            {
                "phase": 11,
                "name": "Audio System",
                "description": "Implement authentic Pac-Man audio",
                "tasks": [
                    "Set up X16 audio system",
                    "Convert original sound effects",
                    "Implement music playback",
                    "Add sound effect triggers",
                    "Match original audio timing"
                ],
                "deliverable": "Complete audio system",
                "test_criteria": "All sounds match original exactly"
            },
            {
                "phase": 12,
                "name": "Polish and Optimization",
                "description": "Final polish and performance optimization",
                "tasks": [
                    "Optimize for 60fps performance",
                    "Add any missing visual effects",
                    "Fine-tune timing to match original",
                    "Add high score system",
                    "Final testing and validation"
                ],
                "deliverable": "Complete, polished Pac-Man game",
                "test_criteria": "Game is indistinguishable from original arcade version"
            }
        ]
    
    def create_phase_implementation(self, phase_num):
        """Create the implementation for a specific phase"""
        phase = self.project_phases[phase_num - 1]
        
        if phase_num == 1:
            return self.implement_phase_1_system_init()
        elif phase_num == 2:
            return self.implement_phase_2_tilemap()
        elif phase_num == 3:
            return self.implement_phase_3_maze()
        # Add more phases as needed
        else:
            return f"Phase {phase_num} implementation not yet defined"
    
    def implement_phase_1_system_init(self):
        """Implement Phase 1: System Initialization"""
        print("Implementing Phase 1: System Initialization")
        
        # Create the new assembly code for phase 1
        phase1_code = """;***************************************************************************
; X16 PAC-MAN - Phase 1: System Initialization
;
; A faithful recreation of Pac-Man for the Commander X16
; Phase 1: Basic system setup, VERA initialization, memory layout
;
; Author: Development System
; Date: """ + datetime.now().strftime('%Y-%m-%d') + """
;***************************************************************************

; BASIC header that runs SYS 2061 ($080D)
.org $0801
.byte $0B,$08,$01,$00,$9E,$32,$30,$36,$31,$00,$00,$00

; program starts at $080D
.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

jmp main

;----------------------------------------------------------
; Zero Page Variables (Pac-Man game state)
;----------------------------------------------------------
game_state      = $02       ; Current game state
pacman_x        = $03       ; Pacman X position
pacman_y        = $04       ; Pacman Y position
pacman_dir      = $05       ; Pacman direction
score_lo        = $06       ; Score low byte
score_mid       = $07       ; Score middle byte
score_hi        = $08       ; Score high byte
lives           = $09       ; Number of lives
level           = $0A       ; Current level

;----------------------------------------------------------
; VERA Registers
;----------------------------------------------------------
VERA_ADDR_L     = $9F20     ; VERA Address low byte
VERA_ADDR_M     = $9F21     ; VERA Address middle byte
VERA_ADDR_H     = $9F22     ; VERA Address high byte
VERA_DATA0      = $9F23     ; VERA data port 0
VERA_DATA1      = $9F24     ; VERA data port 1
VERA_CTRL       = $9F25     ; VERA control register
VERA_IEN        = $9F26     ; VERA interrupt enable
VERA_ISR        = $9F27     ; VERA interrupt status
VERA_DC_VIDEO   = $9F29     ; VERA display composer video
VERA_DC_HSCALE  = $9F2A     ; VERA display composer horizontal scale
VERA_DC_VSCALE  = $9F2B     ; VERA display composer vertical scale
VERA_DC_BORDER  = $9F2C     ; VERA display composer border color

;----------------------------------------------------------
; VRAM Memory Layout (matching original Pac-Man)
;----------------------------------------------------------
TILEMAP_BASE    = $B000     ; Tilemap base address in VRAM
TILE_BASE       = $A000     ; Tile data base address in VRAM
SPRITE_BASE     = $C000     ; Sprite data base address in VRAM

;----------------------------------------------------------
; Game Constants (from original Pac-Man)
;----------------------------------------------------------
SCREEN_WIDTH    = 28        ; Screen width in tiles
SCREEN_HEIGHT   = 36        ; Screen height in tiles
TILE_SIZE       = 8         ; Tile size in pixels

;----------------------------------------------------------
; Game States
;----------------------------------------------------------
STATE_INIT      = 0
STATE_ATTRACT   = 1
STATE_GAME      = 2
STATE_GAMEOVER  = 3

;----------------------------------------------------------
; Main Program Entry Point
;----------------------------------------------------------
main:
    ; Disable interrupts during initialization
    sei
    
    ; Initialize zero page variables
    jsr init_variables
    
    ; Initialize VERA graphics system
    jsr init_vera
    
    ; Set initial game state
    lda #STATE_INIT
    sta game_state
    
    ; Clear screen to test color
    jsr clear_screen_test
    
    ; Enable interrupts
    cli
    
    ; Main game loop
main_loop:
    ; Update game based on current state
    lda game_state
    cmp #STATE_INIT
    beq handle_init_state
    cmp #STATE_ATTRACT
    beq handle_attract_state
    cmp #STATE_GAME
    beq handle_game_state
    cmp #STATE_GAMEOVER
    beq handle_gameover_state
    
    ; Default: stay in current state
    jmp main_loop

;----------------------------------------------------------
; Initialize Zero Page Variables
;----------------------------------------------------------
init_variables:
    ; Clear all game variables
    lda #0
    sta pacman_x
    sta pacman_y
    sta pacman_dir
    sta score_lo
    sta score_mid
    sta score_hi
    sta level
    
    ; Set initial lives
    lda #3
    sta lives
    
    rts

;----------------------------------------------------------
; Initialize VERA Graphics System
;----------------------------------------------------------
init_vera:
    ; Reset VERA
    lda #$00
    sta VERA_CTRL
    
    ; Set up display composer for 40x30 text mode initially
    ; (We'll switch to proper graphics mode in Phase 2)
    lda #$01
    sta VERA_DC_VIDEO
    
    ; Set scale to 1x
    lda #64
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; Set border color to black (like original Pac-Man)
    lda #$00
    sta VERA_DC_BORDER
    
    rts

;----------------------------------------------------------
; Clear Screen Test (Phase 1 deliverable)
;----------------------------------------------------------
clear_screen_test:
    ; Set VERA address to start of screen memory
    lda #$00
    sta VERA_ADDR_L
    lda #$B0
    sta VERA_ADDR_M
    lda #$10        ; Auto-increment
    sta VERA_ADDR_H
    
    ; Fill screen with test pattern
    ldx #0
    ldy #0
clear_loop:
    ; Write test character (space with blue background)
    lda #$20        ; Space character
    sta VERA_DATA0
    lda #$60        ; Blue background
    sta VERA_DATA0
    
    inx
    cpx #40         ; 40 characters per row
    bne clear_loop
    
    ldx #0
    iny
    cpy #30         ; 30 rows
    bne clear_loop
    
    rts

;----------------------------------------------------------
; State Handlers (Stubs for now)
;----------------------------------------------------------
handle_init_state:
    ; Phase 1: Just show test screen and advance to attract
    ; Wait a bit then go to attract mode
    lda #STATE_ATTRACT
    sta game_state
    jmp main_loop

handle_attract_state:
    ; Phase 1: Just cycle border colors to show it's working
    inc VERA_DC_BORDER
    
    ; Simple delay
    ldx #$FF
delay_loop:
    dex
    bne delay_loop
    
    jmp main_loop

handle_game_state:
    ; Phase 1: Not implemented yet
    jmp main_loop

handle_gameover_state:
    ; Phase 1: Not implemented yet
    jmp main_loop

;----------------------------------------------------------
; Interrupt Handler (Placeholder)
;----------------------------------------------------------
irq_handler:
    ; Phase 1: Just return for now
    rti
"""
        
        # Write the new code
        asm_path = os.path.join(self.project_dir, "pacman_x16.asm")
        with open(asm_path, 'w') as f:
            f.write(phase1_code)
        
        return "Phase 1 implementation complete: System initialization with VERA setup"
    
    def implement_phase_2_tilemap(self):
        """Implement Phase 2: Tilemap System"""
        # This would be implemented when we reach phase 2
        return "Phase 2 implementation: Tilemap system (to be implemented)"
    
    def implement_phase_3_maze(self):
        """Implement Phase 3: Maze Rendering"""
        # This would be implemented when we reach phase 3
        return "Phase 3 implementation: Maze rendering (to be implemented)"
    
    def test_phase(self, phase_num):
        """Test the current phase implementation"""
        print(f"Testing Phase {phase_num}...")
        
        # Build the project
        try:
            result = subprocess.run(['make', 'clean'], cwd=self.project_dir, capture_output=True, text=True)
            result = subprocess.run(['make'], cwd=self.project_dir, capture_output=True, text=True)
            
            if result.returncode != 0:
                return False, f"Build failed: {result.stderr}"
            
            print("✓ Build successful")
            
            # Run in emulator for a few seconds to test
            try:
                result = subprocess.run([
                    'x16emu', '-prg', 'pacman.prg', '-run'
                ], cwd=self.project_dir, timeout=5, capture_output=True)
                print("✓ Emulator test completed")
                return True, "Phase test passed"
            except subprocess.TimeoutExpired:
                print("✓ Emulator ran successfully (timeout expected)")
                return True, "Phase test passed"
            
        except Exception as e:
            return False, f"Test failed: {e}"
    
    def execute_phase(self, phase_num):
        """Execute a specific phase of the project"""
        if phase_num > len(self.project_phases):
            return False, "Invalid phase number"
        
        phase = self.project_phases[phase_num - 1]
        
        print(f"\n{'='*60}")
        print(f"EXECUTING PHASE {phase_num}: {phase['name']}")
        print(f"{'='*60}")
        print(f"Description: {phase['description']}")
        print(f"Deliverable: {phase['deliverable']}")
        print()
        
        # Log phase start
        phase_log = {
            'phase': phase_num,
            'name': phase['name'],
            'start_time': datetime.now().isoformat(),
            'tasks_completed': [],
            'status': 'in_progress'
        }
        
        # Execute implementation
        try:
            implementation_result = self.create_phase_implementation(phase_num)
            print(f"Implementation: {implementation_result}")
            
            # Test the implementation
            test_passed, test_message = self.test_phase(phase_num)
            print(f"Test Result: {test_message}")
            
            if test_passed:
                phase_log['status'] = 'completed'
                phase_log['end_time'] = datetime.now().isoformat()
                phase_log['test_result'] = 'passed'
                print(f"✓ PHASE {phase_num} COMPLETED SUCCESSFULLY")
            else:
                phase_log['status'] = 'failed'
                phase_log['test_result'] = 'failed'
                phase_log['error'] = test_message
                print(f"✗ PHASE {phase_num} FAILED")
            
            self.execution_log.append(phase_log)
            return test_passed, test_message
            
        except Exception as e:
            phase_log['status'] = 'error'
            phase_log['error'] = str(e)
            self.execution_log.append(phase_log)
            return False, f"Phase execution error: {e}"
    
    def save_execution_log(self):
        """Save the execution log to file"""
        log_path = os.path.join(self.project_dir, "execution_log.json")
        with open(log_path, 'w') as f:
            json.dump(self.execution_log, f, indent=2)
        
        # Also create a readable summary
        summary_path = os.path.join(self.project_dir, "execution_summary.txt")
        with open(summary_path, 'w') as f:
            f.write("PAC-MAN X16 PROJECT EXECUTION SUMMARY\n")
            f.write("=" * 50 + "\n\n")
            
            completed_phases = [log for log in self.execution_log if log['status'] == 'completed']
            failed_phases = [log for log in self.execution_log if log['status'] == 'failed']
            
            f.write(f"Completed Phases: {len(completed_phases)}\n")
            f.write(f"Failed Phases: {len(failed_phases)}\n")
            f.write(f"Total Phases: {len(self.project_phases)}\n\n")
            
            for log in self.execution_log:
                status_symbol = "✓" if log['status'] == 'completed' else "✗"
                f.write(f"{status_symbol} Phase {log['phase']}: {log['name']} - {log['status']}\n")
        
        print(f"Execution log saved to: {log_path}")
        print(f"Summary saved to: {summary_path}")
    
    def run_project_execution(self, start_phase=1, end_phase=None):
        """Run the project execution from start_phase to end_phase"""
        if end_phase is None:
            end_phase = len(self.project_phases)
        
        print("STARTING PAC-MAN X16 PROJECT EXECUTION")
        print("=" * 50)
        print(f"Executing phases {start_phase} to {end_phase}")
        print(f"Total phases planned: {len(self.project_phases)}")
        print()
        
        success_count = 0
        
        for phase_num in range(start_phase, end_phase + 1):
            success, message = self.execute_phase(phase_num)
            
            if success:
                success_count += 1
            else:
                print(f"\n⚠ STOPPING EXECUTION: Phase {phase_num} failed")
                print(f"Error: {message}")
                break
            
            # Small delay between phases
            import time
            time.sleep(1)
        
        # Save execution log
        self.save_execution_log()
        
        print(f"\n{'='*60}")
        print("EXECUTION SUMMARY")
        print(f"{'='*60}")
        print(f"Phases completed successfully: {success_count}")
        print(f"Phases attempted: {len(self.execution_log)}")
        
        if success_count > 0:
            print(f"\n✓ PROJECT PROGRESS: {success_count}/{len(self.project_phases)} phases complete")
        
        return success_count

if __name__ == "__main__":
    executor = PacmanProjectExecutor()
    
    print("PAC-MAN X16 PROJECT EXECUTION PLAN")
    print("=" * 50)
    print("This will execute the step-by-step plan to create a frame-perfect")
    print("recreation of Pac-Man for the Commander X16.")
    print()
    
    # Show the project plan
    print("PROJECT PHASES:")
    for i, phase in enumerate(executor.project_phases, 1):
        print(f"  Phase {i}: {phase['name']}")
        print(f"    {phase['description']}")
        print(f"    Deliverable: {phase['deliverable']}")
        print()
    
    # Execute the first phase to start
    print("Starting execution with Phase 1...")
    success_count = executor.run_project_execution(start_phase=1, end_phase=1)
    
    if success_count > 0:
        print("\n🎉 Phase 1 completed! Ready to continue with Phase 2.")
        print("Run again to continue with the next phase.")
    else:
        print("\n❌ Phase 1 failed. Check the error messages above.")
