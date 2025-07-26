; ==============================================================================
; PAC-MAN FOR COMMANDER X16
; ==============================================================================
; A faithful recreation of Pac-Man using the X16 Game Development Framework
; Based on the original arcade machine layout and behavior
; ==============================================================================

; Include constants first
.include "core/x16_constants.inc"

; ==============================================================================
; PROGRAM HEADER
; ==============================================================================

.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

; Include framework modules
.include "core/x16_system.asm"
.include "core/vera_graphics.asm"

; BASIC header for X16
.word $0801
.byte $0C, $08, $0A, $00, $9E, $20, $32, $30, $36, $34, $00, $00, $00

; Program entry point
main:
    jmp game_start

; ==============================================================================
; GAME-SPECIFIC CONSTANTS
; ==============================================================================

; Pac-Man maze dimensions (from original arcade)
MAZE_WIDTH       = 28        ; Maze width in tiles
MAZE_HEIGHT      = 31        ; Maze height in tiles (playfield rows 3-33)

; Tile definitions (matching original Pac-Man)
TILE_SPACE       = $40       ; Empty space
TILE_DOT         = $10       ; Small dot
TILE_PILL        = $14       ; Power pellet
TILE_DOOR        = $CF       ; Ghost house door

; Wall tiles (from original ROM)
TILE_WALL_UL     = $D1       ; Upper left corner
TILE_WALL_UR     = $D0       ; Upper right corner
TILE_WALL_LL     = $D5       ; Lower left corner
TILE_WALL_LR     = $D4       ; Lower right corner
TILE_WALL_H      = $DB       ; Horizontal wall
TILE_WALL_V      = $D3       ; Vertical wall (left)
TILE_WALL_VR     = $D2       ; Vertical wall (right)
TILE_WALL_T      = $DC       ; T-junction

; More wall pieces
TILE_WALL_BL     = $DF       ; Bottom left
TILE_WALL_BR     = $E6       ; Bottom right
TILE_WALL_TL     = $E7       ; Top left
TILE_WALL_TR     = $EA       ; Top right

; Game states
GAME_STATE_INIT     = STATE_INIT
GAME_STATE_ATTRACT  = STATE_ATTRACT  
GAME_STATE_PLAYING  = STATE_GAME
GAME_STATE_GAMEOVER = STATE_GAMEOVER

; Game-specific zero page variables (starting at ZP_GAME_START)
game_state     = ZP_GAME_START + 0
pacman_x       = ZP_GAME_START + 1
pacman_y       = ZP_GAME_START + 2
pacman_dir     = ZP_GAME_START + 3
score_lo       = ZP_GAME_START + 4
score_mid      = ZP_GAME_START + 5
score_hi       = ZP_GAME_START + 6
lives          = ZP_GAME_START + 7
level          = ZP_GAME_START + 8
dots_remaining = ZP_GAME_START + 9

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
    
    ; Upload tile graphics to VRAM first
    jsr upload_tile_graphics
    
    ; Set up tilemap layer for maze
    lda #0              ; Layer 0
    ldx #MAP_32x32      ; 32x32 tile map
    ldy #0              ; 8x8 tiles
    jsr vera_setup_tilemap
    
    ; Set up sprites for characters
    jsr vera_setup_sprites
    
    ; Initialize game variables
    lda #3
    sta lives
    
    lda #1
    sta level
    
    stz score_lo
    stz score_mid
    stz score_hi
    
    ; Clear screen and set up colors
    jsr clear_screen
    
    ; Draw the authentic Pac-Man maze
    jsr draw_pacman_maze
    
    ; Set initial Pac-Man position (center of maze)
    lda #14             ; X = 14 (center)
    sta pacman_x
    lda #26             ; Y = 26 (Pac-Man starting position)
    sta pacman_y
    
    lda #DIR_LEFT       ; Start facing left
    sta pacman_dir
    
    ; Count initial dots
    jsr count_dots
    
    ; Transition to attract mode
    lda #GAME_STATE_ATTRACT
    sta game_state
    
    rts

