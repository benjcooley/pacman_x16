; ==============================================================================
; VERA GRAPHICS FRAMEWORK
; ==============================================================================
; Reusable VERA graphics routines for X16 game development
; Provides common graphics operations for tilemaps, sprites, and palettes
; ==============================================================================

; ==============================================================================
; VERA INITIALIZATION
; ==============================================================================

.export vera_init
.export vera_reset_text_mode
.export vera_set_video_mode

; Initialize VERA for graphics mode
; Inputs: None
; Outputs: None
; Modifies: A, X, Y
vera_init:
    ; Reset VERA
    lda #$80
    sta VERA_CTRL
    lda #$00
    sta VERA_CTRL
    
    ; Set up display composer for VGA mode
    lda #DC_VIDEO_VGA
    sta VERA_DC_VIDEO
    
    ; Set scale to 1x
    lda #64
    sta VERA_DC_HSCALE
    sta VERA_DC_VSCALE
    
    ; Set border color to black
    lda #$00
    sta VERA_DC_BORDER
    
    ; Disable both layers initially
    lda #LAYER_DISABLED
    sta VERA_L0_CONFIG
    sta VERA_L1_CONFIG
    
    ; Disable sprites initially
    lda #$00
    sta VERA_SPR_CTRL
    
    rts

; Reset VERA to text mode
; Inputs: None
; Outputs: None
; Modifies: A
vera_reset_text_mode:
    ; Set layer 0 to text mode
    lda #$01
    sta VERA_L0_CONFIG
    
    ; Set text mode parameters
    lda #$00
    sta VERA_L0_MAPBASE
    sta VERA_L0_TILEBASE
    
    ; Disable layer 1
    lda #LAYER_DISABLED
    sta VERA_L1_CONFIG
    
    rts

; Set video output mode
; Inputs: A = video mode (DC_VIDEO_VGA or DC_VIDEO_NTSC)
; Outputs: None
; Modifies: A
vera_set_video_mode:
    sta VERA_DC_VIDEO
    rts

; ==============================================================================
; TILEMAP FUNCTIONS
; ==============================================================================

.export vera_setup_tilemap
.export vera_upload_tiles
.export vera_upload_tilemap
.export vera_set_tile

; Set up tilemap layer
; Inputs: A = layer (0 or 1)
;         X = map width/height config
;         Y = color depth
; Outputs: None
; Modifies: A, X, Y
vera_setup_tilemap:
    cmp #$00
    beq @layer0
    
    ; Layer 1 setup
    lda #(LAYER_TILEMAP | COLOR_4BPP)
    ora tilemap_config,y
    sta VERA_L1_CONFIG
    
    ; Set map base (VRAM_TILEMAP >> 9)
    lda #(VRAM_TILEMAP >> 9)
    sta VERA_L1_MAPBASE
    
    ; Set tile base (VRAM_TILES >> 9) 
    lda #(VRAM_TILES >> 9)
    sta VERA_L1_TILEBASE
    
    bra @done
    
@layer0:
    ; Layer 0 setup
    lda #(LAYER_TILEMAP | COLOR_4BPP | TILE_8x8)
    sta VERA_L0_CONFIG
    
    ; Set map base (VRAM_TILEMAP >> 9)
    lda #(VRAM_TILEMAP >> 9)
    sta VERA_L0_MAPBASE
    
    ; Set tile base (VRAM_TILES >> 9)
    lda #(VRAM_TILES >> 9)
    sta VERA_L0_TILEBASE

@done:
    rts

tilemap_config:
    .byte TILE_8x8, TILE_16x16

; Upload tile data to VRAM
; Inputs: ZP_PTR1 = source data address
;         A = number of tiles
; Outputs: None
; Modifies: A, X, Y
vera_upload_tiles:
    tax  ; Save tile count
    
    ; Set VERA address to tile graphics area
    VERA_SET_ADDR VRAM_TILES, 1
    
    ldy #$00
@tile_loop:
    ; Upload 32 bytes per tile (8x8 4bpp)
    phx
    ldx #32
@byte_loop:
    lda (ZP_PTR1),y
    sta VERA_DATA0
    iny
    bne @no_inc_hi
    inc ZP_PTR1+1
