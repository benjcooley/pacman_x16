; ------------------------------------------------------------
; Simple ASM Logging Test
; Uses simple.cfg segments for proper compilation
; Tests the ASM logging system
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
    ; Test 1: Simple info message (System initialized)
    lda #1
    sta ASM_LOG_INFO
    
    ; Small delay
    ldx #$FF
delay1:
    dex
    bne delay1
    
    ; Test 2: Info with 16-bit parameter (Loading data from address)
    lda #$34            ; Low byte of address $1234
    sta ASM_LOG_PARAM1
    lda #$12            ; High byte of address $1234
    sta ASM_LOG_PARAM2
    lda #2
    sta ASM_LOG_INFO
    
    ; Small delay
    ldx #$FF
delay2:
    dex
    bne delay2
    
    ; Test 3: Info with two 8-bit parameters (Player position)
    lda #$50            ; X position
    sta ASM_LOG_PARAM1
    lda #$30            ; Y position
    sta ASM_LOG_PARAM2
    lda #3
    sta ASM_LOG_INFO
    
    ; Small delay
    ldx #$FF
delay3:
    dex
    bne delay3
    
    ; Test 4: Warning message (Low memory)
    lda #$20            ; 32 bytes remaining
    sta ASM_LOG_PARAM1
    lda #1
    sta ASM_LOG_WARNING
    
    ; Small delay
    ldx #$FF
delay4:
    dex
    bne delay4
    
    ; Test 5: Error message (System error code)
    lda #$FF            ; Error code 255
    sta ASM_LOG_PARAM1
    lda #3
    sta ASM_LOG_ERROR
    
    ; Small delay
    ldx #$FF
delay5:
    dex
    bne delay5
    
    ; Test 6: Score update with 16-bit value
    lda #$00            ; Low byte of score $1000
    sta ASM_LOG_PARAM1
    lda #$10            ; High byte of score $1000
    sta ASM_LOG_PARAM2
    lda #4
    sta ASM_LOG_INFO
    
    ; End with infinite loop
infinite_loop:
    jmp infinite_loop

; Variables go in BSS segment
.segment "BSS"
temp: .res 1
