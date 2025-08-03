; ------------------------------------------------------------
; test_proper_x16.asm
; A proper CA65 program for X16 following the correct methodology
; Tests ASM logging system with proper structure
; ------------------------------------------------------------

    .segment "CODE"
    .export start

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

start:
    ; Change border color to show program is running
    lda #$0F          ; bright white
    sta $D020         ; VIC-II border color register
    
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
    
    ; Check if we've done 10 iterations (smaller for testing)
    lda counter
    cmp #10
    bne loop
    
    ; Change border color to green to show completion
    lda #$05          ; green
    sta $D020
    
    ; End with infinite loop
infinite_loop:
    jmp infinite_loop

; Counter variable
counter: .res 1
