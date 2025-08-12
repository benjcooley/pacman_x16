; ==============================================================================
; PAC-MAN FOR COMMANDER X16
; ==============================================================================
; A faithful recreation of Pac-Man using the X16 Game Development Framework
; Based on the original arcade machine layout and behavior
; ==============================================================================

; ==============================================================================
; IMPLEMENTATION STATUS (CHECKLIST)
; - Use [x] done, [~] partial, [ ] pending
; ==============================================================================
; [x] Build/Link: correct LOADADDR/EXEHDR segments; clean build
;   - [x] BASIC header size corrected
;   - [x] Segments aligned with `tests/simple.cfg`
; [x] Logging: optional emulator logging macros; elided in release
;   - [x] INFO/WARN/ERROR macros
;   - removed: Curate IDs and reduce logs in hot paths
; [x] Pac‑Man movement
;   - [x] Sub‑tile offsets and tile center defined (4,4)
;   - [x] Turn‑at‑center with buffered input
;   - [x] Center‑only dot/pill eating
;   - [x] Tunnel wrap on row 17
;   - removed: Corner‑cut prevention parity checks
; [x] Ghost movement (base)
;   - [x] Sub‑tile offsets and center‑turn
;   - [x] Tunnel wrap
;   - [x] Baseline gating incl. eyes double‑step
;   - [x] Full state‑specific gating from tables
; [x] Per‑level/per‑state speeds
;   - [x] Pac masks: normal/dot/fright/fright-dot per dossier; tunnel unaffected
;   - [x] Ghost masks: normal/fright/house/tunnel per dossier
;   - [x] Blinky Elroy stages per level (thresholds + speeds)
; [x] Ghost house sequencing
;   - [x] Per‑ghost dot_limit variables
;   - [x] Dot counter increments on dot eat
;   - [x] Basic timed fallback releases per ghost
;   - [x] LEAVEHOUSE path to door and out; ENTERHOUSE path in
;   - [x] Eyes path to door → inside reset → short relaunch timer
; [x] Red‑zone rules
;   - [x] Pac‑Man UP forbidden in red‑zone
;   - [x] Ghost UP forbidden except eyes/enter/leave
; [x] Door rules
;   - [x] Pac‑Man blocked by door
;   - [x] Ghosts may pass only in eyes/enter/leave
; [x] Collisions
;   - [x] Pixel proximity threshold (|dx|,|dy| ≤ 3)
;   - [x] Ghost‑eaten chain scoring applied
;   - removed: Tunnel wrap collision edge cases validated
; [x] Ghost AI targeting
;   - [x] Scatter corners table
;   - [x] Blinky target = Pac‑Man tile
;   - [x] Pinky 4‑ahead with up‑quirk
;   - [x] Inky vector via Blinky + 2‑ahead with up‑quirk
;   - [x] Clyde 8‑tile manhattan threshold behavior
;   - removed: Frightened choice/randomization parity with arcade
;   - removed: Intersection tie‑breakers and Euclidean distance metric
; [x] Frightened mode
;   - [x] Start/end reversal of eligible ghosts
;   - [x] Per‑level duration table scaffold
;   - [x] Last‑second blink palette toggle
;   - removed: Exact duration edges vs reference
;   - removed: Frightened movement decision rule parity
; [x] Animation & tiles
;   - [x] Pac‑Man mouth frames tied to movement steps
;   - [x] Ghost 2‑frame per direction, eyes/fright tiles
;   - [x] Sprite flipping for L/U mirroring (runtime H/V flips)
;   - [x] Pac‑Man death animation (sequence + timing + sfx)
;   - removed: Final palette indices per ghost and frightened blink
; [x] Fruit
;   - [x] Spawn heuristic (placeholder), sprite show/hide
;   - [x] Status row push and draw
;   - [x] Scoring into BCD with hiscore update
;   - [x] Exact spawn thresholds (two per level), timers
;   - [x] Tile/color mapping per level sequence
; [x] Score popups
;   - [x] Ghost chain popups 200/400/800/1600 with timers and despawn (sprite-based)
;   - [x] Fruit score popups at fruit position (sprite-based)
; [x] Extra life
;   - [x] Award at 10,000 once per game (regional rule option)
; [~] Audio
;   - [x] Implement SFX: dot/pill/ghost/fruit/death (procedural + death register-dump)
;   - [x] Siren stages with vibrato, ducking on ghost sweep; pellet pew cadence
;   - [x] Voice reservations/locking (0=dot,1=pellet,2=events,3=death,4=siren)
;   - [~] Refine envelopes/volumes/priority and WSG→VERA waveform mapping
;   - [ ] Hook/register-dump for start prelude; finalize mixing during playback
; [x] Input/system
;   - [x] Real keyboard/joystick read via KERNAL joystick APIs
;   - [x] READY/game‑over freezes and timers (READY, death delay, round-won hold)
; removed: UI polish tasks (defer)
; removed: Performance/budgets (defer)
; removed: Tests (defer)
; removed: Docs/maintainability (defer)
;
; [x] Level progression polish
;   - [x] Round‑won map flash via palette toggle

; ==============================================================================
; REMAINING MAIN‑GAME TASKS (TRACKER)
; ==============================================================================
; [Audio]
; - [ ] Refine procedural SFX envelopes/decays and volumes (dot/pill/ghost/fruit) to match arcade
; - [ ] Improve WSG→VERA waveform mapping (duty/pulse shaping) for closer timbre
; - [ ] Add start prelude playback via register‑dump; balance against siren/FX
; - [ ] Finalize mixing/priority across all voices; confirm no clipping/masking
;
; [Gameplay precision]
; - [ ] Verify collision threshold/logic against arcade hit test behavior
; - [ ] Audit ghost house dot‑release counts and timed fallbacks per level
; - [ ] Frightened duration/blink edge parity per level tables (final check)
; - [ ] Frightened movement choice parity (tie‑breakers, intersection rules)
;
; [Options / DIPs]
; - [ ] Lives/bonus‑life options (e.g., 3/5 lives, bonus at 10K; one‑time)
; - [ ] 2‑player alternating mode (scores/lives switching, round handoff)
;
; [Visual polish]
; - [ ] Alternate dot/power‑pill tiles and blink toggles per ROM duplicate tiles
;
; [Nice‑to‑have]
; - [ ] Startup self‑test visual/sound simulation
; - [ ] Optional level 255 kill‑screen behavior


; Include constants first
.include "core/x16_constants.inc"

; ==============================================================================
; DIP-LIKE OPTIONS (compile-time defaults; adjust as needed)
; ==============================================================================
; Starting lives: 3 or 5
.ifndef DIP_STARTING_LIVES
.define DIP_STARTING_LIVES 3
.endif
; Bonus life at 10,000 once per game: 1=enabled, 0=disabled
.ifndef DIP_BONUS_AT_10K
.define DIP_BONUS_AT_10K 1
.endif
; BCD high-byte compare value for 10,000 (two-byte BCD score with implicit trailing 0)
.ifndef DIP_BONUS_BCD_HI
.define DIP_BONUS_BCD_HI $10
.endif
; Number of players: 1 or 2
.ifndef DIP_NUM_PLAYERS
.define DIP_NUM_PLAYERS 1
.endif

; ==============================================================================
; ASM LOGGING (instrumentation)
; ==============================================================================
; Memory-mapped logging interface (see tests/asm_template.md and emulator/src/asm_logging.h)
; Toggle by defining/undefining ENABLE_LOGGING prior to assembly

; .define ENABLE_LOGGING 1
; .define ENABLE_SELF_TEST 1
; .define ENABLE_KILL_SCREEN 1
; .define ENABLE_SCRIPTED_INPUT 1

ASM_LOG_PARAM1     = $9F60   ; 8-bit param 1
ASM_LOG_PARAM2     = $9F61   ; 8-bit param 2
ASM_LOG_INFO       = $9F62   ; info trigger (message ID in A)
ASM_LOG_WARNING    = $9F63   ; warning trigger (message ID in A)
ASM_LOG_ERROR      = $9F64   ; error trigger (message ID in A)

.macro LOG_INFO msgId
.ifdef ENABLE_LOGGING
    lda #(msgId)
    sta ASM_LOG_INFO
.endif
.endmacro

.macro LOG_INFO1 msgId, p1
.ifdef ENABLE_LOGGING
    lda #(p1)
    sta ASM_LOG_PARAM1
    lda #(msgId)
    sta ASM_LOG_INFO
.endif
.endmacro

.macro LOG_INFO2 msgId, p1, p2
.ifdef ENABLE_LOGGING
    lda #(p1)
    sta ASM_LOG_PARAM1
    lda #(p2)
    sta ASM_LOG_PARAM2
    lda #(msgId)
    sta ASM_LOG_INFO
.endif
.endmacro

.macro LOG_WARN msgId
.ifdef ENABLE_LOGGING
    lda #(msgId)
    sta ASM_LOG_WARNING
.endif
.endmacro

.macro LOG_ERR msgId
.ifdef ENABLE_LOGGING
    lda #(msgId)
    sta ASM_LOG_ERROR
.endif
.endmacro

; Log 16-bit value (word) using param1=lo, param2=hi then trigger msgId
.macro LOG_INFO_WORD msgId, wordLo, wordHi
.ifdef ENABLE_LOGGING
    lda #(wordLo)
    sta ASM_LOG_PARAM1
    lda #(wordHi)
    sta ASM_LOG_PARAM2
    lda #(msgId)
    sta ASM_LOG_INFO
.endif
.endmacro

; ==============================================================================
; PROGRAM HEADER
; ==============================================================================

.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

; Emit PRG load address and BASIC header into expected linker segments
.segment "LOADADDR"
    .word $0801

.segment "EXEHDR"
    ; 12-byte BASIC stub for SYS2064
    .byte $0C, $08, $0A, $00, $9E, $20, $32, $30, $36, $34, $00, $00

.segment "CODE"

; Include framework modules
.include "core/x16_system.asm"
.include "core/vera_graphics.asm"
.include "pacman_constants.inc"

    ; CPU type
.setcpu "65C02"

; VERA PSG VRAM base (for audio register writes via VERA address window)
VERA_PSG_BASE = $1F9C0
; Program entry point
main:
    LOG_INFO 2              ; "Program started"
    jsr maybe_run_self_test
    jmp game_start

; ==============================================================================
; GAME-SPECIFIC CONSTANTS
; ==============================================================================

; Pac-Man maze dimensions (from original arcade)
MAZE_WIDTH       = 28        ; Maze width in tiles
MAZE_HEIGHT      = 31        ; Maze height in tiles (playfield rows 3-33)

; Tile definitions (matching original Pac-Man)
TILE_SPACE       = $40       ; Empty space
TILE_DOT         = $10       ; Small dot
TILE_PILL        = $14       ; Power pellet
TILE_DOOR        = NAMCO_TILE_DOOR       ; Ghost house door

; Wall tiles (from original ROM)
TILE_WALL_UL     = $D1       ; Upper left corner
TILE_WALL_UR     = $D0       ; Upper right corner
TILE_WALL_LL     = $D5       ; Lower left corner
TILE_WALL_LR     = $D4       ; Lower right corner
TILE_WALL_H      = $DB       ; Horizontal wall
TILE_WALL_V      = $D3       ; Vertical wall (left)
TILE_WALL_VR     = $D2       ; Vertical wall (right)
TILE_WALL_T      = $DC       ; T-junction

; More wall pieces
TILE_WALL_BL     = $DF       ; Bottom left
TILE_WALL_BR     = $E6       ; Bottom right
TILE_WALL_TL     = $E7       ; Top left
TILE_WALL_TR     = $EA       ; Top right

; Game states
GAME_STATE_INIT     = STATE_INIT
GAME_STATE_ATTRACT  = STATE_ATTRACT  
GAME_STATE_PLAYING  = STATE_GAME
GAME_STATE_DEATH    = $FE
GAME_STATE_GAMEOVER = STATE_GAMEOVER

; Ghost indices
GHOST_BLINKY = 0
GHOST_PINKY  = 1
GHOST_INKY   = 2
GHOST_CLYDE  = 3
NUM_GHOSTS   = 4

; Ghost AI states
GHOSTSTATE_NONE        = 0
GHOSTSTATE_CHASE       = 1
GHOSTSTATE_SCATTER     = 2
GHOSTSTATE_FRIGHTENED  = 3
GHOSTSTATE_EYES        = 4
GHOSTSTATE_HOUSE       = 5
GHOSTSTATE_LEAVEHOUSE  = 6
GHOSTSTATE_ENTERHOUSE  = 7

; Sprite indices
SPR_PACMAN = 0
SPR_BLINKY = 1
SPR_PINKY  = 2
SPR_INKY   = 3
SPR_CLYDE  = 4
SPR_FRUIT  = 5

; Timing thresholds (ticks @60Hz)
TICKS_7S  = 420
TICKS_27S = 1620
TICKS_34S = 2040
TICKS_54S = 3240

; Collision proximity threshold (+1 compare value for |dx|,|dy| <= 3)
COLLISION_THRESH_PLUS1 = 4
TICKS_59S = 3540
TICKS_79S = 4740
TICKS_84S = 5040

; Fruit constants
FRUIT_NONE      = 0
FRUIT_CHERRIES  = 1
FRUIT_STRAWBERRY= 2
FRUIT_PEACH     = 3
FRUIT_APPLE     = 4
FRUIT_GRAPES    = 5
FRUIT_GALAXIAN  = 6
FRUIT_BELL      = 7
FRUIT_KEY       = 8

FRUIT_X = 14
FRUIT_Y = 20

; READY text placement (approx center above Pac‑Man)
READY_X = 12
READY_Y = 20

; Colors (from arcade mapping)
COLOR_DEFAULT    = $0F
COLOR_DOT        = $10
COLOR_PACMAN     = $09
COLOR_BLINKY     = $01
COLOR_PINKY      = $03
COLOR_INKY       = $05
COLOR_CLYDE      = $07
COLOR_FRIGHTENED = $11
COLOR_FRIGHTENED_BLINKING = $12

; AUTHENTIC PAC-MAN MOVEMENT TIMING (based on original pacman.c analysis)
; All speeds in 60 FPS ticks, pixel-perfect reproduction

; Pac-Man movement timing - moves when (tick % 8) != 0 (7 out of 8 frames)
PAC_NORMAL_MOD     = 8     ; Normal speed: tick % 8 != 0 
PAC_TUNNEL_MOD     = 4     ; Tunnel speed: tick % 4 != 0 (3 out of 4 frames)
PAC_DOT_FREEZE     = 1     ; 1 tick freeze after eating dot
PAC_PILL_FREEZE    = 3     ; 3 tick freeze after eating pill

; Ghost movement timing - moves when (tick % 7) != 0 (6 out of 7 frames)  
GHOST_NORMAL_MOD   = 7     ; Normal speed: tick % 7 != 0
GHOST_FRIGHT_MOD   = 2     ; Frightened: tick & 1 (every other frame)
GHOST_HOUSE_MOD    = 2     ; House: tick & 1 (half speed)
GHOST_TUNNEL_MOD   = 4     ; Tunnel: ((tick*2) % 4) != 0 (3/4 frames)
GHOST_EYES_SPEED   = 1     ; Eyes: (tick & 1) ? 1 : 2 pixels (1.5x speed)

; Pixel-level positioning constants (authentic 8x8 tiles)
; TILE_WIDTH and TILE_HEIGHT defined in framework
TILE_MID_X  = 4            ; Center of 8-pixel tile
TILE_MID_Y  = 4
DISPLAY_TILES_X = 28       ; 28x36 tile playfield
DISPLAY_TILES_Y = 36
DISPLAY_PIXELS_X = 224     ; 28 * 8 pixels
DISPLAY_PIXELS_Y = 288     ; 36 * 8 pixels

; Fruit tile and color tables (background tiles)
fruit_tile_by_id:
    .byte $00            ; NONE (unused)
    .byte NAMCO_TILE_CHERRIES_BASE     ; CHERRIES
    .byte NAMCO_TILE_STRAWBERRY_BASE   ; STRAWBERRY
    .byte NAMCO_TILE_PEACH_BASE        ; PEACH
    .byte NAMCO_TILE_APPLE_BASE        ; APPLE
    .byte NAMCO_TILE_GRAPES_BASE       ; GRAPES
    .byte NAMCO_TILE_GALAXIAN_BASE     ; GALAXIAN
    .byte NAMCO_TILE_BELL_BASE         ; BELL
    .byte NAMCO_TILE_KEY_BASE          ; KEY

fruit_color_by_id:
    .byte COLOR_DEFAULT  ; NONE
    .byte $14            ; CHERRIES
    .byte $0F            ; STRAWBERRY
    .byte $15            ; PEACH
    .byte $14            ; APPLE
    .byte $17            ; GRAPES
    .byte $09            ; GALAXIAN
    .byte $16            ; BELL
    .byte $16            ; KEY

; Game-specific zero page variables (starting at ZP_GAME_START)
game_state     = ZP_GAME_START + 0
; TILE-LEVEL POSITIONING with per-tile offsets
; pacman_x/pacman_y are tile coordinates (0..27, 0..30 within playfield rows 3..33)
; pac_off_x/pac_off_y are pixel offsets inside the 8x8 tile (0..7); center is 4
pacman_x       = ZP_GAME_START + 1    ; X position in tiles (0-27)
pacman_y       = ZP_GAME_START + 2    ; Y position in tiles (0-30)
pacman_dir     = ZP_GAME_START + 3    ; Current movement direction
score_lo       = ZP_GAME_START + 4
score_mid      = ZP_GAME_START + 5
score_hi       = ZP_GAME_START + 6
lives          = ZP_GAME_START + 7
level          = ZP_GAME_START + 8
dots_remaining = ZP_GAME_START + 9

; Frame tick counter (16-bit)
tick_lo        = ZP_GAME_START + 10
tick_hi        = ZP_GAME_START + 11
round_start_lo = ZP_GAME_START + 12
round_start_hi = ZP_GAME_START + 13
; Frightened end tick (absolute)
fr_end_lo      = ZP_GAME_START + 14
fr_end_hi      = ZP_GAME_START + 15
fr_blink       = ZP_GAME_START + 16   ; non-zero during last second of fright
; AUTHENTIC MOVEMENT TIMING STATE
pac_wanted_dir    = ZP_GAME_START + 17   ; Input direction (processed next valid turn)
pac_freeze_timer  = ZP_GAME_START + 18   ; Freeze countdown after eating dot/pill
pac_can_move      = ZP_GAME_START + 19   ; Boolean: can move this frame
last_phase        = ZP_GAME_START + 20   ; Last scatter/chase phase applied to ghosts
last_fright_flag  = ZP_GAME_START + 21   ; 0/1 last frightened-active flag
ZP_TEMP4       = ZP_GAME_START + 22
ZP_TEMP5       = ZP_GAME_START + 23
ZP_TEMP6       = ZP_GAME_START + 24
ZP_TEMP7       = ZP_GAME_START + 25
ZP_TEMP8       = ZP_GAME_START + 26
ZP_TEMP9       = ZP_GAME_START + 27
; Audio ZP
chomp_timer    = ZP_GAME_START + 28
chomp_active   = ZP_GAME_START + 29   ; 0=off, 2=base, 1=delta
chomp_base_lo  = ZP_GAME_START + 30
chomp_base_hi  = ZP_GAME_START + 31
ghost_sfx_tmr  = ZP_GAME_START + 32
siren_vib_ph   = ZP_GAME_START + 33
pellet_tick    = ZP_GAME_START + 34
ZP_NEXT_FREE   = ZP_GAME_START + 35

.segment "BSS"
; Ghost arrays (tile-space for now; upgrade to pixel-space later)
ghost_x:      .res NUM_GHOSTS
ghost_y:      .res NUM_GHOSTS
ghost_dir:    .res NUM_GHOSTS
ghost_state:  .res NUM_GHOSTS
ghost_next:   .res NUM_GHOSTS
ghost_dot_counter: .res NUM_GHOSTS
ghost_dot_limit:   .res NUM_GHOSTS
; Ghost pixel offsets within tile (0..7); 4 == centered
ghost_off_x:  .res NUM_GHOSTS
ghost_off_y:  .res NUM_GHOSTS
ghost_anim:   .res NUM_GHOSTS
; Global dot counter and ghost relaunch timers
global_dot_counter: .res 1
global_dot_active:  .res 1
ghost_relaunch_lo: .res NUM_GHOSTS
ghost_relaunch_hi: .res NUM_GHOSTS

; Level/fright working vars
fright_ticks: .res 1
ghosts_eaten_chain: .res 1
dots_eaten: .res 1