@no_inc_hi:
    dex
    bne @byte_loop
    
    plx
    dex
    bne @tile_loop
    
    rts

; Upload tilemap data to VRAM
; Inputs: ZP_PTR1 = source tilemap data
;         A = map width in tiles
;         X = map height in tiles
; Outputs: None
; Modifies: A, X, Y
vera_upload_tilemap:
    sta ZP_TEMP1  ; Save width
    stx ZP_TEMP2  ; Save height
    
    ; Set VERA address to tilemap base
    VERA_SET_ADDR VRAM_TILEMAP, 1
    
    ldy #$00
@row_loop:
    ldx ZP_TEMP1  ; Load width
@col_loop:
    lda (ZP_PTR1),y
    sta VERA_DATA0
    iny
    bne @no_inc_hi
    inc ZP_PTR1+1
@no_inc_hi:
    dex
    bne @col_loop
    
    dec ZP_TEMP2
    bne @row_loop
    
    rts

; Set individual tile in tilemap
; Inputs: A = tile index
;         X = map X position
;         Y = map Y position
; Outputs: None
; Modifies: A, X, Y
vera_set_tile:
    pha  ; Save tile index
    
    ; Calculate VRAM address: VRAM_TILEMAP + (Y * map_width + X) * 2
    ; For now, assume 32-tile width
    tya
    asl
    asl
    asl
    asl
    asl  ; Y * 32
    sta ZP_TEMP1
    
    txa
    asl  ; X * 2 (2 bytes per tile)
    clc
    adc ZP_TEMP1
    sta ZP_TEMP1
    
    lda #$00
    adc #$00
    sta ZP_TEMP2
    
    ; Add to base address
    lda ZP_TEMP1
    clc
    adc #<VRAM_TILEMAP
    sta VERA_ADDR_LOW
    
    lda ZP_TEMP2
    adc #>VRAM_TILEMAP
    sta VERA_ADDR_MID
    
    lda #$01  ; High byte + auto-increment
    sta VERA_ADDR_HIGH
    
    ; Write tile index
    pla
    sta VERA_DATA0
    
    ; Write color/attribute byte (default)
    lda #$00
    sta VERA_DATA0
    
    rts

; ==============================================================================
; SPRITE FUNCTIONS
; ==============================================================================

.export vera_setup_sprites
.export vera_upload_sprite_data
.export vera_set_sprite
.export copy_digits_to_sprite_vram
.export vera_enable_sprite
.export vera_disable_sprite
.export vera_set_sprite_sizepal
.export vera_set_sprite_flip
; Palette helpers
.export vera_upload_palette
.export vera_build_upload_palette_from_rom
; 2bpp -> 4bpp converters
.export vera_convert_upload_tiles_2bpp
.export vera_convert_upload_sprites_2bpp

; Initialize sprite system
; Inputs: None
; Outputs: None
; Modifies: A
vera_setup_sprites:
    ; Enable sprites
    lda #$01
    sta VERA_SPR_CTRL
    
    ; Clear all sprite attributes
    VERA_SET_ADDR VRAM_SPRITES, 1
    
    ldx #128  ; 128 sprites
@clear_loop:
    lda #$00
    sta VERA_DATA0  ; X low
    sta VERA_DATA0  ; X high
    sta VERA_DATA0  ; Y low
    sta VERA_DATA0  ; Y high
    sta VERA_DATA0  ; Z-depth/flip
    sta VERA_DATA0  ; Size/palette
    sta VERA_DATA0  ; Tile index low
    sta VERA_DATA0  ; Tile index high
    dex
    bne @clear_loop
    
    rts

; Upload sprite graphics data
; Inputs: ZP_PTR1 = source data
;         A = sprite number
;         X = number of sprites to upload
; Outputs: None
; Modifies: A, X, Y
vera_upload_sprite_data:
    ; Calculate VRAM address for sprite data
    ; Each 16x16 sprite = 128 bytes
    asl
    asl
    asl
    asl
    asl
    asl
    asl  ; * 128
    clc
    adc #<VRAM_SPRITE_DATA
    sta VERA_ADDR_LOW
    
    lda #$00
    adc #>VRAM_SPRITE_DATA
    sta VERA_ADDR_MID
    
    lda #$11  ; Auto-increment
    sta VERA_ADDR_HIGH
    
    ldy #$00
