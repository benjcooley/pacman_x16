; ------------------------------------------------------------
; test_scroll_simple.asm
; Simple X16 Assembly program that scrolls the text tilemap
; Uses VERA Layer 0 scroll registers - simplified version
; ------------------------------------------------------------

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

; VERA Layer 0 scroll registers
L0_HSCROLL_L       = $9F30
L0_HSCROLL_H       = $9F31
L0_VSCROLL_L       = $9F32
L0_VSCROLL_H       = $9F33

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
    
    ; Initialize scroll counters
    lda #0
    sta h_scroll_lo
    sta h_scroll_hi
    sta v_scroll_lo
    sta v_scroll_hi
    sta frame_counter
    
    ; Log that we're starting scroll demo
    lda #2
    sta ASM_LOG_INFO

main_loop:
    ; Wait for vsync by checking scanline
    lda $9F28       ; Read scanline low byte
wait_loop:
    cmp $9F28       ; Wait for scanline to change
    beq wait_loop
    
    ; Update horizontal scroll every frame
    inc h_scroll_lo
    bne no_h_carry
    inc h_scroll_hi
    lda h_scroll_hi
    and #$0F        ; Keep within 12-bit range (0-4095)
    sta h_scroll_hi
no_h_carry:

    ; Update vertical scroll every 4 frames
    inc frame_counter
    lda frame_counter
    and #$03
    bne no_v_update
    
    inc v_scroll_lo
    bne no_v_carry
    inc v_scroll_hi
    lda v_scroll_hi
    and #$0F        ; Keep within 12-bit range (0-4095)
    sta v_scroll_hi
no_v_carry:

no_v_update:
    ; Set horizontal scroll
    lda h_scroll_lo
    sta L0_HSCROLL_L
    lda h_scroll_hi
    sta L0_HSCROLL_H
    
    ; Set vertical scroll
    lda v_scroll_lo
    sta L0_VSCROLL_L
    lda v_scroll_hi
    sta L0_VSCROLL_H
    
    ; Log scroll values every 64 frames
    lda frame_counter
    and #$3F
    bne skip_log
    
    lda h_scroll_lo
    sta ASM_LOG_PARAM1
    lda v_scroll_lo
    sta ASM_LOG_PARAM2
    lda #3          ; "Player position: X=%1, Y=%2" - reusing for scroll values
    sta ASM_LOG_INFO
    
skip_log:
    jmp main_loop

; Variables
.segment "BSS"
h_scroll_lo:    .res 1
h_scroll_hi:    .res 1
v_scroll_lo:    .res 1
v_scroll_hi:    .res 1
frame_counter:  .res 1
