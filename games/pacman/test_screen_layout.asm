; Pacman Screen Layout Test
; Tests basic 40x31 tile mode setup with playfield (*) and UI (#) areas
; Uses assembly logging system for debugging

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
PLAYFIELD_WIDTH    = 28
UI_WIDTH           = 12
TOTAL_WIDTH        = 40
SCREEN_HEIGHT      = 31

; Character codes
CHAR_ASTERISK      = $2A    ; '*' character
CHAR_HASH          = $23    ; '#' character

; VRAM addresses
TILEMAP_BASE       = $1B000  ; Tilemap at $1B000
CHARSET_BASE       = $1F000  ; Character set at $1F000

start:
    ; Log: Initializing screen layout test
    lda #10
    sta ASM_LOG_INFO
    
    ; Set VERA address select to 0
    lda #0
    sta VERA_CTRL
    
    ; Configure display composer for tile mode
    ; Set DCSEL to 0 for video configuration
    lda #0
    sta VERA_CTRL
    
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
    
    ; Log: Setting VERA tile mode 40x31
    lda #11
    sta ASM_LOG_INFO
    
    ; Configure Layer 0 for tile mode
    ; Map Width=1 (64 tiles), Map Height=0 (32 tiles), 1bpp, tile mode
    lda #%00010000      ; Map Width=1, Map Height=0, T256C=0, Bitmap=0, Color Depth=0 (1bpp)
    sta VERA_L0_CONFIG
    
    ; Set map base address (bits 16:9 of $1B000 = $D8)
    lda #$D8            ; $1B000 >> 9 = $D8
    sta VERA_L0_MAPBASE
    
    ; Set tile base address (bits 16:11 of $1F000 = $7C)
    ; Also set tile size to 8x8 (both bits = 0)
    lda #$7C            ; $1F000 >> 11 = $7C, tile size 8x8
    sta VERA_L0_TILEBASE
    
    ; Log register settings
    lda #$2D            ; L0_CONFIG register number
    sta ASM_LOG_PARAM1
    lda #%00010000      ; Value we set
    sta ASM_LOG_PARAM2
    lda #15
    sta ASM_LOG_INFO
    
    ; Clear the tilemap first (set all to space character)
    jsr clear_tilemap
    
    ; Log: Filling playfield area with *
    lda #12
    sta ASM_LOG_INFO
    
    ; Fill playfield area (columns 0-27) with asterisk
    jsr fill_playfield
    
    ; Log: Filling UI area with #
    lda #13
    sta ASM_LOG_INFO
    
    ; Fill UI area (columns 28-39) with hash
    jsr fill_ui_area
    
    ; Log: Screen layout test complete
    lda #14
    sta ASM_LOG_INFO
    
    ; Infinite loop to display result
loop:
    jmp loop

; Clear entire tilemap to spaces
clear_tilemap:
    ; Set VERA address to tilemap base with increment 1
    lda #<TILEMAP_BASE
    sta VERA_ADDR_LOW
    lda #>TILEMAP_BASE
    sta VERA_ADDR_MID
    lda #(^TILEMAP_BASE | $10)  ; Auto-increment 1
    sta VERA_ADDR_HIGH
    
    ; Clear all 40x31 = 1240 tile entries (2 bytes each = 2480 bytes)
    ldx #0
    ldy #0
clear_loop:
    lda #$20            ; Space character
    sta VERA_DATA0
    lda #$01            ; White on black
    sta VERA_DATA0
    
    inx
    bne clear_continue
    iny
    cpy #10             ; 2480 bytes = 10 * 256 - 80
    bcs clear_done
clear_continue:
    cpx #80
    bne clear_loop
    cpy #9
    bne clear_loop
    
clear_done:
    rts

; Fill playfield area (columns 0-27, rows 0-30) with asterisk
fill_playfield:
    ldy #0              ; Row counter
fill_row_loop:
    ; Calculate tilemap address for this row
    ; Address = TILEMAP_BASE + (row * TOTAL_WIDTH * 2)
    lda #<TILEMAP_BASE
    clc
    adc row_offset_low,y
    sta VERA_ADDR_LOW
    
    lda #>TILEMAP_BASE
    adc row_offset_high,y
    sta VERA_ADDR_MID
    
    lda #^TILEMAP_BASE
    adc row_offset_bank,y
    ora #$10            ; Auto-increment 1
    sta VERA_ADDR_HIGH
    
    ; Fill 28 columns with asterisk
    ldx #0
fill_col_loop:
    lda #CHAR_ASTERISK  ; '*' character
    sta VERA_DATA0
    lda #$0E            ; Yellow on black
    sta VERA_DATA0
    
    inx
    cpx #PLAYFIELD_WIDTH
    bne fill_col_loop
    
    ; Log progress every 10 rows
    tya
    and #$0F
    bne skip_log
    
    ; Log current row
    tya
    sta ASM_LOG_PARAM1
    lda #CHAR_ASTERISK
    sta ASM_LOG_PARAM2
    lda #16
    sta ASM_LOG_INFO
    
skip_log:
    iny
    cpy #SCREEN_HEIGHT
    bne fill_row_loop
    
    rts

; Fill UI area (columns 28-39, rows 0-30) with hash
fill_ui_area:
    ldy #0              ; Row counter
ui_row_loop:
    ; Calculate tilemap address for UI area of this row
    ; Address = TILEMAP_BASE + (row * TOTAL_WIDTH * 2) + (PLAYFIELD_WIDTH * 2)
    lda #<TILEMAP_BASE
    clc
    adc row_offset_low,y
    adc #(PLAYFIELD_WIDTH * 2)  ; Skip to UI area
    sta VERA_ADDR_LOW
    
    lda #>TILEMAP_BASE
    adc row_offset_high,y
    bcc no_carry
    adc #0
no_carry:
    sta VERA_ADDR_MID
    
    lda #^TILEMAP_BASE
    adc row_offset_bank,y
    ora #$10            ; Auto-increment 1
    sta VERA_ADDR_HIGH
    
    ; Fill 12 columns with hash
    ldx #0
ui_col_loop:
    lda #CHAR_HASH      ; '#' character
    sta VERA_DATA0
    lda #$0C            ; Light blue on black
    sta VERA_DATA0
    
    inx
    cpx #UI_WIDTH
    bne ui_col_loop
    
    iny
    cpy #SCREEN_HEIGHT
    bne ui_row_loop
    
    rts

; Row offset tables for tilemap addressing
; Each row is TOTAL_WIDTH * 2 bytes apart
row_offset_low:
    .byte $00, $50, $A0, $F0, $40, $90, $E0, $30
    .byte $80, $D0, $20, $70, $C0, $10, $60, $B0
    .byte $00, $50, $A0, $F0, $40, $90, $E0, $30
    .byte $80, $D0, $20, $70, $C0, $10, $60

row_offset_high:
    .byte $00, $00, $00, $00, $01, $01, $01, $02
    .byte $02, $02, $03, $03, $03, $04, $04, $04
    .byte $05, $05, $05, $05, $06, $06, $06, $07
    .byte $07, $07, $08, $08, $08, $09, $09

row_offset_bank:
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00
