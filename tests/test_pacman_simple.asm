; ------------------------------------------------------------
; test_pacman_simple.asm
; X16 Assembly program that sets up simple 8x8 text mode for Pacman
; 28 columns x 31 rows without scaling first - get it working
; Then we can add scaling later
; ------------------------------------------------------------

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

; VERA registers
VERA_CTRL          = $9F25
VERA_DC_VIDEO      = $9F29
VERA_DC_HSCALE     = $9F2A
VERA_DC_VSCALE     = $9F2B
VERA_DC_BORDER     = $9F2C

; Layer 1 configuration registers
L1_CONFIG          = $9F34
L1_MAPBASE         = $9F35
L1_TILEBASE        = $9F36
L1_HSCROLL_L       = $9F37
L1_HSCROLL_H       = $9F38
L1_VSCROLL_L       = $9F39
L1_VSCROLL_H       = $9F3A

; Load address segment
.segment "LOADADDR"
    .word $0801         ; load address

; BASIC stub header
.segment "EXEHDR"
    .word $080B         ; next line address
    .word 2024          ; line number
    .byte $9E           ; SYS token
    .byte "2061"        ; address string (2061 = $080D)
    .byte $00           ; end of line
    .word $0000         ; end of program

; Main code
.segment "CODE"
start:
    ; Log start of program
    lda #1
    sta ASM_LOG_INFO
    
    ; Set DCSEL to 0 for display composer registers
    lda #0
    sta VERA_CTRL
    
    ; Use standard 1x scaling for now (128 = 1x)
    lda #128
    sta VERA_DC_HSCALE
    lda #128
    sta VERA_DC_VSCALE
    
    ; Set border color to black
    lda #0
    sta VERA_DC_BORDER
    
    ; Configure Layer 1 for 8x8 tile mode
    ; Map Width=1 (64 tiles), Map Height=1 (64 tiles) - gives us room for 28x31
    ; Color Depth=0 (1bpp), Bitmap Mode=0 (tile mode)
    ; Tile Width=0 (8 pixels), Tile Height=0 (8 pixels)
    lda #%00110000      ; Map Height=1, Map Width=1, T256C=0, Bitmap=0, Color Depth=0
    sta L1_CONFIG
    
    ; Set map base to $1B000 (standard text mode location)
    lda #$B0            ; $1B000 >> 9 = $B0
    sta L1_MAPBASE
    
    ; Set tile base to $1F000 (standard charset location)
    ; Tile Width=0 (8px), Tile Height=0 (8px)
    lda #$F0            ; ($1F000 >> 11) << 2 = $F0, plus tile size bits
    sta L1_TILEBASE
    
    ; Reset scroll registers
    lda #0
    sta L1_HSCROLL_L
    sta L1_HSCROLL_H
    sta L1_VSCROLL_L
    sta L1_VSCROLL_H
    
    ; Enable Layer 1 and VGA output
    lda #%00110001      ; Layer1 Enable=1, Layer0 Enable=1, Sprites=0, VGA output
    sta VERA_DC_VIDEO
    
    ; Log that video mode is configured
    lda #2
    sta ASM_LOG_INFO
    
    ; Display Pacman layout test
    jsr display_pacman_test
    
    ; Test scrolling
    jsr test_scrolling
    
    ; Log completion
    lda #3
    sta ASM_LOG_INFO
    
    ; Infinite loop
loop:
    jmp loop

; Display a test pattern showing Pacman's 28x31 layout
display_pacman_test:
    ; Put some text on screen using KERNAL
    ldx #0
text_loop:
    lda message,x
    beq text_done
    jsr $FFD2           ; KERNAL CHROUT
    inx
    bne text_loop
text_done:
    
    ; Draw a simple Pacman-style border
    jsr draw_pacman_border
    rts

; Draw a border to show the 28x31 Pacman area
draw_pacman_border:
    ; Move cursor to start of Pacman area (row 5)
    lda #5
    jsr set_cursor_row
    
    ; Draw top border
    ldx #0
top_loop:
    lda #$2D            ; '-' character
    jsr $FFD2
    inx
    cpx #28
    bne top_loop
    
    ; Draw some side borders
    ldy #6              ; Start at row 6
side_loop:
    ; Set cursor to start of row
    tya
    jsr set_cursor_row
    lda #$7C            ; '|' character
    jsr $FFD2
    
    ; Move to end of row (column 27)
    ldx #26
move_right:
    lda #$20            ; Space
    jsr $FFD2
    dex
    bne move_right
    
    lda #$7C            ; '|' character
    jsr $FFD2
    
    iny
    cpy #36             ; 31 rows + 5 offset
    bne side_loop
    
    ; Draw bottom border
    tya
    jsr set_cursor_row
    ldx #0
bottom_loop:
    lda #$2D            ; '-' character
    jsr $FFD2
    inx
    cpx #28
    bne bottom_loop
    rts

; Set cursor to beginning of row A
set_cursor_row:
    ; Simple cursor positioning
    tax
    lda #13             ; CR
    jsr $FFD2
    dex
    bne set_cursor_row
    rts

; Test scrolling
test_scrolling:
    lda #0
    sta scroll_counter
    
scroll_loop:
    ; Delay
    ldy #$40
delay_outer3:
    ldx #$40
delay_inner3:
    dex
    bne delay_inner3
    dey
    bne delay_outer3
    
    ; Increment scroll
    inc scroll_counter
    lda scroll_counter
    
    ; Set horizontal scroll
    sta L1_HSCROLL_L
    lda #0
    sta L1_HSCROLL_H
    
    ; Set vertical scroll (slower)
    lda scroll_counter
    lsr
    lsr
    sta L1_VSCROLL_L
    lda #0
    sta L1_VSCROLL_H
    
    ; Log occasionally
    lda scroll_counter
    and #$1F            ; Every 32 iterations
    bne skip_scroll_log2
    
    lda scroll_counter
    sta ASM_LOG_PARAM1
    lda scroll_counter
    lsr
    lsr
    sta ASM_LOG_PARAM2
    lda #3              ; "Player position: X=%1, Y=%2"
    sta ASM_LOG_INFO
    
skip_scroll_log2:
    ; Continue for a while
    lda scroll_counter
    cmp #128
    bne scroll_loop
    rts

; Message to display
message:
    .byte "PACMAN 8X8 TEXT MODE TEST", 13
    .byte "28X31 LAYOUT - NO SCALING", 13
    .byte "8X8 TILES = 224X248 PIXELS", 13, 0

; Variables
.segment "BSS"
scroll_counter:     .res 1
