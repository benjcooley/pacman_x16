; Fixed assembly program for ASM logging system
; Corrected BASIC stub to point to the right address

.segment "LOADADDR"
.word $0801

.segment "EXEHDR"
; BASIC stub: 10 SYS 2062 (hex $080E, where our code actually starts)
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $32, $00, $00

.segment "CODE"

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
counter: .res 1
