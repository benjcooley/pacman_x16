;***************************************************************************
; X16 PAC-MAN (6502 Assembly)
;
; A faithful recreation of Pac-Man for the Commander X16
; Based on the original arcade game and pacman.c reference
;
; Author: [Your Name]
; Date: 2025-04-13
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

; Include the data file with sprite and tile data
; .include "pacman_data.asm"

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

; VERA registers
VERA_ADDR_L      = $9F20            ; VERA Address low byte
VERA_ADDR_M      = $9F21            ; VERA Address middle byte
VERA_ADDR_H      = $9F22            ; VERA Address high byte
VERA_DATA0       = $9F23            ; VERA data port 0
VERA_DATA1       = $9F24            ; VERA data port 1
VERA_CTRL        = $9F25            ; VERA control register
VERA_DC_VIDEO    = $9F29            ; VERA display composer video register
VERA_DC_HSCALE   = $9F2A            ; VERA display composer horizontal scale
VERA_DC_VSCALE   = $9F2B            ; VERA display composer vertical scale

;----------------------------------------------------------
; data section
;----------------------------------------------------------
; message data
title_message:
    .byte "PAC-MAN FOR COMMANDER X16", cr, cr
    .byte "TESTING BUILD PROCESS", cr, cr
    .byte "PRESS RUN/STOP TO EXIT", cr, 0

debug_message:
    .byte cr, "PROGRAM IS RUNNING - WATCH THE BORDER COLORS", cr
    .byte "INITIALIZING PACMAN...", cr, cr, 0

exit_message:
    .byte cr, "EXITING PROGRAM", cr, 0

;----------------------------------------------------------
; main program
;----------------------------------------------------------
start:
    sei                         ; disable interrupts during initialization
    
    ; clear the screen
    lda #clear_screen
    jsr chrout
    
    ; set text color to yellow
    lda #$07                    ; petscii yellow
    jsr chrout
    
    ; set border and background colors
    lda #$00                    ; black
    sta $9F34                   ; VERA DC_BORDER
    lda #$01                    ; blue
    sta VERA_ADDR_L
    lda #$00
    sta VERA_ADDR_M
    lda #$11                    ; auto-increment by 1
    sta VERA_ADDR_H
    
    cli                         ; enable interrupts
    
    ; print the title message
    ldx #0
print_loop:
    lda title_message,x
    beq print_done
    jsr chrout
    inx
    bne print_loop
print_done:
    ; Print a message to confirm we're running
    ldx #0
debug_loop:
    lda debug_message,x
    beq main_loop
    jsr chrout
    inx
    bne debug_loop
    
main_loop:
    ; Draw a colorful border to show the program is running
    lda #$01                    ; red color
    sta $9F34                   ; VERA DC_BORDER
    
    ; Wait a bit
    ldx #$FF
delay1:
    ldy #$FF
delay2:
    dey
    bne delay2
    dex
    bne delay1
    
    ; Change border color
    lda #$02                    ; green color
    sta $9F34                   ; VERA DC_BORDER
    
    ; Wait a bit
    ldx #$FF
delay3:
    ldy #$FF
delay4:
    dey
    bne delay4
    dex
    bne delay3
    
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
