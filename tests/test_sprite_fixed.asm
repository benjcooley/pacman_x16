; Test program to verify fixed sprite data
; Uses the corrected power pellet sprite

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
    ; Log that we're starting
    lda #$01
    sta ASM_LOG_INFO
    
    ; Set up VERA for 1bpp sprites
    ; VERA_CTRL = 0
    lda #$00
    sta $9F25
    
    ; Set VERA address to sprite data area ($1FC00)
    lda #$00
    sta $9F20  ; VERA_ADDR_LOW
    lda #$FC
    sta $9F21  ; VERA_ADDR_MID  
    lda #$01
    sta $9F22  ; VERA_ADDR_HIGH (auto-increment)
    
    ; Upload power pellet sprite data
    ldx #0
upload_loop:
    lda power_pellet,x
    sta $9F23  ; VERA_DATA0
    inx
    cpx #8
    bne upload_loop
    
    ; Log that sprite data uploaded
    lda #$02
    sta ASM_LOG_INFO
    
    ; Set up sprite 0
    ; VERA address to sprite attribute table ($1FC00 + 8*128 = $1FE00)
    lda #$00
    sta $9F20  ; VERA_ADDR_LOW
    lda #$FE
    sta $9F21  ; VERA_ADDR_MID
    lda #$01
    sta $9F22  ; VERA_ADDR_HIGH
    
    ; Sprite 0 attributes
    lda #<320  ; X position low
    sta $9F23
    lda #>320  ; X position high
    sta $9F23
    lda #<240  ; Y position low  
    sta $9F23
    lda #>240  ; Y position high
    sta $9F23
    
    ; Z-depth (2) and flip bits (0)
    lda #$02
    sta $9F23
    
    ; Sprite mode: 1bpp, 8x8, sprite data address 0
    lda #$80  ; 1bpp mode
    sta $9F23
    
    lda #$00  ; Sprite data address (points to $1FC00)
    sta $9F23
    
    lda #$09  ; Palette offset (yellow)
    sta $9F23
    
    ; Enable sprites in display composer
    lda #$40  ; Enable sprites
    sta $9F29  ; DC_VIDEO
    
    ; Log that sprite is configured
    lda #$03
    sta ASM_LOG_INFO
    
    ; Infinite loop
loop:
    jmp loop

.segment "DATA"

; Corrected power pellet sprite data from ROM
power_pellet:
    .byte $3C  ; Row 0:   ####
    .byte $7E  ; Row 1:  ######
    .byte $FF  ; Row 2: ########
    .byte $FF  ; Row 3: ########
    .byte $FF  ; Row 4: ########
    .byte $FF  ; Row 5: ########
    .byte $7E  ; Row 6:  ######
    .byte $3C  ; Row 7:   ####
