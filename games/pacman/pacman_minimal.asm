; ==============================================================================
; MINIMAL PAC-MAN FOR COMMANDER X16
; ==============================================================================
; Simplified version that fits in memory - no large data arrays
; ==============================================================================

.include "../../framework/core/x16_constants.inc"

; ==============================================================================
; PROGRAM HEADER
; ==============================================================================

.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

; BASIC header for X16
.word $0801
.byte $0C, $08, $0A, $00, $9E, $20, $32, $30, $36, $34, $00, $00, $00

; Program entry point
main:
    jmp game_start

; ==============================================================================
; GAME CONSTANTS
; ==============================================================================

; Simple tile definitions
TILE_SPACE       = $20       ; Space character
TILE_DOT         = $2E       ; Period for dots
TILE_WALL        = $23       ; Hash for walls
TILE_PACMAN      = $43       ; C for Pac-Man

; Game states
GAME_STATE_INIT     = 0
GAME_STATE_PLAYING  = 1

; Game variables
game_state     = $80
pacman_x       = $81
pacman_y       = $82
score          = $83

; ==============================================================================
; MAIN PROGRAM
; ==============================================================================

game_start:
    ; Initialize game
    jsr game_init
    
    ; Main game loop
game_loop:
    jsr game_update
    jsr game_render
    jmp game_loop

game_init:
    ; Set initial state
    lda #GAME_STATE_PLAYING
    sta game_state
    
    ; Set initial Pac-Man position
    lda #10
    sta pacman_x
    lda #10  
    sta pacman_y
    
    ; Clear score
    lda #0
    sta score
    
    ; Set background color to black
    lda #$00
    sta $9F20    ; VERA_ADDR_LOW
    lda #$F0
    sta $9F21    ; VERA_ADDR_MID  
    lda #$0F
    sta $9F22    ; VERA_ADDR_HIGH
    lda #$00
    sta $9F23    ; VERA_DATA0 - black background
    sta $9F23
    
    ; Draw simple maze using text mode
    jsr draw_simple_maze
    
    rts

game_update:
    ; Simple input handling - move Pac-Man around
    ; This is a placeholder - just move automatically for demo
    inc pacman_x
    lda pacman_x
    cmp #30
    bcc @no_wrap
    lda #5
    sta pacman_x
@no_wrap:
    rts

game_render:
    ; Clear old Pac-Man position (write space)
    ; Position cursor and write Pac-Man character
    ; This is simplified - just increment score for demo
    inc score
    rts

draw_simple_maze:
    ; Draw a simple maze using text characters
    ; Set text mode and draw basic walls
    
    ; Set VERA to text mode (default)
    ; Draw border
    ldx #0
@draw_border:
    ; Top border
    lda #TILE_WALL
    sta $0400,x    ; Screen memory (simplified)
    
    ; Bottom border  
    sta $0400 + 40*24,x
    
    inx
    cpx #40
    bne @draw_border
    
    rts

; ==============================================================================
; MINIMAL DATA
; ==============================================================================

; No large data arrays - keep it simple!