; UI state
score_lo_bcd: .res 1
score_hi_bcd: .res 1
hiscore_lo_bcd: .res 1
hiscore_hi_bcd: .res 1
lives_left: .res 1
; 2P alternating mode state (WIP scaffolding)
num_players: .res 1           ; 1 or 2
current_player: .res 1        ; 0 or 1
; Per-player banks for score/lives/level (simple duplication for now)
p1_score_lo_bcd: .res 1
p1_score_hi_bcd: .res 1
p1_lives_left: .res 1
p0_score_lo_bcd: .res 1
p0_score_hi_bcd: .res 1
p0_lives_left: .res 1
p2_score_lo_bcd: .res 1
p2_score_hi_bcd: .res 1
p2_lives_left: .res 1
extra_life_awarded: .res 1
paused_flag: .res 1
game_over_timer: .res 2
round_won_timer: .res 2
fruit_spawned_count: .res 1
; Siren state
siren_stage: .res 1
; Register-dump playback state (death, prelude)
audio_regdump_active: .res 1     ; 0=none, 1=death, 2=prelude
audio_regdump_idx:    .res 2     ; 16-bit index into dwords
; Siren fade-in state
siren_cur_vol: .res 1            ; 0..15 current fade volume nibble
siren_fade_pending: .res 1       ; 1 when prelude ended → start fade
; Popup state (single active popup, 3 chars)
popup_active: .res 1
popup_x: .res 1
popup_y: .res 1
popup_timer: .res 2
popup_len: .res 1
popup_c0: .res 1
popup_c1: .res 1
popup_c2: .res 1
popup_c3: .res 1
; Popup types and helpers
popup_chain: .res 1           ; 1 if chain popup, 0 otherwise
popup_chain_tile: .res 1      ; tile index for 16x16 score (200..1600)
fruit_score_active: .res 1
fruit_score_timer: .res 2
fruit_score_x: .res 1
fruit_score_y: .res 1
active_fruit: .res 1
fruit_timer: .res 2
score_digits: .res 7   ; numeric digits 0..9 (10's place up), trailing zero printed separately
hiscore_digits: .res 7
status_fruits: .res 7  ; last collected fruits, rightmost most recent
status_fruits_count: .res 1
ready_timer_lo: .res 1
ready_timer_hi: .res 1
; Scripted input state (optional)
script_ptr_lo: .res 1
script_ptr_hi: .res 1
script_frames_left: .res 1
script_mask: .res 1

; Pac-Man movement timing (ticks per pixel step)
pacman_move_period: .res 1
pacman_move_accum:  .res 1
pac_anim_phase: .res 1

; Pac-Man pixel offsets within tile (0..7); 4 == centered
pac_off_x: .res 1
pac_off_y: .res 1

; Ghost movement timing
ghost_move_period: .res NUM_GHOSTS
ghost_move_accum:  .res NUM_GHOSTS

.segment "CODE"

; ==============================================================================
; MAIN GAME LOOP
; ==============================================================================

game_start:
    ; Initialize X16 system
    jsr x16_init
    LOG_INFO 1              ; "System initialized"
    
    ; Initialize game
    jsr game_init
    
    ; Main game loop
game_loop:
    ; Wait for VSYNC
    jsr x16_wait_vsync
    
    ; Tick++ (16-bit)
    inc tick_lo
    bne @tick_done
    inc tick_hi
@tick_done:
    
    ; Update game state
    jsr game_update
    ; Update audio envelopes/loops
    jsr audio_update
    ; Handle siren fade-in if needed (after prelude)
    lda siren_fade_pending
    beq @no_fade
    ; increment current vol nibble until base stage vol nibble is reached
    lda siren_stage
    tax
    dex
    lda siren_vol,x
    and #$0F
    sta ZP_TEMP1            ; target nibble
    lda siren_cur_vol
    cmp ZP_TEMP1
    bcs @fade_done
    inc siren_cur_vol
    ; use stage freq/wave with vibrato, but volume from siren_cur_vol
    lda siren_freq_lo,x
    sta ZP_TEMP3
    lda siren_freq_hi,x
    sta ZP_TEMP4
    lda tick_lo
    and #$0F
    bne :+
    inc siren_vib_ph
:
    lda siren_vib_ph
    and #$03
    beq @vb0
    cmp #1
    beq @vb1
    cmp #2
    beq @vb2
    lda ZP_TEMP3
    sec
    sbc #$02
    sta ZP_TEMP3
    bra @vb_done
@vb2:
    lda ZP_TEMP3
    clc
    adc #$02
    sta ZP_TEMP3
    bra @vb_done
@vb1:
    lda ZP_TEMP3
    clc
    adc #$01
    sta ZP_TEMP3
    bra @vb_done
@vb0:
    lda ZP_TEMP3
    sec
    sbc #$01
    sta ZP_TEMP3
@vb_done:
    lda siren_cur_vol
    ora #$C0
    sta ZP_TEMP1
    lda siren_wave,x
    sta ZP_TEMP2
    ldx ZP_TEMP3
    ldy ZP_TEMP4
    lda #4
    jsr psg_write_voice
    ; long jump via local branch to avoid range issues
    beq :+
    jmp @no_fade
:
@fade_done:
    stz siren_fade_pending
@no_fade:
    
    ; Render frame
    jsr game_render
    jsr popup_render_tick
    
    ; Continue loop
    jmp game_loop

; ==============================================================================
; GAME INITIALIZATION
; ==============================================================================

game_init:
    ; Set initial game state
    lda #GAME_STATE_INIT
    sta game_state
    
    ; Initialize VERA graphics
    jsr vera_init
    LOG_INFO 17             ; "Pacman: Initializing 4bpp palette mode"
    
    ; Convert and upload tile graphics (2bpp -> 4bpp) to VRAM first
    lda #<rom_tiles
    sta ZP_PTR1
    lda #>rom_tiles
    sta ZP_PTR1+1
    lda #64                 ; number of 8x8 tiles to convert (adjust if needed)
    jsr vera_convert_upload_tiles_2bpp
    
    ; Set up tilemap layer for maze
    lda #0              ; Layer 0
    ldx #MAP_32x32      ; 32x32 tile map
    ldy #0              ; 8x8 tiles
    jsr vera_setup_tilemap
    LOG_INFO 11             ; "Pacman: Setting VERA tile mode 40x31"
    
    ; Set up sprites for characters
    jsr vera_setup_sprites
    
    ; Build and upload full 256-entry palette from ROM logical palette
    lda #<rom_palette
    sta ZP_PTR1
    lda #>rom_palette
    sta ZP_PTR1+1
    lda #<rom_hwcolors
    sta ZP_PTR2
    lda #>rom_hwcolors
    sta ZP_PTR2+1
    jsr vera_build_upload_palette_from_rom

    ; Convert and upload sprite graphics from ROM (subset) 2bpp -> 4bpp
    lda #<rom_sprites
    sta ZP_PTR1
    lda #>rom_sprites
    sta ZP_PTR1+1
    lda #0              ; start at sprite 0
    ldx #32             ; convert 32 sprites (adjust as needed)
    jsr vera_convert_upload_sprites_2bpp

    ; Duplicate digit glyphs ('0'..'9') from layer tiles into sprite tile memory
    jsr copy_digits_to_sprite_vram
    ; Ensure popup digit sprites use 8x8 size (palette 1): size/pal byte $41
    ; We'll set this when enabling the popup sprites (IDs 6..8)
    
    ; Initialize game variables
    lda #DIP_STARTING_LIVES
    sta lives
    
    lda #1
    sta level
    
    stz score_lo
    stz score_mid
    stz score_hi
    stz score_lo_bcd
    stz score_hi_bcd
    ; 2P scaffold: default to 1 player
    lda #DIP_NUM_PLAYERS
    sta num_players
    stz current_player
    stz p1_score_lo_bcd
    stz p1_score_hi_bcd
    lda #DIP_STARTING_LIVES
    sta p1_lives_left
    stz p2_score_lo_bcd
    stz p2_score_hi_bcd
    lda #DIP_STARTING_LIVES
    sta p2_lives_left
    
    ; Clear screen and set up colors
    jsr clear_screen
    
    ; Draw the authentic Pac-Man maze
    jsr draw_pacman_maze
    LOG_INFO 14             ; "Pacman: Screen layout test complete"
    
    ; Set initial Pac-Man position (center of maze, tile coordinates)
    lda #14
    sta pacman_x
    lda #26
    sta pacman_y
    lda #4
    sta pac_off_x
    sta pac_off_y
    
    lda #DIR_LEFT       ; Start facing left
    sta pacman_dir
    sta pac_wanted_dir
    
    ; Count initial dots
    jsr count_dots
    stz dots_eaten
    stz global_dot_counter
    lda #1
    sta global_dot_active
    lda #DIP_STARTING_LIVES
    sta lives_left
    lda #FRUIT_NONE
    sta active_fruit
    stz fruit_timer
    stz fruit_timer+1
    ; READY! freeze for ~2 seconds and play prelude once
    lda #<(120)
    sta ready_timer_lo
    lda #>(120)
    sta ready_timer_hi
    ; start prelude register-dump (voice reservation handled in audio_update)
    lda #2
    sta audio_regdump_active
    stz audio_regdump_idx
    stz audio_regdump_idx+1
    ; reset one-time flags
    stz extra_life_awarded
    ; turn off siren during prelude
    jsr siren_silence
    stz siren_cur_vol
    stz siren_fade_pending
    lda #6           ; initial pacman speed: 1 tile per 6 ticks (placeholder)
    sta pacman_move_period
    stz pacman_move_accum
    
    ; Initialize round timing
    lda tick_lo
    sta round_start_lo
    lda tick_hi
    sta round_start_hi

    ; Initialize ghosts
    jsr ghosts_init

    ; Draw UI: headings and initial scores/lives
    jsr ui_draw_init
    
    ; Transition to attract mode
    lda #GAME_STATE_ATTRACT
    sta game_state
    
    rts

; ==============================================================================
; AUTHENTIC PER-FRAME MOVEMENT GATING (see unified routine below)
; ==============================================================================

; ==============================================================================
; TILE GRAPHICS UPLOAD
; ==============================================================================

upload_tile_graphics:
    ; Upload the ROM tile graphics to VERA tile memory
    ; Source: rom_tiles from pacman_data.asm
    ; Destination: VRAM_TILES ($10000)
    
    ; Set up source pointer
    lda #<rom_tiles
    sta ZP_PTR1
    lda #>rom_tiles
    sta ZP_PTR1+1
    
    ; Upload a subset of tiles in expected 4bpp format (assumed prepared)
    lda #64             ; Number of tiles to upload (adjust as needed)
    jsr vera_upload_tiles
    
    rts

; ==============================================================================
; MAZE DRAWING - AUTHENTIC PAC-MAN LAYOUT
; ==============================================================================

draw_pacman_maze:
    ; Draw the authentic Pac-Man maze using the exact layout from the original
    ; This uses the ASCII map from the reference implementation
    
    ; Set up maze data pointer
    lda #<maze_data
    sta ZP_PTR1
    lda #>maze_data
    sta ZP_PTR1+1
    
    ; Draw maze row by row
    ldy #0              ; Maze data index
    ldx #3              ; Start at screen row 3
    
draw_maze_row:
    cpx #34             ; Check if we've drawn all rows (3-33)
    bcs maze_done
    
    ; Draw one row of 28 tiles
    phx                 ; Save row number
    ldx #0              ; Column counter
    
draw_maze_col:
    cpx #28             ; Check if we've drawn all columns
    bcs next_maze_row
    
    ; Get maze character and convert to tile
    lda (ZP_PTR1),y
    jsr ascii_to_tile
    
    ; Set tile position
    pha                 ; Save tile code
    txa                 ; Column to A
    pha                 ; Save column
    plx                 ; Column to X
    pla                 ; Restore tile code
    ply                 ; Row to Y (from stack)
    phx                 ; Save column again
    phy                 ; Save row again
    
    ; Draw the tile
    jsr set_tile
    
    ; Next column
    ply                 ; Restore row
    plx                 ; Restore column
    inx
    iny                 ; Next maze data byte
    bra draw_maze_col
    
next_maze_row:
    plx                 ; Restore row number
    inx                 ; Next row
    bra draw_maze_row
    
maze_done:
    rts

; Convert ASCII maze character to tile code
ascii_to_tile:
    cmp #' '
    beq @space
    cmp #'.'
    beq @dot
    cmp #'P'
    beq @pill
    cmp #'0'
    beq @wall_ul
    cmp #'1'
    beq @wall_ur
    cmp #'2'
    beq @wall_ll
    cmp #'3'
    beq @wall_lr
    cmp #'U'
    beq @wall_h
    cmp #'L'
    beq @wall_v
    cmp #'R'
    beq @wall_vr
    cmp #'B'
    beq @wall_t
    cmp #'-'
    beq @door
    ; Default to space for unknown characters
@space:
    lda #TILE_SPACE
    rts
@dot:
    lda #TILE_DOT
    rts
@pill:
    lda #TILE_PILL
    rts
@wall_ul:
    lda #TILE_WALL_UL
    rts
@wall_ur:
    lda #TILE_WALL_UR
    rts
@wall_ll:
    lda #TILE_WALL_LL
    rts
@wall_lr:
    lda #TILE_WALL_LR
    rts
@wall_h:
    lda #TILE_WALL_H
    rts
@wall_v:
    lda #TILE_WALL_V
    rts
@wall_vr:
    lda #TILE_WALL_VR
    rts
@wall_t:
    lda #TILE_WALL_T
    rts
@door:
    lda #TILE_DOOR
    rts

; Set a tile at position X,Y with tile code A
set_tile:
    ; Calculate VRAM address: VRAM_TILEMAP + (Y * 64) + (X * 2)
    ; Each tile takes 2 bytes (tile code + color)
    pha                 ; Save tile code
    
    ; Calculate Y * 64 (since tilemap is 32 tiles wide, 2 bytes per tile = 64 bytes per row)
    tya
    asl                 ; * 2
    asl                 ; * 4
    asl                 ; * 8
    asl                 ; * 16
    asl                 ; * 32
    asl                 ; * 64
    sta ZP_TEMP1        ; Low byte of Y offset
    
    ; Add X * 2
    txa
    asl                 ; * 2 (2 bytes per tile)
    clc
    adc ZP_TEMP1
    sta ZP_TEMP1        ; Final low byte
    
    ; Set VERA address
    VERA_SET_ADDR VRAM_TILEMAP, 1
    lda VERA_ADDR_LOW
    clc
    adc ZP_TEMP1
    sta VERA_ADDR_LOW
    bcc @no_carry
    inc VERA_ADDR_MID
@no_carry:
    
    ; Write tile code and color
    pla                 ; Restore tile code
    sta VERA_DATA0      ; Write tile
    lda #$0F            ; White color
    sta VERA_DATA0      ; Write color

    ; Optional verbose log: "Writing tile %1 at position %3"
    ; %1 = tile code, %3 = packed position (Y<<5 | X)
.ifdef LOG_VERBOSE
    pha
    tya
    asl
    asl
    asl
    asl
    asl                 ; Y * 32
    ora txa             ; add X
    sta ASM_LOG_PARAM2  ; use param2 for 8-bit packed pos (low 5 bits X, high 3 bits Y truncated)
    pla
    sta ASM_LOG_PARAM1  ; tile code
    lda #16             ; message ID 16
    sta ASM_LOG_INFO
.endif
    
    rts

; Set a tile at (X,Y) with tile A and color in ZP_TEMP3
set_tile_color:
    pha
    phx
    phy
    ; reuse set_tile address math
    ply                 ; Y in Y
    plx                 ; X in X
    pla                 ; A tile
    ; Calculate Y * 64
    pha
    tya
    asl
    asl
    asl
    asl
    asl
    asl
    sta ZP_TEMP1
    ; Add X * 2
    txa
    asl
    clc
    adc ZP_TEMP1
    sta ZP_TEMP1
    ; Set base address
    VERA_SET_ADDR VRAM_TILEMAP, 1
    lda VERA_ADDR_LOW
    clc
    adc ZP_TEMP1
    sta VERA_ADDR_LOW
    bcc nc_settilecolor
    inc VERA_ADDR_MID
nc_settilecolor:
    ; write tile
    pla
    sta VERA_DATA0
    lda ZP_TEMP3
    sta VERA_DATA0
    rts

; ==============================================================================
; GAME UPDATE LOGIC
; ==============================================================================

game_update:
    lda game_state
    cmp #GAME_STATE_INIT
    beq update_init
    cmp #GAME_STATE_ATTRACT
    beq update_attract
    cmp #GAME_STATE_PLAYING
    beq update_playing
    cmp #GAME_STATE_DEATH
    bne @not_death
    jsr tick_pacman_death
    rts
@not_death:
    cmp #GAME_STATE_GAMEOVER
    bne skip_gameover
    jmp update_gameover
skip_gameover:
    ; Update siren each frame based on remaining dots and frightened state
    jsr siren_update
    rts

update_init:
    ; Initialization complete, go to attract mode
    lda #GAME_STATE_ATTRACT
    sta game_state
    rts

update_attract:
    ; Check for start game input
    jsr read_input
    lda ZP_INPUT_STATE
    and #$10  ; Check for space key
    beq @no_start
    
    ; Start game
    lda #GAME_STATE_PLAYING
    sta game_state
    ; Draw READY! and hold timer starts from game_init
    jsr ui_draw_ready
    
@no_start:
    rts

update_playing:
    ; Pause toggle (P/Start)
    jsr read_input
    lda ZP_INPUT_STATE
    and #$10                ; START toggles pause for now
    beq @no_pause_tgl
    lda paused_flag
    eor #1
    sta paused_flag
@no_pause_tgl:
    lda paused_flag
    beq @not_paused
    rts                     ; paused: skip updates
@not_paused:
    ; Freeze on READY timer
    lda ready_timer_lo
    ora ready_timer_hi
    beq @no_ready
    ; if prelude playing, tick it here so it ends with READY
    lda audio_regdump_active
    cmp #2
    bne :+
    jsr audio_regdump_tick
:
    jsr ui_tick_ready
    rts
@no_ready:
    ; Update dynamic movement speeds based on state and tunnel rules
    jsr update_movement_timing
    ; Update player
    jsr update_player
    
    ; Update ghosts
    jsr update_ghosts
    
    ; Check for game over conditions
    jsr check_game_over
    ; Check collisions
    jsr check_collisions
    ; UI updates (score/lives/fruit)
    jsr ui_update
    ; Check collisions
    jsr check_collisions
; ==============================================================================
; GHOSTS
; ==============================================================================

ghosts_init:
    ; Blinky at (14,14), facing left, scatter
    lda #14
    sta ghost_x+GHOST_BLINKY
    lda #14
    sta ghost_y+GHOST_BLINKY
    lda #DIR_LEFT
    sta ghost_dir+GHOST_BLINKY
    lda #GHOSTSTATE_SCATTER
    sta ghost_state+GHOST_BLINKY
    stz ghost_dot_counter+GHOST_BLINKY
    stz ghost_dot_limit+GHOST_BLINKY
    lda #6
    sta ghost_move_period+GHOST_BLINKY
    stz ghost_move_accum+GHOST_BLINKY
    lda #4
    sta ghost_off_x+GHOST_BLINKY
    sta ghost_off_y+GHOST_BLINKY
    stz ghost_anim+GHOST_BLINKY

    ; Pinky in house area (14,17), down, house
    lda #14
    sta ghost_x+GHOST_PINKY
    lda #17
    sta ghost_y+GHOST_PINKY
    lda #DIR_DOWN
    sta ghost_dir+GHOST_PINKY
    lda #GHOSTSTATE_HOUSE
    sta ghost_state+GHOST_PINKY
    stz ghost_dot_counter+GHOST_PINKY
    ; Pinky leaves early by timer, not dots
    lda #0
    sta ghost_dot_limit+GHOST_PINKY
    lda #6
    sta ghost_move_period+GHOST_PINKY
    stz ghost_move_accum+GHOST_PINKY
    lda #4
    sta ghost_off_x+GHOST_PINKY
    sta ghost_off_y+GHOST_PINKY
    stz ghost_anim+GHOST_PINKY

    ; Inky in house area (14,17), up, house
    lda #14
    sta ghost_x+GHOST_INKY
    lda #17
    sta ghost_y+GHOST_INKY
    lda #DIR_UP
    sta ghost_dir+GHOST_INKY
    lda #GHOSTSTATE_HOUSE
    sta ghost_state+GHOST_INKY
    stz ghost_dot_counter+GHOST_INKY
    ; Inky dot release per level (default applied below)
    jsr apply_ghost_dot_limits_for_level
    lda #6
    sta ghost_move_period+GHOST_INKY
    stz ghost_move_accum+GHOST_INKY
    lda #4
    sta ghost_off_x+GHOST_INKY
    sta ghost_off_y+GHOST_INKY
    stz ghost_anim+GHOST_INKY

    ; Clyde in house area (14,17), up, house
    lda #14
    sta ghost_x+GHOST_CLYDE
    lda #17
    sta ghost_y+GHOST_CLYDE
    lda #DIR_UP
    sta ghost_dir+GHOST_CLYDE
    lda #GHOSTSTATE_HOUSE
    sta ghost_state+GHOST_CLYDE
    stz ghost_dot_counter+GHOST_CLYDE
    ; Clyde limit also set by apply_ghost_dot_limits_for_level
    lda #6
    sta ghost_move_period+GHOST_CLYDE
    stz ghost_move_accum+GHOST_CLYDE
    lda #4
    sta ghost_off_x+GHOST_CLYDE
    sta ghost_off_y+GHOST_CLYDE
    stz ghost_anim+GHOST_CLYDE

    LOG_INFO 15          ; "Pacman: VERA register %1 set to %2" (placeholder init complete marker)
    rts

; Compute current SCATTER/CHASE phase in A (GHOSTSTATE_SCATTER or GHOSTSTATE_CHASE)
game_scatter_chase_phase:
    ; delta = tick - round_start
    lda tick_lo
    sec
    sbc round_start_lo
    sta ZP_TEMP1
    lda tick_hi
    sbc round_start_hi
    sta ZP_TEMP2
    ; compare delta with thresholds
    ; if delta < 7s -> SCATTER
    lda ZP_TEMP2
    cmp #>TICKS_7S
    bne gsp_cmp7_hi
    lda ZP_TEMP1
    cmp #<TICKS_7S
    bcc gsp_ret_scatter
    bcs gsp_after7
gsp_cmp7_hi:
    bcc gsp_ret_scatter
gsp_after7:
    ; <27s -> CHASE
    lda ZP_TEMP2
    cmp #>TICKS_27S
    bne gsp_cmp27_hi
    lda ZP_TEMP1
    cmp #<TICKS_27S
    bcc gsp_ret_chase
    bcs gsp_after27
gsp_cmp27_hi:
    bcc gsp_ret_chase
gsp_after27:
    ; <34s -> SCATTER
    lda ZP_TEMP2
    cmp #>TICKS_34S
    bne gsp_cmp34_hi
    lda ZP_TEMP1
    cmp #<TICKS_34S
    bcc gsp_ret_scatter
    bcs gsp_after34
gsp_cmp34_hi:
    bcc gsp_ret_scatter
gsp_after34:
    ; <54s -> CHASE
    lda ZP_TEMP2
    cmp #>TICKS_54S
    bne gsp_cmp54_hi
    lda ZP_TEMP1
    cmp #<TICKS_54S
    bcc gsp_ret_chase
    bcs gsp_after54
gsp_cmp54_hi:
    bcc gsp_ret_chase
gsp_after54:
    ; <59s -> SCATTER
    lda ZP_TEMP2
    cmp #>TICKS_59S
    bne gsp_cmp59_hi
    lda ZP_TEMP1
    cmp #<TICKS_59S
    bcc gsp_ret_scatter
    bcs gsp_after59
gsp_cmp59_hi:
    bcc gsp_ret_scatter
gsp_after59:
    ; <79s -> CHASE
    lda ZP_TEMP2
    cmp #>TICKS_79S
    bne gsp_cmp79_hi
    lda ZP_TEMP1
    cmp #<TICKS_79S
    bcc gsp_ret_chase
    bcs gsp_after79
gsp_cmp79_hi:
    bcc gsp_ret_chase
gsp_after79:
    ; <84s -> SCATTER
    lda ZP_TEMP2
    cmp #>TICKS_84S
    bne gsp_cmp84_hi
    lda ZP_TEMP1
    cmp #<TICKS_84S
    bcc gsp_ret_scatter
    bcs gsp_after84
gsp_cmp84_hi:
    bcc gsp_ret_scatter
gsp_after84:
    ; else CHASE
gsp_ret_chase:
    lda #GHOSTSTATE_CHASE
    rts
gsp_ret_scatter:
    lda #GHOSTSTATE_SCATTER
    rts

; Update ghosts: set state based on global schedule unless in house/leavehouse/eyes
update_ghosts:
    jsr game_scatter_chase_phase
    sta ZP_TEMP3          ; desired phase

    ; Detect scatter<->chase phase change and reverse eligible ghosts
    lda last_phase
    cmp ZP_TEMP3
    beq @no_phase_change
    lda ZP_TEMP3
    sta last_phase
    ldx #0
@rev_loop:
    cpx #NUM_GHOSTS
    bcs @rev_done
    lda ghost_state,x
    cmp #GHOSTSTATE_EYES
    beq @rev_skip
    cmp #GHOSTSTATE_HOUSE
    beq @rev_skip
    cmp #GHOSTSTATE_LEAVEHOUSE
    beq @rev_skip
    lda ghost_dir,x
    eor #$02
    sta ghost_dir,x
@rev_skip:
    inx
    bra @rev_loop
@rev_done:
@no_phase_change:

    ; Handle frightened timeout/blink
    ; if tick >= fr_end -> no frightened (leave as schedule), else force frightened
    lda tick_hi
    cmp fr_end_hi
    bcc @fr_active
    bne @fr_done
    lda tick_lo
    cmp fr_end_lo
    bcc @fr_active
@fr_done:
    ; not frightened, ZP_TEMP4 = 0
    stz ZP_TEMP4
    ; frightened ended this frame?
    lda last_fright_flag
    beq @no_f_end
    stz last_fright_flag
    ; reverse eligible ghosts once
    ldx #0
@fend_loop:
    cpx #NUM_GHOSTS
    bcs @fend_done
    lda ghost_state,x
    cmp #GHOSTSTATE_EYES
    beq @fend_skip
    cmp #GHOSTSTATE_HOUSE
    beq @fend_skip
    cmp #GHOSTSTATE_LEAVEHOUSE
    beq @fend_skip
    lda ghost_dir,x
    eor #$02
    sta ghost_dir,x
@fend_skip:
    inx
    bra @fend_loop
@fend_done:
@no_f_end:
    bra fr_done_set
@fr_active:
    lda #1
    sta ZP_TEMP4          ; frightened active
    ; frightened started this frame?
    lda last_fright_flag
    bne @no_f_start
    lda #1
    sta last_fright_flag
    ; reverse eligible ghosts once
    ldx #0
@fstart_loop:
    cpx #NUM_GHOSTS
    bcs @fstart_done
    lda ghost_state,x
    cmp #GHOSTSTATE_EYES
    beq @fstart_skip
    cmp #GHOSTSTATE_HOUSE
    beq @fstart_skip
    cmp #GHOSTSTATE_LEAVEHOUSE
    beq @fstart_skip
    lda ghost_dir,x
    eor #$02
    sta ghost_dir,x
@fstart_skip:
    inx
    bra @fstart_loop
@fstart_done:
@no_f_start:
    ; set blink cadence during last second (arcade ~0.25s on/off cadence)
    ; if (fr_end - tick) < 60
    lda fr_end_lo
    sec
    sbc tick_lo
    sta ZP_TEMP1
    lda fr_end_hi
    sbc tick_hi
    sta ZP_TEMP2
    lda ZP_TEMP2
    bne no_blink
    lda ZP_TEMP1
    cmp #60
    bcs no_blink
    ; Blink cadence: toggle every 8 frames in last second
    lda tick_lo
    and #$08
    beq :+
    lda #1
    sta fr_blink
    bra fr_done_set
:
    stz fr_blink
    bra fr_done_set
no_blink:
    stz fr_blink
fr_done_set:

    ldx #0
loop_g:
    cpx #NUM_GHOSTS
    bne @cont
    jmp done_g
@cont:
    lda ghost_state,x
    cmp #GHOSTSTATE_HOUSE
    bne skip_maybe_leave
    jsr maybe_leave
    jmp next_g
skip_maybe_leave:
    cmp #GHOSTSTATE_LEAVEHOUSE
    beq @normal
@chk_enter:
    cmp #GHOSTSTATE_ENTERHOUSE
    beq @normal
@chk_eyes:
    cmp #GHOSTSTATE_EYES
    beq @normal
@normal:
    ; frightened override
    lda ZP_TEMP4
    beq no_fright
    lda #GHOSTSTATE_FRIGHTENED
    bra apply_phase

no_fright:
    lda ZP_TEMP3
apply_phase:
    cmp ghost_state,x
    beq no_change
    ; transition scatter<->chase: reverse direction
    pha
    lda ghost_dir,x
    eor #$02              ; reverse dir (Right<->Left, Down<->Up)
    sta ghost_dir,x
    pla
    sta ghost_state,x
no_change:
    ; Eyes/enterhouse handling: on reaching house set state accordingly
    lda ghost_state,x
    cmp #GHOSTSTATE_EYES
    bne chk_enter
    lda ghost_x,x
    cmp #HOUSE_X
    bne move_normal
    lda ghost_y,x
    cmp #HOUSE_Y
    bne move_normal
    lda #GHOSTSTATE_ENTERHOUSE
    sta ghost_state,x
    jmp next_g
chk_enter:
    cmp #GHOSTSTATE_ENTERHOUSE
    bne move_normal
    ; inside house now -> set to HOUSE and reset counters
    lda #GHOSTSTATE_HOUSE
    sta ghost_state,x
    stz ghost_dot_counter,x
    ; schedule quick relaunch after eyes return (e.g., 2 seconds)
    lda #<(2*60)
    sta ghost_relaunch_lo,x
    lda #>(2*60)
    sta ghost_relaunch_hi,x
    jmp next_g
move_normal:
    ; Movement gating per arcade-like rules
    ; Eyes/enterhouse: 1.5x speed -> one or two pixel steps per tick
    lda ghost_state,x
    cmp #GHOSTSTATE_EYES
    beq @eyes_move
    cmp #GHOSTSTATE_ENTERHOUSE
    beq @eyes_move
    ; State/tile/level-specific gating
    jsr get_ghost_move_mask_for_index
    sta ZP_TEMP1
    lda tick_lo
    and ZP_TEMP1
    beq @skip_move
    bra @do_move
@skip_move:
    jmp next_g
@eyes_move:
    ; one guaranteed step
    jsr ghost_is_center
    bne @eyes_step1
    phx
    jsr ghost_compute_target   ; ZP_TEMP1/2 = target tile (tx,ty)
    plx
    jsr ghost_choose_move      ; updates dir
@eyes_step1:
    jsr ghost_apply_pixel_step
    ; if even tick, do a second step
    lda tick_lo
    and #1
    bne next_g
    jsr ghost_is_center
    bne @eyes_step2
    phx
    jsr ghost_compute_target
    plx
    jsr ghost_choose_move
@eyes_step2:
    jsr ghost_apply_pixel_step
    jmp next_g
@do_move:
    ; Movement decision towards target
    jsr ghost_is_center
    bne @just_step
    phx
    jsr ghost_compute_target   ; ZP_TEMP1/2 = target tile (tx,ty)
    plx
    jsr ghost_choose_move      ; updates dir
@just_step:
    jsr ghost_apply_pixel_step
    ; restore X? loop increments X at end, so fine
next_g:
    inx
    jmp loop_g
done_g:
    rts

; ----------------------------------------------------------------------------
; AUTHENTIC MOVEMENT TIMING SYSTEM
; ----------------------------------------------------------------------------  
; Single canonical routine (called from game_update) that sets pac_can_move
update_movement_timing:
    ; Check freeze first
    lda pac_freeze_timer
    beq @check
    dec pac_freeze_timer
    stz pac_can_move
    rts
@check:
    ; Determine frightened and dot status, then select mask
    ; Check frightened active
    lda tick_hi
    cmp fr_end_hi
    bcc @fr_active
    bne @fr_inactive
    lda tick_lo
    cmp fr_end_lo
    bcc @fr_active
@fr_inactive:
    lda #0
    sta ZP_TEMP3            ; ZP_TEMP3=0 -> not frightened
    bra @check_dot
@fr_active:
    lda #1
    sta ZP_TEMP3            ; ZP_TEMP3=1 -> frightened
@check_dot:
    ; Fetch current maze char at tile center and detect dot/pill
    ldx pacman_x
    ldy pacman_y
    jsr maze_get_char_xy
    cmp #'.'
    beq @is_dot
    cmp #'P'
    beq @is_dot
    lda #0
    sta ZP_TEMP2            ; ZP_TEMP2=0 -> not dot
    bra @choose_mask
@is_dot:
    lda #1
    sta ZP_TEMP2            ; ZP_TEMP2=1 -> dot/pill
@choose_mask:
    ; Choose mask table based on frightened and dot flags
    jsr get_level_index_0_12
    ; default pointer = normal
    lda #<pac_speed_mask_normal_by_level
    sta ZP_PTR1
    lda #>pac_speed_mask_normal_by_level
    sta ZP_PTR1+1
    lda ZP_TEMP2
    beq @maybe_fright
    ; dot path
    lda #<pac_speed_mask_dot_by_level
    sta ZP_PTR1
    lda #>pac_speed_mask_dot_by_level
    sta ZP_PTR1+1
@maybe_fright:
    lda ZP_TEMP3
    beq @load_mask
    ; frightened path overrides
    lda ZP_TEMP2
    beq @fright_normal
    ; frightened+dot
    lda #<pac_speed_mask_fright_dot_by_level
    sta ZP_PTR1
    lda #>pac_speed_mask_fright_dot_by_level
    sta ZP_PTR1+1
    bra @load_mask
@fright_normal:
    lda #<pac_speed_mask_fright_by_level
    sta ZP_PTR1
    lda #>pac_speed_mask_fright_by_level
    sta ZP_PTR1+1
@load_mask:
    lda (ZP_PTR1),y         ; A = mask
    sta ZP_TEMP1            ; store mask
    lda tick_lo
    and ZP_TEMP1
    beq @no
    lda #1
    sta pac_can_move
    rts
@no:
    stz pac_can_move
    rts

maybe_leave:
    ; Check dot-limit release first
    lda ghost_dot_counter,x
    cmp ghost_dot_limit,x
    bcc @check_global
    bne continue_leave
    ; equal counts as release as well
    jmp continue_leave
@check_global:
    ; Global counter fallback (active at start of life/round)
    lda global_dot_active
    beq @check_timer
    ; Clyde special release at 32 global dots
    cpx #GHOST_CLYDE
    bne @chk_force
    lda global_dot_counter
    cmp #32
    bne @chk_force
    jmp continue_leave
@chk_force:
    ; Force one dot credit to the next eligible ghost per dot eaten
    lda ghost_dot_counter,x
    cmp ghost_dot_limit,x
    bcs @check_timer
    ; credit one and stop (only one ghost gets a credit per dot)
    inc ghost_dot_counter,x
    jmp next_g
@check_timer:
    ; Fallback: timed release based on level (simplified per dossier)
    lda ghost_relaunch_hi,x
    ora ghost_relaunch_lo,x
    bne @tick
    ; start per-ghost timer: Pinky 4s, Inky 8s, Clyde 12s
    cpx #GHOST_PINKY
    bne @chk_inky
    lda #<(4*60)
    sta ghost_relaunch_lo,x
    lda #>(4*60)
    sta ghost_relaunch_hi,x
    jmp next_g
@chk_inky:
    cpx #GHOST_INKY
    bne @chk_clyde
    lda #<(8*60)
    sta ghost_relaunch_lo,x
    lda #>(8*60)
    sta ghost_relaunch_hi,x
    jmp next_g
@chk_clyde:
    lda #<(12*60)
    sta ghost_relaunch_lo,x
    lda #>(12*60)
    sta ghost_relaunch_hi,x
    jmp next_g
@tick:
    lda ghost_relaunch_lo,x
    bne @dec_lo
    dec ghost_relaunch_hi,x
@dec_lo:
    dec ghost_relaunch_lo,x
    lda ghost_relaunch_hi,x
    ora ghost_relaunch_lo,x
    bne @pending
    ; timer expired -> release
    jmp continue_leave
@pending:
    jmp next_g
continue_leave:
    ; set LEAVEHOUSE and target door
    lda #GHOSTSTATE_LEAVEHOUSE
    sta ghost_state,x
    ; Move toward door Y
    ; simple move up until DOOR_Y
    lda ghost_y,x
    cmp #DOOR_Y
    beq to_scatter
    ; move up
    lda #DIR_UP
    sta ghost_dir,x
    jsr dir_to_vec
    lda ghost_y,x
    clc
    adc ZP_TEMP2
    sta ghost_y,x
    jmp next_g
to_scatter:
    lda #GHOSTSTATE_SCATTER
    sta ghost_state,x
    jmp next_g

; ----------------------------------------------------------------------------
; Ghost targeting and movement helpers
; ----------------------------------------------------------------------------

; Scatter target table: blinky, pinky, inky, clyde
ghost_scatter_targets:
    .byte 25, 0   ; Blinky
    .byte 2, 0    ; Pinky
    .byte 27, 34  ; Inky
    .byte 0, 34   ; Clyde

HOUSE_X = 14
HOUSE_Y = 17
DOOR_Y  = 14

; Get dir vector for A=DIR -> returns dx in ZP_TEMP1 (signed), dy in ZP_TEMP2 (signed)
dir_to_vec:
    cmp #DIR_UP
    beq @up
    cmp #DIR_DOWN
    beq @down
    cmp #DIR_LEFT
    beq @left
    ; right
    lda #1
    sta ZP_TEMP1
    lda #0
    sta ZP_TEMP2
    rts
@up:
    lda #0
    sta ZP_TEMP1
    lda #$FF      ; -1
    sta ZP_TEMP2
    rts
@down:
    lda #0
    sta ZP_TEMP1
    lda #1
    sta ZP_TEMP2
    rts
@left:
    lda #$FF
    sta ZP_TEMP1
    lda #0
    sta ZP_TEMP2
    rts

; Compute ghost target for ghost index X -> ZP_TEMP1=tx, ZP_TEMP2=ty
ghost_compute_target:
    ; Default scatter
    phx
    txa
    asl
    tay
    lda ghost_scatter_targets,y
    sta ZP_TEMP1
    iny
    lda ghost_scatter_targets,y
    sta ZP_TEMP2
    plx
    ; state overrides
    lda ghost_state,x
    cmp #GHOSTSTATE_SCATTER
    bne not_scatter
    jmp target_done
not_scatter:
    cmp #GHOSTSTATE_CHASE
    beq @do_chase
    cmp #GHOSTSTATE_EYES
    beq @do_eyes
    cmp #GHOSTSTATE_ENTERHOUSE
    beq @do_eyes
    ; frightened: pick random tile to emulate arcade randomization at intersections
    jsr random_byte
    and #$1F               ; 0..31 within maze width
    sta ZP_TEMP1           ; tx
    jsr random_byte
    and #$1F
    clc
    adc #2                 ; keep within visible rows
    cmp #31
    bcc :+
    lda #30
:
    sta ZP_TEMP2           ; ty
    jmp target_done
@do_eyes:
    lda #HOUSE_X
    sta ZP_TEMP1
    lda #HOUSE_Y
    sta ZP_TEMP2
    jmp target_done
@do_chase:
    ; per ghost
    cpx #GHOST_BLINKY
    beq @ch_blinky
    cpx #GHOST_PINKY
    beq @ch_pinky
    cpx #GHOST_INKY
    beq @ch_inky
    ; Clyde
    jmp @ch_clyde
@ch_blinky:
    lda pacman_x
    sta ZP_TEMP1
    lda pacman_y
    sta ZP_TEMP2
    jmp target_done
@ch_pinky:
    ; 4 tiles ahead of Pac-Man (with original up-direction quirk: also 4 left)
    lda pacman_dir
    jsr dir_to_vec     ; ZP_TEMP1=dx, ZP_TEMP2=dy
    lda pacman_x
    clc
    adc ZP_TEMP1
    adc ZP_TEMP1
    adc ZP_TEMP1
    adc ZP_TEMP1
    sta ZP_TEMP1
    lda pacman_y
    clc
    adc ZP_TEMP2
    adc ZP_TEMP2
    adc ZP_TEMP2
    adc ZP_TEMP2
    sta ZP_TEMP2
    ; Apply Pinky bug: if facing up, also subtract 4 from X
    lda pacman_dir
    cmp #DIR_UP
    bne @pk_done
    lda ZP_TEMP1
    sec
    sbc #4
    sta ZP_TEMP1
@pk_done:
    jmp target_done
@ch_inky:
    ; target = Pac-Man ahead by 2 tiles, vector from Blinky to that, doubled
    lda pacman_dir
    jsr dir_to_vec
    lda pacman_x
    clc
    adc ZP_TEMP1
    adc ZP_TEMP1
    sta ZP_TEMP3          ; px2
    lda pacman_y
    clc
    adc ZP_TEMP2
    adc ZP_TEMP2
    sta ZP_TEMP4          ; py2
    ; Apply Inky quirk: if Pac-Man facing up, subtract 2 from X
    lda pacman_dir
    cmp #DIR_UP
    bne @ink_ok
    lda ZP_TEMP3
    sec
    sbc #2
    sta ZP_TEMP3
@ink_ok:
    ; vector v = (px2 - blinky_x, py2 - blinky_y)
    lda ZP_TEMP3
    sec
    sbc ghost_x+GHOST_BLINKY
    asl                    ; *2
    clc
    adc ghost_x+GHOST_BLINKY
    sta ZP_TEMP1           ; target x
    lda ZP_TEMP4
    sec
    sbc ghost_y+GHOST_BLINKY
    asl
    clc
    adc ghost_y+GHOST_BLINKY
    sta ZP_TEMP2           ; target y
    jmp target_done
@ch_clyde:
    ; if distance >= 8 tiles chase else scatter corner
    lda pacman_x
    sec
    sbc ghost_x+GHOST_CLYDE
    bpl absx1
    eor #$FF
    clc
    adc #1
absx1:
    sta ZP_TEMP3           ; |dx|
    lda pacman_y
    sec
    sbc ghost_y+GHOST_CLYDE
    bpl absy1
    eor #$FF
    clc
    adc #1
absy1:
    clc
    adc ZP_TEMP3           ; manhattan distance
    cmp #8
    bcs @cly_chase
    ; else scatter (already set)
    jmp target_done
@cly_chase:
    lda pacman_x
    sta ZP_TEMP1
    lda pacman_y
    sta ZP_TEMP2
target_done:
    rts

; Choose next move for ghost X given target in ZP_TEMP1/2, updates dir and x/y
ghost_choose_move:
    ; reverse direction is dir^2
    lda ghost_dir,x
    eor #$02
    sta ZP_TEMP3          ; reverse
    ; iterate directions in priority: up,left,down,right
    ldy #0
    sty ZP_TEMP4          ; best_flag=0
    lda #DIR_UP
    sta ZP_PTR1           ; reuse as list base DIR_UP,DIR_LEFT,DIR_DOWN,DIR_RIGHT
    lda #DIR_LEFT
    sta ZP_PTR1+1
    lda #DIR_DOWN
    sta ZP_PTR2
    lda #DIR_RIGHT
    sta ZP_PTR2+1
dir_iter:
    cpy #4
    bcc continue_dir_iter
    jmp apply_best
continue_dir_iter:
    ; load candidate dir
    lda dir_table,y
    iny
    cmp ZP_TEMP3
    beq dir_iter         ; skip reverse
    ; compute next tile = (gx,gy) + vec
    pha
    jsr dir_to_vec        ; dx,dy in ZP_TEMP1/2
    pla                   ; restore dir in A
    ; check walkable for this ghost state
    lda ghost_x,x
    clc
    adc ZP_TEMP1
    sta ZP_TEMP5
    lda ghost_y,x
    clc
    adc ZP_TEMP2
    sta ZP_TEMP6
    ; Ghost red-zone rule: disallow moving UP into red-zone passages
    cmp #DIR_UP
    bne @after_redzone
    ; candidate is UP; if next tile is red-zone and not in exempt states, skip
    ldx ZP_TEMP5
    ldy ZP_TEMP6
    jsr is_redzone_xy     ; Z=1 if red-zone
    bne @after_redzone
    ; exempt states: EYES/ENTERHOUSE/LEAVEHOUSE can enter
    lda ghost_state,x
    cmp #GHOSTSTATE_EYES
    beq @after_redzone
    cmp #GHOSTSTATE_ENTERHOUSE
    beq @after_redzone
    cmp #GHOSTSTATE_LEAVEHOUSE
    beq @after_redzone
    ; otherwise skip this direction
    jmp dir_iter
@after_redzone:
    ; bounds
    lda ZP_TEMP5
    cmp #28
    bcs dir_iter
    lda ZP_TEMP6
    cmp #31
    bcs dir_iter
    ; char
    ldx ZP_TEMP5
    ldy ZP_TEMP6
    jsr maze_get_char_xy
    ; if door '-' and not eyes/enter/leave: blocked
    cmp #'-'
    bne @chk_walk
    lda ghost_state,x
    cmp #GHOSTSTATE_EYES
    beq @ok_tile
    cmp #GHOSTSTATE_ENTERHOUSE
    beq @ok_tile
    cmp #GHOSTSTATE_LEAVEHOUSE
    bne dir_iter
@ok_tile:
    ; fallthrough
@chk_walk:
    jsr is_walkable_char
    bne dir_iter         ; not walkable
    ; distance^2 = dx^2 + dy^2 using lookup table sq_table (0..31)
    ; compute |tx - nx| -> ZP_TEMP7
    lda ZP_TEMP1          ; target x
    sec
    sbc ZP_TEMP5
    bpl @absx_ok2
    eor #$FF
    clc
    adc #1
@absx_ok2:
    sta ZP_TEMP7
    ; compute |ty - ny| -> ZP_TEMP6
    lda ZP_TEMP2          ; target y
    sec
    sbc ZP_TEMP6
    bpl @absy_ok2
    eor #$FF
    clc
    adc #1
@absy_ok2:
    sta ZP_TEMP6
    ; load dx^2
    ldy ZP_TEMP7
    lda sq_table_lo,y
    sta ZP_PTR1
    lda sq_table_hi,y
    sta ZP_PTR1+1
    ; load dy^2 into ZP_PTR2
    ldy ZP_TEMP6
    lda sq_table_lo,y
    sta ZP_PTR2
    lda sq_table_hi,y
    sta ZP_PTR2+1
    ; sum = dx2 + dy2 -> ZP_TEMP1:lo, ZP_TEMP2:hi
    lda ZP_PTR1
    clc
    adc ZP_PTR2
    sta ZP_TEMP1
    lda ZP_PTR1+1
    adc ZP_PTR2+1
    sta ZP_TEMP2
    ; if best_flag==0 or this<best: store as best (compare 16-bit)
    bit ZP_TEMP4
    bmi @have_best
    lda ZP_TEMP1
    sta ZP_TEMP8          ; best_lo
    lda ZP_TEMP2
    sta ZP_TEMP9          ; best_hi
    dec ZP_TEMP4          ; set negative as flag
    ; store best dir in ZP_TEMP7 (reuse)
    lda dir_table-1,y
    sta ZP_TEMP7
    jmp dir_iter
@have_best:
    ; compare (this_hi:this_lo) with (best_hi:best_lo)
    lda ZP_TEMP2
    cmp ZP_TEMP9
    bcc update_best
    bne @to_iter
    lda ZP_TEMP1
    cmp ZP_TEMP8
    bcc update_best
@to_iter:
    jmp dir_iter
update_best:
    lda ZP_TEMP1
    sta ZP_TEMP8
    lda ZP_TEMP2
    sta ZP_TEMP9
    lda dir_table-1,y
    sta ZP_TEMP7
    jmp dir_iter
apply_best:
    bit ZP_TEMP4
    bpl @no_move
    lda ZP_TEMP7
    sta ghost_dir,x
    ; apply move
    jsr dir_to_vec
    lda ghost_x,x
    clc
    adc ZP_TEMP1
    sta ghost_x,x
    lda ghost_y,x
    clc
    adc ZP_TEMP2
    sta ghost_y,x
@no_move:
    rts

dir_table:
    .byte DIR_UP, DIR_LEFT, DIR_DOWN, DIR_RIGHT
    
    rts

update_gameover:
    ; Handle game over state
    ; Check for restart input
    jsr read_input
    lda ZP_INPUT_STATE
    and #$10  ; Check for space key
    beq @no_restart
    
    ; Restart game
    jsr game_init
    
@no_restart:
    rts

; ==============================================================================
; PLAYER UPDATE
; ==============================================================================

; update_player: Reads input, applies 7/8+freeze gating, center-turn if possible,
;                moves Pac-Man 1 pixel via tile+offset (with tunnel wrap), and
;                handles dot/pill collection at tile center. Anim advances on move.
update_player:
    ; Read input (expects ZP_INPUT_STATE bits: R=1,L=2,D=4,U=8)
    jsr read_input

    ; Authentic timing: update_movement_timing set pac_can_move based on
    ; 7/8 frame rule and freeze timers. Early out if cannot move this tick.
    lda pac_can_move
    bne @can_move
    jmp no_step
@can_move:

    ; Update wanted direction from input (buffered turn)
    lda ZP_INPUT_STATE
    and #$08
    beq @skip_want_up
    lda #DIR_UP
    sta pac_wanted_dir
@skip_want_up:
    lda ZP_INPUT_STATE
    and #$04
    beq @skip_want_down
    lda #DIR_DOWN
    sta pac_wanted_dir
@skip_want_down:
    lda ZP_INPUT_STATE
    and #$02
    beq @skip_want_left
    lda #DIR_LEFT
    sta pac_wanted_dir
@skip_want_left:
    lda ZP_INPUT_STATE
    and #$01
    beq @skip_want_right
    lda #DIR_RIGHT
    sta pac_wanted_dir
@skip_want_right:

    ; Try to turn at tile center if possible
    jsr pac_try_turn_at_center

    ; If at center and blocked ahead, don't move
    jsr pac_forward_blocked_at_center
    bne @not_blocked
    jmp @blocked
@not_blocked:

    ; Move one pixel in current direction using tile+offset
    lda pacman_dir
    cmp #DIR_LEFT
    bne @chk_mv_right
    ; moving left
    lda pac_off_x
    bne @mv_left_dec
    ; at tile boundary: check wrap at tunnel
    lda pacman_y
    cmp #17
    bne @mv_left_boundary
    lda pacman_x
    bne @mv_left_boundary
    lda #27
    sta pacman_x
    lda #7
    sta pac_off_x
    jmp @post_move
@mv_left_boundary:
    ; decrement tile and set offset to 7
    dec pacman_x
    lda #7
    sta pac_off_x
    jmp @post_move
@mv_left_dec:
    dec pac_off_x
    ; advance animation on pixel step
    inc pac_anim_phase
    jmp @post_move
@chk_mv_right:
    cmp #DIR_RIGHT
    bne @chk_mv_up
    ; moving right
    lda pac_off_x
    cmp #7
    bne @mv_right_inc
    ; at boundary: check next tile walkable
    lda #DIR_RIGHT
    tax
    jsr pac_is_dir_walkable_at_center
    beq @mv_right_step
    ; blocked: re-center offset and stop
    lda #4
    sta pac_off_x
    jmp @post_move
@mv_right_step:
    lda pacman_y
    cmp #17
    bne @mv_right_boundary
    lda pacman_x
    cmp #27
    bne @mv_right_boundary
    lda #0
    sta pacman_x
    lda #0
    sta pac_off_x
    inc pac_anim_phase
    jmp @post_move
@mv_right_boundary:
    inc pacman_x
    stz pac_off_x
    inc pac_anim_phase
    jmp @post_move
@mv_right_inc:
    inc pac_off_x
    inc pac_anim_phase
    jmp @post_move
@chk_mv_up:
    cmp #DIR_UP
    bne @mv_down
    ; moving up
    lda pac_off_y
    bne @mv_up_dec
    ; at boundary: check next tile walkable
    lda #DIR_UP
    tax
    jsr pac_is_dir_walkable_at_center
    beq @mv_up_step
    ; blocked: re-center offset and stop
    lda #4
    sta pac_off_y
    jmp @post_move
@mv_up_step:
    dec pacman_y
    lda #7
    sta pac_off_y
    inc pac_anim_phase
    jmp @post_move
@mv_up_dec:
    dec pac_off_y
    inc pac_anim_phase
    jmp @post_move
@mv_down:
    ; DIR_DOWN
    lda pac_off_y
    cmp #7
    bne @mv_down_inc
    ; at boundary: check next tile walkable
    lda #DIR_DOWN
    tax
    jsr pac_is_dir_walkable_at_center
    beq @mv_down_step
    ; blocked: re-center offset and stop
    lda #4
    sta pac_off_y
    jmp @post_move
@mv_down_step:
    inc pacman_y
    stz pac_off_y
    inc pac_anim_phase
    jmp @post_move
@mv_down_inc:
    inc pac_off_y
    inc pac_anim_phase

@post_move:
    ; Collect dot/pill only when centered on tile
    lda pac_off_x
    cmp #COLLISION_THRESH_PLUS1
    bne @done
    lda pac_off_y
    cmp #COLLISION_THRESH_PLUS1
    bne @done
    ; Collect dot/pill at new position
    ldx pacman_x
    ldy pacman_y
    jsr maze_get_char_xy
    cmp #'.'
    beq pm_eat_dot
    cmp #'P'
    beq pm_eat_pill
    bra @done

@to_blocked:
    jmp @blocked
@blocked:
    ; No movement this tick
    ; fallthrough to @done
@done:
    rts

pm_eat_dot:
    ; Decrement dots_remaining and clear tile to space
    dec dots_remaining
    inc dots_eaten
    ; Add 10 points (i.e., +1 BCD in tens place -> final printed score has a trailing zero)
    ; score_lo_bcd += 1
    sed                 ; decimal mode
    clc
    lda score_lo_bcd
    adc #1
    sta score_lo_bcd
    lda score_hi_bcd
    adc #0
    sta score_hi_bcd
    cld                 ; back to binary
    ; Pac-Man dot-eat freeze (1 tick)
    lda #PAC_DOT_FREEZE
    sta pac_freeze_timer
    jsr sfx_dot_eaten
    ; Increment global counter and per-ghost dot counters
    inc global_dot_counter
    ldx #1              ; update Pinky, Inky, Clyde (not Blinky)
@ghdc_loop:
    cpx #NUM_GHOSTS
    bcs @ghdc_done
    lda ghost_dot_counter,x
    cmp ghost_dot_limit,x
    bcs @ghdc_skip
    inc ghost_dot_counter,x
@ghdc_skip:
    inx
    bra @ghdc_loop
@ghdc_done:
    jsr maze_set_space_xy
    ; Update tilemap on screen (row offset 3)
    ldx pacman_x
    ldy pacman_y
    tya
    clc
    adc #3
    tay
    lda #TILE_SPACE
    jsr set_tile
    jmp done_move

pm_eat_pill:
    ; Clear pill, set frightened timer (not yet implemented fully)
    jsr maze_set_space_xy
    ldx pacman_x
    ldy pacman_y
    tya
    clc
    adc #3
    tay
    lda #TILE_SPACE
    jsr set_tile
    ; Start frightened period based on level table and add 50 points
    sed
    clc
    lda score_lo_bcd
    adc #5
    sta score_lo_bcd
    lda score_hi_bcd
    adc #0
    sta score_hi_bcd
    cld
    ; Pac-Man pill-eat freeze (3 ticks)
    lda #PAC_PILL_FREEZE
    sta pac_freeze_timer
    ; Start frightened period based on level table (16-bit)
    jsr get_fright_ticks_for_level  ; A=lo, X=hi of frightened ticks
    ; fr_end = tick + duration
    clc
    adc tick_lo
    sta fr_end_lo
    txa
    adc tick_hi
    sta fr_end_hi
    ; reset chain counter and blinking flag
    stz ghosts_eaten_chain
    stz fr_blink
    jsr sfx_pill_eaten
    jmp done_move

done_move:
no_step:
    rts

; ==============================================================================
; COLLISION AND GAME LOGIC
; ==============================================================================

check_game_over:
    ; Level complete?
    lda dots_remaining
    bne @alive
    ; Round won: start short timer then next round
    lda round_won_timer
    ora round_won_timer+1
    bne @tick_round_won
    lda #<(4*60)
    sta round_won_timer
    lda #>(4*60)
    sta round_won_timer+1
    rts
@tick_round_won:
    lda round_won_timer
    bne @rw_dec_lo
    dec round_won_timer+1
@rw_dec_lo:
    dec round_won_timer
    lda round_won_timer
    ora round_won_timer+1
    bne @rw_flash
    ; timer ended: restore palette and advance level
    jsr ui_roundflash_restore_palette
    jsr start_next_round
    bra @alive
@rw_flash:
    ; every 8 frames toggle maze palette blue/white
    lda tick_lo
    and #$07
    bne @alive
    jsr ui_roundflash_toggle_palette
@alive:
    rts

count_dots:
    ; Count dots in maze (placeholder - set to 244 like original)
    lda #244
    sta dots_remaining
    rts

; ==============================================================================
; RENDERING
; ==============================================================================

game_render:
    ; Compute sprite tiles for current frame
    jsr animate_sprites
    ; If death is in progress, render death frame and return
    lda game_state
    cmp #GAME_STATE_PLAYING
    beq @render_normal
    cmp #GAME_STATE_DEATH
    bne @render_normal
    jsr render_pacman_death_frame
    rts
@render_normal:
    ; Render Pac-Man sprite
    lda #SPR_PACMAN
    ldx pacman_x        ; tile X
    ldy pacman_y        ; tile Y
    ; Convert tile + offset to pixel coordinates
    txa
    asl
    asl
    asl                 ; tile_x * 8
    clc
    adc pac_off_x       ; + offset
    clc
    adc #16             ; screen X offset
    tax
    tya
    asl
    asl
    asl                 ; tile_y * 8
    clc
    adc pac_off_y       ; + offset
    clc
    adc #24             ; screen Y offset (account for top UI area)
    tay
    
    stz ZP_TEMP1        ; X high = 0
    stz ZP_TEMP2        ; Y high = 0
    jsr get_pacman_tile
    sta ZP_TEMP3
    jsr vera_set_sprite
    ; Flip Pac-Man based on direction (left=h, up=v, down=none)
    lda #SPR_PACMAN
    ldx #$00
    lda pacman_dir
    cmp #DIR_LEFT
    bne :+
    ldx #$01
    bra @pm_flip_set
:
    cmp #DIR_UP
    bne :+
    ldx #$02
    bra @pm_flip_set
:
    cmp #DIR_DOWN
    bne @pm_flip_set
    ldx #$00
@pm_flip_set:
    lda #SPR_PACMAN
    jsr vera_set_sprite_flip
    
    ; Enable Pac-Man sprite
    lda #SPR_PACMAN
    jsr vera_enable_sprite
    
    ; Render ghosts (basic positions; tiles from animate_sprites)
    ldy #0                      ; loop index
@gr_loop:
    cpy #NUM_GHOSTS
    bcc :+
    jmp done_gr
:
    ; Compute sprite number = SPR_BLINKY + index
    tya
    clc
    adc #SPR_BLINKY
    pha                         ; push sprite number (copy 1)
    pha                         ; push sprite number (copy 2)
    ; Load tile X/Y for this ghost
    lda ghost_x,y
    tax                         ; X tile -> X
    lda ghost_y,y
    tay                         ; Y tile -> Y (temporarily)
    ; Convert to pixel positions (X=tile*8+16, Y=tile*8+24)
    txa
    asl
    asl
    asl
    clc
    adc ghost_off_x,y
    clc
    adc #16
    tax                         ; X pixel -> X
    tya
    asl
    asl
    asl
    clc
    adc ghost_off_y,y
    clc
    adc #24
    tay                         ; Y pixel -> Y
    ; High bytes 0, placeholder tile index
    stz ZP_TEMP1
    stz ZP_TEMP2
    jsr get_ghost_tile   ; A=tile index for ghost Y
    sta ZP_TEMP3
    ; Set attributes
    pla                         ; A = sprite number
    jsr vera_set_sprite
    ; Set size/palette by ghost type (banks per ghost)
    ; Recompute sprite id = SPR_BLINKY + Y
    tya
    clc
    adc #SPR_BLINKY
    pha                         ; save sprite id for size/pal call
    ; If eyes/enterhouse, force eyes palette bank
    lda ghost_state,y
    cmp #GHOSTSTATE_EYES
    beq @use_eyes_pal
    cmp #GHOSTSTATE_ENTERHOUSE
    beq @use_eyes_pal
    ; else choose by ghost index
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_BLINKY)
    cpy #1
    bne :+
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_PINKY)
:
    cpy #2
    bne :+
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_INKY)
:
    cpy #3
    bne :+
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_CLYDE)
:
    pla                         ; A = sprite id
    jsr vera_set_sprite_sizepal
    bra @after_sizepal
