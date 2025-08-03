; ------------------------------------------------------------
; test_scroll_slow.asm
; X16 Assembly program that demonstrates VERA Layer 1 scrolling
; MUCH SLOWER version to see the scrolling effect clearly
; ------------------------------------------------------------

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

; VERA Layer 1 scroll registers (confirmed correct!)
L1_HSCROLL_L       = $9F34
L1_HSCROLL_H       = $9F35
L1_VSCROLL_L       = $9F36
L1_VSCROLL_H       = $9F37

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
    
    ; Put some visible text on screen using KERNAL
    ldx #0
text_loop:
    lda message,x
    beq text_done
    jsr $FFD2           ; KERNAL CHROUT
    inx
    bne text_loop
text_done:

    ; Initialize scroll counters to 0
    lda #0
    sta h_scroll_lo
    sta h_scroll_hi
    sta v_scroll_lo
    sta v_scroll_hi
    sta delay_counter
    
    ; Reset Layer 1 scroll registers to 0
    sta L1_HSCROLL_L
    sta L1_HSCROLL_H
    sta L1_VSCROLL_L
    sta L1_VSCROLL_H
    
    ; Log that we're starting scroll demo
    lda #2
    sta ASM_LOG_INFO

main_loop:
    ; MUCH LONGER delay - wait about 1 second between updates
    ldy #$FF
delay_outer:
    ldx #$FF
delay_inner:
    dex
    bne delay_inner
    dey
    bne delay_outer
    
    ; Even longer delay
    ldy #$FF
delay_outer2:
    ldx #$FF
delay_inner2:
    dex
    bne delay_inner2
    dey
    bne delay_outer2
    
    ; Increment delay counter
    inc delay_counter
    
    ; Only update scroll every 4 delay cycles (very slow)
    lda delay_counter
    and #$03
    bne skip_scroll_update
    
    ; Update horizontal scroll by only 1 pixel each time
    inc h_scroll_lo
    bne no_h_carry
    inc h_scroll_hi
no_h_carry:

    ; Update vertical scroll every 16 iterations (very slow vertical)
    lda delay_counter
    and #$0F
    bne no_v_update
    
    ; Update vertical scroll by 1 pixel
    inc v_scroll_lo
    bne no_v_carry
    inc v_scroll_hi
no_v_carry:

no_v_update:
    ; Set Layer 1 horizontal scroll
    lda h_scroll_lo
    sta L1_HSCROLL_L
    lda h_scroll_hi
    and #$0F        ; Keep within 12-bit range
    sta L1_HSCROLL_H
    
    ; Set Layer 1 vertical scroll
    lda v_scroll_lo
    sta L1_VSCROLL_L
    lda v_scroll_hi
    and #$0F        ; Keep within 12-bit range
    sta L1_VSCROLL_H
    
    ; Log scroll values every 16 iterations
    lda delay_counter
    and #$0F
    bne skip_log
    
    lda h_scroll_lo
    sta ASM_LOG_PARAM1
    lda v_scroll_lo
    sta ASM_LOG_PARAM2
    lda #3          ; "Player position: X=%1, Y=%2" - reusing for scroll values
    sta ASM_LOG_INFO
    
skip_log:
skip_scroll_update:
    jmp main_loop

; Message to display
message:
    .byte "SLOW LAYER 1 SCROLL TEST", 13
    .byte "WATCH THE TEXT MOVE SLOWLY", 13
    .byte "HORIZONTAL: 1 PIXEL EVERY 4 CYCLES", 13
    .byte "VERTICAL: 1 PIXEL EVERY 16 CYCLES", 13
    .byte "THIS SHOULD BE VERY SMOOTH", 13, 0

; Variables
.segment "BSS"
h_scroll_lo:    .res 1
h_scroll_hi:    .res 1
v_scroll_lo:    .res 1
v_scroll_hi:    .res 1
delay_counter:  .res 1
