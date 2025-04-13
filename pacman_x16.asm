;***************************************************************************
; x16 hello world (6502 assembly)
;
; A simple program that:
;   - Clears the screen
;   - Prints "HELLO WORLD" message
;   - Waits for RUN/STOP key to exit
;
; Author: [Your Name]
; Date: 2025-04-12
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

; jump to our entry point
jmp start

;----------------------------------------------------------
; define memory macros and constants
;----------------------------------------------------------
; kernal routines
chrout           = $ffd2            ; output character to current device
stop             = $ffe1            ; check if stop key is pressed

; petscii values
cr               = $0d              ; carriage return
clear_screen     = $93              ; clear screen code

;----------------------------------------------------------
; data section
;----------------------------------------------------------
; message data
hello_message:
    .byte "HELLO WORLD!", cr, cr
    .byte "COMMANDER X16 ASSEMBLY DEMO", cr, cr
    .byte "PRESS RUN/STOP TO EXIT", cr, 0

exit_message:
    .byte cr, "EXITING PROGRAM", cr, 0

;----------------------------------------------------------
; main program
;----------------------------------------------------------
start:
    sei                         ; disable interrupts during initialization
    
    ; Intentionally crash by jumping to an invalid address
    jmp $FFFF                   ; This will cause a crash
    
    ; clear the screen
    lda #clear_screen
    jsr chrout
    
    ; set text color to white
    lda #$05                    ; petscii white
    jsr chrout
    
    ; set border and background colors
    lda #$00                    ; black
    sta $9F34                   ; VERA DC_BORDER
    lda #$01                    ; blue
    sta $9F20                   ; VERA ADDR_L
    lda #$00
    sta $9F21                   ; VERA ADDR_M
    lda #$11                    ; auto-increment by 1
    sta $9F22                   ; VERA ADDR_H
    
    cli                         ; enable interrupts
    
    ; print the hello message
    ldx #0
print_loop:
    lda hello_message,x
    beq main_loop
    jsr chrout
    inx
    bne print_loop
    
main_loop:
    jsr stop                    ; check if stop key is pressed
    beq exit                    ; if stop key was pressed (z=1), exit
    jmp main_loop               ; otherwise continue looping

exit:
    ; print exit message
    ldx #0
exit_loop:
    lda exit_message,x
    beq done
    jsr chrout
    inx
    bne exit_loop
    
done:
    rts                         ; return to basic