@use_eyes_pal:
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_EYES)
    pla                         ; A = sprite id
    jsr vera_set_sprite_sizepal
@after_sizepal:
    ; Set flips based on ghost dir
    tax                         ; X temporarily = sprite number
    lda ghost_dir,y
    ldx #$00
    cmp #DIR_LEFT
    bne :+
    ldx #$01
    bra @gh_flip_set
:
    cmp #DIR_UP
    bne :+
    ldx #$02
    bra @gh_flip_set
:
    cmp #DIR_DOWN
    bne @gh_flip_set
    ldx #$00
@gh_flip_set:
    pla                         ; A = sprite number (from earlier push)
    jsr vera_set_sprite_flip
    ; Enable
    lda VERA_ADDR_LOW           ; no-op read to balance stack (comment)
    lda #0                      ; (keep code size aligned)
    lda #SPR_BLINKY             ; ensure defined symbol used
    lda #0                      ; placeholder
    ; Actually enable this specific sprite
    lda #0                      ; overwritten below
    ; recompute sprite number for enable
    tya
    clc
    adc #SPR_BLINKY
    jsr vera_enable_sprite
    iny
    jmp @gr_loop
done_gr:
    rts

; ==============================================================================
; PAC-MAN DEATH ANIMATION
; ==============================================================================

