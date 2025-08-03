; ------------------------------------------------------------
; test_cx16_final.asm
; Proper X16 assembly program using cx16.cfg segments
; Tests ASM logging system with correct structure
; ------------------------------------------------------------

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

; 1) PRG‐header: must go first, in the LOADADDR segment
.segment "LOADADDR"
    .word $0801         ; load address (BASIC stub does SYS 2060 → $0801+$0005)

; 2) Vectors: Reset/NMI/IRQ
.segment "VECTORS"
    .word start         ; Reset vector → our `start` label
    .word 0             ; NMI vector (unused)
    .word 0             ; IRQ/BRK vector (unused)

; 3) Main code: begins at $0801
.segment "CODE"
    .org $0801
    .export start

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

; Counter variable in CODE segment to avoid BSS issues
counter: .res 1