; ==============================================================================
; TILE GRAPHICS UPLOAD
; ==============================================================================

upload_tile_graphics:
    ; Upload the ROM tile graphics to VERA tile memory
    ; Source: rom_tiles from pacman_data.asm
    ; Destination: VRAM_TILES ($10000)
    
    ; Set up source pointer
    lda #<rom_tiles
    sta ZP_PTR1
    lda #>rom_tiles
    sta ZP_PTR1+1
    
    ; Upload 64 tiles (each tile is 64 bytes in original format)
    ; We need to convert from 2bpp to 4bpp format
    lda #64             ; Number of tiles to upload
    jsr vera_upload_tiles
    
    rts

; ==============================================================================
; MAZE DRAWING - AUTHENTIC PAC-MAN LAYOUT
; ==============================================================================

draw_pacman_maze:
    ; Draw the authentic Pac-Man maze using the exact layout from the original
    ; This uses the ASCII map from the reference implementation
    
    ; Set up maze data pointer
    lda #<maze_data
    sta ZP_PTR1
    lda #>maze_data
    sta ZP_PTR1+1
    
    ; Draw maze row by row
    ldy #0              ; Maze data index
    ldx #3              ; Start at screen row 3
    
draw_maze_row:
    cpx #34             ; Check if we've drawn all rows (3-33)
    bcs maze_done
    
    ; Draw one row of 28 tiles
    phx                 ; Save row number
    ldx #0              ; Column counter
    
draw_maze_col:
    cpx #28             ; Check if we've drawn all columns
    bcs next_maze_row
    
    ; Get maze character and convert to tile
    lda (ZP_PTR1),y
    jsr ascii_to_tile
    
    ; Set tile position
    pha                 ; Save tile code
    txa                 ; Column to A
    pha                 ; Save column
    plx                 ; Column to X
    pla                 ; Restore tile code
    ply                 ; Row to Y (from stack)
    phx                 ; Save column again
    phy                 ; Save row again
    
    ; Draw the tile
    jsr set_tile
    
    ; Next column
    ply                 ; Restore row
    plx                 ; Restore column
    inx
    iny                 ; Next maze data byte
    bra draw_maze_col
    
next_maze_row:
    plx                 ; Restore row number
    inx                 ; Next row
    bra draw_maze_row
    
maze_done:
    rts

; Convert ASCII maze character to tile code
ascii_to_tile:
    cmp #' '
    beq @space
    cmp #'.'
    beq @dot
    cmp #'P'
    beq @pill
    cmp #'0'
    beq @wall_ul
    cmp #'1'
    beq @wall_ur
    cmp #'2'
    beq @wall_ll
    cmp #'3'
    beq @wall_lr
    cmp #'U'
    beq @wall_h
    cmp #'L'
    beq @wall_v
    cmp #'R'
    beq @wall_vr
    cmp #'B'
    beq @wall_t
    cmp #'-'
    beq @door
    ; Default to space for unknown characters
@space:
    lda #TILE_SPACE
    rts
@dot:
    lda #TILE_DOT
    rts
@pill:
    lda #TILE_PILL
    rts
@wall_ul:
    lda #TILE_WALL_UL
    rts
@wall_ur:
    lda #TILE_WALL_UR
    rts
@wall_ll:
    lda #TILE_WALL_LL
    rts
@wall_lr:
    lda #TILE_WALL_LR
    rts
@wall_h:
    lda #TILE_WALL_H
    rts
@wall_v:
    lda #TILE_WALL_V
    rts
@wall_vr:
    lda #TILE_WALL_VR
    rts
@wall_t:
    lda #TILE_WALL_T
    rts
@door:
    lda #TILE_DOOR
    rts

