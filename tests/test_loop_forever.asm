; Test program that loops forever to keep emulator running
; This allows the test_program tool to capture screenshots

.org $0801

; BASIC stub: 10 SYS 2064
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

; Main program starts at $0810 (2064)
main:
    ; Clear screen
    lda #$93
    jsr $ffd2
    
    ; Print "RUNNING TEST LOOP..."
    ldx #0
print_loop:
    lda message,x
    beq start_loop
    jsr $ffd2
    inx
    jmp print_loop
    
start_loop:
    ; Infinite loop to keep emulator running
    ; Change background color to show it's running
    lda #$00    ; Black
    sta $9f29   ; VERA background color
    
    ; Wait a bit
    ldy #$ff
wait1:
    ldx #$ff
wait2:
    dex
    bne wait2
    dey
    bne wait1
    
    ; Change to blue
    lda #$06    ; Blue
    sta $9f29
    
    ; Wait a bit
    ldy #$ff
wait3:
    ldx #$ff
wait4:
    dex
    bne wait4
    dey
    bne wait3
    
    ; Loop forever
    jmp start_loop

message:
    .byte "RUNNING TEST LOOP...", $0d, $00
