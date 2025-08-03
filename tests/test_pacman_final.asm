; Pacman X16 - Final Working Version with Optimal Scaling
; Default: 80x80 for clean, centered display
; Alternative: 70x70 for score-on-right layout

.org $0801

; BASIC stub: 10 SYS 2064
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

start:
    ; Set up VERA for optimal Pacman scaling
    lda #80          ; Horizontal scale (80 = clean, even scaling)
    sta $9F2A        ; VERA_DC_HSCALE
    
    lda #80          ; Vertical scale (80 = clean, even scaling)  
    sta $9F2B        ; VERA_DC_VSCALE
    
    ; Log our success to the emulator
    lda #$50         ; ASCII 'P' for Pacman
    sta $9FB0        ; ASM logging port
    
    lda #$41         ; ASCII 'A'
    sta $9FB0
    
    lda #$43         ; ASCII 'C'
    sta $9FB0
    
    lda #$4D         ; ASCII 'M'
    sta $9FB0
    
    lda #$41         ; ASCII 'A'
    sta $9FB0
    
    lda #$4E         ; ASCII 'N'
    sta $9FB0
    
    lda #$20         ; ASCII space
    sta $9FB0
    
    lda #$4F         ; ASCII 'O'
    sta $9FB0
    
    lda #$4B         ; ASCII 'K'
    sta $9FB0
    
    ; Print success message to screen
    ldx #0
print_loop:
    lda message,x
    beq done
    jsr $FFD2        ; CHROUT
    inx
    bne print_loop
    
done:
    rts

message:
    .byte "PACMAN SCALING CONFIGURED!", 13
    .byte "HORIZONTAL: 80, VERTICAL: 80", 13
    .byte "READY FOR PACMAN DEVELOPMENT!", 13
    .byte "MODE: CENTERED 80X80 SCALING", 13
    .byte "ALT: 70X70 FOR SCORE-ON-RIGHT", 13, 0
