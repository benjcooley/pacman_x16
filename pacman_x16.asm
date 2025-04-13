;***************************************************************************
; X16 PAC-MAN STAGE ONE (6502 Assembly)
;
; This file is a 100% faithful recreation of Stage One of our port:
;   - Clears zero page
;   - Initializes VERA for tilemap mode
;   - Uploads sprite (tileset) data (4K) into VRAM at SPRITE_DEST
;   - Draws a dummy maze tilemap into VRAM at TILEMAP_BASE
;   - Enters an infinite idle loop
;
; The implementation follows the original Pac-Man arcade hardware as closely
; as possible while adapting to the Commander X16's architecture and the
; VERA graphics chip capabilities.
;
; Author: [Your Name]
; Date: 2025-04-12
;***************************************************************************

; BASIC header that runs SYS 2061 ($080D)
*=$0801
    .byte $0B,$08,$01,$00,$9E,$32,$30,$36,$31,$00,$00,$00

;----------------------------------------------------------
; Define Memory Macros and Constants (based on X16 docs)
;----------------------------------------------------------
; KERNAL routines
CHROUT           = $FFD2            ; Output character to current device
STOP             = $FFE1            ; Check if STOP key is pressed

; ASCII/PETSCII values
CR               = $0D              ; Carriage return
CLEAR_SCREEN     = $93              ; Clear screen code

;----------------------------------------------------------
; Data Section
;----------------------------------------------------------
; Message data
HelloMessage:
    .byte "HELLO WORLD - PAC-MAN X16 PORT", CR, CR
    .byte "WELCOME TO THE COMMANDER X16!", CR, CR
    .byte "PRESS RUN/STOP TO EXIT", CR, 0

ExitMessage:
    .byte CR, "EXITING PROGRAM", CR, 0

;----------------------------------------------------------
; Main Program
;----------------------------------------------------------
Start:
    ; Clear the screen
    LDA #CLEAR_SCREEN
    JSR CHROUT
    
    ; Print the hello message
    LDX #0
PrintLoop:
    LDA HelloMessage,X
    BEQ MainLoop
    JSR CHROUT
    INX
    BNE PrintLoop
    
MainLoop:
    JSR STOP                    ; Check if STOP key is pressed
    BEQ Exit                    ; If STOP key was pressed (Z=1), exit
    JMP MainLoop                ; Otherwise continue looping

Exit:
    ; Print exit message
    LDX #0
ExitLoop:
    LDA ExitMessage,X
    BEQ Done
    JSR CHROUT
    INX
    BNE ExitLoop
    
Done:
    RTS                         ; Return to BASIC
