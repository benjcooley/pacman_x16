; ==============================================================================
; X16 CONSTANTS
; ==============================================================================
; Common constants for Commander X16 development
; Hardware addresses, register definitions, and standard values
; ==============================================================================

.ifndef X16_CONSTANTS_INC
.define X16_CONSTANTS_INC

; ==============================================================================
; MEMORY MAP
; ==============================================================================

; Banking registers
RAM_BANK = $00
ROM_BANK = $01

; I/O Area
VIA1_BASE = $9F00
VIA2_BASE = $9F10
VERA_BASE = $9F20
YM2151_BASE = $9F40

; ==============================================================================
; VERA REGISTERS
; ==============================================================================

; VERA Control Registers
VERA_ADDR_LOW    = $9F20
VERA_ADDR_MID    = $9F21
VERA_ADDR_HIGH   = $9F22
VERA_DATA0       = $9F23
VERA_DATA1       = $9F24
VERA_CTRL        = $9F25
VERA_IEN         = $9F26
VERA_ISR         = $9F27

; VERA Display Composer
VERA_DC_VIDEO    = $9F29
VERA_DC_HSCALE   = $9F2A
VERA_DC_VSCALE   = $9F2B
VERA_DC_BORDER   = $9F2C

; VERA Layer 0
VERA_L0_CONFIG   = $9F2D
VERA_L0_MAPBASE  = $9F2E
VERA_L0_TILEBASE = $9F2F
VERA_L0_HSCROLL_L = $9F30
VERA_L0_HSCROLL_H = $9F31
VERA_L0_VSCROLL_L = $9F32
VERA_L0_VSCROLL_H = $9F33

; VERA Layer 1
VERA_L1_CONFIG   = $9F34
VERA_L1_MAPBASE  = $9F35
VERA_L1_TILEBASE = $9F36
VERA_L1_HSCROLL_L = $9F37
VERA_L1_HSCROLL_H = $9F38
VERA_L1_VSCROLL_L = $9F39
VERA_L1_VSCROLL_H = $9F3A

; VERA Sprites
VERA_SPR_CTRL    = $9F3B
VERA_SPR_COLLISION = $9F3C

; VERA Audio (PSG)
VERA_AUDIO_CTRL  = $9F3D
VERA_AUDIO_RATE  = $9F3E
VERA_AUDIO_DATA  = $9F3F

; ==============================================================================
; VERA CONFIGURATION VALUES
; ==============================================================================

; Display Composer Video Modes
DC_VIDEO_VGA     = $01
DC_VIDEO_NTSC    = $00

; Layer Configuration
LAYER_DISABLED   = $00
LAYER_TILEMAP    = $01
LAYER_BITMAP     = $02

; Color Depths
COLOR_1BPP       = $00
COLOR_2BPP       = $01
COLOR_4BPP       = $02
COLOR_8BPP       = $03

; Tile Sizes
TILE_8x8         = $00
TILE_16x16       = $01

; Map Sizes
MAP_32x32        = $00
MAP_64x32        = $01
MAP_32x64        = $02
MAP_64x64        = $03
MAP_128x32       = $04
MAP_32x128       = $05
MAP_128x64       = $06
MAP_64x128       = $07
MAP_256x32       = $08
MAP_32x256       = $09
MAP_256x64       = $0A
MAP_64x256       = $0B
MAP_128x128      = $0C
MAP_256x128      = $0D
MAP_128x256      = $0E
MAP_256x256      = $0F

; Sprite Sizes
SPR_8x8          = $00
SPR_16x16        = $01
SPR_32x32        = $02
SPR_64x64        = $03

; ==============================================================================
; VRAM ADDRESSES
; ==============================================================================

; Standard VRAM layout for games
VRAM_PALETTE     = $1FA00  ; Color palette (512 bytes)
VRAM_SPRITES     = $1FC00  ; Sprite attributes (1KB)
VRAM_TILEMAP     = $1B000  ; Tilemap data (varies)
VRAM_TILES       = $10000  ; Tile graphics data (varies)
VRAM_SPRITE_DATA = $14000  ; Sprite graphics data (varies)

; ==============================================================================
; KEYBOARD SCANCODES
; ==============================================================================

KEY_ESC          = $01
KEY_1            = $02
KEY_2            = $03
KEY_SPACE        = $39
KEY_ENTER        = $1C
KEY_UP           = $48
KEY_DOWN         = $50
KEY_LEFT         = $4B
KEY_RIGHT        = $4D
KEY_W            = $11
KEY_A            = $1E
KEY_S            = $1F
KEY_D            = $20

; ==============================================================================
; GAME FRAMEWORK CONSTANTS
; ==============================================================================

; Standard game states
STATE_INIT       = $00
STATE_ATTRACT    = $01
STATE_GAME       = $02
STATE_GAMEOVER   = $03
STATE_PAUSED     = $04

; Standard directions
DIR_RIGHT        = $00
DIR_DOWN         = $01
DIR_LEFT         = $02
DIR_UP           = $03

; Standard screen dimensions
SCREEN_WIDTH     = 640
SCREEN_HEIGHT    = 480
TILE_WIDTH       = 8
TILE_HEIGHT      = 8

; Standard timing
FRAMES_PER_SEC   = 60
TICKS_PER_FRAME  = 1

; ==============================================================================
; ZERO PAGE ALLOCATIONS
; ==============================================================================
; Standard zero page layout for games
; Games can override these as needed

ZP_GAME_STATE    = $02
ZP_FRAME_COUNTER = $03
ZP_INPUT_STATE   = $04
ZP_TEMP1         = $05
ZP_TEMP2         = $06
ZP_TEMP3         = $07
ZP_PTR1          = $08  ; 2 bytes
ZP_PTR2          = $0A  ; 2 bytes
ZP_PTR3          = $0C  ; 2 bytes

; Game-specific variables start at $10
ZP_GAME_START    = $10

; ==============================================================================
; MACROS
; ==============================================================================

; Set VERA address for data port 0
.macro VERA_SET_ADDR addr, increment
    lda #<(addr)
    sta VERA_ADDR_LOW
    lda #>(addr)
    sta VERA_ADDR_MID
    lda #((addr >> 16) | (increment << 4))
    sta VERA_ADDR_HIGH
.endmacro

; Set VERA address for data port 1
.macro VERA_SET_ADDR1 addr, increment
    lda VERA_CTRL
    ora #$01
    sta VERA_CTRL
    lda #<(addr)
    sta VERA_ADDR_LOW
    lda #>(addr)
    sta VERA_ADDR_MID
    lda #((addr >> 16) | (increment << 4))
    sta VERA_ADDR_HIGH
    lda VERA_CTRL
    and #$FE
    sta VERA_CTRL
.endmacro

; Wait for specified number of frames
.macro WAIT_FRAMES frames
    lda #frames
    jsr delay_frames
.endmacro

.endif ; X16_CONSTANTS_INC
