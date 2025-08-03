; Test program for the assembly logging system
; Demonstrates various logging features

.org $0801

; BASIC stub: 10 SYS 2060
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $30, $00, $00, $00

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62
ASM_LOG_WARNING    = $9F63
ASM_LOG_ERROR      = $9F64

start:
    ; Test 1: Simple info message (System initialized)
    lda #1
    sta ASM_LOG_INFO
    
    ; Test 2: Info with 16-bit parameter (Loading data from address)
    lda #$34        ; Low byte of address $1234
    sta ASM_LOG_PARAM1
    lda #$12        ; High byte of address $1234
    sta ASM_LOG_PARAM2
    lda #2
    sta ASM_LOG_INFO
    
    ; Test 3: Info with two 8-bit parameters (Player position)
    lda #$50        ; X position
    sta ASM_LOG_PARAM1
    lda #$30        ; Y position
    sta ASM_LOG_PARAM2
    lda #3
    sta ASM_LOG_INFO
    
    ; Test 4: Warning message (Low memory)
    lda #$20        ; 32 bytes remaining
    sta ASM_LOG_PARAM1
    lda #1
    sta ASM_LOG_WARNING
    
    ; Test 5: Error message (System error code)
    lda #$FF        ; Error code 255
    sta ASM_LOG_PARAM1
    lda #3
    sta ASM_LOG_ERROR
    
    ; Test 6: Score update with 16-bit value
    lda #$00        ; Low byte of score $1000
    sta ASM_LOG_PARAM1
    lda #$10        ; High byte of score $1000
    sta ASM_LOG_PARAM2
    lda #4
    sta ASM_LOG_INFO
    
    ; Test 7: Collision detection with coordinates
    lda #$40        ; X coordinate
    sta ASM_LOG_PARAM1
    lda #$60        ; Y coordinate
    sta ASM_LOG_PARAM2
    lda #3
    sta ASM_LOG_WARNING
    
    ; Test 8: Level completion
    lda #5          ; Level 5
    sta ASM_LOG_PARAM1
    lda #5
    sta ASM_LOG_INFO
    
    ; Test 9: Undefined message ID (should show fallback)
    lda #99         ; Undefined message ID
    sta ASM_LOG_INFO
    
    ; End program
    rts
