; ==============================================================================
; X16 SYSTEM FRAMEWORK
; ==============================================================================
; Reusable X16 system initialization and utilities for game ports
; This provides a common foundation for all X16 game implementations
; ==============================================================================

; ==============================================================================
; SYSTEM INITIALIZATION
; ==============================================================================

.export x16_init
.export x16_shutdown
.export x16_wait_vsync

; Initialize X16 system for game use
; Inputs: None
; Outputs: None
; Modifies: A, X, Y
x16_init:
    ; Disable interrupts during initialization
    sei
    
    ; Set up banking
    stz RAM_BANK
    stz ROM_BANK
    
    ; Initialize VERA (placeholder - implement in game)
    ; jsr vera_init
    
    ; Set up interrupt vectors
    jsr setup_interrupts
    
    ; Enable interrupts
    cli
    
    rts

; Shutdown X16 system
; Inputs: None
; Outputs: None
; Modifies: A, X, Y
x16_shutdown:
    ; Disable interrupts
    sei
    
    ; Reset VERA to text mode (placeholder - implement in game)
    ; jsr vera_reset_text_mode
    
    ; Restore system state
    cli
    
    rts

; Wait for vertical sync
; Inputs: None
; Outputs: None
; Modifies: A
x16_wait_vsync:
    lda VERA_ISR
    and #$01
    beq x16_wait_vsync
    
    ; Clear VSYNC flag
    lda #$01
    sta VERA_ISR
    
    rts

; ==============================================================================
; INTERRUPT HANDLING
; ==============================================================================

setup_interrupts:
    ; Set up IRQ vector
    lda #<irq_handler
    sta $0314
    lda #>irq_handler
    sta $0315
    
    ; Enable VSYNC interrupt
    lda #$01
    sta VERA_IEN
    
    rts

irq_handler:
    ; Save registers
    pha
    txa
    pha
    tya
    pha
    
    ; Check VERA interrupt
    lda VERA_ISR
    and #$01
    beq @not_vsync
    
    ; Handle VSYNC
    jsr handle_vsync
    
    ; Clear VSYNC flag
    lda #$01
    sta VERA_ISR

@not_vsync:
    ; Restore registers
    pla
    tay
    pla
    tax
    pla
    
    rti

; VSYNC handler - called every frame
; Override this in game-specific code
handle_vsync:
    ; Default: do nothing
    rts

; ==============================================================================
; MEMORY MANAGEMENT
; ==============================================================================

.export set_ram_bank
.export get_ram_bank
.export set_rom_bank
.export get_rom_bank

; Set RAM bank
; Inputs: A = bank number
; Outputs: None
; Modifies: None
set_ram_bank:
    sta RAM_BANK
    rts

; Get current RAM bank
; Inputs: None
; Outputs: A = bank number
; Modifies: A
get_ram_bank:
    lda RAM_BANK
    rts

; Set ROM bank
; Inputs: A = bank number
; Outputs: None
; Modifies: None
set_rom_bank:
    sta ROM_BANK
    rts

; Get current ROM bank
; Inputs: None
; Outputs: A = bank number
; Modifies: A
get_rom_bank:
    lda ROM_BANK
    rts

; ==============================================================================
; UTILITY FUNCTIONS
; ==============================================================================

.export delay_frames
.export random_byte

; Delay for specified number of frames
; Inputs: A = number of frames
; Outputs: None
; Modifies: A, X
delay_frames:
    tax
@loop:
    jsr x16_wait_vsync
    dex
    bne @loop
    rts

; Generate pseudo-random byte
; Uses simple LFSR algorithm
; Inputs: None
; Outputs: A = random byte
; Modifies: A
random_seed: .byte $A5

random_byte:
    lda random_seed
    asl
    bcc @no_eor
    eor #$1D
@no_eor:
    sta random_seed
    rts
