; Pac-Man (Namco) Asset Indices - Shared Constants
; 8x8 layer tiles and 16x16 sprite tiles per Namco mapping

; 8x8 Layer Tilemap (background)
.define NAMCO_TILE_LIFE_BASE          $20    ; $20..$23
.define NAMCO_TILE_CHERRIES_BASE      $90    ; $90..$93
.define NAMCO_TILE_STRAWBERRY_BASE    $94    ; $94..$97
.define NAMCO_TILE_PEACH_BASE         $98    ; $98..$9B
.define NAMCO_TILE_BELL_BASE          $9C    ; $9C..$9F
.define NAMCO_TILE_APPLE_BASE         $A0    ; $A0..$A3
.define NAMCO_TILE_GRAPES_BASE        $A4    ; $A4..$A7
.define NAMCO_TILE_GALAXIAN_BASE      $A8    ; $A8..$AB
.define NAMCO_TILE_KEY_BASE           $AC    ; $AC..$AF
.define NAMCO_TILE_GHOST              $B0
.define NAMCO_TILE_DOOR               $CF

; Fruit score tile groups (drawn as 4 tiles on layer)
.define NAMCO_TILE_SCORE_100_0        $40
.define NAMCO_TILE_SCORE_100_1        $81
.define NAMCO_TILE_SCORE_100_2        $85
.define NAMCO_TILE_SCORE_100_3        $40
.define NAMCO_TILE_SCORE_300_0        $40
.define NAMCO_TILE_SCORE_300_1        $82
.define NAMCO_TILE_SCORE_300_2        $85
.define NAMCO_TILE_SCORE_300_3        $40
.define NAMCO_TILE_SCORE_500_0        $40
.define NAMCO_TILE_SCORE_500_1        $83
.define NAMCO_TILE_SCORE_500_2        $85
.define NAMCO_TILE_SCORE_500_3        $40
.define NAMCO_TILE_SCORE_700_0        $40
.define NAMCO_TILE_SCORE_700_1        $84
.define NAMCO_TILE_SCORE_700_2        $85
.define NAMCO_TILE_SCORE_700_3        $40
.define NAMCO_TILE_SCORE_1000_0       $40
.define NAMCO_TILE_SCORE_1000_1       $86
.define NAMCO_TILE_SCORE_1000_2       $8D
.define NAMCO_TILE_SCORE_1000_3       $8E
.define NAMCO_TILE_SCORE_2000_0       $87
.define NAMCO_TILE_SCORE_2000_1       $88
.define NAMCO_TILE_SCORE_2000_2       $8D
.define NAMCO_TILE_SCORE_2000_3       $8E
.define NAMCO_TILE_SCORE_3000_0       $89
.define NAMCO_TILE_SCORE_3000_1       $8A
.define NAMCO_TILE_SCORE_3000_2       $8D
.define NAMCO_TILE_SCORE_3000_3       $8E
.define NAMCO_TILE_SCORE_5000_0       $8B
.define NAMCO_TILE_SCORE_5000_1       $8C
.define NAMCO_TILE_SCORE_5000_2       $8D
.define NAMCO_TILE_SCORE_5000_3       $8E

; 16x16 Sprite Set
.define NAMCO_SPRITETILE_CHERRIES     0
.define NAMCO_SPRITETILE_STRAWBERRY   1
.define NAMCO_SPRITETILE_PEACH        2
.define NAMCO_SPRITETILE_BELL         3
.define NAMCO_SPRITETILE_APPLE        4
.define NAMCO_SPRITETILE_GRAPES       5
.define NAMCO_SPRITETILE_GALAXIAN     6
.define NAMCO_SPRITETILE_KEY          7

.define NAMCO_SPRITETILE_FRIGHT_0     28
.define NAMCO_SPRITETILE_FRIGHT_1     29
.define NAMCO_SPRITETILE_INVISIBLE    30
.define NAMCO_SPRITETILE_EYES_RIGHT   32
.define NAMCO_SPRITETILE_EYES_DOWN    34
.define NAMCO_SPRITETILE_EYES_LEFT    36
.define NAMCO_SPRITETILE_EYES_UP      38

; Ghost normal animation tiles per dir (2 frames)
.define NAMCO_SPRITETILE_GHOST_R0     32
.define NAMCO_SPRITETILE_GHOST_R1     33
.define NAMCO_SPRITETILE_GHOST_D0     34
.define NAMCO_SPRITETILE_GHOST_D1     35
.define NAMCO_SPRITETILE_GHOST_L0     36
.define NAMCO_SPRITETILE_GHOST_L1     37
.define NAMCO_SPRITETILE_GHOST_U0     38
.define NAMCO_SPRITETILE_GHOST_U1     39

; Ghost chain popup scores
.define NAMCO_SPRITETILE_SCORE_200    40
.define NAMCO_SPRITETILE_SCORE_400    41
.define NAMCO_SPRITETILE_SCORE_800    42
.define NAMCO_SPRITETILE_SCORE_1600   43

; Pac-Man tiles
.define NAMCO_SPRITETILE_PM_H0        44
.define NAMCO_SPRITETILE_PM_V0        45
.define NAMCO_SPRITETILE_PM_H1        46
.define NAMCO_SPRITETILE_PM_V1        47
.define NAMCO_SPRITETILE_PM_CLOSED    48
.define NAMCO_SPRITETILE_PM_DEATH_START 52
.define NAMCO_SPRITETILE_PM_DEATH_END   63

; -----------------
; Sprite palette banks (lower nibble of size/palette)
; -----------------
.define NAMCO_PAL_SPR_PACMAN      $0
.define NAMCO_PAL_SPR_BLINKY      $1
.define NAMCO_PAL_SPR_PINKY       $2
.define NAMCO_PAL_SPR_INKY        $3
.define NAMCO_PAL_SPR_CLYDE       $4
.define NAMCO_PAL_SPR_FRUIT       $5
.define NAMCO_PAL_SPR_SCORE       $6
.define NAMCO_PAL_SPR_EYES        $7
.define NAMCO_PAL_SPR_FRIGHT      $8
.define NAMCO_PAL_SPR_FRIGHT_BLINK $9

; Size/palette base bytes
.define NAMCO_SIZEPAL_8x8_BASE    $40    ; 8x8, palette nibble ORed in
.define NAMCO_SIZEPAL_16x16_BASE  $50    ; 16x16, palette nibble ORed in

; -----------------
; 8x8 special character tiles
; -----------------
.define NAMCO_TILE_SPACE           $40
.define NAMCO_TILE_SLASH           $3A
.define NAMCO_TILE_DASH            $3B
.define NAMCO_TILE_DQUOTE          $26
.define NAMCO_TILE_EXCL            $5B       ; 'Z'+1 in this tileset
.define NAMCO_TILE_COPYRIGHT       $5C       ; directly after '!'
.define NAMCO_TILE_NAMCO_BASE      $18       ; start of NAMCO logo letters
.define NAMCO_TILE_PTS_BASE        $5D       ; 'P','T','S' at $5D,$5E,$5F
.define NAMCO_TILE_GRID_L0         $3C
.define NAMCO_TILE_GRID_L1         $3D
.define NAMCO_TILE_GRID_L2         $3E
.define NAMCO_TILE_GRID_L3         $3F

; Colors (tile layer color codes)
.define NAMCO_COLOR_FRUIT_SCORE    $03



