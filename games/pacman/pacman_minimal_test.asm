; ------------------------------------------------------------
; Minimal Pacman Test - Just verify logging works
; Uses proper segments and basic stub
; ------------------------------------------------------------

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62
ASM_LOG_WARNING    = $9F63
ASM_LOG_ERROR      = $9F64

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
    ; Test 1: System initialized
    lda #1
    sta ASM_LOG_INFO
    
    ; Test 2: Program started
    lda #2
    sta ASM_LOG_INFO
    
    ; Test 3: Basic test complete
    lda #20
    sta ASM_LOG_INFO
    
    ; End with infinite loop
infinite_loop:
    jmp infinite_loop

; Variables go in BSS segment
.segment "BSS"
temp: .res 1