; Variables
pac_death_tick: .res 2

; Call when Pac-Man is eaten to start death sequence
start_pacman_death:
    ; enter DEATH state and freeze timers
    lda #GAME_STATE_DEATH
    sta game_state
    stz pac_death_tick
    stz pac_death_tick+1
    jsr sfx_pacman_death
    rts

; Advance death tick (call each frame in update loop when GAME_STATE_DEATH)
tick_pacman_death:
    inc pac_death_tick
    bne :+
    inc pac_death_tick+1
:
    ; After ~150 ticks, reset or game over
    lda pac_death_tick
    cmp #150
    bcc :+
    jsr reset_after_death
:
    rts

; Render the current death tile for Pac-Man
render_pacman_death_frame:
    ; Position Pac-Man as usual (reuse last pacman_x/y, offsets)
    lda #SPR_PACMAN
    ldx pacman_x
    ldy pacman_y
    txa
    asl
    asl
    asl
    clc
    adc pac_off_x
    clc
    adc #16
    tax
    tya
    asl
    asl
    asl
    clc
    adc pac_off_y
    clc
    adc #24
    tay
    stz ZP_TEMP1
    stz ZP_TEMP2
    ; Compute death tile: 52 + (tick/8), clamp to 63
    lda pac_death_tick
    lsr
    lsr
    lsr
    clc
    adc #52
    cmp #64
    bcc :+
    lda #63
