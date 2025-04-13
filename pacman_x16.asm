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

; program starts at $080D
.org $080D

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
    .byte "hello world", cr, cr
    .byte "press run/stop to exit", cr, 0

exit_message:
    .byte cr, "exiting program", cr, 0

;----------------------------------------------------------
; main program
;----------------------------------------------------------
start:
    ; clear the screen
    lda #clear_screen
    jsr chrout
    
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
