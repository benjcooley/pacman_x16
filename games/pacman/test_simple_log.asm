; Simple logging test - just test assembly logging works
.org $0801

; BASIC stub: 10 SYS 2064
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $34, $00, $00, $00

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62
ASM_LOG_WARNING    = $9F63
ASM_LOG_ERROR      = $9F64

start:
    ; Test: Pacman screen layout initialization
    lda #10
    sta ASM_LOG_INFO
    
    ; Test: Setting VERA tile mode
    lda #11
    sta ASM_LOG_INFO
    
    ; Test: Filling playfield area
    lda #12
    sta ASM_LOG_INFO
    
    ; Test: Filling UI area
    lda #13
    sta ASM_LOG_INFO
    
    ; Test: Screen layout complete
    lda #14
    sta ASM_LOG_INFO
    
    ; End program and return to BASIC
    rts