@sprite_loop:
    ; Upload 128 bytes per 16x16 sprite
    phx
    ldx #128
@byte_loop:
    lda (ZP_PTR1),y
    sta VERA_DATA0
    iny
    bne @no_inc_hi
    inc ZP_PTR1+1
@no_inc_hi:
    dex
    bne @byte_loop
    
    plx
    dex
    bne @sprite_loop
    
    rts

; Set sprite attributes
; Inputs: A = sprite number
;         X = X position (low byte)
;         Y = Y position (low byte)
;         ZP_TEMP1 = X position (high byte)
;         ZP_TEMP2 = Y position (high byte)
;         ZP_TEMP3 = sprite tile index
; Outputs: None
; Modifies: A
vera_set_sprite:
    ; Calculate sprite attribute address
    asl
    asl
    asl  ; * 8 bytes per sprite
    clc
    adc #<VRAM_SPRITES
    sta VERA_ADDR_LOW
    
    lda #$00
    adc #>VRAM_SPRITES
    sta VERA_ADDR_MID
    
    lda #$11  ; Auto-increment
    sta VERA_ADDR_HIGH
    
    ; Write sprite attributes
    stx VERA_DATA0      ; X low
    lda ZP_TEMP1
    sta VERA_DATA0      ; X high
    
    sty VERA_DATA0      ; Y low
    lda ZP_TEMP2
    sta VERA_DATA0      ; Y high
    
    lda #$0C            ; Z-depth 3, no flip (flip set separately)
    sta VERA_DATA0
    
    lda #$51            ; 16x16, palette 1
    sta VERA_DATA0
    
    lda ZP_TEMP3
    sta VERA_DATA0      ; Tile index low
    
    lda #$00
    sta VERA_DATA0      ; Tile index high
    
    rts

; Set sprite flip bits (H/V) and keep current Z-depth
; Inputs: A = sprite number, X: bit0=HFLIP, bit1=VFLIP
; Outputs: None
; Modifies: A
vera_set_sprite_flip:
    jsr get_sprite_attr_addr
    ; move to byte 6 (collision/z/flip)
    lda VERA_ADDR_LOW
    clc
    adc #$06
    sta VERA_ADDR_LOW
    bcc :+
    inc VERA_ADDR_MID
:
    ; read-modify-write flips preserving collision/z-depth
    lda VERA_DATA0
    and #$FC           ; clear H/V flip bits (low 2 bits)
    txa
    and #$03           ; keep only H/V flags
    ora #$0C           ; ensure Z-depth=3
    sta VERA_DATA0
    rts

; Copy digit glyphs '0'..'9' from layer tile VRAM to sprite tile VRAM contiguous block
; Assumes layer tiles at VRAM_TILES and sprite tiles at VRAM_SPRITE_DATA
; Uses ZP_TEMP1..ZP_TEMP3 as scratch
copy_digits_to_sprite_vram:
    ; Configure source: VRAM_TILES + digit_base_offset
    ; Namco digits are ASCII '0'..'9'; our conv_char maps to tile codes directly
    ; Here we copy tiles at tile codes '0'(0x30)..'9'(0x39)
    ldx #0               ; digit index 0..9
@cd_loop:
    cpx #10
    bcs @cd_done
    ; source address = VRAM_TILES + (tile_code * 32) (4bpp 8x8 = 32 bytes per tile)
    txa                 ; A = X
    clc
    adc #$30            ; tile_code = '0'+X
    ; compute byte offset = tile_code * 32
    tay                 ; Y = tile_code
    lda #0
    sta ZP_TEMP1        ; src_off_lo
    sta ZP_TEMP2        ; src_off_hi
    tya
    asl                 ; *2
    asl                 ; *4
    asl                 ; *8
    asl                 ; *16
    asl                 ; *32
    sta ZP_TEMP1
    lda #0
    sta ZP_TEMP2
    ; set source address
    VERA_SET_ADDR VRAM_TILES, 1
    lda VERA_ADDR_LOW
    clc
    adc ZP_TEMP1
    sta VERA_ADDR_LOW
    bcc :+
    inc VERA_ADDR_MID
