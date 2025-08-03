; ------------------------------------------------------------
; test_working.asm
; Simple X16 assembly program using simple.cfg segments
; Tests ASM logging system with correct structure
; ------------------------------------------------------------

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

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
    ; Change border color to show program is running
    lda #$0F            ; bright white border
    sta $D020           ; VIC-II border color register
    
    ; Initialize counter
    lda #0
    sta counter
    
loop:
    ; Set parameter to current counter value
    lda counter
    sta ASM_LOG_PARAM1
    
    ; Log message ID 3 (Player position: X=%1, Y=%2)
    lda #3
    sta ASM_LOG_INFO
    
    ; Increment counter
    inc counter
    
    ; Check if we've done 10 iterations
    lda counter
    cmp #10
    bne loop
    
    ; Change border color to green to show completion
    lda #$05            ; green
    sta $D020
    
    ; End with infinite loop
infinite_loop:
    jmp infinite_loop

; Counter variable
.segment "BSS"
counter: .res 1
