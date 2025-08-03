; Test BASIC stub functionality
; Simple program that just logs a message and exits

.org $0801

; BASIC stub: 10 SYS 2062
.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $32, $00, $00, $00

; Assembly logging memory addresses
ASM_LOG_INFO       = $9F62

start:
    ; Log: Basic stub test
    lda #1
    sta ASM_LOG_INFO
    
    ; Return to BASIC
    rts