:
    ; set destination address = VRAM_SPRITE_DATA + (SPRITE_DIGIT_BASE_TILE + X)*32
    VERA_SET_ADDR VRAM_SPRITE_DATA, 1
    txa                 ; A = X
    asl                 ; *2
    asl                 ; *4
    asl                 ; *8
    asl                 ; *16
    asl                 ; *32
    ; add base offset SPRITE_DIGIT_BASE_TILE*32
    clc
    adc #<(SPRITE_DIGIT_BASE_TILE*32)
    sta ZP_TEMP3
    lda #0
    adc #>(SPRITE_DIGIT_BASE_TILE*32)
    sta ZP_TEMP2
    lda VERA_ADDR_LOW
    clc
    adc ZP_TEMP3
    clc
    sta VERA_ADDR_LOW
    bcc :+
    inc VERA_ADDR_MID
:
    ; copy 32 bytes
    ldy #32
@blk:
    lda VERA_DATA0
    sta VERA_DATA0
    dey
    bne @blk
    inx
    bra @cd_loop
@cd_done:
    rts

; ==============================================================================
; 2BPP -> 4BPP CONVERSION (LUT-BASED)
; ==============================================================================

; Lookup tables to expand plane bits into packed 4bpp bytes (two pixels per byte)
; For a 4-bit nibble b3 b2 b1 b0 (left->right pixels):
;  - T0_A: (b3?0x10:0) | (b2?0x01:0)  -> first two pixels, plane0 contributes bit0 of each nibble
;  - T0_B: (b1?0x10:0) | (b0?0x01:0)  -> next two pixels, plane0 contributes bit0 of each nibble
;  - T1_A/B are the same but shifted up one bit in each nibble (0x20/0x02) for plane1

vera_lut_t0_a:
    .byte $00,$00,$00,$00,$01,$01,$01,$01,$10,$10,$10,$10,$11,$11,$11,$11
vera_lut_t0_b:
    .byte $00,$01,$10,$11,$00,$01,$10,$11,$00,$01,$10,$11,$00,$01,$10,$11
vera_lut_t1_a:
    .byte $00,$00,$00,$00,$02,$02,$02,$02,$20,$20,$20,$20,$22,$22,$22,$22
vera_lut_t1_b:
    .byte $00,$02,$20,$22,$00,$02,$20,$22,$00,$02,$20,$22,$00,$02,$20,$22

; Convert and upload 8x8 tiles from 2bpp Namco format to 4bpp VERA
; Inputs: ZP_PTR1 = source (points to start of rom_tiles)
;         A       = number of tiles to convert
; Writes to: VRAM_TILES, 32 bytes per tile
; Trashes: A,X,Y, ZP_PTR2,ZP_TEMP1..ZP_TEMP3
vera_convert_upload_tiles_2bpp:
    tax                         ; X = tiles remaining
    VERA_SET_ADDR VRAM_TILES, 1 ; set VRAM dest, auto-inc by 1
    ; ZP_PTR2 will track plane1 pointer (ptr1 + 8)
    ldy #$00
@tile_loop:
    txa
    bne @tile_do                ; X != 0, continue
    jmp @done_tiles             ; X==0 -> done
@tile_do:
    phx                         ; save tile count
    ; initialize plane pointers for this tile
    lda ZP_PTR1
    clc
    adc #8
    sta ZP_PTR2
    lda ZP_PTR1+1
    adc #0
    sta ZP_PTR2+1

    ldy #0                      ; row index 0..7
