; ==============================================================================
; GAME TEMPLATE FOR X16
; ==============================================================================
; Template for creating new games on the Commander X16
; Replace asteroids with your game name
; ==============================================================================

.include "core/x16_constants.inc"

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
; GAME-SPECIFIC CONSTANTS
; ==============================================================================

; Game states
GAME_STATE_INIT     = STATE_INIT
GAME_STATE_ATTRACT  = STATE_ATTRACT  
GAME_STATE_PLAYING  = STATE_GAME
GAME_STATE_GAMEOVER = STATE_GAMEOVER

; Game-specific zero page variables (starting at ZP_GAME_START)
game_state     = ZP_GAME_START + 0
player_x       = ZP_GAME_START + 1
player_y       = ZP_GAME_START + 2
player_dir     = ZP_GAME_START + 3
score_lo       = ZP_GAME_START + 4
score_mid      = ZP_GAME_START + 5
score_hi       = ZP_GAME_START + 6
lives          = ZP_GAME_START + 7
level          = ZP_GAME_START + 8

; ==============================================================================
; MAIN GAME LOOP
; ==============================================================================

game_start:
    ; Initialize X16 system
    jsr x16_init
    
    ; Initialize game
    jsr game_init
    
    ; Main game loop
game_loop:
    ; Wait for VSYNC
    jsr x16_wait_vsync
    
    ; Update game state
    jsr game_update
    
    ; Render frame
    jsr game_render
    
    ; Continue loop
    bra game_loop

; ==============================================================================
; GAME INITIALIZATION
; ==============================================================================

game_init:
    ; Set initial game state
    lda #GAME_STATE_INIT
    sta game_state
    
    ; Initialize VERA graphics
    jsr vera_init
    
    ; Set up tilemap layer
    lda #0          ; Layer 0
    ldx #MAP_32x32  ; Map size
    ldy #0          ; 8x8 tiles
    jsr vera_setup_tilemap
    
    ; Set up sprites
    jsr vera_setup_sprites
    
    ; Initialize game variables
    lda #3
    sta lives
    
    lda #1
    sta level
    
    stz score_lo
    stz score_mid
    stz score_hi
    
    ; Set up game-specific graphics
    jsr load_graphics
    
    ; Set initial player position
    lda #100
    sta player_x
    lda #100
    sta player_y
    
    lda #DIR_RIGHT
    sta player_dir
    
    ; Transition to attract mode
    lda #GAME_STATE_ATTRACT
    sta game_state
    
    rts

; ==============================================================================
; GAME UPDATE LOGIC
; ==============================================================================

game_update:
    lda game_state
    cmp #GAME_STATE_INIT
    beq update_init
    cmp #GAME_STATE_ATTRACT
    beq update_attract
    cmp #GAME_STATE_PLAYING
    beq update_playing
    cmp #GAME_STATE_GAMEOVER
    beq update_gameover
    rts

update_init:
    ; Initialization complete, go to attract mode
    lda #GAME_STATE_ATTRACT
    sta game_state
    rts

update_attract:
    ; Check for start game input
    jsr read_input
    lda ZP_INPUT_STATE
    and #$01  ; Check for button press
    beq @no_start
    
    ; Start game
    lda #GAME_STATE_PLAYING
    sta game_state
    
@no_start:
    rts

update_playing:
    ; Update player
    jsr update_player
    
    ; Update game objects
    jsr update_game_objects
    
    ; Check for game over conditions
    jsr check_game_over
    
    rts

update_gameover:
    ; Handle game over state
    ; Check for restart input
    jsr read_input
    lda ZP_INPUT_STATE
    and #$01  ; Check for button press
    beq @no_restart
    
    ; Restart game
    jsr game_init
    
@no_restart:
    rts

; ==============================================================================
; PLAYER UPDATE
; ==============================================================================

update_player:
    ; Read input
    jsr read_input
    
    ; Update player direction based on input
    lda ZP_INPUT_STATE
    and #$08  ; Up
    beq @not_up
    lda #DIR_UP
    sta player_dir
@not_up:
    
    lda ZP_INPUT_STATE
    and #$04  ; Down
    beq @not_down
    lda #DIR_DOWN
    sta player_dir
@not_down:
    
    lda ZP_INPUT_STATE
    and #$02  ; Left
    beq @not_left
    lda #DIR_LEFT
    sta player_dir
