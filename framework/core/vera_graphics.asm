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
.export vera_enable_sprite
.export vera_disable_sprite

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
    
    lda #$0C            ; Z-depth 3, no flip
    sta VERA_DATA0
    
    lda #$51            ; 16x16, palette 1
    sta VERA_DATA0
    
    lda ZP_TEMP3
    sta VERA_DATA0      ; Tile index low
    
    lda #$00
    sta VERA_DATA0      ; Tile index high
    
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

; ==============================================================================
; PALETTE FUNCTIONS
; ==============================================================================

.export vera_upload_palette
.export vera_set_palette_color

; Upload palette data
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
