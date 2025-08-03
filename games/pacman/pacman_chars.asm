; Pacman 1bpp Sprite Data for Commander X16
; Converted from original Pacman ROM data
; Each sprite is 8x8 pixels, 1 bit per pixel (8 bytes total)
; 0 = transparent, 1 = foreground color (set by palette offset)

.segment "DATA"

; Pacman sprites (right-facing)
pacman_right_open:
    .byte $1E  ; Row 0:   ####
    .byte $3F  ; Row 1:  ######
    .byte $7F  ; Row 2: #######
    .byte $FC  ; Row 3: ######
    .byte $FC  ; Row 4: ######
    .byte $7F  ; Row 5: #######
    .byte $3F  ; Row 6:  ######
    .byte $1E  ; Row 7:   ####

pacman_right_closed:
    .byte $1E  ; Row 0:   ####
    .byte $3F  ; Row 1:  ######
    .byte $7F  ; Row 2: #######
    .byte $FF  ; Row 3: ########
    .byte $FF  ; Row 4: ########
    .byte $7F  ; Row 5: #######
    .byte $3F  ; Row 6:  ######
    .byte $1E  ; Row 7:   ####

; Ghost sprites
ghost_normal:
    .byte $1F  ; Row 0:   #####
    .byte $7F  ; Row 1:  #######
    .byte $F7  ; Row 2: #### ###
    .byte $FF  ; Row 3: ########
    .byte $FF  ; Row 4: ########
    .byte $FF  ; Row 5: ########
    .byte $FF  ; Row 6: ########
    .byte $DD  ; Row 7: ## ### #

ghost_frightened:
    .byte $1F  ; Row 0:   #####
    .byte $7F  ; Row 1:  #######
    .byte $F7  ; Row 2: #### ###
    .byte $FF  ; Row 3: ########
    .byte $FF  ; Row 4: ########
    .byte $FF  ; Row 5: ########
    .byte $FF  ; Row 6: ########
    .byte $DD  ; Row 7: ## ### #

; Collectible sprites
dot:
    .byte $00  ; Row 0:
    .byte $00  ; Row 1:
    .byte $00  ; Row 2:
    .byte $0F  ; Row 3:     ####
    .byte $0F  ; Row 4:     ####
    .byte $00  ; Row 5:
    .byte $00  ; Row 6:
    .byte $00  ; Row 7:

power_pellet:
    .byte $0F  ; Row 0:     ####
    .byte $3F  ; Row 1:   ######
    .byte $FF  ; Row 2: ########
    .byte $FF  ; Row 3: ########
    .byte $FF  ; Row 4: ########
    .byte $FF  ; Row 5: ########
    .byte $3F  ; Row 6:   ######
    .byte $0F  ; Row 7:     ####

; Palette color constants (from original Pacman ROM)
COLOR_PACMAN     = $09  ; Yellow
COLOR_BLINKY     = $01  ; Red
COLOR_PINKY      = $03  ; Pink
COLOR_INKY       = $05  ; Cyan
COLOR_CLYDE      = $07  ; Orange
COLOR_FRIGHTENED = $11  ; Blue
COLOR_DOT        = $10  ; White/Yellow

; Sprite size constants
SPRITE_WIDTH  = 8
SPRITE_HEIGHT = 8
SPRITE_SIZE   = 8  ; 8 bytes per 1bpp sprite

; Additional Pacman animation frames can be created by rotating the base sprites
; For left-facing: horizontally flip the right-facing sprites
; For up/down-facing: use rotated versions or create new sprite data