@row_loop:
    cpy #8
    beq @rows_done
    ; load plane0/1 row bytes
    lda (ZP_PTR1),y
    sta ZP_TEMP1                ; P0
    lda (ZP_PTR2),y
    sta ZP_TEMP2                ; P1

    ; ---- high nibble (pixels 0..3) -> 2 bytes ----
    lda ZP_TEMP1
    lsr
    lsr
    lsr
    lsr                         ; A = P0 >> 4
    tay
    lda vera_lut_t0_a,y
    sta ZP_TEMP3                ; hold P0 contrib for first output byte
    lda ZP_TEMP2
    lsr
    lsr
    lsr
    lsr                         ; A = P1 >> 4
    tay
    lda vera_lut_t1_a,y
    ora ZP_TEMP3
    sta VERA_DATA0              ; write first byte (pixels 0,1)

    ; second byte of high nibble group (pixels 2,3)
    lda ZP_TEMP1
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t0_b,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t1_b,y
    ora ZP_TEMP3
    sta VERA_DATA0              ; write second byte (pixels 2,3)

    ; ---- low nibble (pixels 4..7) -> 2 bytes ----
    lda ZP_TEMP1
    and #$0F
    tay
    lda vera_lut_t0_a,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    and #$0F
    tay
    lda vera_lut_t1_a,y
    ora ZP_TEMP3
    sta VERA_DATA0              ; write third byte (pixels 4,5)

    lda ZP_TEMP1
    and #$0F
    tay
    lda vera_lut_t0_b,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    and #$0F
    tay
    lda vera_lut_t1_b,y
    ora ZP_TEMP3
    sta VERA_DATA0              ; write fourth byte (pixels 6,7)

    iny
    jmp @row_loop

@rows_done:
    ; advance source pointers by 16 bytes (next tile)
    clc
    lda ZP_PTR1
    adc #16
    sta ZP_PTR1
    lda ZP_PTR1+1
    adc #0
    sta ZP_PTR1+1
    clc
    lda ZP_PTR2
    adc #16
    sta ZP_PTR2
    lda ZP_PTR2+1
    adc #0
    sta ZP_PTR2+1

    plx
    dex
    beq @done_tiles
    jmp @tile_loop
@done_tiles:
    rts

; Convert and upload 16x16 sprites from 2bpp Namco format to 4bpp VERA
; Inputs: ZP_PTR1 = source (points to start of rom_sprites)
;         A       = start sprite index in VRAM_SPRITE_DATA
;         X       = number of sprites to convert
; Writes to: VRAM_SPRITE_DATA, 128 bytes per sprite
; Trashes: A,X,Y, ZP_PTR2,ZP_PTR3,ZP_TEMP1..ZP_TEMP3
vera_convert_upload_sprites_2bpp:
    ; set VRAM address to start sprite * 128 + base
    asl
    asl
    asl
    asl
    asl
    asl
    asl                         ; A *= 128
    clc
    adc #<VRAM_SPRITE_DATA
    sta VERA_ADDR_LOW
    lda #$00
    adc #>VRAM_SPRITE_DATA
    sta VERA_ADDR_MID
    lda #$11
    sta VERA_ADDR_HIGH

    ; X = sprite count remains
@spr_loop:
    cpx #0
    bne @spr_do
    jmp @spr_done
@spr_do:
    phx                         ; save count

    ; For each sprite, P0 starts at ZP_PTR1, P1 starts at ZP_PTR1+2
    lda ZP_PTR1
    sta ZP_PTR2                 ; P0 pointer
    lda ZP_PTR1+1
    sta ZP_PTR2+1
    lda ZP_PTR1
    clc
    adc #2
    sta ZP_PTR3                 ; P1 pointer
    lda ZP_PTR1+1
    adc #0
    sta ZP_PTR3+1

    ldy #16                     ; 16 rows
@spr_row:
    ; read two bytes from each plane for this row (left 8px, right 8px)
    ; -- left 8px --
    lda (ZP_PTR2)
    sta ZP_TEMP1                ; P0 left
    inc ZP_PTR2
    bne :+
    inc ZP_PTR2+1
:
    lda (ZP_PTR3)
    sta ZP_TEMP2                ; P1 left
    inc ZP_PTR3
    bne :+
    inc ZP_PTR3+1
:
    ; high nibble group
    lda ZP_TEMP1
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t0_a,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t1_a,y
    ora ZP_TEMP3
    sta VERA_DATA0

    lda ZP_TEMP1
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t0_b,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t1_b,y
    ora ZP_TEMP3
    sta VERA_DATA0

    ; low nibble group
    lda ZP_TEMP1
    and #$0F
    tay
    lda vera_lut_t0_a,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    and #$0F
    tay
    lda vera_lut_t1_a,y
    ora ZP_TEMP3
    sta VERA_DATA0

    lda ZP_TEMP1
    and #$0F
    tay
    lda vera_lut_t0_b,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    and #$0F
    tay
    lda vera_lut_t1_b,y
    ora ZP_TEMP3
    sta VERA_DATA0

    ; -- right 8px --
    lda (ZP_PTR2)
    sta ZP_TEMP1                ; P0 right
    inc ZP_PTR2
    bne :+
    inc ZP_PTR2+1
