e; Pacman 4bpp Palette Test
; Demonstrates 4bpp tile mode with palette offsets for colorful Pacman graphics
; Shows how to use multiple 16-color palettes for different game elements
; Uses the configured assembly logging system

.org $0801

; BASIC stub: 10 SYS 2064
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62
ASM_LOG_WARNING    = $9F63
ASM_LOG_ERROR      = $9F64

; VERA registers
VERA_ADDR_LOW      = $9F20
VERA_ADDR_MID      = $9F21
VERA_ADDR_HIGH     = $9F22
VERA_DATA0         = $9F23
VERA_DATA1         = $9F24
VERA_CTRL          = $9F25
VERA_DC_VIDEO      = $9F29
VERA_DC_HSCALE     = $9F2A
VERA_DC_VSCALE     = $9F2B
VERA_DC_BORDER     = $9F2C
VERA_L0_CONFIG     = $9F2D
VERA_L0_MAPBASE    = $9F2E
VERA_L0_TILEBASE   = $9F2F

; Screen layout constants
SCREEN_WIDTH       = 40
SCREEN_HEIGHT      = 30
PLAYFIELD_WIDTH    = 28
UI_WIDTH           = 12

; VRAM addresses
TILEMAP_BASE       = $1B000  ; Tilemap at $1B000
TILEDATA_BASE      = $10000  ; Tile graphics at $10000
PALETTE_BASE       = $1FA00  ; Palette at $1FA00

; Color definitions (12-bit RGB values)
COLOR_BLACK        = $000
COLOR_BLUE         = $00F
COLOR_YELLOW       = $FF0
COLOR_WHITE        = $FFF
COLOR_RED          = $F00
COLOR_PINK         = $F0F
COLOR_CYAN         = $0FF
COLOR_ORANGE       = $F80
COLOR_GREEN        = $0F0
COLOR_PURPLE       = $80F
COLOR_BROWN        = $840
COLOR_LIGHT_BLUE   = $8FF
COLOR_DARK_GRAY    = $444
COLOR_MEDIUM_GRAY  = $888
COLOR_LIGHT_GRAY   = $CCC
COLOR_LIME         = $8F0

start:
    ; Log: System initialized
    lda #1
    sta ASM_LOG_INFO
    
    ; Initialize VERA for 4bpp tile mode
    jsr init_vera_4bpp
    
    ; Set up custom palette for Pacman
    jsr setup_pacman_palette
    
    ; Create sample tile graphics
    jsr create_sample_tiles
    
    ; Fill screen with demonstration tiles
    jsr fill_demo_screen
    
    ; Log: Test complete
    lda #20
    sta ASM_LOG_INFO
    
    ; Infinite loop to display result
loop:
    jmp loop

; Initialize VERA for 4bpp tile mode
init_vera_4bpp:
    ; Log: Initializing 4bpp mode
    lda #17
    sta ASM_LOG_INFO
    
    ; Set VERA address select to 0
    lda #0
    sta VERA_CTRL
    
    ; Configure display composer for tile mode
    ; Enable Layer 0, disable sprites and layer 1
    lda #%00010000      ; Layer 0 enable, VGA output
    sta VERA_DC_VIDEO
    
    ; Set 2x scaling for 320x240 effective resolution
    lda #64             ; 2x scale
    sta VERA_DC_HSCALE
    lda #64             ; 2x scale  
    sta VERA_DC_VSCALE
    
    ; Set border color to black
    lda #0
    sta VERA_DC_BORDER
    
    ; Configure Layer 0 for 4bpp tile mode
    ; Map Width=1 (64 tiles), Map Height=0 (32 tiles), 4bpp, tile mode
    lda #%00010010      ; Map Width=1, Map Height=0, T256C=0, Bitmap=0, Color Depth=2 (4bpp)
    sta VERA_L0_CONFIG
    
    ; Log register setting
    lda #$2D            ; L0_CONFIG register number
    sta ASM_LOG_PARAM1
    lda #%00010010      ; Value we set
    sta ASM_LOG_PARAM2
    lda #15
    sta ASM_LOG_INFO
    
    ; Set map base address (bits 16:9 of $1B000 = $D8)
    lda #$D8            ; $1B000 >> 9 = $D8
    sta VERA_L0_MAPBASE
    
    ; Set tile base address (bits 16:11 of $10000 = $40)
    ; Also set tile size to 8x8 (both bits = 0)
    lda #$40            ; $10000 >> 11 = $40, tile size 8x8
    sta VERA_L0_TILEBASE
    
    rts

