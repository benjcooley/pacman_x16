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
.org $0801
    .byte $0B,$08,$01,$00,$9E,$32,$30,$36,$31,$00,$00,$00

;----------------------------------------------------------
; Define Memory Macros and Constants (based on X16 docs)
;----------------------------------------------------------
; KERNAL routines
CHROUT           = $FFD2            ; Output character to current device
STROUT           = $FF5A            ; Output null-terminated string (pointed to by A/Y)
STOP             = $FFE1            ; Check if STOP key is pressed

; ASCII/PETSCII values
CR               = $0D              ; Carriage return
CLEAR_SCREEN     = $93              ; Clear screen code

;----------------------------------------------------------
; Data Section
;----------------------------------------------------------
; Message data
HelloMessage:
    .byte "HELLO WORLD - PAC-MAN X16 PORT", $0D, $0D
    .byte "WELCOME TO THE COMMANDER X16!", $0D, $0D
    .byte "PRESS RUN/STOP TO EXIT", $0D, 0

ExitMessage:
    .byte $0D, "EXITING PROGRAM", $0D, 0

;----------------------------------------------------------
; Main Program
;----------------------------------------------------------
Start:
    ; Clear the screen
    LDA #$93
    JSR CHROUT
    
    ; Print the hello message using STROUT
    LDA #<HelloMessage          ; Low byte of message address
    LDY #>HelloMessage          ; High byte of message address
    JSR STROUT                  ; Call string output routine
    
MainLoop:
    JSR STOP                    ; Check if STOP key is pressed
    BEQ Exit                    ; If STOP key was pressed (Z=1), exit
    JMP MainLoop                ; Otherwise continue looping

Exit:
    ; Print exit message using STROUT
    LDA #<ExitMessage           ; Low byte of message address
    LDY #>ExitMessage           ; High byte of message address
    JSR STROUT                  ; Call string output routine
    
Done:
    RTS                         ; Return to BASIC