@not_left:
    
    lda ZP_INPUT_STATE
    and #$01  ; Right
    beq @not_right
    lda #DIR_RIGHT
    sta player_dir
@not_right:
    
    ; Move player based on direction
    lda player_dir
    cmp #DIR_UP
    beq @move_up
    cmp #DIR_DOWN
    beq @move_down
    cmp #DIR_LEFT
    beq @move_left
    cmp #DIR_RIGHT
    beq @move_right
    rts

@move_up:
    dec player_y
    rts
@move_down:
    inc player_y
    rts
@move_left:
    dec player_x
    rts
@move_right:
    inc player_x
    rts

; ==============================================================================
; GAME OBJECT UPDATES
; ==============================================================================

update_game_objects:
    ; Update game-specific objects here
    ; (enemies, collectibles, etc.)
    rts

; ==============================================================================
; COLLISION AND GAME LOGIC
; ==============================================================================

check_game_over:
    ; Check for game over conditions
    ; (player death, level complete, etc.)
    rts

; ==============================================================================
; RENDERING
; ==============================================================================

game_render:
    ; Render player sprite
    lda #0              ; Sprite 0
    ldx player_x        ; X position
    ldy player_y        ; Y position
    stz ZP_TEMP1        ; X high = 0
    stz ZP_TEMP2        ; Y high = 0
    lda #0
    sta ZP_TEMP3        ; Sprite tile 0
    jsr vera_set_sprite
    
    ; Enable player sprite
    lda #0
    jsr vera_enable_sprite
    
    ; Render game-specific objects
    jsr render_game_objects
    
    ; Render UI
    jsr render_ui
    
    rts

render_game_objects:
    ; Render game-specific objects here
    rts

render_ui:
    ; Render score, lives, etc.
    rts

; ==============================================================================
; INPUT HANDLING
; ==============================================================================

read_input:
    ; Read keyboard input and store in ZP_INPUT_STATE
    ; Bit 0: Right/D
    ; Bit 1: Left/A  
    ; Bit 2: Down/S
    ; Bit 3: Up/W
    ; Bit 4: Space
    ; Bit 5: Enter
    ; Bit 6: Escape
    ; Bit 7: Unused
    
    stz ZP_INPUT_STATE
    
    ; Check arrow keys and WASD
    ; (Implementation depends on X16 keyboard interface)
    ; This is a placeholder - implement actual keyboard reading
    
    rts

; ==============================================================================
; GRAPHICS LOADING
; ==============================================================================

load_graphics:
    ; Load game-specific graphics data
    ; Upload tiles, sprites, and palette
    
    ; Load palette
    lda #<game_palette
    sta ZP_PTR1
    lda #>game_palette
    sta ZP_PTR1+1
    jsr vera_upload_palette
    
    ; Load tiles
    lda #<game_tiles
    sta ZP_PTR1
    lda #>game_tiles
    sta ZP_PTR1+1
    lda #<VRAM_TILES
    sta ZP_PTR2
    lda #>VRAM_TILES
    sta ZP_PTR2+1
    lda #16  ; Number of tiles
    jsr vera_upload_tiles
    
    ; Load sprite data
    lda #<game_sprites
    sta ZP_PTR1
    lda #>game_sprites
    sta ZP_PTR1+1
    lda #0   ; Sprite 0
    ldx #4   ; 4 sprites
    jsr vera_upload_sprite_data
    
    rts

; ==============================================================================
; FRAMEWORK INCLUDES
; ==============================================================================

.include "core/x16_system.asm"
.include "core/vera_graphics.asm"

; ==============================================================================
; GAME DATA
; ==============================================================================

; Placeholder graphics data - replace with actual game graphics
game_palette:
    ; 16 colors * 2 bytes each = 32 bytes
    .word $0000, $0F00, $00F0, $0FF0  ; Black, Red, Green, Yellow
    .word $000F, $0F0F, $00FF, $0FFF  ; Blue, Magenta, Cyan, White
    .word $0777, $0AAA, $0DDD, $0222  ; Gray shades
    .word $0F80, $08F0, $080F, $0F8F  ; Orange, Lime, Purple, Pink

game_tiles:
    ; Placeholder tile data - 16 tiles * 32 bytes each
    .repeat 16 * 32
    .byte $00
    .endrepeat

game_sprites:
    ; Placeholder sprite data - 4 sprites * 128 bytes each  
    .repeat 4 * 128
    .byte $00
    .endrepeat