; Set up custom palette for Pacman colors
setup_pacman_palette:
    ; Log: Setting up palette
    lda #18
    sta ASM_LOG_INFO
    
    ; Set VERA address to palette base with increment 1
    lda #<PALETTE_BASE
    sta VERA_ADDR_LOW
    lda #>PALETTE_BASE
    sta VERA_ADDR_MID
    lda #(^PALETTE_BASE | $10)  ; Auto-increment 1
    sta VERA_ADDR_HIGH
    
    ; Palette 0 (colors 0-15): Maze and basic elements
    ; Color 0: Black (transparent)
    lda #<COLOR_BLACK
    sta VERA_DATA0
    lda #>COLOR_BLACK
    sta VERA_DATA0
    
    ; Color 1: Blue (maze walls)
    lda #<COLOR_BLUE
    sta VERA_DATA0
    lda #>COLOR_BLUE
    sta VERA_DATA0
    
    ; Color 2: Yellow (pellets, Pacman)
    lda #<COLOR_YELLOW
    sta VERA_DATA0
    lda #>COLOR_YELLOW
    sta VERA_DATA0
    
    ; Color 3: White (power pellets, text)
    lda #<COLOR_WHITE
    sta VERA_DATA0
    lda #>COLOR_WHITE
    sta VERA_DATA0
    
    ; Color 4: Red (Blinky ghost)
    lda #<COLOR_RED
    sta VERA_DATA0
    lda #>COLOR_RED
    sta VERA_DATA0
    
    ; Color 5: Pink (Pinky ghost)
    lda #<COLOR_PINK
    sta VERA_DATA0
    lda #>COLOR_PINK
    sta VERA_DATA0
    
    ; Color 6: Cyan (Inky ghost)
    lda #<COLOR_CYAN
    sta VERA_DATA0
    lda #>COLOR_CYAN
    sta VERA_DATA0
    
    ; Color 7: Orange (Sue ghost)
    lda #<COLOR_ORANGE
    sta VERA_DATA0
    lda #>COLOR_ORANGE
    sta VERA_DATA0
    
    ; Colors 8-15: Additional game colors
    lda #<COLOR_GREEN
    sta VERA_DATA0
    lda #>COLOR_GREEN
    sta VERA_DATA0
    
    lda #<COLOR_PURPLE
    sta VERA_DATA0
    lda #>COLOR_PURPLE
    sta VERA_DATA0
    
    lda #<COLOR_BROWN
    sta VERA_DATA0
    lda #>COLOR_BROWN
    sta VERA_DATA0
    
    lda #<COLOR_LIGHT_BLUE
    sta VERA_DATA0
    lda #>COLOR_LIGHT_BLUE
    sta VERA_DATA0
    
    lda #<COLOR_DARK_GRAY
    sta VERA_DATA0
    lda #>COLOR_DARK_GRAY
    sta VERA_DATA0
    
    lda #<COLOR_MEDIUM_GRAY
    sta VERA_DATA0
    lda #>COLOR_MEDIUM_GRAY
    sta VERA_DATA0
    
    lda #<COLOR_LIGHT_GRAY
    sta VERA_DATA0
    lda #>COLOR_LIGHT_GRAY
    sta VERA_DATA0
    
    lda #<COLOR_LIME
    sta VERA_DATA0
    lda #>COLOR_LIME
    sta VERA_DATA0
    
    ; Palette 1 (colors 16-31): UI and score elements
    ; Set up a grayscale + accent palette for UI
    ldx #16
palette1_loop:
    ; Create grayscale ramp with some accent colors
    txa
    and #$0F
    asl
    asl
    asl
    asl
    sta VERA_DATA0      ; Low byte
    lda #$00
    sta VERA_DATA0      ; High byte
    
    inx
    cpx #32
    bne palette1_loop
    
    rts

; Create sample tile graphics in VRAM
create_sample_tiles:
    ; Log: Creating tile graphics
    lda #19
    sta ASM_LOG_INFO
    
    ; Set VERA address to tile graphics base
    lda #<TILEDATA_BASE
    sta VERA_ADDR_LOW
    lda #>TILEDATA_BASE
    sta VERA_ADDR_MID
    lda #(^TILEDATA_BASE | $10)  ; Auto-increment 1
    sta VERA_ADDR_HIGH
    
    ; Tile 0: Solid block (maze wall)
    ; Each byte contains 2 pixels (4 bits each)
    ; Pixel format: high nibble = left pixel, low nibble = right pixel
    ldy #32             ; 32 bytes per 8x8 4bpp tile
