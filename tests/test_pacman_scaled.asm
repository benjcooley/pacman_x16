; ------------------------------------------------------------
; test_pacman_scaled.asm
; X16 Assembly program that sets up scaled video mode for Pacman
; 8x8 tiles in 28x31 layout, scaled to fill 320x200 display
; Horizontal scale: 366 (Q8 for 1.428571x)
; Vertical scale: 206 (Q8 for 0.806452x)
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
    
    ; Configure display scaling using Q8 fixed-point values
    ; Horizontal scale: 366 (Q8 for 320/224 = 1.428571)
    lda #366 & $FF     ; Low byte of 366
    sta VERA_DC_HSCALE
    
    ; Vertical scale: 206 (Q8 for 200/248 = 0.806452)  
    lda #206
    sta VERA_DC_VSCALE
    
    ; Set border color to black
    lda #0
    sta VERA_DC_BORDER
    
    ; Configure Layer 1 for 8x8 tile mode
    ; Map Width=0 (32 tiles), Map Height=1 (64 tiles) - gives us room for 28x31
    ; Color Depth=0 (1bpp), Bitmap Mode=0 (tile mode)
    ; Tile Width=0 (8 pixels), Tile Height=0 (8 pixels)
    lda #%00010000      ; Map Height=1, Map Width=0, T256C=0, Bitmap=0, Color Depth=0
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
    
    ; Test scrolling with scaling
    jsr test_scaled_scrolling
    
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
    
    ; Draw border around the 28x31 area to show scaling
    jsr draw_border
    rts

; Draw a border to visualize the 28x31 Pacman area
draw_border:
    ; Top border (row 3, columns 0-27)
    ldy #3              ; Start at row 3 (after score area)
    ldx #0              ; Start at column 0
top_border:
    jsr set_cursor_xy
    lda #$2D            ; '-' character
    jsr $FFD2
    inx
    cpx #28
    bne top_border
    
    ; Bottom border (row 34, columns 0-27) 
    ldy #34             ; Row 34 (after 31 maze rows)
    ldx #0
bottom_border:
    jsr set_cursor_xy
    lda #$2D            ; '-' character
    jsr $FFD2
    inx
    cpx #28
    bne bottom_border
    
    ; Left and right borders
    ldy #4              ; Start at row 4
side_borders:
    ; Left border
    ldx #0
    jsr set_cursor_xy
    lda #$7C            ; '|' character
    jsr $FFD2
    
    ; Right border  
    ldx #27
    jsr set_cursor_xy
    lda #$7C            ; '|' character
    jsr $FFD2
    
    iny
    cpy #34
    bne side_borders
    rts

; Set cursor to X,Y position
set_cursor_xy:
    ; Convert X,Y to screen position and set cursor
    ; This is a simplified version - in real Pacman we'd write directly to VRAM
    clc
    tya
    adc #$20            ; Add offset to avoid overwriting our message
    tay
    txa
    clc
    adc #$20
    tax
    rts

; Test scrolling with the scaled display
test_scaled_scrolling:
    lda #0
    sta scroll_counter
    
scroll_loop:
    ; Small delay
    ldy #$20
delay_outer2:
    ldx #$20
delay_inner2:
    dex
    bne delay_inner2
    dey
    bne delay_outer2
    
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
    lsr                 ; Divide by 4 for slower vertical scroll
    sta L1_VSCROLL_L
    lda #0
    sta L1_VSCROLL_H
    
    ; Log scroll values occasionally
    lda scroll_counter
    and #$3F            ; Every 64 iterations
    bne skip_scroll_log
    
    lda scroll_counter
    sta ASM_LOG_PARAM1
    lda scroll_counter
    lsr
    lsr
    sta ASM_LOG_PARAM2
    lda #3              ; "Player position: X=%1, Y=%2"
    sta ASM_LOG_INFO
    
skip_scroll_log:
    ; Continue scrolling for a while
    lda scroll_counter
    cmp #200
    bne scroll_loop
    rts

; Message to display
message:
    .byte "PACMAN SCALED VIDEO MODE TEST", 13
    .byte "28X31 LAYOUT SCALED TO 320X200", 13
    .byte "HSCALE=366 VSCALE=206 (Q8)", 13, 0

; Variables
.segment "BSS"
scroll_counter:     .res 1