:
    lda (ZP_PTR3)
    sta ZP_TEMP2                ; P1 right
    inc ZP_PTR3
    bne :+
    inc ZP_PTR3+1
:
    ; high nibble group
    lda ZP_TEMP1
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t0_a,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t1_a,y
    ora ZP_TEMP3
    sta VERA_DATA0

    lda ZP_TEMP1
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t0_b,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    lsr
    lsr
    lsr
    lsr
    tay
    lda vera_lut_t1_b,y
    ora ZP_TEMP3
    sta VERA_DATA0

    ; low nibble group
    lda ZP_TEMP1
    and #$0F
    tay
    lda vera_lut_t0_a,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    and #$0F
    tay
    lda vera_lut_t1_a,y
    ora ZP_TEMP3
    sta VERA_DATA0

    lda ZP_TEMP1
    and #$0F
    tay
    lda vera_lut_t0_b,y
    sta ZP_TEMP3
    lda ZP_TEMP2
    and #$0F
    tay
    lda vera_lut_t1_b,y
    ora ZP_TEMP3
    sta VERA_DATA0

    ; advance P0/P1 pointers by 2 to jump to next row (stride 4, already consumed 2)
    clc
    lda ZP_PTR2
    adc #2
    sta ZP_PTR2
    lda ZP_PTR2+1
    adc #0
    sta ZP_PTR2+1
    clc
    lda ZP_PTR3
    adc #2
    sta ZP_PTR3
    lda ZP_PTR3+1
    adc #0
    sta ZP_PTR3+1

    dey
    beq @spr_row_done
    jmp @spr_row
@spr_row_done:

    ; advance source base pointer by 64 bytes to next sprite
    clc
    lda ZP_PTR1
    adc #64
    sta ZP_PTR1
    lda ZP_PTR1+1
    adc #0
    sta ZP_PTR1+1

    plx
    dex
    beq @spr_done
    jmp @spr_loop
@spr_done:
    rts
; Enable sprite
; Inputs: A = sprite number
; Outputs: None
; Modifies: A, X, Y
vera_enable_sprite:
    ; Set sprite visible by setting non-zero size
    jsr get_sprite_attr_addr
    
    ; Skip to size/palette byte (offset 5)
    lda VERA_ADDR_LOW
    clc
    adc #$05
    sta VERA_ADDR_LOW
    bcc @no_carry
    inc VERA_ADDR_MID
@no_carry:
    
    lda #$51  ; 16x16, palette 1
    sta VERA_DATA0
    
    rts

; Disable sprite
; Inputs: A = sprite number
; Outputs: None
; Modifies: A, X, Y
vera_disable_sprite:
    ; Set sprite invisible by setting zero size
    jsr get_sprite_attr_addr
    
    ; Skip to size/palette byte (offset 5)
    lda VERA_ADDR_LOW
    clc
    adc #$05
    sta VERA_ADDR_LOW
    bcc @no_carry
    inc VERA_ADDR_MID
@no_carry:
    
    lda #$00  ; Size 0 = invisible
    sta VERA_DATA0
    
    rts

; Helper: Get sprite attribute address
; Inputs: A = sprite number
; Outputs: VERA address set
; Modifies: A
get_sprite_attr_addr:
    asl
    asl
    asl  ; * 8 bytes per sprite
    clc
    adc #<VRAM_SPRITES
    sta VERA_ADDR_LOW
    
    lda #$00
    adc #>VRAM_SPRITES
    sta VERA_ADDR_MID
    
    lda #$10  ; No auto-increment
    sta VERA_ADDR_HIGH
    
    rts

; Set sprite size/palette byte (offset 5)
; Inputs: A = sprite number, X = size/palette value
; Outputs: None
; Modifies: A
vera_set_sprite_sizepal:
    jsr get_sprite_attr_addr
    ; skip to offset 5
    lda VERA_ADDR_LOW
    clc
    adc #$05
    sta VERA_ADDR_LOW
    bcc :+
    inc VERA_ADDR_MID
:
    txa
    sta VERA_DATA0
    rts

