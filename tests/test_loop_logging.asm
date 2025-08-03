; Simple loop test for ASM logging system
; Loops 50 times and logs numbers 0-49

.org $0801

; BASIC stub: 10 SYS 2062
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $32, $00, $00, $00

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

start:
    ; Initialize counter
    lda #0
    sta counter
    
loop:
    ; Set parameter to current counter value
    lda counter
    sta ASM_LOG_PARAM1
    
    ; Log message ID 3 (Player position: X=%1, Y=%2)
    ; We'll use this to show the counter value
    lda #3
    sta ASM_LOG_INFO
    
    ; Increment counter
    inc counter
    
    ; Check if we've done 50 iterations
    lda counter
    cmp #50
    bne loop
    
    ; End program
    rts

; Counter variable
counter: .byte 0