tile0_loop:
    lda #$11            ; Both pixels = color 1 (blue)
    sta VERA_DATA0
    dey
    bne tile0_loop
    
    ; Tile 1: Small pellet (centered dot)
    ; Create a small yellow dot in center
    lda #$00            ; Row 0: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 1: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 2: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 3: start pellet
    sta VERA_DATA0
    lda #$22            ; Center pixels = color 2 (yellow)
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 4: continue pellet
    sta VERA_DATA0
    lda #$22            ; Center pixels = color 2 (yellow)
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 5: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 6: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 7: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    ; Tile 2: Power pellet (larger dot)
    lda #$00            ; Row 0: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    lda #$00            ; Row 1: start power pellet
    sta VERA_DATA0
    lda #$33            ; Color 3 (white)
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    
    lda #$03            ; Row 2: full width
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$30
    sta VERA_DATA0
    
    lda #$03            ; Row 3: full width
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$30
    sta VERA_DATA0
    
    lda #$03            ; Row 4: full width
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$30
    sta VERA_DATA0
    
    lda #$03            ; Row 5: full width
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$30
    sta VERA_DATA0
    
    lda #$00            ; Row 6: end power pellet
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    
    lda #$00            ; Row 7: transparent
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    sta VERA_DATA0
    
    ; Tile 3: Ghost (red - Blinky)
    ; Simple ghost shape using color 4 (red)
    lda #$00            ; Row 0: transparent
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$00
    sta VERA_DATA0
    
    lda #$04            ; Row 1: ghost head
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$40
    sta VERA_DATA0
    
    lda #$44            ; Row 2: full ghost
    sta VERA_DATA0
    lda #$33            ; Eyes (white)
    sta VERA_DATA0
    lda #$33
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    
    lda #$44            ; Row 3: ghost body
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    
    lda #$44            ; Row 4: ghost body
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    
    lda #$44            ; Row 5: ghost body
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    
    lda #$44            ; Row 6: ghost bottom
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    lda #$44
    sta VERA_DATA0
    
    lda #$40            ; Row 7: ghost feet
    sta VERA_DATA0
    lda #$04
    sta VERA_DATA0
    lda #$40
    sta VERA_DATA0
    lda #$04
    sta VERA_DATA0
    
    rts

; Fill screen with demonstration tiles
fill_demo_screen:
    ; Set VERA address to tilemap base
    lda #<TILEMAP_BASE
    sta VERA_ADDR_LOW
    lda #>TILEMAP_BASE
    sta VERA_ADDR_MID
    lda #(^TILEMAP_BASE | $10)  ; Auto-increment 1
    sta VERA_ADDR_HIGH
    
    ; Fill screen with pattern demonstrating different tiles and palettes
    ldy #0              ; Row counter
row_loop:
    ldx #0              ; Column counter
col_loop:
    ; Determine tile and palette based on position
    txa
    cmp #PLAYFIELD_WIDTH
    bcs ui_area
    
    ; Playfield area - create a pattern
    tya
    and #$03
    beq wall_tile
    
    txa
    and #$03
    beq pellet_tile
    cmp #$02
    beq power_pellet_tile
    
    ; Ghost tile
    lda #$03            ; Tile 3 (ghost)
    sta VERA_DATA0
    lda #$00            ; Palette 0
    sta VERA_DATA0
    jmp next_col
    
wall_tile:
    lda #$00            ; Tile 0 (wall)
    sta VERA_DATA0
    lda #$00            ; Palette 0
    sta VERA_DATA0
    jmp next_col
    
pellet_tile:
    lda #$01            ; Tile 1 (pellet)
    sta VERA_DATA0
    lda #$00            ; Palette 0
    sta VERA_DATA0
    jmp next_col
    
power_pellet_tile:
    lda #$02            ; Tile 2 (power pellet)
    sta VERA_DATA0
    lda #$00            ; Palette 0
    sta VERA_DATA0
    jmp next_col
    
ui_area:
    ; UI area - use different palette
    lda #$01            ; Tile 1 (pellet as UI element)
    sta VERA_DATA0
    lda #$10            ; Palette 1 (palette offset = 1)
    sta VERA_DATA0
    
next_col:
    inx
    cpx #SCREEN_WIDTH
    bne col_loop
    
    ; Log progress every 8 rows
    tya
    and #$07
    bne skip_log
    
    ; Log current row
    tya
    sta ASM_LOG_PARAM1
    lda #$2A            ; '*' character for progress
    sta ASM_LOG_PARAM2
    lda #16
    sta ASM_LOG_INFO
    
skip_log:
    iny
    cpy #SCREEN_HEIGHT
    bne row_loop
    
    rts
