;***************************************************************************
; X16 PAC-MAN STAGE ONE (6502 Assembly)
;
; This file is a 100% faithful recreation of Stage One of our port:
;   - Clears zero page
;   - Initializes VERA for tilemap mode
;   - Uploads sprite (tileset) data (4K) into VRAM at SPRITE_DEST
;   - Draws a dummy maze tilemap into VRAM at TILEMAP_BASE
;   - Enters an infinite idle loop
;
; Sprite data is embedded as literal data (4K in size).
;
; Author: [Your Name]
;***************************************************************************

                .org $1000         ; Program code begins at address $1000

;----------------------------------------------------------
; Define Memory Macros and Constants (based on X16 docs)
;----------------------------------------------------------
BANK_RAM         = $0000            ; (Fixed banking for zero page, etc.)
ZERO_PAGE_SIZE   = $0100            ; 256 bytes

; VERA register addresses (from VERA Programmer's Reference)
VERA_ADDR_L      = $9F20            ; VERA Address low byte
VERA_ADDR_M      = $9F21            ; VERA Address middle byte
VERA_ADDR_H      = $9F22            ; VERA Address high byte
VERA_DATA0       = $9F23            ; VERA data port (sequential write)
VERA_CTRL        = $9F25            ; Control register
VERA_DC_VIDEO    = $9F29            ; Display Composer video settings
VERA_DC_HSCALE   = $9F2A            ; Display Composer horizontal scale
VERA_DC_VSCALE   = $9F2B            ; Display Composer vertical scale
VERA_L0_CONFIG   = $9F2D            ; Layer 0 configuration
VERA_L0_MAPBASE  = $9F2E            ; Layer 0 map base address
VERA_L0_TILEBASE = $9F2F            ; Layer 0 tile base address

; Destination addresses in VRAM:
TILEMAP_BASE     = $B000            ; VRAM address for tilemap
SPRITE_DEST      = $A000            ; VRAM address for sprite/tileset data

;----------------------------------------------------------
; Data Section
;----------------------------------------------------------
; Include the data file that contains all Pac-Man assets
.include "pacman_data.asm"

; Maze data for testing
MazeData:
    .byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    .byte 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
MazeData_End:
MazeDataLen = MazeData_End - MazeData

;----------------------------------------------------------
; Code Section
;----------------------------------------------------------

Start:
    ;------------------------------------------------------
    ; Section 1.1: Boot and Basic Initialization
    ;------------------------------------------------------

    SEI                          ; Disable interrupts

    ;--- Clear Zero Page ($0000 - $00FF) ---
    LDY #$00
ClearZeroPage:
    LDA #$00
    STA $0000, Y
    INY
    CPY #0
    BNE ClearZeroPage

    ;------------------------------------------------------
    ; Section 1.1.2: VERA Initialization
    ; Configure VERA for tilemap mode
    ;------------------------------------------------------
    
    ; Configure VERA
    
    ; Configure VERA for 8x8 tiles, 16-color mode
    LDA #1          ; Reset VERA and set ADDR1 as active
    STA VERA_CTRL
    
    ; Enable display output, set 8bpp mode
    LDA #%10000001  ; Enable video output + 8bpp mode
    STA VERA_DC_VIDEO
    
    ; Set scaling to 1:1 (no scaling)
    LDA #64         ; Scale factor 64 = 100%
    STA VERA_DC_HSCALE
    STA VERA_DC_VSCALE
    
    ; Configure Layer 0 for tilemap mode
    LDA #%00000010  ; Enable bitmap mode, 8bpp
    STA VERA_L0_CONFIG
    
    ; Set map base address (high byte only, assumes 8K alignment)
    LDA #(TILEMAP_BASE >> 9)
    STA VERA_L0_MAPBASE
    
    ; Set tile base address (high byte only, assumes 8K alignment)
    LDA #(SPRITE_DEST >> 9)
    STA VERA_L0_TILEBASE
    
    ; Now set up VERA address for data upload
    LDA #<TILEMAP_BASE           ; Low byte of TILEMAP_BASE
    STA VERA_ADDR_L
    LDA #>TILEMAP_BASE           ; High byte of TILEMAP_BASE
    STA VERA_ADDR_M
    LDA #$10                     ; Auto-increment by 1
    STA VERA_ADDR_H

    ;------------------------------------------------------
    ; Section 1.2: Sprite/Tileset Data Upload
    ; Set VERA address to SPRITE_DEST and copy the 4K sprite data.
    ;------------------------------------------------------
    LDA #<SPRITE_DEST           ; Set low byte of SPRITE_DEST
    STA VERA_ADDR_L
    LDA #>SPRITE_DEST           ; Set high byte of SPRITE_DEST
    STA VERA_ADDR_M
    LDA #$00                    ; Top byte = 0
    STA VERA_ADDR_H

    ; Initialize for sprite data upload
    LDX #$00                    ; X = high byte counter (0..15)
    LDY #$00                    ; Y = low byte counter (0..255)
    
    ; Set up pointer to rom_tiles
    LDA #<rom_tiles
    STA $00                     ; Store low byte at zero page $00
    LDA #>rom_tiles
    STA $01                     ; Store high byte at zero page $01
    
UploadSpriteLoop:
    LDA ($00),Y                 ; Load byte from tile data using indirect addressing
    STA VERA_DATA0              ; Write byte to VERA (auto-increment)
    INY                         ; Increment low byte
    BNE UploadSpriteLoop        ; If Y didn't wrap, continue
    
    ; Y wrapped from 255->0, so increment high byte of our pointer
    INC $01                     ; Increment high byte of pointer
    INX                         ; Increment our counter
    CPX #$10                    ; Check if we've uploaded all 4096 bytes (16 * 256)
    BNE UploadSpriteLoop        ; If not done, continue

    ;------------------------------------------------------
    ; Section 1.3: Maze Tilemap Drawing Routine
    ; Set VERA address to TILEMAP_BASE and copy MazeData.
    ;------------------------------------------------------
    LDA #<TILEMAP_BASE          ; Re-load TILEMAP_BASE into VERA registers
    STA VERA_ADDR_L
    LDA #>TILEMAP_BASE
    STA VERA_ADDR_M
    LDA #$00
    STA VERA_ADDR_H

    LDY #$00                    ; Y index for maze data
DrawMazeLoop:
    LDA MazeData, Y             ; Load tile code from MazeData
    STA VERA_DATA0              ; Write to VERA tilemap
    INY
    CPY MazeDataLen
    BNE DrawMazeLoop

    ;------------------------------------------------------
    ; Section 2: Main Entry Point and Idle Loop
    ;------------------------------------------------------
IdleLoop:
    JMP IdleLoop                ; Infinite loop

                .end