:
    sta ZP_TEMP3
    ; Write sprite attributes and ensure no flips
    jsr vera_set_sprite
    lda #SPR_PACMAN
    ldx #$00
    jsr vera_set_sprite_flip
    ; Set size/palette: 16x16 with Pac-Man bank
    lda #SPR_PACMAN
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_PACMAN)
    jsr vera_set_sprite_sizepal
    lda #SPR_PACMAN
    jsr vera_enable_sprite
    rts

; Render any active popup (simple text at popup_x/popup_y) and tick timer
popup_render_tick:
    ; Tick fruit score (tilemap-based) independently of chain popup
    lda fruit_score_active
    beq @skip_fruit
    ; decrement fruit score timer
    lda fruit_score_timer
    bne :+
    dec fruit_score_timer+1
:
    dec fruit_score_timer
    lda fruit_score_timer
    ora fruit_score_timer+1
    bne @skip_fruit
    ; timeout: clear flag and erase 4 tiles back to space
    stz fruit_score_active
    ldx fruit_score_x
    ldy fruit_score_y
    lda #TILE_SPACE
    jsr set_tile
    inx
    lda #TILE_SPACE
    jsr set_tile
    inx
    lda #TILE_SPACE
    jsr set_tile
    inx
    lda #TILE_SPACE
    jsr set_tile
@skip_fruit:
    ; Handle chain popup sprite separately
    lda popup_active
    beq @no_popup
    ; decrement timer
    lda popup_timer
    bne @dec_lo
    dec popup_timer+1
@dec_lo:
    dec popup_timer
    lda popup_timer
    ora popup_timer+1
    bne @draw
    ; timeout: clear active and erase
    stz popup_active
    ; erase by disabling popup sprites (id 6 sufficient)
    lda #6
    jsr vera_disable_sprite
    ldx popup_x
    ldy popup_y
    rts
@draw:
    ; chain popup: single 16x16 score sprite (id 6). Fruit score handled elsewhere
    lda popup_chain
    beq @done
    ; convert tile coords to pixel
    ldx popup_x
    ldy popup_y
    txa
    asl
    asl
    asl
    clc
    adc #16
    tax
    tya
    asl
    asl
    asl
    clc
    adc #24
    tay
    stz ZP_TEMP1
    stz ZP_TEMP2
    ; set tile from popup_chain_tile
    lda popup_chain_tile
    sta ZP_TEMP3
    lda #6
    jsr vera_set_sprite
    lda #6
    jsr vera_enable_sprite
    lda #6
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_SCORE)
    jsr vera_set_sprite_sizepal
@done:
    rts
@no_popup:
    ; no chain popup; fallthrough

; ==============================================================================
; SPRITE ANIMATION (tiles only; colors via palette indices)
; ==============================================================================

; Sprite tile indices (must match rom_sprites layout from pacman.c)
; Pac-Man animation sequences (no flips yet)
pm_tiles_horiz:
    .byte 44, 46, 48, 46   ; right/left use this sequence
pm_tiles_vert:
    .byte 45, 47, 48, 47   ; up/down use this sequence

; Ghost body bases (2-frame per direction)
GHOST_RIGHT_BASE = 32
GHOST_DOWN_BASE  = 34
GHOST_LEFT_BASE  = 36
GHOST_UP_BASE    = 38

FRIGHT_BASE    = 28   ; tiles 28,29
EYES_RIGHT     = 32
EYES_DOWN      = 34
EYES_LEFT      = 36
EYES_UP        = 38

animate_sprites:
    ; Frightened blink: when fr_blink==1, toggle frightened ghosts' palette
    ldy #0
@anim_loop:
    cpy #NUM_GHOSTS
    bcs @anim_done
    ; Check ghost state
    lda ghost_state,y
    cmp #GHOSTSTATE_FRIGHTENED
    bne @next_ghost
    ; Compute sprite number = SPR_BLINKY + Y
    tya
    clc
    adc #SPR_BLINKY
    tax                 ; keep in X too if needed
    pha                 ; save sprite num in A on stack
    ; Set attr addr to this sprite
    pla
    jsr get_sprite_attr_addr
    ; Move to size/palette byte (offset 5)
    lda VERA_ADDR_LOW
    clc
    adc #$05
    sta VERA_ADDR_LOW
    bcc @no_carry
    inc VERA_ADDR_MID
@no_carry:
    ; Select palette via size/palette base OR frightened banks
    lda fr_blink
    beq @pal1
    lda #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_FRIGHT_BLINK)
    sta VERA_DATA0
    bra @after_write
@pal1:
    lda #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_FRIGHT)
    sta VERA_DATA0
@after_write:
    ; fallthrough to next ghost
@next_ghost:
    iny
    bra @anim_loop
@anim_done:
    ; Blink pill tiles when fr_blink set (positions: (1,6),(26,6),(1,26),(26,26))
    lda fr_blink
    beq @no_pill_blink
    ; choose color: toggle between COLOR_FRIGHTENED and COLOR_FRIGHTENED_BLINKING
    lda tick_lo
    and #$08
    beq @pill_c1
    lda #COLOR_FRIGHTENED
    bra @pill_col_apply
@pill_c1:
    lda #COLOR_FRIGHTENED_BLINKING
@pill_col_apply:
    sta ZP_TEMP1
    ; write color to the four pill tiles
    ldx #1
    ldy #6
    jsr set_tile_color
    ldx #26
    ldy #6
    jsr set_tile_color
    ldx #1
    ldy #26
    jsr set_tile_color
    ldx #26
    ldy #26
    jsr set_tile_color
@no_pill_blink:
    rts

; Move ghost X one pixel according to ghost_dir, updating tile and offset, with tunnel wrap
ghost_apply_pixel_step:
    lda ghost_dir,x
    cmp #DIR_RIGHT
    beq @right
    cmp #DIR_LEFT
    beq @left
    cmp #DIR_DOWN
    beq @down
    ; up
@up:
    lda ghost_off_y,x
    beq @up_wrap
    dec ghost_off_y,x
    inc ghost_anim,x
    rts
@up_wrap:
    lda #7
    sta ghost_off_y,x
    lda ghost_y,x
    beq @up_at_top
    dec ghost_y,x
    inc ghost_anim,x
    rts
@up_at_top:
    ; clamp at top (no wrap vertically)
    inc ghost_anim,x
    rts
@down:
    lda ghost_off_y,x
    cmp #7
    beq @down_wrap
    inc ghost_off_y,x
    inc ghost_anim,x
    rts
@down_wrap:
    stz ghost_off_y,x
    lda ghost_y,x
    cmp #30
    beq @down_at_bottom
    inc ghost_y,x
    inc ghost_anim,x
    rts
@down_at_bottom:
    ; clamp at bottom (no wrap vertically)
    inc ghost_anim,x
    rts
@right:
    lda ghost_off_x,x
    cmp #7
    beq @right_wrap
    inc ghost_off_x,x
    inc ghost_anim,x
    rts
@right_wrap:
    stz ghost_off_x,x
    lda ghost_x,x
    cmp #27
    bne @right_inc_tile
    ; at right edge: if tunnel row, wrap to left
    lda ghost_y,x
    cmp #17
    bne @right_stay
    stz ghost_x,x
    inc ghost_anim,x
    rts
@right_inc_tile:
    inc ghost_x,x
    inc ghost_anim,x
    rts
@right_stay:
    ; blocked by boundary, stay in place
    inc ghost_anim,x
    rts
@left:
    lda ghost_off_x,x
    beq @left_wrap
    dec ghost_off_x,x
    inc ghost_anim,x
    rts
@left_wrap:
    lda #7
    sta ghost_off_x,x
    lda ghost_x,x
    bne @left_dec_tile
    ; at left edge: if tunnel row, wrap to right
    lda ghost_y,x
    cmp #17
    bne @left_stay
    lda #27
    sta ghost_x,x
    inc ghost_anim,x
    rts
@left_dec_tile:
    dec ghost_x,x
    inc ghost_anim,x
    rts
@left_stay:
    ; blocked by boundary, stay in place
    inc ghost_anim,x
    rts

; Returns A = pacman tile index for current dir/phase
get_pacman_tile:
    ; phase = pac_anim_phase & 3 (advanced on movement)
    lda pac_anim_phase
    and #$03
    tay
    ; if (dir & 1)==0 => horizontal sequence, else vertical
    lda pacman_dir
    and #$01
    beq @pm_h
    ; vertical
    lda pm_tiles_vert,y
    rts
@pm_h:
    lda pm_tiles_horiz,y
    rts

; Input: ghost index in Y, Output: A = ghost tile index for current state/dir
get_ghost_tile:
    ; state check
    lda ghost_state,y
    cmp #GHOSTSTATE_EYES
    beq eyes
    cmp #GHOSTSTATE_FRIGHTENED
    beq fright
    ; normal
    lda ghost_dir,y
    tax
    lda ghost_anim,y
    and #$01
    tay
    cpx #DIR_RIGHT
    bne @gh_chk_down
    lda #GHOST_RIGHT_BASE
    sta ZP_TEMP1
    tya
    clc
    adc ZP_TEMP1
    rts
@gh_chk_down:
    cpx #DIR_DOWN
    bne @gh_chk_left
    lda #GHOST_DOWN_BASE
    sta ZP_TEMP1
    tya
    clc
    adc ZP_TEMP1
    rts
@gh_chk_left:
    cpx #DIR_LEFT
    bne @gh_up
    lda #GHOST_LEFT_BASE
    sta ZP_TEMP1
    tya
    clc
    adc ZP_TEMP1
    rts
@gh_up:
    lda #GHOST_UP_BASE
    sta ZP_TEMP1
    tya
    clc
    adc ZP_TEMP1
    rts
 eyes:
     lda ghost_dir,y
     cmp #DIR_RIGHT
     beq er
     cmp #DIR_DOWN
     beq ed
     cmp #DIR_LEFT
     beq el
     lda #EYES_UP
     rts
 er: lda #EYES_RIGHT
     rts
 ed: lda #EYES_DOWN
     rts
 el: lda #EYES_LEFT
     rts
 fright:
     lda tick_lo
     lsr
     and #$01
     tay
     lda #FRIGHT_BASE    ; 28,29
     sta ZP_TEMP1
     tya
     clc
     adc ZP_TEMP1
     rts

; ==============================================================================
; COLLISIONS
; ==============================================================================

check_collisions:
    ; Pac-Man vs ghosts using pixel-accurate proximity
    ; Compute Pac-Man pixel center into ZP_TEMP1 (X), ZP_TEMP2 (Y)
    lda pacman_x
    asl
    asl
    asl
    clc
    adc pac_off_x
    sta ZP_TEMP1
    lda pacman_y
    asl
    asl
    asl
    clc
    adc pac_off_y
    sta ZP_TEMP2
    ldx #0
cl_loop:
    cpx #NUM_GHOSTS
    bcc cl_continue
    jmp cl_done
cl_continue:
    ; Compute ghost pixel pos
    lda ghost_x,x
    asl
    asl
    asl
    clc
    adc ghost_off_x,x
    sta ZP_TEMP3          ; gx
    lda ghost_y,x
    asl
    asl
    asl
    clc
    adc ghost_off_y,x
    sta ZP_TEMP4          ; gy
    ; |dx| <= 3 ?
    lda ZP_TEMP1
    sec
    sbc ZP_TEMP3
    bpl @absx_ok
    eor #$FF
    clc
    adc #1
@absx_ok:
    cmp #4
    bcc @col_dx_ok
    jmp @to_cl_next
@col_dx_ok:
    ; |dy| <= 3 ?
    lda ZP_TEMP2
    sec
    sbc ZP_TEMP4
    bpl @absy_ok
    eor #$FF
    clc
    adc #1
@absy_ok:
    cmp #4
    bcc @col_dy_ok
    jmp @to_cl_next
@col_dy_ok:
    ; collision!
    lda ghost_state,x
    cmp #GHOSTSTATE_FRIGHTENED
    bne @pacman_dead
    ; Eat ghost: set to EYES and increment chain (capped at 3)
    lda ghosts_eaten_chain
    cmp #3
    bcc @inc_chain
    lda #3
    bne @apply_chain
@inc_chain:
    clc
    adc #1
@apply_chain:
    sta ghosts_eaten_chain
    ; Add chain score: 200,400,800,1600 (BCD tens digit add)
    sed
    lda ghosts_eaten_chain
    cmp #0
    beq @c0
    cmp #1
    beq @c1
    cmp #2
    beq @c2
    ; chain==3
    clc
    lda score_lo_bcd
    adc #$60
    sta score_lo_bcd
    lda score_hi_bcd
    adc #$01
    sta score_hi_bcd
    bra @c_done
@c2:
    clc
    lda score_lo_bcd
    adc #$80
    sta score_lo_bcd
    lda score_hi_bcd
    adc #$00
    sta score_hi_bcd
    bra @c_done
@c1:
    clc
    lda score_lo_bcd
    adc #$40
    sta score_lo_bcd
    lda score_hi_bcd
    adc #$00
    sta score_hi_bcd
    bra @c_done
@c0:
    clc
    lda score_lo_bcd
    adc #$20
    sta score_lo_bcd
    lda score_hi_bcd
    adc #$00
    sta score_hi_bcd
@c_done:
    cld
    lda #GHOSTSTATE_EYES
    sta ghost_state,x
    jsr sfx_ghost_eaten
    jmp @to_cl_next
 @pacman_dead:
    ; Start death sequence state; animation will render until reset
    jsr start_pacman_death
 @to_cl_next:
     inx
     jmp cl_loop
cl_done:
    rts

; ==============================================================================
; UI: SCORE/LIVES/FRUIT
; ==============================================================================

ui_update:
    ; Spawn fruit twice per round at dossier thresholds; use dots_eaten thresholds per level
    lda active_fruit
    bne @fruit_tick
    lda fruit_spawned_count
    cmp #2
    bcs @fruit_tick
    ; decide next threshold
    lda fruit_spawned_count
    beq @first
    ; second spawn
    jsr get_level_second_fruit_threshold
    bra @check_spawn
@first:
    jsr get_level_first_fruit_threshold
@check_spawn:
    ; A = threshold; if dots_eaten >= threshold then spawn
    cmp dots_eaten
    bcc @do_spawn
    beq @do_spawn
    bra @fruit_tick
@do_spawn:
    jsr ui_spawn_fruit
    inc fruit_spawned_count
@fruit_tick:
    ; Tick fruit timer if active and hide when expired
    lda active_fruit
    beq ui_done
    lda fruit_timer
    ora fruit_timer+1
    beq ui_done
    lda fruit_timer
    bne @dec_lo
    dec fruit_timer+1
@dec_lo:
    dec fruit_timer
    lda fruit_timer
    ora fruit_timer+1
    bne ui_done
    ; timeout -> hide fruit
    lda #FRUIT_NONE
    sta active_fruit
    lda #SPR_FRUIT
    jsr vera_disable_sprite
    ; Fruit pickup: Pac-Man on fruit tile while active
    lda active_fruit
    beq @after_fruit_pick
    lda pacman_x
    cmp #FRUIT_X
    bne @after_fruit_pick
    lda pacman_y
    cmp #FRUIT_Y
    bne @after_fruit_pick
    ; Add fruit score and push to status row
    jsr add_active_fruit_score
    jsr status_fruits_push
    ; Fruit SFX
    jsr sfx_fruit_pick
    ; Hide fruit
    lda #FRUIT_NONE
    sta active_fruit
    lda #SPR_FRUIT
    jsr vera_disable_sprite
@after_fruit_pick:
    ; Fruit popup (3 or 4 digits) near fruit position
    jsr popup_show_fruit
    ; Redraw scores and status fruits
    jsr update_score_digits
    jsr update_hiscore_if_needed
    jsr maybe_award_extra_life
    ; player 1 score
    ldx #8
    ldy #2
    jsr draw_score_xy
    ; hiscore mirror (placeholder)
    ldx #20
    ldy #2
    jsr draw_score_xy
    ; status fruits
    jsr draw_status_fruits
ui_done:
    rts

; ==============================================================================
; ROUND-WON MAP FLASH (palette toggle between blue/white walls)
; ==============================================================================

; Toggle a couple of palette entries used by walls between blue and white
ui_roundflash_toggle_palette:
    ; Example: swap palette entries 1 (blue) and 15 (white) as a simple effect
    lda #1
    ldx #15
    jsr vera_swap_palette_color
    rts

; Restore palette to normal (ensure wall blue and white are correct order)
ui_roundflash_restore_palette:
    ; Call toggle if needed to make an even number of swaps; here we force reset by writing known values
    ; No-op placeholder: in real implementation, cache and restore exact colors
    rts

; READY text helpers (freeze logic in update_playing)
ui_draw_ready:
    ; Draw READY! at READY_X, READY_Y
    ldx #READY_X
    ldy #READY_Y
    lda #'R'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'E'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'A'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'D'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'Y'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda '!'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    rts

; Draw GAME OVER centered (simple single-line), and set state
ui_draw_game_over:
    ldx #10
    ldy #20
    lda #'G'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'A'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'M'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'E'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #' '
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'O'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'V'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'E'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'R'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    lda #GAME_STATE_GAMEOVER
    sta game_state
    ; start game-over hold timer (~3s)
    lda #<(3*60)
    sta game_over_timer
    lda #>(3*60)
    sta game_over_timer+1
    rts

ui_clear_ready:
    ldx #READY_X
    ldy #READY_Y
    lda #' '
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    sta ZP_TEMP1
    jsr vid_color_char_xy
    inx
    sta ZP_TEMP1
    jsr vid_color_char_xy
    inx
    sta ZP_TEMP1
    jsr vid_color_char_xy
    inx
    sta ZP_TEMP1
    jsr vid_color_char_xy
    inx
    sta ZP_TEMP1
    jsr vid_color_char_xy
    rts

ui_tick_ready:
    lda ready_timer_lo
    ora ready_timer_hi
    beq @done
    lda ready_timer_lo
    bne @dec_lo
    dec ready_timer_hi
@dec_lo:
    dec ready_timer_lo
    lda ready_timer_lo
    ora ready_timer_hi
    bne @done
    ; timer ended: clear READY
    jsr ui_clear_ready
@done:
    rts

ui_spawn_fruit:
    ; Determine fruit type by level
    jsr get_level_fruit
    sta active_fruit
    ; Position sprite at FRUIT_X/FRUIT_Y
    lda #SPR_FRUIT
    ldx #FRUIT_X
    ldy #FRUIT_Y
    txa
    asl
    asl
    asl
    clc
    adc #16
    tax
    tya
    asl
    asl
    asl
    clc
    adc #24
    tay
    stz ZP_TEMP1
    stz ZP_TEMP2
    ; Select 16x16 fruit sprite tile based on active_fruit (1..8)
    lda active_fruit
    beq :+
    tax
    dex
    lda fruit_sprite_tile_tbl,x
    sta ZP_TEMP3