; Set a tile at position X,Y with tile code A
set_tile:
    ; Calculate VRAM address: VRAM_TILEMAP + (Y * 64) + (X * 2)
    ; Each tile takes 2 bytes (tile code + color)
    pha                 ; Save tile code
    
    ; Calculate Y * 64 (since tilemap is 32 tiles wide, 2 bytes per tile = 64 bytes per row)
    tya
    asl                 ; * 2
    asl                 ; * 4
    asl                 ; * 8
    asl                 ; * 16
    asl                 ; * 32
    asl                 ; * 64
    sta ZP_TEMP1        ; Low byte of Y offset
    
    ; Add X * 2
    txa
    asl                 ; * 2 (2 bytes per tile)
    clc
    adc ZP_TEMP1
    sta ZP_TEMP1        ; Final low byte
    
    ; Set VERA address
    VERA_SET_ADDR VRAM_TILEMAP, 1
    lda VERA_ADDR_LOW
    clc
    adc ZP_TEMP1
    sta VERA_ADDR_LOW
    bcc @no_carry
    inc VERA_ADDR_MID
@no_carry:
    
    ; Write tile code and color
    pla                 ; Restore tile code
    sta VERA_DATA0      ; Write tile
    lda #$0F            ; White color
    sta VERA_DATA0      ; Write color
    
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
    and #$10  ; Check for space key
    beq @no_start
    
    ; Start game
    lda #GAME_STATE_PLAYING
    sta game_state
    
@no_start:
    rts

update_playing:
    ; Update player
    jsr update_player
    
    ; Check for game over conditions
    jsr check_game_over
    
    rts

update_gameover:
    ; Handle game over state
    ; Check for restart input
    jsr read_input
    lda ZP_INPUT_STATE
    and #$10  ; Check for space key
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
    sta pacman_dir
@not_up:
    
    lda ZP_INPUT_STATE
    and #$04  ; Down
    beq @not_down
    lda #DIR_DOWN
    sta pacman_dir
@not_down:
    
    lda ZP_INPUT_STATE
    and #$02  ; Left
    beq @not_left
    lda #DIR_LEFT
    sta pacman_dir
@not_left:
    
    lda ZP_INPUT_STATE
    and #$01  ; Right
    beq @not_right
    lda #DIR_RIGHT
    sta pacman_dir
@not_right:
    
    ; Move player based on direction (simplified for now)
    lda pacman_dir
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
    lda pacman_y
    beq @no_move
    dec pacman_y
    rts
@move_down:
    lda pacman_y
    cmp #30
    bcs @no_move
    inc pacman_y
    rts
@move_left:
    lda pacman_x
    beq @no_move
    dec pacman_x
    rts
@move_right:
    lda pacman_x
    cmp #27
    bcs @no_move
    inc pacman_x
@no_move:
    rts

; ==============================================================================
; COLLISION AND GAME LOGIC
; ==============================================================================

check_game_over:
    ; Check for game over conditions
    ; (player death, level complete, etc.)
    rts

count_dots:
    ; Count dots in maze (placeholder - set to 244 like original)
    lda #244
    sta dots_remaining
    rts

; ==============================================================================
; RENDERING
; ==============================================================================

game_render:
    ; Render Pac-Man sprite
    lda #0              ; Sprite 0
    ldx pacman_x        ; X position
    ldy pacman_y        ; Y position
    
    ; Convert tile coordinates to pixel coordinates
    ; X pixel = tile_x * 8 + offset
    txa
    asl
    asl
    asl                 ; * 8
    clc
    adc #16             ; Add offset
    tax
    
    ; Y pixel = tile_y * 8 + offset  
    tya
    asl
    asl
    asl                 ; * 8
    clc
    adc #24             ; Add offset (account for top UI area)
    tay
    
    stz ZP_TEMP1        ; X high = 0
    stz ZP_TEMP2        ; Y high = 0
    lda #0              ; Pac-Man sprite tile
    sta ZP_TEMP3
    jsr vera_set_sprite
    
    ; Enable Pac-Man sprite
    lda #0
    jsr vera_enable_sprite
    
    rts