; ==============================================================================
; PALETTE FUNCTIONS
; ==============================================================================

.export vera_upload_palette
.export vera_set_palette_color
.export vera_get_palette_color
.export vera_swap_palette_color

; Upload palette data (raw 512 bytes)
; Inputs: ZP_PTR1 = palette data (512 bytes)
; Outputs: None
; Modifies: A, X, Y
vera_upload_palette:
    VERA_SET_ADDR VRAM_PALETTE, 1
    
    ldy #$00
    ldx #$02  ; 2 pages (512 bytes)
@page_loop:
    lda (ZP_PTR1),y
    sta VERA_DATA0
    iny
    bne @page_loop
    
    inc ZP_PTR1+1
    dex
    bne @page_loop
    
    rts

; Set individual palette color
; Inputs: A = color index
;         X = color value low byte
;         Y = color value high byte
; Outputs: None
; Modifies: A
vera_set_palette_color:
    asl  ; * 2 bytes per color
    clc
    adc #<VRAM_PALETTE
    sta VERA_ADDR_LOW
    
    lda #$00
    adc #>VRAM_PALETTE
    sta VERA_ADDR_MID
    
    lda #$11  ; Auto-increment
    sta VERA_ADDR_HIGH
    
    stx VERA_DATA0  ; Low byte
    sty VERA_DATA0  ; High byte
    
    rts

; Read individual palette color
; Inputs: A = color index, returns X=low, Y=high
vera_get_palette_color:
    pha
    asl
    clc
    adc #<VRAM_PALETTE
    sta VERA_ADDR_LOW
    lda #$00
    adc #>VRAM_PALETTE
    sta VERA_ADDR_MID
    lda #$10   ; no auto-inc
    sta VERA_ADDR_HIGH
    pla
    ; read low then high
    ldx VERA_DATA0
    ldy VERA_DATA0
    rts

; Swap two palette entries (indexes in A and X)
; Inputs: A = idx0, X = idx1
vera_swap_palette_color:
    sta ZP_TEMP1         ; idx0
    stx ZP_TEMP2         ; idx1
    ; read idx0 -> X0 (low0), Y0 (high0) and push to stack (low then high)
    lda ZP_TEMP1
    jsr vera_get_palette_color
    txa
    pha
    tya
    pha
    ; read idx1 -> X1 (low1), Y1 (high1)
    lda ZP_TEMP2
    jsr vera_get_palette_color
    ; write idx0 <- low1/high1 (A must be idx0)
    lda ZP_TEMP1
    jsr vera_set_palette_color
    ; restore low0/high0 and write to idx1
    pla
    tay
    pla
    tax
    lda ZP_TEMP2
    jsr vera_set_palette_color
    rts

; Build-and-upload palette from ROM tables used by the reference port
; Inputs:
;   ZP_PTR1 -> rom_palette (256 bytes of 0..15 indices)
;   ZP_PTR2 -> rom_hwcolors (32 bytes, 16 entries of 2 bytes each)
; Output: writes 512 bytes to VRAM palette (indices 0..255)
; Modifies: A,X,Y, ZP_TEMP1..ZP_TEMP3
vera_build_upload_palette_from_rom:
    VERA_SET_ADDR VRAM_PALETTE, 1
    ldy #$00                ; index 0..255
@pal_loop:
    ; read logical index
    lda (ZP_PTR1),y
    and #$0F                ; 0..15
    asl                     ; *2 (each hw color is 2 bytes)
    tax
    ; fetch low, high from rom_hwcolors
    lda ZP_PTR2
    clc
    adc #$00
    sta ZP_TEMP1            ; base low
    lda ZP_PTR2+1
    adc #$00
    sta ZP_TEMP2            ; base high
    ; add X to base
    txa
    clc
    adc ZP_TEMP1
    sta ZP_TEMP1
    lda ZP_TEMP2
    adc #$00
    sta ZP_TEMP2
    ; write two bytes to VERA
    lda (ZP_TEMP1)
    sta VERA_DATA0
    inc ZP_TEMP1
    bne :+
    inc ZP_TEMP2
:
    lda (ZP_TEMP1)
    sta VERA_DATA0
    ; next palette entry
    iny
    bne @pal_loop
    rts