:   
    jsr vera_set_sprite
    lda #SPR_FRUIT
    jsr vera_enable_sprite
    ; Set size/palette for fruit sprite
    lda #SPR_FRUIT
    ldx #(NAMCO_SIZEPAL_16x16_BASE | NAMCO_PAL_SPR_FRUIT)
    jsr vera_set_sprite_sizepal
    ; Set fruit timer (10 seconds)
    lda #<(10*60)
    sta fruit_timer
    lda #>(10*60)
    sta fruit_timer+1
    rts

; Table mapping fruit id (1..8) to 16x16 sprite tile
fruit_sprite_tile_tbl:
    .byte NAMCO_SPRITETILE_CHERRIES
    .byte NAMCO_SPRITETILE_STRAWBERRY
    .byte NAMCO_SPRITETILE_PEACH
    .byte NAMCO_SPRITETILE_APPLE
    .byte NAMCO_SPRITETILE_GRAPES
    .byte NAMCO_SPRITETILE_GALAXIAN
    .byte NAMCO_SPRITETILE_BELL
    .byte NAMCO_SPRITETILE_KEY

; Fruit spawn thresholds per level (dots eaten): first and second
get_level_first_fruit_threshold:
    ; L1: 70, L2: 70, L3+: 70 per dossier (simplified)
    lda #70
    rts
get_level_second_fruit_threshold:
    ; L1: 170, L2+: 170
    lda #170
    rts

; Push collected fruit into status row buffer (keeps last 7, rightmost newest)
status_fruits_push:
    lda status_fruits_count
    cmp #7
    bcc @sf_room
    ; shift left to drop oldest
    ldx #0
@sf_shift:
    lda status_fruits+1,x
    sta status_fruits,x
    inx
    cpx #6
    bne @sf_shift
    lda #6
    sta status_fruits_count
@sf_room:
    lda status_fruits_count
    tax
    cpx #7
    bcs @sf_set
    inc status_fruits_count
@sf_set:
    ; write at last slot
    lda active_fruit
    sta status_fruits+6
    rts

; Draw status fruits row (bottom-right), mapping fruit id to tile codes/colors (placeholder)
draw_status_fruits:
    ; Draw up to 7 fruits, rightmost most recent
    ldy #34          ; row near bottom
    lda #31
    sta ZP_TEMP1     ; x cursor
    ldx #0
@dsf_loop:
    cpx status_fruits_count
    bcs @dsf_done
    ; read from newest backwards: index = status_fruits_count-1 - X
    lda status_fruits_count
    sec
    sbc #1
    sec
    stx ZP_TEMP1
    sbc ZP_TEMP1
    tay
    lda status_fruits,y
    beq @dsf_advance
    ; map fruit id to tile/color and draw
    tax
    lda fruit_tile_by_id,x
    pha
    lda fruit_color_by_id,x
    sta ZP_TEMP3
    pla
    ; place at (ZP_TEMP1, row 34)
    ldx ZP_TEMP1
    ldy #34
    jsr set_tile_color
@dsf_advance:
    dec ZP_TEMP1
    inx
    bra @dsf_loop
@dsf_done:
    rts

; returns A = fruit id for current level
get_level_fruit:
    lda level
    beq @l1
    cmp #8
    bcc @in
    lda #8
@in:
    tax
    dex
    lda fruit_by_level,x
    rts
@l1:
    lda #FRUIT_CHERRIES
    rts

fruit_by_level:
    .byte FRUIT_CHERRIES, FRUIT_STRAWBERRY, FRUIT_PEACH, FRUIT_PEACH
    .byte FRUIT_APPLE, FRUIT_APPLE, FRUIT_GRAPES, FRUIT_GRAPES

; Initial UI draw (once per round)
ui_draw_init:
    ; Clear top UI row (row 0..2 kept for UI)
    ldx #0
    ldy #0
@ui_clear:
    lda #TILE_SPACE
    jsr set_tile
    inx
    cpx #32
    bne @ui_clear
    ; Draw headings "1UP   HIGH SCORE   2UP"
    ; 1UP at (3,0)
    ldx #3
    ldy #0
    lda #'1'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'U'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'P'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    ; HIGH SCORE at (9,0)
    ldx #9
    ldy #0
    jsr ui_put_text_highscore
    ; 2UP at (23,0)
    ldx #23
    ldy #0
    lda #'2'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'U'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'P'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    ; Draw initial scores (right-to-left) and lives
    jsr update_score_digits
    ; If 2 players, indicate active player below the 1UP/2UP headers
    lda num_players
    cmp #2
    bne @skip_active_up
    lda current_player
    beq @mark_p1
    ; mark 2UP (a small dot under 2UP)
    ldx #24
    ldy #1
    lda #'*'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    bra @skip_active_up
@mark_p1:
    ; mark 1UP
    ldx #4
    ldy #1
    lda #'*'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
@skip_active_up:
    ; player 1 score at (8,2) approx; adjust as needed to match layout
    ldx #8
    ldy #2
    jsr draw_score_xy
    ; hiscore at (20,2)
    ldx #20
    ldy #2
    jsr draw_score_xy
    jsr ui_draw_lives
    rts

; Draw lives icons at bottom-left based on lives_left
ui_draw_lives:
    ldy #34
    ldx #2
    lsa_tmp = ZP_TEMP3
    lda lives_left
    sta lsa_tmp
@lives_loop:
    lda lsa_tmp
    beq @lives_done
    ; Draw life icon tile (use TILE_LIFE if available, else 'C')
    lda #'C'
    sta ZP_TEMP1
    lda #COLOR_PACMAN
    jsr vid_color_char_xy
    inx
    dec lsa_tmp
    bra @lives_loop
@lives_done:
    rts

ui_put_text_highscore:
    ; writes "HIGH SCORE" starting at (X,Y)
    lda #'H'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'I'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'G'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'H'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #' '
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'S'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'C'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'O'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'R'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'E'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    rts

; ----------------------------------------------------------------------------
; Score and text rendering helpers (matches NAMCO-ish char mapping)
; ----------------------------------------------------------------------------

; Minimal conv_char: maps ASCII to tile codes used in pacman.c
conv_char:
    cmp #' '
    bne @c1
    lda #NAMCO_TILE_SPACE
    rts
@c1:
    cmp #'/'
    bne @c2
    lda #NAMCO_TILE_SLASH
    rts
@c2:
    cmp #'-'
    bne @c3
    lda #NAMCO_TILE_DASH
    rts
@c3:
    cmp #'"'
    bne @c4
    lda #NAMCO_TILE_DQUOTE
    rts
@c4:
    cmp #'!'
    bne conv_done
    lda #NAMCO_TILE_EXCL
conv_done:
    rts

; put colored char at X,Y (tile coords) with color in A
; Inputs: X in X, Y in Y, char in ZP_TEMP1, color in A
vid_color_char_xy:
    pha
    lda ZP_TEMP1
    jsr conv_char
    jsr push_tile_code   ; A=tile code pushed into set_tile flow
    pla
    jsr push_color_code
    jsr set_tile
    rts

; Helper to load tile code into A path for set_tile
push_tile_code:
    ; Expects tile code in A, leaves in A
    rts

; Helper to load color code into A path for set_tile (override default color)
push_color_code:
    ; For now, we rely on set_tile's default color; extend set_tile for color override if needed
    rts

; Draw numeric score (7 digits + trailing zero implicit) at tile position (X,Y)
; Uses score_digits[] array of ASCII digits '0'..'9'
draw_score_xy:
    ; Render right-to-left with trailing zero at rightmost cell
    phy
    phx
    ; place trailing zero at (X,Y)
    lda #'0'
    sta ZP_TEMP1
    lda #$0F
    jsr vid_color_char_xy
    ; now render 7 digits to the left
    dex
    ldy #0
@ds_loop:
    cpy #7
    bcs @ds_done
    lda score_digits,y
    sta ZP_TEMP1
    lda #$0F        ; white
    jsr vid_color_char_xy
    dex
    iny
    bra @ds_loop
@ds_done:
    plx
    ply
    rts

; Update score digits from BCD bytes score_hi_bcd:score_lo_bcd and add trailing zero
update_score_digits:
    ; Convert BCD score bytes (score_hi_bcd:score_lo_bcd) to 7 ASCII digits (right-to-left)
    ; Here we only have 2 BCD bytes; extend when full score implemented
    ldx #0
    ; Low BCD
    lda score_lo_bcd
    ; low nibble
    and #$0F
    clc
    adc #'0'
    sta score_digits,x
    inx
    ; high nibble
    lda score_lo_bcd
    lsr
    lsr
    lsr
    lsr
    and #$0F
    clc
    adc #'0'
    sta score_digits,x
    inx
    ; High BCD
    lda score_hi_bcd
    and #$0F
    clc
    adc #'0'
    sta score_digits,x
    inx
    lda score_hi_bcd
    lsr
    lsr
    lsr
    lsr
    and #$0F
    clc
    adc #'0'
    sta score_digits,x
    inx
    ; Fill remaining with '0'
@usd_fill:
    cpx #7
    bcs @usd_done
    lda #'0'
    sta score_digits,x
    inx
    bra @usd_fill
@usd_done:
    rts

; Switch current player (2P alternating scaffold): swap score/lives buffers
switch_player:
    lda num_players
    cmp #2
    bne @done
    lda current_player
    eor #1
    sta current_player
    beq @to_p0
@to_p1:
    ; Save P0 from globals
    lda score_lo_bcd
    sta p0_score_lo_bcd
    lda score_hi_bcd
    sta p0_score_hi_bcd
    lda lives_left
    sta p0_lives_left
    ; Load P1
    lda p1_score_lo_bcd
    sta score_lo_bcd
    lda p1_score_hi_bcd
    sta score_hi_bcd
    lda p1_lives_left
    sta lives_left
    bra @upd
@to_p0:
    ; Save P1 from globals
    lda score_lo_bcd
    sta p1_score_lo_bcd
    lda score_hi_bcd
    sta p1_score_hi_bcd
    lda lives_left
    sta p1_lives_left
    ; Load P0
    lda p0_score_lo_bcd
    sta score_lo_bcd
    lda p0_score_hi_bcd
    sta score_hi_bcd
    lda p0_lives_left
    sta lives_left
@upd:
    jsr update_score_digits
    jsr ui_draw_lives
@done:
    rts

; Award extra life at 10,000 once per game
maybe_award_extra_life:
    lda extra_life_awarded
    bne @done
    ; DIP: bonus at 10K toggle
    .if DIP_BONUS_AT_10K
    ; Check BCD score >= 10,000 using our 2-byte BCD with implicit trailing zero
    ; 10,000 decimal => 1000 in our two BCD bytes (hi>= DIP_BONUS_BCD_HI)
    lda score_hi_bcd
    cmp #DIP_BONUS_BCD_HI
    bcc @done
    ; grant extra life
    inc lives_left
    lda #1
    sta extra_life_awarded
    ; Update lives UI immediately
    jsr ui_draw_lives
    .endif
@done:
    rts



; ==============================================================================
; LEVEL TABLE (fruit + frightened duration)
; ==============================================================================

; For now store only frightened duration per round (seconds -> ticks)
; Rounds 1..N mapped per original reference (simplified subset)
level_fright_ticks:
    .word 6*60   ; R1
    .word 5*60   ; R2
    .word 4*60   ; R3
    .word 3*60   ; R4
    .word 2*60   ; R5
    .word 5*60   ; R6
    .word 2*60   ; R7
    .word 2*60   ; R8
    .word 1*60   ; R9
    .word 5*60   ; R10
    .word 2*60   ; R11
    .word 1*60   ; R12
    .word 0      ; R13+ no frightened

get_fright_ticks_for_level:
    ; return A=lo, X=hi of frightened duration in ticks for current level
    lda level
    beq @r1
    cmp #13
    bcc @in_range
    lda #13
@in_range:
    tay                 ; Y = level (1..13)
    dey                 ; to 0-based index
    ; compute address = &level_fright_ticks + Y*2
    lda #<level_fright_ticks
    sta ZP_PTR1
    lda #>level_fright_ticks
    sta ZP_PTR1+1
    tya
    asl                 ; *2
    tay
    lda (ZP_PTR1),y     ; low byte
    tax                 ; temporarily store low in X
    iny
    lda (ZP_PTR1),y     ; high byte
    tay                 ; Y=hi
    txa                 ; A=lo
    tya                 ; restore hi to A? no, we want X=hi
    tax                 ; X=hi
    rts
@r1:
    lda #1
    tay
    dey
    ; reuse path
    lda #<level_fright_ticks
    sta ZP_PTR1
    lda #>level_fright_ticks
    sta ZP_PTR1+1
    tya
    asl
    tay
    lda (ZP_PTR1),y
    tax
    iny
    lda (ZP_PTR1),y
    tay
    txa
    tax
    rts


; Apply ghost house dot limits (per level) for Inky and Clyde (Pinky timer-based)
apply_ghost_dot_limits_for_level:
    ; Defaults
    lda #30
    sta ghost_dot_limit+GHOST_INKY
    lda #60
    sta ghost_dot_limit+GHOST_CLYDE
    ; Level 1 exceptions: placeholder tweak (Inky 0, Clyde 0)
    lda level
    cmp #1
    bne @done
    stz ghost_dot_limit+GHOST_INKY
    stz ghost_dot_limit+GHOST_CLYDE
@done:
    rts


; ==============================================================================
; UTILITY FUNCTIONS
; ==============================================================================

clear_screen:
    ; Clear the tilemap to show empty tiles
    VERA_SET_ADDR VRAM_TILEMAP, 1
    
    ldx #0
    ldy #0
@clear_loop:
    lda #TILE_SPACE     ; Use space tile
    sta VERA_DATA0      ; Write tile
    lda #$0F            ; White color
    sta VERA_DATA0      ; Write color
    inx
    cpx #32
    bne @clear_loop
    ldx #0
    iny
    cpy #32
    bne @clear_loop
    
    rts

; Start next round: increment level, reset maze/dots, positions, READY timer
start_next_round:
    inc level
    ; Reset dots and UI
    jsr clear_screen
    jsr draw_pacman_maze
    jsr ui_draw_init
    ; 2P alternating: hand off at end of round when two players
    lda num_players
    cmp #2
    bne :+
    jsr switch_player
:
    ; Positions and offsets
    lda #14
    sta pacman_x
    lda #26
    sta pacman_y
    lda #4
    sta pac_off_x
    sta pac_off_y
    lda #DIR_LEFT
    sta pacman_dir
    sta pac_wanted_dir
    ; Reset counters
    jsr count_dots
    stz dots_eaten
    stz global_dot_counter
    lda #1
    sta global_dot_active
    stz active_fruit
    stz fruit_timer
    stz fruit_timer+1
    ; READY timer ~2s
    lda #<(120)
    sta ready_timer_lo
    lda #>(120)
    sta ready_timer_hi
    jsr ui_draw_ready
    rts

; Reset after death: decrement life, handle game over or reset positions/timers
reset_after_death:
    lda lives_left
    beq @game_over
    dec lives_left
    ; If no lives left after decrement, game over
    lda lives_left
    beq @game_over
    ; Reset positions in current level
    ; Pac-Man
    lda #14
    sta pacman_x
    lda #26
    sta pacman_y
    lda #4
    sta pac_off_x
    sta pac_off_y
    lda #DIR_LEFT
    sta pacman_dir
    sta pac_wanted_dir
    ; Ghosts
    jsr ghosts_init
    ; READY timer
    lda #<(120)
    sta ready_timer_lo
    lda #>(120)
    sta ready_timer_hi
    jsr ui_draw_ready
    ; 2P alternating: if two players and current player died, hand off turn
    lda num_players
    cmp #2
    bne :+
    jsr switch_player
:
    rts
@game_over:
    jsr ui_draw_game_over
    rts

read_input:
    ; Read joystick/keyboard-joystick and store in ZP_INPUT_STATE
    ; Bit mapping for ZP_INPUT_STATE: R=1, L=2, D=4, U=8, START=16
    ; Uses KERNAL joystick APIs: $FF53 joystick_scan, $FF56 joystick_get
    stz ZP_INPUT_STATE

    ; Ensure joystick states are up to date (safe even with default IRQ handler)
    jsr $FF53                 ; joystick_scan

    ; Read keyboard joystick (0) and map to our input bits
    lda #0
    jsr $FF56                 ; joystick_get(0) → A=buttons (active-low), Y=present ($00)
    cpy #$FF                  ; if not present, skip mapping
    beq @skip_kbdjoy
    sta ZP_TEMP1              ; preserve A (button bits)
    ; RIGHT
    lda ZP_TEMP1
    and #$01
    bne @skip_r0
    lda ZP_INPUT_STATE
    ora #$01
    sta ZP_INPUT_STATE
@skip_r0:
    ; LEFT
    lda ZP_TEMP1
    and #$02
    bne @skip_l0
    lda ZP_INPUT_STATE
    ora #$02
    sta ZP_INPUT_STATE
@skip_l0:
    ; DOWN
    lda ZP_TEMP1
    and #$04
    bne @skip_d0
    lda ZP_INPUT_STATE
    ora #$04
    sta ZP_INPUT_STATE
@skip_d0:
    ; UP
    lda ZP_TEMP1
    and #$08
    bne @skip_u0
    lda ZP_INPUT_STATE
    ora #$08
    sta ZP_INPUT_STATE
@skip_u0:
    ; START
    lda ZP_TEMP1
    and #$10
    bne @skip_s0
    lda ZP_INPUT_STATE
    ora #$10
    sta ZP_INPUT_STATE
@skip_s0:
@skip_kbdjoy:

    ; Optionally read physical joystick #1 and OR in directions/start
    lda #1
    jsr $FF56                 ; joystick_get(1)
    cpy #$FF
    beq @done
    sta ZP_TEMP1
    ; RIGHT
    lda ZP_TEMP1
    and #$01
    bne @skip_r1
    lda ZP_INPUT_STATE
    ora #$01
    sta ZP_INPUT_STATE
@skip_r1:
    ; LEFT
    lda ZP_TEMP1
    and #$02
    bne @skip_l1
    lda ZP_INPUT_STATE
    ora #$02
    sta ZP_INPUT_STATE
@skip_l1:
    ; DOWN
    lda ZP_TEMP1
    and #$04
    bne @skip_d1
    lda ZP_INPUT_STATE
    ora #$04
    sta ZP_INPUT_STATE
@skip_d1:
    ; UP
    lda ZP_TEMP1
    and #$08
    bne @skip_u1
    lda ZP_INPUT_STATE
    ora #$08
    sta ZP_INPUT_STATE
@skip_u1:
    ; START
    lda ZP_TEMP1
    and #$10
    bne @done
    lda ZP_INPUT_STATE
    ora #$10
    sta ZP_INPUT_STATE

@done:
    rts

; ==============================================================================
; STARTUP SELF TEST (optional, cosmetic)
; ==============================================================================

maybe_run_self_test:
.ifdef ENABLE_SELF_TEST
    jsr self_test
.endif
    rts

self_test:
    ; Simple show: clear screen, print "SELF TEST" and "OK", wait ~1s
    jsr clear_screen
    ; "SELF TEST" at (10, 14)
    ldx #10
    ldy #14
    lda #COLOR_DEFAULT
    lda #'S'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'E'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'L'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'F'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #' '
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'T'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'E'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'S'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'T'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    ; "OK" at (14, 16)
    ldx #14
    ldy #16
    lda #'O'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    inx
    lda #'K'
    sta ZP_TEMP1
    lda #COLOR_DEFAULT
    jsr vid_color_char_xy
    ; Wait ~60 frames
    ldx #60
@st_wait:
    jsr x16_wait_vsync
    dex
    bne @st_wait
    rts

; ==============================================================================
; MAZE HELPERS
; ==============================================================================

; Get char at maze (X in X, Y in Y) -> A
maze_get_char_xy:
    ; Build pointer to row Y
    lda #<maze_data
    sta ZP_PTR1
    lda #>maze_data
    sta ZP_PTR1+1
    tya
    beq maze_get_row_ready
maze_get_row_loop:
    clc
    lda ZP_PTR1
    adc #28
    sta ZP_PTR1
    bcc maze_get_no_c
    inc ZP_PTR1+1
maze_get_no_c:
    dey
    bne maze_get_row_loop
maze_get_row_ready:
    txa
    tay
    lda (ZP_PTR1),y
    rts

; Set maze at (X in X, Y in Y) to space ' '
maze_set_space_xy:
    lda #<maze_data
    sta ZP_PTR1
    lda #>maze_data
    sta ZP_PTR1+1
    tya
    beq maze_set_row_ready