; ==============================================================================
; UTILITY FUNCTIONS
; ==============================================================================

clear_screen:
    ; Clear the tilemap to show empty tiles
    VERA_SET_ADDR VRAM_TILEMAP, 1
    
    ldx #0
    ldy #0
@clear_loop:
    lda #TILE_SPACE     ; Use space tile
    sta VERA_DATA0      ; Write tile
    lda #$0F            ; White color
    sta VERA_DATA0      ; Write color
    inx
    cpx #32
    bne @clear_loop
    ldx #0
    iny
    cpy #32
    bne @clear_loop
    
    rts

read_input:
    ; Read keyboard input and store in ZP_INPUT_STATE
    ; This is a placeholder - implement actual keyboard reading
    stz ZP_INPUT_STATE
    rts

; ==============================================================================
; MAZE DATA - AUTHENTIC PAC-MAN LAYOUT
; ==============================================================================
; This is the exact maze from the original Pac-Man arcade machine
; Converted from the ASCII representation in the reference code

maze_data:
    ; Row 3 (top border)
    .byte "0UUUUUUUUUUUU45UUUUUUUUUUUU1"
    ; Row 4
    .byte "L............rl............R"
    ; Row 5
    .byte "L.ebbf.ebbbf.rl.ebbbf.ebbf.R"
    ; Row 6
    .byte "LPr  l.r   l.rl.r   l.r  lPR"
    ; Row 7
    .byte "L.guuh.guuuh.gh.guuuh.guuh.R"
    ; Row 8
    .byte "L..........................R"
    ; Row 9
    .byte "L.ebbf.ef.ebbbbbbf.ef.ebbf.R"
    ; Row 10
    .byte "L.guuh.rl.guuyxuuh.rl.guuh.R"
    ; Row 11
    .byte "L......rl....rl....rl......R"
    ; Row 12
    .byte "2BBBBf.rzbbf rl ebbwl.eBBBB3"
    ; Row 13
    .byte "     L.rxuuh gh guuyl.R     "
    ; Row 14
    .byte "     L.rl          rl.R     "
    ; Row 15
    .byte "     L.rl mjs--tjn rl.R     "
    ; Row 16
    .byte "UUUUUh.gh i      q gh.gUUUUU"
    ; Row 17
    .byte "      .   i      q   .      "
    ; Row 18
    .byte "BBBBBf.ef i      q ef.eBBBBB"
    ; Row 19
    .byte "     L.rl okkkkkkp rl.R     "
    ; Row 20
    .byte "     L.rl          rl.R     "
    ; Row 21
    .byte "     L.rl ebbbbbbf rl.R     "
    ; Row 22
    .byte "0UUUUh.gh guuyxuuh gh.gUUUU1"
    ; Row 23
    .byte "L............rl............R"
    ; Row 24
    .byte "L.ebbf.ebbbf.rl.ebbbf.ebbf.R"
    ; Row 25
    .byte "L.guyl.guuuh.gh.guuuh.rxuh.R"
    ; Row 26
    .byte "LP..rl.......  .......rl..PR"
    ; Row 27
    .byte "6bf.rl.ef.ebbbbbbf.ef.rl.eb8"
    ; Row 28
    .byte "7uh.gh.rl.guuyxuuh.rl.gh.gu9"
    ; Row 29
    .byte "L......rl....rl....rl......R"
    ; Row 30
    .byte "L.ebbbbwzbbf.rl.ebbwzbbbbf.R"
    ; Row 31
    .byte "L.guuuuuuuuh.gh.guuuuuuuuh.R"
    ; Row 32
    .byte "L..........................R"
    ; Row 33 (bottom border)
    .byte "2BBBBBBBBBBBBBBBBBBBBBBBBBB3"

; Include the data file for sprites and tiles
.include "pacman_data.asm"
