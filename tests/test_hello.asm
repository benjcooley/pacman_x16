; Simple test program for the test_program MCP tool
; This program displays "HELLO WORLD!" on the screen

.org $0801

; BASIC stub: 10 SYS 2064
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

; Main program starts at $0810 (2064)
main:
    ; Clear screen
    lda #$93
    jsr $ffd2
    
    ; Print "HELLO WORLD!"
    ldx #0
print_loop:
    lda message,x
    beq done
    jsr $ffd2
    inx
    jmp print_loop
    
done:
    ; Wait for keypress
    jsr $ffe4
    rts

message:
    .byte "HELLO WORLD!", $0d, $00