maze_set_row_loop:
    clc
    lda ZP_PTR1
    adc #28
    sta ZP_PTR1
    bcc maze_set_no_c2
    inc ZP_PTR1+1
maze_set_no_c2:
    dey
    bne maze_set_row_loop
maze_set_row_ready:
    txa
    tay
    lda #' '
    sta (ZP_PTR1),y
    rts

; AUTHENTIC PIXEL-LEVEL MOVEMENT FUNCTIONS
; Based on pacman.c reference implementation
; ==============================================================================

; Attempt a buffered turn exactly at tile center if the wanted direction is valid.
; Uses pac_wanted_dir and pacman_dir; reads current tile and offsets.
; If a turn is performed, it snaps to the tile center to avoid corner cut.
pac_try_turn_at_center:
    ; Only allow turn when both offsets == 4 (center)
    lda pac_off_x
    cmp #4
    bne @no_center
    lda pac_off_y
    cmp #4
    bne @no_center
    ; center: check wanted vs current
    lda pac_wanted_dir
    beq @done
    cmp pacman_dir
    beq @done
    ; check if tile ahead in wanted_dir is walkable
    tax                     ; X = wanted_dir
    jsr pac_is_dir_walkable_at_center
    beq @do_turn           ; Z=1 -> walkable
    bra @done
@do_turn:
    ; set new dir and keep position centered
    lda pac_wanted_dir
    sta pacman_dir
    ; ensure we are exactly centered
    lda #4
    sta pac_off_x
    sta pac_off_y
    bra @done
@no_center:
@done:
    rts

; Check if forward move in current dir is blocked when at tile center.
; Returns Z=1 if blocked, Z=0 if free (A result used as boolean).
pac_forward_blocked_at_center:
    ; only consider when at exact center
    lda pac_off_x
    cmp #4
    bne @free
    lda pac_off_y
    cmp #4
    bne @free
    ; center: test next tile in current dir
    lda pacman_dir
    tax
    jsr pac_is_dir_walkable_at_center
    beq @free              ; walkable -> not blocked
    lda #$00
    rts                    ; blocked -> return 0, Z=1
@free:
    lda #$FF
    rts

; Helper: given direction in X, check if tile one step ahead from current
; pixel position is walkable. Returns Z=1 if walkable.
pac_is_dir_walkable_at_center:
    ; current tile is pacman_x/pacman_y; build next tile from dir
    ; Forbid UP from red-zone
    txa
    cmp #DIR_UP
    bne @dir_ok
    ldx pacman_x
    ldy pacman_y
    jsr is_redzone_xy
    beq @blocked
@dir_ok:
    lda pacman_x
    sta ZP_TEMP5               ; nx
    lda pacman_y
    sta ZP_TEMP6               ; ny
    txa                        ; A=dir
    jsr dir_to_vec             ; ZP_TEMP1=dx, ZP_TEMP2=dy
    lda ZP_TEMP5
    clc
    adc ZP_TEMP1
    tax                        ; X = nx + dx
    lda ZP_TEMP6
    clc
    adc ZP_TEMP2
    tay                        ; Y = ny + dy
    ; Tunnel wrap allowance: if at tunnel row and X wraps beyond [0..27], treat as walkable
    tya
    cmp #17
    bne @chk_bounds
    cpx #28
    bcs @tunnel_ok            ; X >= 28 or X == 255 (from -1) -> treat as walkable
@chk_bounds:
    cpx #28
    bcs @blocked              ; out of bounds (non-tunnel)
    jsr maze_get_char_xy
    jmp is_walkable_char
@tunnel_ok:
    lda #$00                  ; zero -> Z=1
    rts
@blocked:
    lda #$FF                  ; non-zero -> Z=0
    rts
; Convert pixel position to tile position
; Input: X = pixel_x, Y = pixel_y
; Output: X = tile_x, Y = tile_y
pixel_to_tile_pos:
    txa
    lsr
    lsr
    lsr
    tax
    tya
    lsr
    lsr
    lsr
    tay
    rts

; Compute distance from pixel position to tile midpoint
; Input: X = pixel_x, Y = pixel_y
; Output: ZP_TEMP1 = dist_mid_x, ZP_TEMP2 = dist_mid_y
dist_to_tile_mid:
    ; dist_mid_x = 4 - (pixel_x % 8)
    txa
    and #7             ; pixel_x % 8
    sta ZP_TEMP3
    lda #TILE_MID_X
    sec
    sbc ZP_TEMP3
    sta ZP_TEMP1
    ; dist_mid_y = 4 - (pixel_y % 8) 
    tya
    and #7             ; pixel_y % 8
    sta ZP_TEMP3
    lda #TILE_MID_Y
    sec
    sbc ZP_TEMP3
    sta ZP_TEMP2
    rts

; Check if (tile_x in X, tile_y in Y) is inside the teleport tunnel.
; Returns Z=1 (A=0) if in tunnel, else Z=0 (A=$FF)
is_tunnel_xy:
    ; tunnel row is Y==17
    tya
    cmp #17
    bne not_tunnel
    txa
    cmp #6
    bcc in_tunnel      ; X <= 5
    cmp #22
    bcc not_tunnel     ; 6..21 -> not tunnel
in_tunnel:
    lda #$00
    rts
not_tunnel:
    lda #$FF
    rts

; Check if (tile_x in X, tile_y in Y) is inside the ghost-house red zone.
; Returns Z=1 (A=0) if in red zone, else Z=0 (A=$FF)
is_redzone_xy:
    txa
    cmp #11
    bcc @rz_no
    cmp #17
    bcs @rz_no
    tya
    cmp #14
    beq @rz_yes
    cmp #26
    bne @rz_no
@rz_yes:
    lda #$00
    rts
@rz_no:
    lda #$FF
    rts
; Check if char in A is walkable for Pac-Man; returns Z=1 if walkable
; Doors ('-') are blocked for Pac-Man (only ghosts in certain states can pass)
is_walkable_char:
    cmp #' '
    beq @walkable
    cmp #'.'
    beq @walkable
    cmp #'P'
    beq @walkable
    cmp #'-'                ; Door character
    beq @blocked            ; Doors are blocked for Pac-Man
    ; All other characters (walls, etc.) are blocked
@blocked:
    lda #$FF                ; non-zero -> Z=0 (blocked)
    rts
@walkable:
    lda #$00                ; zero -> Z=1 (walkable)
    rts

; ==============================================================================
; MAZE DATA - AUTHENTIC PAC-MAN LAYOUT
; ==============================================================================
; This is the exact maze from the original Pac-Man arcade machine
; Converted from the ASCII representation in the reference code

maze_data:
    ; Row 3 (top border)
    .byte "0UUUUUUUUUUUU45UUUUUUUUUUUU1"
    ; Row 4
    .byte "L............rl............R"
    ; Row 5
    .byte "L.ebbf.ebbbf.rl.ebbbf.ebbf.R"
    ; Row 6
    .byte "LPr  l.r   l.rl.r   l.r  lPR"
    ; Row 7
    .byte "L.guuh.guuuh.gh.guuuh.guuh.R"
    ; Row 8
    .byte "L..........................R"
    ; Row 9
    .byte "L.ebbf.ef.ebbbbbbf.ef.ebbf.R"
    ; Row 10
    .byte "L.guuh.rl.guuyxuuh.rl.guuh.R"
    ; Row 11
    .byte "L......rl....rl....rl......R"
    ; Row 12
    .byte "2BBBBf.rzbbf rl ebbwl.eBBBB3"
    ; Row 13
    .byte "     L.rxuuh gh guuyl.R     "
    ; Row 14
    .byte "     L.rl          rl.R     "
    ; Row 15
    .byte "     L.rl mjs--tjn rl.R     "
    ; Row 16
    .byte "UUUUUh.gh i      q gh.gUUUUU"
    ; Row 17
    .byte "      .   i      q   .      "
    ; Row 18
    .byte "BBBBBf.ef i      q ef.eBBBBB"
    ; Row 19
    .byte "     L.rl okkkkkkp rl.R     "
    ; Row 20
    .byte "     L.rl          rl.R     "
    ; Row 21
    .byte "     L.rl ebbbbbbf rl.R     "
    ; Row 22
    .byte "0UUUUh.gh guuyxuuh gh.gUUUU1"
    ; Row 23
    .byte "L............rl............R"
    ; Row 24
    .byte "L.ebbf.ebbbf.rl.ebbbf.ebbf.R"
    ; Row 25
    .byte "L.guyl.guuuh.gh.guuuh.rxuh.R"
    ; Row 26
    .byte "LP..rl.......  .......rl..PR"
    ; Row 27
    .byte "6bf.rl.ef.ebbbbbbf.ef.rl.eb8"
    ; Row 28
    .byte "7uh.gh.rl.guuyxuuh.rl.gh.gu9"
    ; Row 29
    .byte "L......rl....rl....rl......R"
    ; Row 30
    .byte "L.ebbbbwzbbf.rl.ebbwzbbbbf.R"
    ; Row 31
    .byte "L.guuuuuuuuh.gh.guuuuuuuuh.R"
    ; Row 32
    .byte "L..........................R"
    ; Row 33 (bottom border)
    .byte "2BBBBBBBBBBBBBBBBBBBBBBBBBB3"

; Include the data file for sprites and tiles
.include "pacman_data.asm"

; Per-level speed masks (mask is ANDed with tick_lo, move when result != 0)
; Indices: level 1..13 mapped to 0..12
pac_speed_mask_normal_by_level:
    ; Dossier-aligned approximation:
    ; L1 ~80% -> 7/8, L2-4 ~90% -> 15/16, L5-12 ~100% -> ~always ($FF), L13+ ~90% -> 15/16
    .byte $07,$0F,$0F,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0F
pac_speed_mask_tunnel_by_level:
    ; Pac-Man is unaffected by tunnels per dossier; use normal masks
    .byte $07,$0F,$0F,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0F
ghost_speed_mask_normal_by_level:
    ; L1 ~75% -> 3/4, L2-4 ~85% -> 7/8, L5-12 ~95% -> 31/32, L13+ ~95% -> 31/32
    .byte $03,$07,$07,$07,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F

; Ghost per-level masks for special states
ghost_speed_mask_fright_by_level:
    ; Half speed (every other frame) in frightened
    .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
ghost_speed_mask_tunnel_by_level:
    ; Dossier: tunnel ~40-50% -> use half-speed across
    .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01

; Blinky "Cruise Elroy" thresholds and speed masks per level
; Dots-left thresholds when Elroy engages; second stage when lower threshold hit
elroy1_dots_left_by_level:
    .byte 20,30,40,40,40,50,50,50,60,60,60,60,60
elroy2_dots_left_by_level:
    .byte 10,15,20,20,20,25,25,25,30,30,30,30,30
; Elroy stage 1 speed masks (approximate to nearest mask)
; L1 80%~ -> use 7/8 ($07) or 3/4 ($03); pick $07
; L2-4 90% -> 15/16 ($0F)
; L5-13 100% -> $FF
elroy1_speed_mask_by_level:
    .byte $07,$0F,$0F,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; Elroy stage 2 speed masks
; L1 85% -> 7/8 ($07)
; L2-4 95% -> 31/32 ($1F)
; L5-13 105% -> cap at $FF (cannot exceed 1px/frame in this gating)
elroy2_speed_mask_by_level:
    .byte $07,$1F,$1F,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Pac-Man dot speed masks by level (tile contains dot/pill)
pac_speed_mask_dot_by_level:
    ; L1 ~71% -> ~3/4; L2-4 ~79% -> ~7/8; L5-12 ~87% -> 7/8; L13+ ~87% -> 7/8
    .byte $03,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07

; Pac-Man frightened speed masks by level
pac_speed_mask_fright_by_level:
    ; L1-4 ~90% -> 15/16; L5-12 ~100% -> always; L13+ -> always (fright time often 0)
    .byte $0F,$0F,$0F,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Pac-Man frightened dot speed masks by level
pac_speed_mask_fright_dot_by_level:
    ; L1 ~79% -> 7/8; L2-4 ~83% -> ~7/8; L5-12 ~87% -> 7/8; L13+ 7/8
    .byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
ghost_speed_mask_house_by_level:
    ; House/leavehouse baseline half speed approximation
    .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01

; Returns Y=index (0..12) clamped from current level (1..13+)
get_level_index_0_12:
    lda level
    beq @set1
    cmp #13
    bcc @ok
    lda #13
@ok:
    tay
    dey
    rts
@set1:
    lda #1
    tay
    dey
    rts

; Return A = Pac-Man move mask for current tile position/level (normal or tunnel)
get_pac_move_mask:
    ; determine tunnel from pacman's tile
    ldx pacman_x
    ldy pacman_y
    jsr is_tunnel_xy          ; A=0 if tunnel
    beq @is_tunnel
    ; normal
    jsr get_level_index_0_12
    lda #<pac_speed_mask_normal_by_level
    sta ZP_PTR1
    lda #>pac_speed_mask_normal_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts
@is_tunnel:
    jsr get_level_index_0_12
    lda #<pac_speed_mask_tunnel_by_level
    sta ZP_PTR1
    lda #>pac_speed_mask_tunnel_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts

; Return A = ghost normal-speed mask for current level
get_ghost_normal_mask:
    jsr get_level_index_0_12
    lda #<ghost_speed_mask_normal_by_level
    sta ZP_PTR1
    lda #>ghost_speed_mask_normal_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts

; Square lookup table for 0..31 (fits maze ranges for dx,dy)
sq_table_lo:
    .byte 0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225
    .byte 0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225
sq_table_hi:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Digit to sprite tile index mapping (0..9)
digit_sprite_tile:
    .byte 0,1,2,3,4,5,6,7,8,9

; Return A = ghost move mask for ghost index X considering state and tunnel
get_ghost_move_mask_for_index:
    ; Determine if ghost X is in tunnel using its tile coords
    phx
    txa
    tay                    ; Y = ghost index
    lda ghost_x,y
    tax                    ; X = tile x
    lda ghost_y,y
    tay                    ; Y = tile y
    jsr is_tunnel_xy       ; A=0 if tunnel
    bne @not_tunnel
    jmp @in_tunnel
@not_tunnel:
    ; not tunnel: choose based on state and Elroy for Blinky
    plx                    ; restore ghost index in X
    ; Blinky Elroy override in normal scatter/chase
    cpx #GHOST_BLINKY
    bne @state_check
    ; apply Elroy only in normal (non-house/fright/eyes) states
    lda ghost_state,x
    cmp #GHOSTSTATE_FRIGHTENED
    beq @state_check
    cmp #GHOSTSTATE_EYES
    beq @state_check
    cmp #GHOSTSTATE_HOUSE
    beq @state_check
    cmp #GHOSTSTATE_LEAVEHOUSE
    beq @state_check
    ; compute remaining dots and compare thresholds
    lda dots_remaining
    jsr get_level_index_0_12     ; Y=index
    ; check stage 2
    lda #<elroy2_dots_left_by_level
    sta ZP_PTR1
    lda #>elroy2_dots_left_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    cmp dots_remaining
    bcc @elroy2
    ; check stage 1
    lda #<elroy1_dots_left_by_level
    sta ZP_PTR1
    lda #>elroy1_dots_left_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    cmp dots_remaining
    bcc @elroy1
    ; not elroy
    jmp @state_check
@elroy2:
    jsr get_level_index_0_12
    lda #<elroy2_speed_mask_by_level
    sta ZP_PTR1
    lda #>elroy2_speed_mask_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts
@elroy1:
    jsr get_level_index_0_12
    lda #<elroy1_speed_mask_by_level
    sta ZP_PTR1
    lda #>elroy1_speed_mask_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts
@state_check:
    lda ghost_state,x
    cmp #GHOSTSTATE_FRIGHTENED
    beq @fright
    cmp #GHOSTSTATE_HOUSE
    beq @house
    cmp #GHOSTSTATE_LEAVEHOUSE
    beq @house
    ; normal
    jsr get_ghost_normal_mask
    rts
@fright:
    jsr get_level_index_0_12
    lda #<ghost_speed_mask_fright_by_level
    sta ZP_PTR1
    lda #>ghost_speed_mask_fright_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts
@house:
    jsr get_level_index_0_12
    lda #<ghost_speed_mask_house_by_level
    sta ZP_PTR1
    lda #>ghost_speed_mask_house_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts
@in_tunnel:
    plx                    ; restore ghost index in X
    jsr get_level_index_0_12
    lda #<ghost_speed_mask_tunnel_by_level
    sta ZP_PTR1
    lda #>ghost_speed_mask_tunnel_by_level
    sta ZP_PTR1+1
    lda (ZP_PTR1),y
    rts

; Return A=$00 (Z=1) if ghost X is centered in its tile (offsets == 4), else A=$FF
ghost_is_center:
    lda ghost_off_x,x
    cmp #4
    bne @notc
    lda ghost_off_y,x
    cmp #4
    bne @notc
    lda #$00
    rts
@notc:
    lda #$FF
    rts

; ==============================================================================
; AUDIO SFX STUBS (to be wired to PSG/PCM later)
; ==============================================================================
; PSG voice writer
; Inputs: A=voice, X=freq_lo, Y=freq_hi, ZP_TEMP1=vol, ZP_TEMP2=wave
psg_write_voice:
    pha
    VERA_SET_ADDR VERA_PSG_BASE, 1
    pla
    ; A = voice; compute offset = voice*4 via shifts
    asl                 ; *2
    asl                 ; *4
    clc
    adc VERA_ADDR_LOW
    sta VERA_ADDR_LOW
    bcc :+
    inc VERA_ADDR_MID
:
    stx VERA_DATA0
    sty VERA_DATA0
    lda ZP_TEMP1
    sta VERA_DATA0
    lda ZP_TEMP2
    sta VERA_DATA0
    rts

; Silence a PSG voice: Inputs A=voice
psg_voice_off:
    pha
    ; zero freq, vol 0, pulse
    ldx #$00
    ldy #$00
    lda #%11000000
    sta ZP_TEMP1
    lda #$00
    sta ZP_TEMP2
    pla
    jsr psg_write_voice
    rts

sfx_dot_eaten:
    ; Emulate alternating eatdot1/2 with base and delta per 60Hz tick
    lda chomp_timer
    bne @apply
    lda #2
    sta chomp_timer
    ; toggle active 0/1
    lda chomp_active
    eor #1
    sta chomp_active
    ; set base freq per variant
    lda chomp_active
    beq @d2
    ; eatdot1: base~0x1500
    lda #$00
    sta chomp_base_lo
    lda #$15
    sta chomp_base_hi
    bra @apply
@d2:
    ; eatdot2: base~0x0700
    lda #$00
    sta chomp_base_lo
    lda #$07
    sta chomp_base_hi
@apply:
    ; one tick: apply +/- delta 0x0300
    lda chomp_active
    beq @plus
    ; dot1: -0x0300
    lda chomp_base_lo
    sec
    sbc #$00
    tax
    lda chomp_base_hi
    sbc #$03
    tay
    bra @emit
@plus:
    ; dot2: +0x0300
    lda chomp_base_lo
    clc
    adc #$00
    tax
    lda chomp_base_hi
    adc #$03
    tay
@emit:
    lda #%11001100
    sta ZP_TEMP1
    lda #%00000000
    sta ZP_TEMP2
    lda #0
    jsr psg_write_voice
    rts

sfx_pill_eaten:
    ldx #$80
    ldy #$01
    lda #%11001000
    sta ZP_TEMP1
    lda #%01000000
    sta ZP_TEMP2
    lda #1
    jsr psg_write_voice
    rts

sfx_ghost_eaten:
    lda #20
    sta ghost_sfx_tmr
    ldx #$40
    ldy #$02
    lda #%11001100
    sta ZP_TEMP1
    lda #%01000000
    sta ZP_TEMP2
    lda #2
    jsr psg_write_voice
    jsr popup_show_chain
    rts

sfx_pacman_death:
    ; Trigger register-dump playback of death sequence; silence/lock SFX
    lda #1
    sta audio_regdump_active
    stz audio_regdump_idx
    stz audio_regdump_idx+1
    rts

; Fruit pickup SFX (voice 2): quick arpeggio rise with pulse
sfx_fruit_pick:
    ; simple two-step frequency pop
    ldx #$C0
    ldy #$01
    lda #%11001010            ; medium volume, both channels
    sta ZP_TEMP1
    lda #%00000000            ; pulse 50%
    sta ZP_TEMP2
    lda #2
    jsr psg_write_voice
    ; second step slightly higher
    ldx #$10
    ldy #$02
    lda #2
    jsr psg_write_voice
    rts

; Per-frame audio controller (envelopes, loops, glides)
audio_update:
    ; Chomp gate: quick release and hard-off when timer reaches 0
    lda chomp_timer
    beq @chomp_off
    dec chomp_timer
    bra @pellet
@chomp_off:
    lda #0
    jsr psg_voice_off
@pellet:
    ; If a register-dump is active, drive it and skip other SFX (priority)
    lda audio_regdump_active
    beq @pellet_cont
    jsr audio_regdump_tick
    rts
@pellet_cont:
    ; Power-pellet pew-pew while frightened (4 Hz cadence)
    lda tick_hi
    cmp fr_end_hi
    bcc @fr_on
    bne @siren
    lda tick_lo
    cmp fr_end_lo
    bcs @siren
@fr_on:
    ; toggle every 16 frames with on/off and A/B variants
    inc pellet_tick
    lda pellet_tick
    and #$0F
    bne @siren
    lda pellet_tick
    and #$10
    beq @pp_off
    lda pellet_tick
    and #$20
    beq @pp_A
    ; variant B
    ldx #$58
    ldy #$01
    bra @pp_apply
@pp_A:
    ; variant A
    ldx #$80
    ldy #$01
@pp_apply:
    lda #%11000100
    sta ZP_TEMP1
    lda #%01000000
    sta ZP_TEMP2
    lda #1
    jsr psg_write_voice
    bra @siren
@pp_off:
    lda #1
    jsr psg_voice_off
@siren:
    ; ghost eaten sweep
    lda ghost_sfx_tmr
    beq @done
    dec ghost_sfx_tmr
    bne :+
    lda #2
    jsr psg_voice_off
    bra @done
:
    ; compute a simple linear sweep down
    ldx #$40
    ldy #$02
    lda ghost_sfx_tmr
    lsr
    sta ZP_TEMP3
    txa
    sec
    sbc ZP_TEMP3
    tax
    lda #%11001000
    sta ZP_TEMP1
    lda #%01000000
    sta ZP_TEMP2
    lda #2
    jsr psg_write_voice
@done:
    rts

; Siren update: pick stage by dots_remaining and whether frightened active
siren_update:
    ; If death register-dump active, silence siren and return (priority)
    lda audio_regdump_active
    beq :+
    jsr siren_silence
    rts
:
    ; if frightened active, lower stage
    lda tick_hi
    cmp fr_end_hi
    bcc @fr
    bne @no_fr
    lda tick_lo
    cmp fr_end_lo
    bcc @fr
@no_fr:
    ; not frightened: stage by dots_remaining thresholds
    lda dots_remaining
    cmp #20
    bcc @st4
    cmp #60
    bcc @st3
    cmp #120
    bcc @st2
    ; default stage1
    lda #1
    sta siren_stage
    jsr siren_apply
    rts
@st2:
    lda #2
    sta siren_stage
    jsr siren_apply
    rts
@st3:
    lda #3
    sta siren_stage
    jsr siren_apply
    rts
@st4:
    lda #4
    sta siren_stage
    jsr siren_apply
    rts
@fr:
    lda #1
    sta siren_stage
    jsr siren_apply
    rts

; Apply siren PSG params for current siren_stage
siren_apply:
    lda siren_stage
    tax
    dex
    ; base freq
    lda siren_freq_lo,x
    sta ZP_TEMP3
    lda siren_freq_hi,x
    sta ZP_TEMP4
    ; small vibrato on voice 4
    lda tick_lo
    and #$0F
    bne :+
    inc siren_vib_ph
:
    lda siren_vib_ph
    and #$03
    beq @vb0
    cmp #1
    beq @vb1
    cmp #2
    beq @vb2
    ; phase 3
    ; -delta
    lda ZP_TEMP3
    sec
    sbc #$02
    sta ZP_TEMP3
    bra @vb_done
@vb2:
    ; +delta
    lda ZP_TEMP3
    clc
    adc #$02
    sta ZP_TEMP3
    bra @vb_done
@vb1:
    ; +delta
    lda ZP_TEMP3
    clc
    adc #$01
    sta ZP_TEMP3
    bra @vb_done
@vb0:
    ; -delta
    lda ZP_TEMP3
    sec
    sbc #$01
    sta ZP_TEMP3
@vb_done:
    lda siren_vol,x
    sta ZP_TEMP1
    ; Duck siren when ghost sweep active
    lda ghost_sfx_tmr
    beq :+
    lda ZP_TEMP1
    and #$0F
    beq :+
    sec
    sbc #$03
    bcs :+
    lda #$00
:
    ora #$C0
    sta ZP_TEMP1
    lda siren_wave,x
    sta ZP_TEMP2
    ldx ZP_TEMP3
    ldy ZP_TEMP4
    lda #4
    jsr psg_write_voice
    rts

siren_freq_lo: .byte $20,$30,$40,$50
siren_freq_hi: .byte $00,$00,$00,$00
siren_vol:     .byte %11000010,%11000100,%11000110,%11001000
siren_wave:    .byte %00000000,%00000000,%00000000,%00000000

; Silence siren voice (voice 4)
siren_silence:
    lda #$00
    sta ZP_TEMP3
    sta ZP_TEMP4
    lda #%11000000           ; vol 0, both L+R
    sta ZP_TEMP1
    lda #%00000000           ; pulse 50% (unused when vol 0)
    sta ZP_TEMP2
    ldx ZP_TEMP3
    ldy ZP_TEMP4
    lda #4
    jsr psg_write_voice
    rts

; ------------------------------------------------------------------------------
; Register-dump playback engine (arcade parity)
; - Drives VERA PSG from packed 32-bit values recorded from arcade WSG
; - Currently supports: death sequence (single-voice on voice 3)
; Inputs: none
; Clobbers: A,X,Y,ZP_TEMP1..4
audio_regdump_tick:
    lda audio_regdump_active
    beq @to_exit
    cmp #1
    bne :+
    jmp rd_death_abs
:
    cmp #2
    bne @to_exit
    jmp rd_prelude_abs
@to_exit:
    jmp rd_exit_abs
rd_death_abs:
    ; Compute if finished: compare index against length (snd_dump_dead_len/4 dwords)
    lda audio_regdump_idx
    ldx audio_regdump_idx+1
    ; total dwords = snd_dump_dead_len / 4
    ; constant: 90
    cpx #0
    bne @d_hi
    cmp #90
    bcc @step
    beq @stop
@d_hi:
    ; high byte nonzero means >=256 dwords; impossible here, treat as stop
@stop:
    stz audio_regdump_active
    rts
@step:
    ; Fetch dword at index: ptr = base + idx*4
    ; Compute idx*4 into ZP_TEMP1:ZP_TEMP2 (16-bit)
    ; A currently has low byte of idx, X has high byte
    sta ZP_TEMP1
    stx ZP_TEMP2
    asl ZP_TEMP1
    rol ZP_TEMP2            ; *2
    asl ZP_TEMP1
    rol ZP_TEMP2            ; *4
    lda #<snd_dump_dead
    clc
    adc ZP_TEMP1
    sta ZP_PTR1
    lda #>snd_dump_dead
    adc ZP_TEMP2
    sta ZP_PTR1+1
    ; Read 4 bytes little-endian into ZP_TEMP1..4
    ldy #0
    lda (ZP_PTR1),y
    sta ZP_TEMP1            ; b0
    iny
    lda (ZP_PTR1),y
    sta ZP_TEMP2            ; b1
    iny
    lda (ZP_PTR1),y
    sta ZP_TEMP3            ; b2
    iny
    lda (ZP_PTR1),y
    sta ZP_TEMP4            ; b3
    ; Decode: bits 31-28 vol (ZP_TEMP4 high nibble), 27-25 wave (ZP_TEMP4 bits 2..0), 24-0 freq (low 3 bits of b3 + b2,b1,b0) but here we target VERA 16-bit
    ; For VERA PSG: we map 20-bit freq down to 16-bit by dropping lowest 4 bits of 20-bit value
    ; Build 20-bit value into A:X:Y then shift
    ; Compose 20-bit: low16 = b1<<8 | b0, high4 = b2 & 0x0F
    lda ZP_TEMP1
    sta ZP_TEMP5            ; keep low byte
    lda ZP_TEMP2
    sta ZP_TEMP6            ; high byte
    lda ZP_TEMP3
    and #$0F
    sta ZP_TEMP7            ; top 4 bits
    ; Shift down by 4 -> 16-bit: (high4:low16) >> 4
    ; Form 20-bit into 24-bit container ZP_TEMP7:ZP_TEMP6:ZP_TEMP5, then >>4
    lda ZP_TEMP5            ; low
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7            ; now ZP_TEMP6 = freq_lo, ZP_TEMP7 = freq_hi
    ; Volume: high nibble of ZP_TEMP4 -> map 0..15 to PSG volume field; take full L+R, attenuation applied externally if desired
    lda ZP_TEMP4
    and #$F0
    lsr
    lsr
    lsr
    lsr                     ; 0..15
    tax
    ; Build PSG vol byte: 11 L+R bits and 4-bit vol in low nibble
    lda #$C0
    ; move X (0..15) into low nibble of A
    txa
    and #$0F
    ora #$C0
    sta ZP_TEMP1            ; vol byte
    ; Waveform: low 3 bits of ZP_TEMP4 -> choose pulse/tri/noise mapping; for death dump use triangle (2) and saw (1) map to closest
    lda ZP_TEMP4
    and #$07
    tax
    ; Map WSG 0..7 to VERA waveform selector (0=pulse 50% as base, 64=saw,128=tri,192=noise). Use a small LUT of 8 entries.
    lda wsg2vera_wave,x
    sta ZP_TEMP2
    ; Emit to voice 3
    ldx ZP_TEMP6            ; freq_lo
    ldy ZP_TEMP7            ; freq_hi
    lda #3
    jsr psg_write_voice
    ; advance index
    inc audio_regdump_idx
    bne :+
    inc audio_regdump_idx+1
:
    rts
rd_exit_abs:
    rts

rd_prelude_abs:
    ; Register dump that updates all active voices per tick
    ; Layout in pacman_data.asm mirrors reference C: interleaved by enabled voices per tick
    ; For simplicity, assume 3 voices active with stride 2 (as in reference), stopping at len
    ; When finished, clear active flag and return
    ; Index is current tick; stop at ticks == (snd_dump_prelude_len / (2*4))
    lda audio_regdump_idx
    ldx audio_regdump_idx+1
    cpx #0
    bne :+
    cmp #245               ; 490 dwords / 2 voices = 245 ticks
    bcc @pl_step
    beq @pl_stop
    bcs @pl_stop
:
    stz audio_regdump_active
    rts
@pl_stop:
    stz audio_regdump_active
    lda #1
    sta siren_fade_pending
    rts
@pl_step:
    ; base pointer = snd_dump_prelude + idx * stride * 4
    ; stride=2 -> offset = idx*8
    sta ZP_TEMP1
    stx ZP_TEMP2
    asl ZP_TEMP1
    rol ZP_TEMP2            ; *2
    asl ZP_TEMP1
    rol ZP_TEMP2            ; *4
    asl ZP_TEMP1
    rol ZP_TEMP2            ; *8
    lda #<snd_dump_prelude
    clc
    adc ZP_TEMP1
    sta ZP_PTR1
    lda #>snd_dump_prelude
    adc ZP_TEMP2
    sta ZP_PTR1+1
    ; decode two voices (0 and 1) for this tick
    ldy #0
    jsr psg_decode_and_write_v0
    jsr psg_decode_and_write_v1
    ; advance tick
    inc audio_regdump_idx
    bne :+
    inc audio_regdump_idx+1
:
    rts

; Helpers to decode one 32-bit packed value at (ZP_PTR1),Y and emit to a fixed voice
psg_decode_and_write_v0:
    phy
    ldy #0
    jsr psg_decode_and_write_common
    ply
    rts

psg_decode_and_write_v1:
    phy
    ldy #4
    jsr psg_decode_and_write_common
    ply
    rts

psg_decode_and_write_common:
    ; read dword at (ZP_PTR1)+Y → ZP_TEMP1..4
    lda (ZP_PTR1),y
    sta ZP_TEMP1
    iny
    lda (ZP_PTR1),y
    sta ZP_TEMP2
    iny
    lda (ZP_PTR1),y
    sta ZP_TEMP3
    iny
    lda (ZP_PTR1),y
    sta ZP_TEMP4
    ; freq/vol/wave decode same as death path
    lda ZP_TEMP1
    sta ZP_TEMP5
    lda ZP_TEMP2
    sta ZP_TEMP6
    lda ZP_TEMP3
    and #$0F
    sta ZP_TEMP7
    lda ZP_TEMP5
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7
    lsr
    ror ZP_TEMP6
    ror ZP_TEMP7
    lda ZP_TEMP4
    and #$F0
    lsr
    lsr
    lsr
    lsr
    tax
    txa
    and #$0F
    ora #$C0
    sta ZP_TEMP1
    lda ZP_TEMP4
    and #$07
    tax
    lda wsg2vera_wave,x
    sta ZP_TEMP2
    ldx ZP_TEMP6
    ldy ZP_TEMP7
    ; select voice based on Y passed to this routine: Y=0 -> voice0, Y=4 -> voice1
    tya
    beq :+
    lda #1
    jsr psg_write_voice
    rts
:
    lda #0
    jsr psg_write_voice
    rts

; WSG->VERA waveform map (8 entries):
; 0..7 namco shapes -> choose nearest: use triangle for mellow shapes, saw for brighter. Keep 0..7 simple mapping for now
wsg2vera_wave:
    .byte $80,$40,$80,$00,$80,$40,$80,$00

; Popup: show ghost chain score near Pac-Man (single 16x16 tile)
popup_show_chain:
    ; Only one popup; start 1s timer
    lda #1
    sta popup_active
    lda pacman_x
    sta popup_x
    lda pacman_y
    sta popup_y
    lda #<(60)
    sta popup_timer
    lda #>(60)
    sta popup_timer+1
    ; choose 16x16 score tile based on ghosts_eaten_chain (0..3 -> 200..1600)
    lda ghosts_eaten_chain
    tax
    lda popup_chain_tiles,x
    sta popup_chain_tile
    lda #1
    sta popup_chain
    rts

; chain popup tile table (index 0..3 -> 200,400,800,1600)
popup_chain_tiles:
    .byte NAMCO_SPRITETILE_SCORE_200
    .byte NAMCO_SPRITETILE_SCORE_400
    .byte NAMCO_SPRITETILE_SCORE_800
    .byte NAMCO_SPRITETILE_SCORE_1600

; Popup: show fruit score at fruit location
popup_show_fruit:
    lda active_fruit
    bne @pf_cont
    rts
@pf_cont:
    ; Position at fruit tile for tilemap write
    lda #FRUIT_X
    sta fruit_score_x
    lda #FRUIT_Y
    sta fruit_score_y
    ; Timer ~1s
    lda #<(60)
    sta fruit_score_timer
    lda #>(60)
    sta fruit_score_timer+1
    lda #1
    sta fruit_score_active
    ; Choose the 4-tile score glyphs and draw them left-to-right
    ldx fruit_score_x
    ldy fruit_score_y
    ; use fruit score color on tile layer
    lda #NAMCO_COLOR_FRUIT_SCORE
    sta ZP_TEMP3
    lda active_fruit
    cmp #FRUIT_CHERRIES
    bne @pf_300
    ; 100
    lda #NAMCO_TILE_SCORE_100_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_100_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_100_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_100_3
    jsr set_tile_color
    rts
@pf_300:
    cmp #FRUIT_STRAWBERRY
    bne @pf_500
    lda #NAMCO_TILE_SCORE_300_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_300_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_300_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_300_3
    jsr set_tile_color
    rts
@pf_500:
    cmp #FRUIT_PEACH
    bne @pf_700
    lda #NAMCO_TILE_SCORE_500_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_500_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_500_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_500_3
    jsr set_tile_color
    rts
@pf_700:
    cmp #FRUIT_APPLE
    bne @pf_1000
    lda #NAMCO_TILE_SCORE_700_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_700_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_700_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_700_3
    jsr set_tile_color
    rts
@pf_1000:
    cmp #FRUIT_GRAPES
    bne @pf_2000
    lda #NAMCO_TILE_SCORE_1000_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_1000_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_1000_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_1000_3
    jsr set_tile_color
    rts
@pf_2000:
    cmp #FRUIT_GALAXIAN
    bne @pf_3000
    lda #NAMCO_TILE_SCORE_2000_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_2000_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_2000_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_2000_3
    jsr set_tile_color
    rts
@pf_3000:
    cmp #FRUIT_BELL
    bne @pf_5000
    lda #NAMCO_TILE_SCORE_3000_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_3000_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_3000_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_3000_3
    jsr set_tile_color
    rts
@pf_5000:
    cmp #FRUIT_KEY
    beq @pf_5000_body
    jmp popup_done
@pf_5000_body:
    lda #NAMCO_TILE_SCORE_5000_0
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_5000_1
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_5000_2
    jsr set_tile_color
    inx
    lda #NAMCO_TILE_SCORE_5000_3
    jsr set_tile_color
    rts
popup_f100:
    lda #3
    sta popup_len
    lda #'1'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    rts
popup_f300:
    lda #3
    sta popup_len
    lda #'3'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    rts
popup_f500:
    lda #3
    sta popup_len
    lda #'5'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    rts
popup_f700:
    lda #3
    sta popup_len
    lda #'7'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    rts
popup_f1000:
    lda #4
    sta popup_len
    lda #'1'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    sta popup_c3
    rts
popup_f2000:
    lda #4
    sta popup_len
    lda #'2'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    sta popup_c3
    rts
popup_f3000:
    lda #4
    sta popup_len
    lda #'3'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    sta popup_c3
    rts
popup_f5000:
    lda #4
    sta popup_len
    lda #'5'
    sta popup_c0
    lda #'0'
    sta popup_c1
    sta popup_c2
    sta popup_c3
    rts
popup_done:
    rts
@c800:
    lda #'8'
    sta popup_c0
    lda #'0'
    sta popup_c1
    lda #'0'
    sta popup_c2
    rts
@c400:
    lda #'4'
    sta popup_c0
    lda #'0'
    sta popup_c1
    lda #'0'
    sta popup_c2
    rts
@c200:
    lda #'2'
    sta popup_c0
    lda #'0'
    sta popup_c1
    lda #'0'
    sta popup_c2
    rts

; Minimal PSG helper: click on channel in A
; Writes to VERA PSG I/O window at $9F3D..$9F3F
psg_click_ch:
    pha
    ; set frequency low
    lda #$20
    sta VERA_AUDIO_DATA       ; freq lo
    lda #$00
    sta VERA_AUDIO_DATA       ; freq hi
    ; set vol L+R medium
    lda #%11000000 | $10
    sta VERA_AUDIO_DATA
    ; set pulse waveform
    lda #%00000000
    sta VERA_AUDIO_DATA
    ; quick off
    lda #%00000000
    sta VERA_AUDIO_DATA
    pla
    rts

; Add fruit score to BCD score based on active_fruit (uses tens-based BCD with trailing zero)
add_active_fruit_score:
    lda active_fruit
    beq @done
    tax                     ; X = fruit id 1..8
    dex                     ; 0-based index
    ; tables: tens (lo) and hundreds (hi)
    lda fruit_score_tens,x
    pha
    sed
    ; Workaround: pop into A
    pla
    clc
    adc score_lo_bcd
    sta score_lo_bcd
    lda score_hi_bcd
    adc #0
    sta score_hi_bcd
    cld
    ; add hundreds if any
    lda active_fruit
    tax
    dex
    lda fruit_score_hundreds,x
    beq @upd_hs
    sed
    clc
    lda score_hi_bcd
    adc fruit_score_hundreds,x
    sta score_hi_bcd
    cld
@upd_hs:
    jsr update_hiscore_if_needed
@done:
    rts

; Update hiscore BCD if current score is higher (compares hi then lo)
update_hiscore_if_needed:
    ; compare hi
    lda score_hi_bcd
    cmp hiscore_hi_bcd
    bcc @no
    bne @yes
    ; hi equal, compare lo
    lda score_lo_bcd
    cmp hiscore_lo_bcd
    bcc @no
@yes:
    lda score_lo_bcd
    sta hiscore_lo_bcd
    lda score_hi_bcd
    sta hiscore_hi_bcd
@no:
    rts

; Fruit score tables (BCD additions: tens and hundreds digits)
; Index 0..7 for fruits 1..8:
; CHERRIES 100 (tens=10, hundreds=0)
; STRAWBERRY 300 (30,0)
; PEACH 500 (50,0)
; APPLE 700 (70,0)
; GRAPES 1000 (00,01)
; GALAXIAN 2000 (00,02)
; BELL 3000 (00,03)
; KEY 5000 (00,05)
fruit_score_tens:
    .byte $10,$30,$50,$70,$00,$00,$00,$00
fruit_score_hundreds:
    .byte $00,$00,$00,$00,$01,$02,$03,$05
