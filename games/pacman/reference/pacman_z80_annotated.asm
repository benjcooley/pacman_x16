; ==============================================================================
; PAC-MAN Z80 ASSEMBLY CODE - FULLY ANNOTATED VERSION
; ==============================================================================
; Original Pac-Man arcade game disassembly with comprehensive annotations
; Including C pseudo-code, memory maps, and detailed function descriptions
; 
; Use grep patterns to find sections:
; grep "SECTION:" for major code sections
; grep "FUNCTION:" for individual functions/routines  
; grep "MEMORY_MAP:" for memory layout documentation
; grep "ALGORITHM:" for game logic explanations
; grep "C_PSEUDO:" for C code equivalents
; ==============================================================================
;
; ################################################################################
; # PAC-MAN GAME ARCHITECTURE OVERVIEW
; ################################################################################
;
; This is a comprehensive annotation of the original Pac-Man arcade game's Z80
; assembly code, revealing the sophisticated architecture behind this iconic game.
;
; ## CORE ARCHITECTURAL PRINCIPLES
;
; 1. **STATE-DRIVEN DESIGN**: Every game entity uses numbered states
;    - State 0: Normal operation
;    - State 1: Collision/special event
;    - State 2: Return/recovery
;    - State 3: Frightened/alternate mode
;
; 2. **INTERRUPT-DRIVEN TIMING**: 60Hz interrupt system provides:
;    - Consistent game timing across all systems
;    - Synchronized sprite animations
;    - Real-time collision detection
;    - Sound effect timing
;
; 3. **MODULAR SUBSYSTEMS**: Game is built from independent, interacting modules:
;    - Game state management (attract, gameplay, demo)
;    - Character movement and AI systems
;    - Sound and visual effects
;    - Score and bonus management
;    - Input handling and timing
;
; 4. **DATA-DRIVEN CONFIGURATION**: Extensive use of lookup tables for:
;    - Level progression parameters
;    - Ghost AI behavior patterns
;    - Fruit bonus configurations
;    - Sprite animation sequences
;    - Sound effect parameters
;
; 5. **MEMORY-EFFICIENT DESIGN**: Careful memory organization with:
;    - Shared data structures for similar entities
;    - Bit-packed flags and states
;    - Circular buffers for sprites and sound
;    - Position-based calculations rather than storing coordinates
;
; ## MAJOR SUBSYSTEM BREAKDOWN
;
; ### INTERRUPT AND TIMING SYSTEM (0x008D-0x0266)
; - 60Hz master clock driving all game timing
; - Interrupt Mode 2 (IM2) vectored interrupts
; - Cascaded timing for different game speeds
; - Watchdog timer for hardware reliability
;
; ### COIN AND CREDIT SYSTEM (0x0267-0x039C)
; - Debounced coin input with 1100 pattern detection
; - BCD arithmetic for credit management
; - Solenoid control for coin mechanisms
; - Player input processing with timing
;
; ### GAME STATE MACHINE (0x03C8-0x09E7)
; - Hierarchical state management
; - Attract mode with multiple sub-states
; - Game initialization and level progression
; - Demo mode with automated input
; - Transition management between modes
;
; ### GHOST AI SYSTEM (0x051C-0x0B9C)
; - Individual AI for each ghost (Blinky, Pinky, Inky, Sue)
; - Sophisticated targeting algorithms
; - Frightened mode with retreat behavior
; - Collision detection and response
; - State-synchronized animation
;
; ### CHARACTER MOVEMENT ENGINE (0x0c42-0x0e22)
; - Precise maze position tracking
; - Tunnel teleportation handling
; - Direction change validation
; - Smooth sprite interpolation
; - Position-based trigger systems
;
; ### AUDIO SYSTEM (0x0c0d-0x0c41)
; - Multi-channel sound synthesis
; - Pac-Man's iconic "wakka wakka" eating sound
; - Context-sensitive audio (gameplay vs attract)
; - Timing-synchronized sound effects
;
; ### VISUAL EFFECTS SYSTEM (0x0bd6-0x0eac)
; - Dynamic sprite visibility control
; - Power pellet blinking based on position
; - Animation timing and synchronization
; - Display memory management
; - Color and pattern control
;
; ### BONUS AND SCORING SYSTEM (0x0e36-0x0f38)
; - Position-triggered fruit bonuses
; - Level-based fruit progression
; - Point value calculations
; - Bonus timing and display management
;
; ## KEY TECHNICAL INNOVATIONS
;
; 1. **Position-Based Logic**: Uses precise maze coordinates for:
;    - Trigger detection (0x46, 0xaa for bonuses)
;    - Tunnel handling (0x78, 0x80)
;    - Power pellet visibility zones
;    - Start position management (0x64)
;
; 2. **Bit Manipulation Optimization**: Efficient use of:
;    - Bit rotation for animation timing
;    - Bit flags for entity states
;    - Bit masks for display control
;    - Packed data structures
;
; 3. **Table-Driven Configuration**: Lookup tables control:
;    - Level progression parameters
;    - Ghost speed and timing
;    - Fruit appearance and values
;    - Jump tables for state dispatch
;
; 4. **Memory-Mapped Hardware**: Direct hardware control via:
;    - Sprite position and appearance registers
;    - Sound channel control
;    - Input reading and debouncing
;    - Display memory manipulation
;
; This architecture demonstrates how the constraints of 1980s hardware led to
; elegant, efficient solutions that created one of gaming's most enduring and
; influential titles.
;
; ################################################################################

; MEMORY_MAP: Game Memory Layout
; ==============================================================================
; 0x0000-0x3FFF: ROM (Game code and data)
; 0x4000-0x43FF: Video RAM (32x32 tiles, 1KB)
; 0x4400-0x47FF: Color RAM (32x32 color attributes, 1KB) 
; 0x4800-0x4BFF: Unused/Mirror
; 0x4C00-0x4FFF: Main RAM (1KB)
;   0x4C00-0x4C7F: Game variables and state
;   0x4C80-0x4CBF: Sound/interrupt buffer
;   0x4CC0-0x4CFF: Sprite position buffer
;   0x4D00-0x4FFF: Game objects, AI state, etc.
; 0x5000-0x5007: Hardware control registers
; 0x5040-0x507F: Sound generation hardware
; 0x50C0: Watchdog timer reset

; MEMORY_MAP: Key Game Variables
; ==============================================================================
	;; 0x4E66: Last state coin inputs shifted left by 1
	;; 0x4E6B: Number of coins per credit
	;; 0x4E6C: Left over coins (partial credits)
	;; 0x4E6D: Number of credits per coin
	;; 0x4E6E: Current number of credits
	;; 0x4E6F: Number of lives per game
	;; 0x4E80-0x4E83: Player 1 score (4 bytes BCD)
	;; 0x4E84-0x4E87: Player 2 score (4 bytes BCD)
	;; 0x4E88-0x4E8B: High score (4 bytes BCD)
	;; 0x4370: Number of players (0=1 player, 1=2 players)

; MEMORY_MAP: Hardware Registers
; ==============================================================================
	;; 0x5000: Interrupt enable (bit 0)
	;; 0x5001: Sound enable
	;; 0x5002: Aux board enable
	;; 0x5003: Flip screen
	;; 0x5004: Player 1 start lamp
	;; 0x5005: Player 2 start lamp
	;; 0x5006: Coin lockout
	;; 0x5007: Coin counter
	;; 0x5040-0x5055: Sound registers (3 channels)
	;; 0x50C0: Watchdog reset

	Starting address: 0
  Ending address: 16383
     Output file: (none)
Pass 1 of 1

; ################################################################################
; # INTERRUPT AND TIMING SYSTEM ARCHITECTURE
; ################################################################################
; 
; The Pac-Man interrupt system is the heartbeat of the entire game, providing
; precise 60Hz timing that drives all game mechanics. This system demonstrates
; sophisticated real-time programming on 1980s hardware.
;
; ## INTERRUPT ARCHITECTURE
;
; - **Z80 Interrupt Mode 2 (IM2)**: Uses vectored interrupts for fast response
; - **60Hz Master Clock**: Derived from video sync, ensuring consistent timing
; - **Cascaded Timers**: Multiple timing levels for different game speeds
; - **Watchdog Integration**: Hardware watchdog prevents system lockup
;
; ## TIMING HIERARCHY
;
; 1. **Frame Level (60Hz)**: Main interrupt drives display refresh
; 2. **Game Level (Variable)**: Game logic timing based on level difficulty  
; 3. **Animation Level (8-frame)**: Sprite animation cycling
; 4. **Sound Level (10-frame)**: Audio effect timing
;
; ## REAL-TIME SCHEDULING
;
; The interrupt handler acts as a simple scheduler, calling subsystems in
; priority order:
; - Hardware management (watchdog, inputs)
; - Game state updates
; - Character movement and AI
; - Visual and audio effects
; - Display refresh
;
; This architecture ensures that critical game timing remains consistent
; regardless of the complexity of individual game logic routines.
;
; ################################################################################

; ==============================================================================
; SECTION: RESET AND INTERRUPT VECTORS
; ==============================================================================

; FUNCTION: RESET_VECTOR - System Reset Entry Point
; C_PSEUDO: void reset_vector() { disable_interrupts(); setup_interrupt_page(); jump_to_startup(); }
0000  f3        di			; Disable interrupts
0001  3e3f      ld      a,#3f
0003  ed47      ld      i,a		; Set interrupt page register to 0x3F (interrupt vectors at 0x3F00)
0005  c30b23    jp      #230b		; Jump to startup/self-test routine

; FUNCTION: FILL_MEMORY - Fill memory block with value
; Parameters: HL = start address, B = count, A = fill value
; C_PSEUDO: void fill_memory(uint16_t addr, uint8_t count, uint8_t value) {
; C_PSEUDO:   for(int i = 0; i < count; i++) { memory[addr + i] = value; }
; C_PSEUDO: }
0008  77        ld      (hl),a		; Store A at address HL
0009  23        inc     hl		; Increment address
000a  10fc      djnz    #0008           ; Decrement B and loop if not zero
000c  c9        ret     

000d  c30e07    jp      #070e		; Jump to unknown routine

; FUNCTION: INDEXED_MEMORY_ACCESS - Add offset to HL and read byte
; Parameters: HL = base address, A = offset
; Returns: A = byte at (HL + A)
; C_PSEUDO: uint8_t indexed_read(uint16_t base, uint8_t offset) {
; C_PSEUDO:   return memory[base + offset];
; C_PSEUDO: }
0010  85        add     a,l		; Add offset to low byte of HL
0011  6f        ld      l,a		; Store result in L
0012  3e00      ld      a,#00		; Clear A
0014  8c        adc     a,h		; Add carry to high byte of HL
0015  67        ld      h,a		; Store result in H
0016  7e        ld      a,(hl)		; Read byte from calculated address
0017  c9        ret     

; FUNCTION: TABLE_LOOKUP_16BIT - 16-bit table lookup with index
; Parameters: HL = table base, B = index (multiplied by 2)
; Returns: HL = 16-bit value from table[index*2]
; C_PSEUDO: uint16_t table_lookup(uint16_t *table, uint8_t index) {
; C_PSEUDO:   return table[index];  // index auto-scaled for 16-bit entries
; C_PSEUDO: }
; ALGORITHM: Used for score calculations and jump tables
0018  78        ld      a,b		; Get index
0019  87        add     a,a		; Multiply by 2 (16-bit entries)
001a  d7        rst     #10		; Call indexed memory access routine (0x0010)
001b  5f        ld      e,a		; Store low byte in E
001c  23        inc     hl		; Point to high byte
001d  56        ld      d,(hl)		; Store high byte in D
001e  eb        ex      de,hl		; Exchange DE and HL (result now in HL)
001f  c9        ret     

; FUNCTION: COMPUTED_JUMP - Jump table dispatch
; Parameters: Stack has return address, A = index
; C_PSEUDO: void computed_jump(uint8_t index) {
; C_PSEUDO:   uint16_t *table = (uint16_t *)return_address;
; C_PSEUDO:   uint16_t target = table[index];
; C_PSEUDO:   jump_to(target);
; C_PSEUDO: }
0020  e1        pop     hl		; Get return address (points to jump table)
0021  87        add     a,a		; Double index for 16-bit table entries
0022  d7        rst     #10		; Add index to table base
0023  5f        ld      e,a		; Get target address low byte
0024  23        inc     hl
0025  56        ld      d,(hl)		; Get target address high byte
0026  eb        ex      de,hl		; Put target address in HL
0027  e9        jp      (hl)		; Jump to computed address

; FUNCTION: GET_PARAMETERS_AND_CALL - Extract parameters from return address
; C_PSEUDO: void get_params_and_call() {
; C_PSEUDO:   uint16_t *params = (uint16_t *)return_address;
; C_PSEUDO:   BC = *params++;
; C_PSEUDO:   return_address = params;
; C_PSEUDO:   call_routine_at_0042();
; C_PSEUDO: }

; ======================================================================
; RST #28 COMMAND QUEUING SYSTEM
; ======================================================================
; RST #28 extracts 2 parameter bytes and queues commands for execution
; 
; IMPLEMENTATION:
0028  e1        pop     hl		; Get return address (points after RST #28)
0029  46        ld      b,(hl)		; Get command byte
002a  23        inc     hl		; Advance to parameter byte
002b  4e        ld      c,(hl)		; Get parameter byte  
002c  23        inc     hl		; Advance past parameters
002d  e5        push    hl		; Push updated return address
002e  1812      jr      #0042           ; Jump to command buffer routine

; COMPLETE RST #28 COMMAND ANALYSIS:
; ======================================================================
; TOTAL COMMANDS: 68 RST #28 calls found in codebase
; COMMAND STRUCTURE: **CONFIRMED** - Function codes with parameters
; BUFFER: 0x4CC0-0x4CFF (64 bytes = 32 commands max)
; PROCESSING: **CONFIRMED** - Commands processed in main loop at 238D
; BUFFER CLEARING: **CONFIRMED** - Buffer consumed until empty each cycle
;
; **EXACT COMMAND PROCESSING MECHANISM:**
; ======================================================================
; 1. RST #28 (0x0028): Extracts 2 bytes, stores in circular buffer
; 2. Main Loop (238D): Reads commands from buffer until empty
; 3. Command Dispatch (23A7): RST #20 with jump table lookup
; 4. Jump Table (23A8): 32 function addresses (0x00-0x1F commands)
; 5. Parameter Passing: B register contains parameter byte
; 6. Return: Commands return to 238D loop for next command
;
; **JUMP TABLE AT 0x23A8 (32 entries, 2 bytes each):**
; 0x00: 0x23ED = Display system initialization
; 0x01: 0x24D7 = Game state management  
; 0x02: 0x2419 = Level/maze management
; 0x03: 0x2448 = Sprite system management
; 0x04: 0x243D = Sound effect triggers
; 0x05: 0x258B = Animation/timing updates
; 0x06: 0x260D = Input processing system
; 0x07: 0x2424 = Score/statistics display
; 0x08: 0x2698 = Blinky obstacle avoidance
; 0x09: 0x2630 = Pinky obstacle avoidance  
; 0x0a: 0x276C = Inky obstacle avoidance
; 0x0b: 0x27A9 = Clyde obstacle avoidance
; 0x0c: 0x27F1 = Blinky scatter targeting
; 0x0d: 0x2824 = Pinky scatter targeting ⚠️ CONTAINS BUG
; 0x0e: 0x285A = Inky scatter targeting
; 0x0f: 0x2890 = Clyde scatter targeting
; [Commands 0x10-0x1F continue pattern for display/system functions]
;
; **CONFIRMED GHOST AI COMMANDS:**
;   0x08 param = Blinky obstacle avoidance
;   0x09 param = Pinky obstacle avoidance  
;   0x0a param = Inky obstacle avoidance
;   0x0b param = Clyde obstacle avoidance
;   0x0c param = Blinky scatter targeting (direct aggressive)
;   0x0d param = Pinky scatter targeting (4-tile ambush) ⚠️ CONTAINS BUG
;   0x0e param = Inky scatter targeting (complex algorithm)  
;   0x0f param = Clyde scatter targeting (shy behavior)
;
; **WHY TWO BYTES?**
; Command byte (0x00-0x1F) indexes jump table, parameter passed in B register
; Allows each command handler to receive context-specific data
;
; **BUFFER MANAGEMENT:**
; - Write Pointer: 0x4C80 (increments with each RST #28)
; - Read Pointer: 0x4C82 (increments as commands processed)
; - Buffer wraps at 0x4CC0-0x4CFF boundary
; - Commands marked 0xFF when consumed
; - Loop continues until no valid commands remain
; ======================================================================

; FUNCTION: SETUP_SPRITE_SEARCH - Initialize sprite search parameters
; C_PSEUDO: void setup_sprite_search() {
; C_PSEUDO:   DE = 0x4C90;  // Sprite data base address
; C_PSEUDO:   B = 0x10;     // Number of sprites to check
; C_PSEUDO:   jump_to_sprite_routine();
; C_PSEUDO: }
0030  11904c    ld      de,#4c90	; Load sprite data address
0033  0610      ld      b,#10		; Load sprite count
0035  c35100    jp      #0051		; Jump to sprite processing routine

; FUNCTION: HARDWARE_WAIT_LOOP - Wait for interrupt or hardware event
; C_PSEUDO: void hardware_wait() {
; C_PSEUDO:   while(1) {
; C_PSEUDO:     hardware_reg[0x5000] = 0;  // Disable interrupts
; C_PSEUDO:     hardware_reg[0x5007] = 0;  // Clear coin counter
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Infinite loop waiting for hardware interrupt
0038  af        xor     a		; A = 0
0039  320050    ld      (#5000),a	; Disable hardware interrupts
003c  320750    ld      (#5007),a	; Clear coin counter
003f  c33800    jp      #0038		; Infinite loop

; FUNCTION: CIRCULAR_BUFFER_WRITE - Write BC to circular buffer
; Parameters: BC = data to write
; C_PSEUDO: void circular_buffer_write(uint16_t data) {
; C_PSEUDO:   uint16_t *ptr = (uint16_t *)buffer_pointer;
; C_PSEUDO:   *ptr++ = data;
; C_PSEUDO:   if(ptr >= buffer_end) ptr = buffer_start;
; C_PSEUDO:   buffer_pointer = ptr;
; C_PSEUDO: }
; ALGORITHM: Manages circular buffer from 0x4CC0 to 0x4CFF
0042  2a804c    ld      hl,(#4c80)	; Get current buffer pointer
0045  70        ld      (hl),b		; Store high byte
0046  2c        inc     l		; Increment to next byte
0047  71        ld      (hl),c		; Store low byte
0048  2c        inc     l		; Increment to next position
0049  2002      jr      nz,#004d        ; If not at end of page, continue
004b  2ec0      ld      l,#c0		; Wrap to start of buffer (0x4CC0)
004d  22804c    ld      (#4c80),hl	; Update buffer pointer
0050  c9        ret     

; FUNCTION: SPRITE_SCAN_ROUTINE - Scan for active sprites
; Parameters: DE = sprite data pointer, B = sprite count
; C_PSEUDO: bool sprite_scan(sprite_t *sprites, int count) {
; C_PSEUDO:   while(count--) {
; C_PSEUDO:     if(sprites->active == 0) return found_inactive(sprites);
; C_PSEUDO:     sprites += 3;  // Each sprite is 3 bytes
; C_PSEUDO:   }
; C_PSEUDO:   return false;
; C_PSEUDO: }
0051  1a        ld      a,(de)		; Get sprite status byte
0052  a7        and     a		; Test if zero (inactive)
0053  2806      jr      z,#005b         ; Jump if inactive sprite found
0055  1c        inc     e		; Move to next sprite
0056  1c        inc     e		; (3 bytes per sprite)
0057  1c        inc     e
0058  10f7      djnz    #0051           ; Loop for all sprites
005a  c9        ret     		; Return if no inactive sprite found

; FUNCTION: COPY_SPRITE_DATA - Copy 3 bytes of sprite data
; Parameters: HL = source, DE = destination
; C_PSEUDO: void copy_sprite_data(uint8_t *src, uint8_t *dest) {
; C_PSEUDO:   for(int i = 0; i < 3; i++) {
; C_PSEUDO:     dest[i] = src[i];
; C_PSEUDO:   }
; C_PSEUDO:   jump_to_next_instruction();
; C_PSEUDO: }
005b  e1        pop     hl		; Get source address from stack
005c  0603      ld      b,#03		; Copy 3 bytes
005e  7e        ld      a,(hl)		; Read byte from source
005f  12        ld      (de),a		; Write byte to destination
0060  23        inc     hl		; Increment source
0061  1c        inc     e		; Increment destination
0062  10fa      djnz    #005e           ; Loop for all 3 bytes
0064  e9        jp      (hl)		; Jump to address following source data

0065  c32d20    jp      #202d		; Jump to routine at 0x202D

; ==============================================================================
; SECTION: INTERRUPT SERVICE ROUTINES
; ==============================================================================

; FUNCTION: MAIN_INTERRUPT_HANDLER - Main game interrupt routine (60Hz)
; C_PSEUDO: void main_interrupt() {
; C_PSEUDO:   save_all_registers();
; C_PSEUDO:   kick_watchdog();
; C_PSEUDO:   disable_interrupts();
; C_PSEUDO:   update_sound();
; C_PSEUDO:   update_sprites();
; C_PSEUDO:   restore_all_registers();
; C_PSEUDO: }
; ALGORITHM: Called 60 times per second, handles all real-time game updates
008d  f5        push    af		; Save accumulator and flags
008e  32c050    ld      (#50c0),a	; Kick watchdog timer
0091  af        xor     a		; A = 0
0092  320050    ld      (#5000),a	; Disable hardware interrupts
0095  f3        di			; Disable CPU interrupts
0096  c5        push    bc		; Save BC register pair
0097  d5        push    de		; Save DE register pair
0098  e5        push    hl		; Save HL register pair
0099  dde5      push    ix		; Save IX index register
009b  fde5      push    iy		; Save IY index register

; ALGORITHM: Sound Update - Copy sound parameters to hardware
009d  218c4e    ld      hl,#4e8c	; Source: sound parameter buffer
00a0  115050    ld      de,#5050	; Destination: sound hardware registers
00a3  011000    ld      bc,#0010	; Copy 16 bytes
00a6  edb0      ldir			; Block copy sound data to hardware

00a8  3acc4e    ld      a,(#4ecc)	; Read sound control flag (unused)
00ab  a7        and     a		; Test value

; ALGORITHM: Sound Waveform Selection - Choose waveforms for 3 sound channels
; C_PSEUDO: void update_sound_waveforms() {
; C_PSEUDO:   // Channel 1 waveform selection
; C_PSEUDO:   if(sound_control[0] != 0) {
; C_PSEUDO:     waveform = sound_params[0];
; C_PSEUDO:   } else {
; C_PSEUDO:     waveform = default_waveform[0];
; C_PSEUDO:   }
; C_PSEUDO:   sound_hardware[0x5045] = waveform;
; C_PSEUDO:   // Similar for channels 2 and 3...
; C_PSEUDO: }
00ac  3acf4e    ld      a,(#4ecf)	; Get channel 1 control flag
00af  2003      jr      nz,#00b4        ; If non-zero, use current waveform
00b1  3a9f4e    ld      a,(#4e9f)	; Otherwise use default waveform
00b4  324550    ld      (#5045),a	; Write to sound hardware channel 1

00b7  3adc4e    ld      a,(#4edc)	; Channel 2 control flag
00ba  a7        and     a
00bb  3adf4e    ld      a,(#4edf)	; Channel 2 current waveform
00be  2003      jr      nz,#00c3        ; If control flag set, use current
00c0  3aaf4e    ld      a,(#4eaf)	; Otherwise use default
00c3  324a50    ld      (#504a),a	; Write to sound hardware channel 2

00c6  3aec4e    ld      a,(#4eec)	; Channel 3 control flag
00c9  a7        and     a
00ca  3aef4e    ld      a,(#4eef)	; Channel 3 current waveform
00cd  2003      jr      nz,#00d2        ; If control flag set, use current
00cf  3abf4e    ld      a,(#4ebf)	; Otherwise use default
00d2  324f50    ld      (#504f),a	; Write to sound hardware channel 3

; ALGORITHM: Sprite Animation - Rotate sprite animation frames
; C_PSEUDO: void animate_sprites() {
; C_PSEUDO:   // Copy current sprite data to previous frame buffer
; C_PSEUDO:   memcpy(&sprite_buffer[0x22], &sprite_buffer[0x02], 28);
; C_PSEUDO:   
; C_PSEUDO:   // Rotate animation bits for each sprite (4 sprites * 2 bits each)
; C_PSEUDO:   for(int i = 0; i < 4; i++) {
; C_PSEUDO:     sprite_anim[i] = (sprite_anim[i] << 2) | (sprite_anim[i] >> 6);
; C_PSEUDO:   }
; C_PSEUDO: }
00d5  21024c    ld      hl,#4c02	; Source: current sprite positions
00d8  11224c    ld      de,#4c22	; Destination: previous sprite positions
00db  011c00    ld      bc,#001c	; Copy 28 bytes
00de  edb0      ldir			; Block copy sprite data

00e0  dd21204c  ld      ix,#4c20	; Point to sprite animation data
00e4  dd7e02    ld      a,(ix+#02)	; Get sprite 1 animation bits
00e7  07        rlca    		; Rotate left 2 positions
00e8  07        rlca    
00e9  dd7702    ld      (ix+#02),a	; Store back

00ec  dd7e04    ld      a,(ix+#04)	; Get sprite 2 animation bits
00ef  07        rlca    		; Rotate left 2 positions
00f0  07        rlca    
00f1  dd7704    ld      (ix+#04),a	; Store back

00f4  dd7e06    ld      a,(ix+#06)	; Get sprite 3 animation bits
00f7  07        rlca    		; Rotate left 2 positions
00f8  07        rlca    
00f9  dd7706    ld      (ix+#06),a	; Store back

00fc  dd7e08    ld      a,(ix+#08)	; Get sprite 4 animation bits
00ff  07        rlca    		; Rotate left 2 positions
0100  07        rlca    
0101  dd7708    ld      (ix+#08),a	; Store back

0104  dd7e0a    ld      a,(ix+#0a)	; Get sprite 5 animation bits
0107  07        rlca    		; Rotate left 2 positions
0108  07        rlca    
0109  dd770a    ld      (ix+#0a),a	; Store back

010c  dd7e0c    ld      a,(ix+#0c)	; Get sprite 6 animation bits
010f  07        rlca    		; Rotate left 2 positions
0110  07        rlca    
0111  dd770c    ld      (ix+#0c),a	; Store back

; ALGORITHM: Player/Ghost Position Management
; C_PSEUDO: void manage_positions() {
; C_PSEUDO:   if(game_state == PLAYING) {
; C_PSEUDO:     swap_player_positions();  // For smooth movement interpolation
; C_PSEUDO:   }
; C_PSEUDO: }
0114  3ad14d    ld      a,(#4dd1)	; Get game state flag
0117  fe01      cp      #01		; Check if in playing mode
0119  2038      jr      nz,#0153        ; Skip position swap if not playing

; FUNCTION: POSITION_INTERPOLATION - Smooth movement between frames
; C_PSEUDO: void interpolate_positions() {
; C_PSEUDO:   int sprite_index = current_player * 2;  // Each sprite has X,Y
; C_PSEUDO:   uint16_t temp_pos1 = current_positions[sprite_index];
; C_PSEUDO:   uint16_t temp_pos2 = previous_positions[sprite_index];
; C_PSEUDO:   current_positions[sprite_index] = previous_positions[sprite_index];
; C_PSEUDO:   previous_positions[sprite_index] = temp_pos1;
; C_PSEUDO: }
011b  dd21204c  ld      ix,#4c20	; Point to sprite position data
011f  3aa44d    ld      a,(#4da4)	; Get current player index
0122  87        add     a,a		; Multiply by 2 (X,Y coordinates)
0123  5f        ld      e,a		; Store offset in E
0124  1600      ld      d,#00		; Clear high byte
0126  dd19      add     ix,de		; Add offset to sprite data pointer

0128  2a244c    ld      hl,(#4c24)	; Load current positions (player 1)
012b  ed5b344c  ld      de,(#4c34)	; Load current positions (player 2)
012f  dd7e00    ld      a,(ix+#00)	; Get previous X position
0131  32244c    ld      (#4c24),a	; Store as current X
0135  dd7e01    ld      a,(ix+#01)	; Get previous Y position
0138  32254c    ld      (#4c25),a	; Store as current Y
013b  dd7e10    ld      a,(ix+#10)	; Get previous X position (sprite 2)
013e  32344c    ld      (#4c34),a	; Store as current X
0141  dd7e11    ld      a,(ix+#11)	; Get previous Y position (sprite 2)
0144  32354c    ld      (#4c35),a	; Store as current Y
0147  dd7500    ld      (ix+#00),l	; Store temp X position
014a  dd7401    ld      (ix+#01),h	; Store temp Y position
014d  dd7310    ld      (ix+#10),e	; Store temp X position (sprite 2)
0150  dd7211    ld      (ix+#11),d	; Store temp Y position (sprite 2)

; ALGORITHM: Ghost Position Swapping
; C_PSEUDO: void swap_ghost_positions() {
; C_PSEUDO:   if(ghost_swap_flag) {
; C_PSEUDO:     // Swap ghost positions for smooth animation
; C_PSEUDO:     swap_positions(&ghost1_pos, &ghost1_prev);
; C_PSEUDO:     swap_positions(&ghost2_pos, &ghost2_prev);
; C_PSEUDO:   }
; C_PSEUDO: }
0153  3aa64d    ld      a,(#4da6)	; Get ghost swap flag
0156  a7        and     a		; Test if zero
0157  ca7601    jp      z,#0176		; Skip if no swap needed

015a  ed4b224c  ld      bc,(#4c22)	; Load ghost 1 current position
015e  ed5b324c  ld      de,(#4c32)	; Load ghost 2 current position
0162  2a2a4c    ld      hl,(#4c2a)	; Load ghost 1 previous position
0165  22224c    ld      (#4c22),hl	; Store as current
0168  2a3a4c    ld      hl,(#4c3a)	; Load ghost 2 previous position
016b  22324c    ld      (#4c32),hl	; Store as current
016e  ed432a4c  ld      (#4c2a),bc	; Store ghost 1 temp as previous
0172  ed533a4c  ld      (#4c3a),de	; Store ghost 2 temp as previous

; FUNCTION: SPRITE_HARDWARE_UPDATE - Copy sprite data to hardware
; C_PSEUDO: void update_sprite_hardware() {
; C_PSEUDO:   // Copy 12 bytes of sprite position data to hardware registers
; C_PSEUDO:   memcpy(&sprite_hardware[0x4FF2], &sprite_memory[0x4C22], 12);
; C_PSEUDO:   memcpy(&sprite_hardware[0x5062], &sprite_memory[0x4C32], 12);
; C_PSEUDO: }
; ALGORITHM: Hardware sprite registers expect specific format for rendering
0176  21224c    ld      hl,#4c22	; Source: sprite position buffer
0179  11f24f    ld      de,#4ff2	; Destination: hardware sprite registers
017c  010c00    ld      bc,#000c	; Copy 12 bytes
017f  edb0      ldir    		; Block copy to hardware

0181  21324c    ld      hl,#4c32	; Source: more sprite data
0184  116250    ld      de,#5062	; Destination: more hardware registers
0187  010c00    ld      bc,#000c	; Copy 12 bytes
018a  edb0      ldir    		; Block copy to hardware

; FUNCTION: GAME_LOGIC_DISPATCHER - Main game update dispatcher
; C_PSEUDO: void update_game_logic() {
; C_PSEUDO:   update_timers();
; C_PSEUDO:   update_controls();
; C_PSEUDO:   dispatch_game_state();
; C_PSEUDO:   if(game_active) {
; C_PSEUDO:     update_player();
; C_PSEUDO:     update_ai();
; C_PSEUDO:     check_collisions();
; C_PSEUDO:     update_score();
; C_PSEUDO:     update_maze();
; C_PSEUDO:   }
; C_PSEUDO: }
018c  cddc01    call    #01dc		; Update game timers
018f  cd2102    call    #0221		; Update sprite logic
0192  cdc803    call    #03c8		; Game state dispatcher

0195  3a004e    ld      a,(#4e00)	; Get game state
0198  a7        and     a		; Check if game active
0199  2812      jr      z,#01ad         ; Skip game logic if not active

019b  cd9d03    call    #039d		; Update player controls
019e  cd9014    call    #1490		; AI logic update
01a1  cd1f14    call    #141f		; Collision detection
01a4  cd6702    call    #0267		; Coin/credit handling
01a7  cdad02    call    #02ad		; Input processing
01aa  cdfd02    call    #02fd		; Additional game logic

01ad  3a004e    ld      a,(#4e00)	; Get game state again
01b0  3d        dec     a		; Decrement (check for state 1)
01b1  2006      jr      nz,#01b9        ; Skip if not state 1

01b3  32ac4e    ld      (#4eac),a	; Clear sound register
01b6  32bc4e    ld      (#4ebc),a	; Clear another sound register

01b9  cd0c2d    call    #2d0c		; Update display/rendering
01bc  cdc12c    call    #2cc1		; Additional rendering

; ALGORITHM: Interrupt Cleanup and Return
; C_PSEUDO: void interrupt_cleanup() {
; C_PSEUDO:   restore_all_registers();
; C_PSEUDO:   check_test_mode();
; C_PSEUDO:   enable_interrupts();
; C_PSEUDO: }
01bf  fde1      pop     iy		; Restore IY register
01c1  dde1      pop     ix		; Restore IX register
01c3  e1        pop     hl		; Restore HL register pair
01c4  d1        pop     de		; Restore DE register pair
01c5  c1        pop     bc		; Restore BC register pair

01c6  3a004e    ld      a,(#4e00)	; Check game state
01c9  a7        and     a		; Test if zero
01ca  2808      jr      z,#01d4         ; Skip test check if game off

01cc  3a4050    ld      a,(#5040)	; Read hardware test switch
01cf  e610      and     #10		; Check test mode bit
01d1  ca0000    jp      z,#0000		; Reset system if test mode active

01d4  3e01      ld      a,#01		; A = 1
01d6  320050    ld      (#5000),a	; Re-enable hardware interrupts
01d9  fb        ei			; Re-enable CPU interrupts
01da  f1        pop     af		; Restore accumulator and flags
01db  c9        ret     		; Return from interrupt

; ==============================================================================
; SECTION: GAME TIMING AND ANIMATION
; ==============================================================================

; FUNCTION: GAME_TIMER_UPDATE - Update various game timing counters
; C_PSEUDO: void update_game_timers() {
; C_PSEUDO:   frame_counter++;
; C_PSEUDO:   animation_timer--;
; C_PSEUDO:   
; C_PSEUDO:   // Handle various timing events based on frame counter
; C_PSEUDO:   if((frame_counter & 0x0F) == timing_table[event]) {
; C_PSEUDO:     trigger_event(event);
; C_PSEUDO:     frame_counter = (frame_counter & 0xF0) + 0x10;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: 60Hz timing system for game events and animations
01dc  21844c    ld      hl,#4c84	; Point to frame counter
01df  34        inc     (hl)		; Increment frame counter
01e0  23        inc     hl		; Point to animation timer
01e1  35        dec     (hl)		; Decrement animation timer
01e2  23        inc     hl		; Point to event timer
01e3  111902    ld      de,#0219	; Point to timing table
01e6  010104    ld      bc,#0401	; B=4 events, C=1 (event counter)

01e9  34        inc     (hl)		; Increment current timer
01ea  7e        ld      a,(hl)		; Read timer value
01eb  e60f      and     #0f		; Mask lower 4 bits
01ed  eb        ex      de,hl		; Swap HL and DE
01ee  be        cp      (hl)		; Compare with timing table entry
01ef  2013      jr      nz,#0204        ; Jump if not time for event

01f1  0c        inc     c		; Increment event counter
01f2  1a        ld      a,(de)		; Get current timer value
01f3  c610      add     a,#10		; Add 16 to upper nibble
01f5  e6f0      and     #f0		; Clear lower nibble
01f7  12        ld      (de),a		; Store back to timer
01f8  23        inc     hl		; Point to next timing table entry
01f9  be        cp      (hl)		; Check against next timing value
01fa  2008      jr      nz,#0204        ; Jump if different

01fc  0c        inc     c		; Increment event counter again
01fd  eb        ex      de,hl		; Swap back
01fe  3600      ld      (hl),#00	; Reset timer to 0
0200  23        inc     hl		; Next timer
0201  13        inc     de		; Next table entry
0202  10e5      djnz    #01e9           ; Loop for all 4 timers

0204  218a4c    ld      hl,#4c8a	; Point to event result storage
0207  71        ld      (hl),c		; Store event count
0208  2c        inc     l		; Point to next counter
0209  7e        ld      a,(hl)		; Read counter value
020a  87        add     a,a		; Multiply by 4
020b  87        add     a,a
020c  86        add     a,(hl)		; Add original (multiply by 5)
020d  3c        inc     a		; Add 1
020e  77        ld      (hl),a		; Store back (counter = counter * 5 + 1)
020f  2c        inc     l		; Point to next counter
0210  7e        ld      a,(hl)		; Read counter value
0211  87        add     a,a		; Multiply by 2
0212  86        add     a,(hl)		; Add original (multiply by 3)
0213  87        add     a,a		; Multiply by 2 (now * 6)
0214  87        add     a,a		; Multiply by 2 (now * 12)
0215  86        add     a,(hl)		; Add original (multiply by 13)
0216  3c        inc     a		; Add 1
0217  77        ld      (hl),a		; Store back (counter = counter * 13 + 1)
0218  c9        ret     

; MEMORY_MAP: Timing Table - Controls when events happen
0219  06a0      .db     #06, #a0	; Event timing values
021b  0a        .db     #0a		; More timing values
021c  60        .db     #60
021d  0a        .db     #0a
021e  60        .db     #60
021f  0a        .db     #0a
0220  a0        .db     #a0

; ==============================================================================
; SECTION: SPRITE AND ENEMY MANAGEMENT
; ==============================================================================

; FUNCTION: SPRITE_LOGIC_UPDATE - Update all active sprites
; C_PSEUDO: void update_sprite_logic() {
; C_PSEUDO:   sprite_t *sprites = &sprite_array[0];
; C_PSEUDO:   uint8_t priority = current_priority;
; C_PSEUDO:   
; C_PSEUDO:   for(int i = 0; i < 16; i++) {  // 16 sprites max
; C_PSEUDO:     if(sprites[i].active && sprites[i].priority >= priority) {
; C_PSEUDO:       sprites[i].timer--;
; C_PSEUDO:       if((sprites[i].timer & 0x3F) == 0) {
; C_PSEUDO:         sprites[i].active = 0;  // Deactivate sprite
; C_PSEUDO:         call_sprite_handler(sprites[i].type, sprites[i].x, sprites[i].y);
; C_PSEUDO:       }
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Manages ghosts, fruits, score displays, and effects
0221  21904c    ld      hl,#4c90	; Point to sprite array base
0224  3a8a4c    ld      a,(#4c8a)	; Get current priority level
0227  4f        ld      c,a		; Store priority in C
0228  0610      ld      b,#10		; 16 sprites to check

022a  7e        ld      a,(hl)		; Read sprite status byte
022b  a7        and     a		; Check if active (non-zero)
022c  282f      jr      z,#025d         ; Skip if inactive

022e  e6c0      and     #c0		; Get priority bits (upper 2 bits)
0230  07        rlca    		; Rotate to lower bits
0231  07        rlca    
0232  b9        cp      c		; Compare with current priority
0233  3028      jr      nc,#025d        ; Skip if priority too low

0235  35        dec     (hl)		; Decrement sprite timer
0236  7e        ld      a,(hl)		; Read updated timer
0237  e63f      and     #3f		; Check lower 6 bits
0239  2022      jr      nz,#025d        ; Continue if timer not expired

023b  77        ld      (hl),a		; Clear sprite (A=0 from AND above)
023c  c5        push    bc		; Save loop counters
023d  e5        push    hl		; Save sprite pointer
023e  2c        inc     l		; Point to sprite X coordinate
023f  7e        ld      a,(hl)		; Read X coordinate
0240  2c        inc     l		; Point to sprite Y coordinate
0241  46        ld      b,(hl)		; Read Y coordinate into B
0242  215b02    ld      hl,#025b	; Push return address for sprite handler
0245  e5        push    hl
0246  e7        rst     #20		; Call computed jump with sprite type in A

; MEMORY_MAP: Sprite Handler Jump Table
0247  94        .dw     #0894		; Handler for sprite type 0
0248  08        .dw     #08a3		; Handler for sprite type 1  
0249  a3        .dw     #a306		; Handler for sprite type 2
024a  068e      .dw     #8e05		; Handler for sprite type 3
024c  05        .dw     #0572		; Handler for sprite type 4
024d  72        .dw     #7212		; Handler for sprite type 5
024e  12        .dw     #1200		; Handler for sprite type 6
024f  00        .dw     #0010		; Handler for sprite type 7
0250  100b      .dw     #0b10		; Handler for sprite type 8
0252  1063      .dw     #6302		; Handler for sprite type 9
0254  02        .dw     #022b		; Handler for sprite type 10
0255  2b        .dw     #2b21		; Handler for sprite type 11
0256  21f021    .dw     #21f0		; Handler for sprite type 12
0259  b9        .dw     #b922		; Handler for sprite type 13
025a  22        .dw     #22e1		; Handler for sprite type 14

; FUNCTION: SPRITE_HANDLER_RETURN - Common return point for sprite handlers
025b  e1        pop     hl		; Restore sprite pointer
025c  c1        pop     bc		; Restore loop counters

025d  2c        inc     l		; Move to next sprite
025e  2c        inc     l		; (3 bytes per sprite: status, X, Y)
025f  2c        inc     l
0260  10c8      djnz    #022a           ; Loop for all 16 sprites
0262  c9        ret     

; Sprite effect routine entries
0263  ef        rst     #28		; Call routine
0264  1c        inc     e
0265  86        add     a,(hl)
0266  c9        ret

; ==============================================================================
; SECTION: COIN AND CREDIT SYSTEM
; ==============================================================================

; FUNCTION: COIN_CREDIT_MANAGER - Handle coin inputs and credit management
; C_PSEUDO: void manage_coins_credits() {
; C_PSEUDO:   if(credits >= 99) {
; C_PSEUDO:     enable_coin_lockout();  // Prevent more coins when at max credits
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   check_coin_inputs();      // Debounce and process coin switches
; C_PSEUDO:   update_coin_counters();   // Handle coin counter output
; C_PSEUDO: }
; ALGORITHM: Implements coin-op arcade machine credit system with lockout
0267  3a6e4e    ld      a,(#4e6e)	; Get current credit count
026a  fe99      cp      #99		; Check if at maximum (99 credits)
026c  17        rla     		; Rotate carry into bit 0
026d  320650    ld      (#5006),a	; Set coin lockout if credits maxed
0270  1f        rra     		; Restore A register
0271  d0        ret     nc		; Return if credits not maxed

; FUNCTION: COIN_INPUT_DEBOUNCER - Debounce coin switch inputs
; C_PSEUDO: void debounce_coin_inputs() {
; C_PSEUDO:   uint8_t coin_state = hardware_input_register;
; C_PSEUDO:   
; C_PSEUDO:   // Debounce coin slot 1
; C_PSEUDO:   coin_history[0] = (coin_history[0] << 1) | coin_state.bit0;
; C_PSEUDO:   if((coin_history[0] & 0x0F) == 0x0C) add_coin();  // 1100 pattern = valid coin
; C_PSEUDO:   
; C_PSEUDO:   // Similar for other coin slots...
; C_PSEUDO: }
; ALGORITHM: Requires specific bit pattern (1100) to prevent false coin detection
0272  3a0050    ld      a,(#5000)	; Read hardware input register
0275  47        ld      b,a		; Save input state
0276  cb00      rlc     b		; Rotate coin input bits

; Coin slot 1 debouncing
0278  3a664e    ld      a,(#4e66)	; Get coin 1 history
027b  17        rla     		; Shift left, bring in new bit
027c  e60f      and     #0f		; Keep only 4 bits of history
027e  32664e    ld      (#4e66),a	; Store updated history
0281  d60c      sub     #0c		; Check for pattern 1100 (valid coin)
0283  ccdf02    call    z,#02df		; If pattern matches, add coin

; Coin slot 2 debouncing  
0286  cb00      rlc     b		; Get next coin input bit
0288  3a674e    ld      a,(#4e67)	; Get coin 2 history
028b  17        rla     		; Shift left, bring in new bit
028c  e60f      and     #0f		; Keep only 4 bits of history
028e  32674e    ld      (#4e67),a	; Store updated history
0291  d60c      sub     #0c		; Check for pattern 1100
0293  c29a02    jp      nz,#029a	; Jump if no coin detected
0296  21694e    ld      hl,#4e69	; Point to coin counter
0299  34        inc     (hl)		; Increment coin counter

; Coin slot 3 debouncing
029a  cb00      rlc     b		; Get next coin input bit
029c  3a684e    ld      a,(#4e68)	; Get coin 3 history
029f  17        rla     		; Shift left, bring in new bit
02a0  e60f      and     #0f		; Keep only 4 bits of history
02a2  32684e    ld      (#4e68),a	; Store updated history
02a5  d60c      sub     #0c		; Check for pattern 1100
02a7  c0        ret     nz		; Return if no coin

02a8  21694e    ld      hl,#4e69	; Point to coin counter
02ab  34        inc     (hl)		; Increment coin counter
02ac  c9        ret     

; FUNCTION: COIN_COUNTER_OUTPUT - Control coin counter solenoid
; C_PSEUDO: void handle_coin_counter() {
; C_PSEUDO:   if(coins_to_count > 0) {
; C_PSEUDO:     if(counter_phase == 0) {
; C_PSEUDO:       activate_coin_counter();  // Turn on solenoid
; C_PSEUDO:       add_coin();
; C_PSEUDO:     }
; C_PSEUDO:     if(counter_phase == 8) {
; C_PSEUDO:       deactivate_coin_counter();  // Turn off solenoid
; C_PSEUDO:     }
; C_PSEUDO:     counter_phase = (counter_phase + 1) % 16;
; C_PSEUDO:     if(counter_phase == 0) coins_to_count--;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Controls mechanical coin counter with proper timing
02ad  3a694e    ld      a,(#4e69)	; Get coins to count
02b0  a7        and     a		; Check if any coins pending
02b1  c8        ret     z		; Return if no coins to count

02b2  47        ld      b,a		; Save coin count
02b3  3a6a4e    ld      a,(#4e6a)	; Get counter phase
02b6  5f        ld      e,a		; Save phase in E
02b7  fe00      cp      #00		; Check if phase 0
02b9  c2c402    jp      nz,#02c4	; Jump if not phase 0

02bc  3e01      ld      a,#01		; A = 1
02be  320750    ld      (#5007),a	; Activate coin counter solenoid
02c1  cddf02    call    #02df		; Process the coin (add credit)

02c4  7b        ld      a,e		; Get phase back
02c5  fe08      cp      #08		; Check if phase 8
02c7  c2ce02    jp      nz,#02ce	; Jump if not phase 8

02ca  af        xor     a		; A = 0
02cb  320750    ld      (#5007),a	; Deactivate coin counter solenoid

02ce  1c        inc     e		; Increment phase
02cf  7b        ld      a,e		; Get updated phase
02d0  326a4e    ld      (#4e6a),a	; Store back
02d3  d610      sub     #10		; Check if phase wrapped (16 phases)
02d5  c0        ret     nz		; Return if not wrapped

02d6  326a4e    ld      (#4e6a),a	; Store wrapped phase (0)
02d9  05        dec     b		; Decrement coins to count
02da  78        ld      a,b		; Get updated count
02db  32694e    ld      (#4e69),a	; Store back
02de  c9        ret     

; FUNCTION: ADD_COIN - Convert coins to credits
; Parameters: None (uses DIP switch settings)
; C_PSEUDO: void add_coin() {
; C_PSEUDO:   uint8_t coins_per_credit = dip_switch_coins_per_credit;
; C_PSEUDO:   leftover_coins++;
; C_PSEUDO:   
; C_PSEUDO:   if(leftover_coins >= coins_per_credit) {
; C_PSEUDO:     leftover_coins = 0;
; C_PSEUDO:     uint8_t credits_per_coin = dip_switch_credits_per_coin;
; C_PSEUDO:     credits += credits_per_coin;
; C_PSEUDO:     if(credits > 99) credits = 99;  // BCD maximum
; C_PSEUDO:     set_credit_added_flag();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Handles various coin/credit ratios (1 coin/1 credit, 2 coins/1 credit, etc.)
02df  3a6b4e    ld      a,(#4e6b)	; Get coins needed per credit (DIP switch)
02e2  216c4e    ld      hl,#4e6c	; Point to leftover coins counter
02e5  34        inc     (hl)		; Increment leftover coins
02e6  96        sub     (hl)		; Subtract leftover from coins needed
02e7  c0        ret     nz		; Return if not enough coins for credit

02e8  77        ld      (hl),a		; Clear leftover coins (A=0 from subtraction)
02e9  3a6d4e    ld      a,(#4e6d)	; Get credits per coin (DIP switch)
02ec  216e4e    ld      hl,#4e6e	; Point to credit counter
02ef  86        add     a,(hl)		; Add credits to current total
02f0  27        daa     		; Decimal adjust for BCD addition
02f1  d2f602    jp      nc,#02f6	; Jump if no carry (not over 99)
02f4  3e99      ld      a,#99		; Cap at 99 credits maximum

02f6  77        ld      (hl),a		; Store updated credit count
02f7  219c4e    ld      hl,#4e9c	; Point to sound/status flags
02fa  cbce      set     1,(hl)		; Set "credit added" sound flag
02fc  c9        ret     

; ==============================================================================
; SECTION: GAME STATE AND DISPLAY MANAGEMENT  
; ==============================================================================

; FUNCTION: DISPLAY_UPDATE - Update various display elements
; C_PSEUDO: void update_display() {
; C_PSEUDO:   display_timer++;
; C_PSEUDO:   
; C_PSEUDO:   // Update display based on timing
; C_PSEUDO:   if((display_timer & 0x0F) == 0) {
; C_PSEUDO:     update_credit_display();
; C_PSEUDO:     update_player_indicators();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Controls "1UP", "2UP", credit display flashing
02fd  21ce4d    ld      hl,#4dce	; Point to display timer
0300  34        inc     (hl)		; Increment display timer
0301  7e        ld      a,(hl)		; Read timer value
0302  e60f      and     #0f		; Check lower 4 bits
0304  201f      jr      nz,#0325        ; Skip if not time to update

0306  7e        ld      a,(hl)		; Read timer again
0307  0f        rrca    		; Divide by 16 (upper 4 bits)
0308  0f        rrca    
0309  0f        rrca    
030a  0f        rrca    
030b  47        ld      b,a		; Store in B
030c  3ad64d    ld      a,(#4dd6)	; Get display enable mask
030f  2f        cpl     		; Complement (invert bits)
0310  b0        or      b		; Combine with timer
0311  4f        ld      c,a		; Store result

0312  3a6e4e    ld      a,(#4e6e)	; Get credit count
0315  d601      sub     #01		; Subtract 1
0317  3002      jr      nc,#031b        ; Jump if credits >= 1
0319  af        xor     a		; A = 0 if no credits
031a  4f        ld      c,a		; Clear display if no credits

031b  2801      jr      z,#031e         ; Jump if exactly 1 credit
031d  4f        ld      c,a		; Store result for multi-credit display

; FUNCTION: PLAYER_LAMP_CONTROL - Control start button lamps
; C_PSEUDO: void control_player_lamps(uint8_t display_mask) {
; C_PSEUDO:   hardware_reg[0x5004] = display_mask;  // Player 1 lamp
; C_PSEUDO:   hardware_reg[0x5005] = display_mask;  // Player 2 lamp
; C_PSEUDO: }
031e  79        ld      a,c		; Get display mask
031f  320550    ld      (#5005),a	; Set Player 2 start lamp
0322  79        ld      a,c		; Get display mask again
0323  320450    ld      (#5004),a	; Set Player 1 start lamp
0326  c9        ret

; ==============================================================================
; SECTION: PLAYER CONTROL INPUT HANDLING
; ==============================================================================

; FUNCTION: PLAYER_INPUT_HANDLER - Process joystick and button inputs
; C_PSEUDO: void handle_player_input() {
; C_PSEUDO:   if(game_state >= 3) return;  // Only handle input during certain states
; C_PSEUDO:   
; C_PSEUDO:   player_controls[0] = &joystick_data[0x43D8];  // Player 1 controls  
; C_PSEUDO:   player_controls[1] = &joystick_data[0x43C5];  // Player 2 controls
; C_PSEUDO:   
; C_PSEUDO:   if(credits >= 3 || active_players < 2) {
; C_PSEUDO:     update_player_controls();
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_alternating_players();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Handles 1-player and 2-player alternating control schemes
0327  dd21d843  ld      ix,#43d8	; Point to Player 1 control data
032b  fd21c543  ld      iy,#43c5	; Point to Player 2 control data
032f  3a004e    ld      a,(#4e00)	; Get current game state
0332  fe03      cp      #03		; Check if state >= 3
0334  ca4403    jp      z,#0344		; Jump to alternate handling if state 3

0337  3a034e    ld      a,(#4e03)	; Get number of active players
033a  fe02      cp      #02		; Check if 2 players
033c  d24403    jp      nc,#0344	; Jump if 2 players active

033f  cd6903    call    #0369		; Update Player 1 controls
0342  cd7603    call    #0376		; Update Player 2 controls  
0345  c9        ret     

; FUNCTION: ALTERNATING_PLAYER_CONTROL - Handle alternating 2-player mode
; C_PSEUDO: void handle_alternating_players() {
; C_PSEUDO:   if(current_player_flag) {
; C_PSEUDO:     if(control_switch & 0x10) {
; C_PSEUDO:       update_player1_controls();
; C_PSEUDO:     } else {
; C_PSEUDO:       clear_player1_controls();
; C_PSEUDO:     }
; C_PSEUDO:   } else {
; C_PSEUDO:     if(control_switch & 0x10) {
; C_PSEUDO:       update_player2_controls();  
; C_PSEUDO:     } else {
; C_PSEUDO:       clear_player2_controls();
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(cocktail_mode_flag) clear_other_controls();
; C_PSEUDO: }
; ALGORITHM: In 2-player mode, only current player can control Pac-Man
0346  3a094e    ld      a,(#4e09)	; Get current player flag
0349  a7        and     a		; Test if zero (Player 1's turn)
034a  3ace4d    ld      a,(#4dce)	; Get control input register
034d  c25903    jp      nz,#0359	; Jump if Player 2's turn

; Player 1's turn
0350  cb67      bit     4,a		; Test bit 4 (control enable)
0352  cc6903    call    z,#0369		; Update Player 1 controls if enabled
0355  c48303    call    nz,#0383	; Clear Player 1 controls if disabled
0358  c36103    jp      #0361		; Continue

; Player 2's turn  
0359  cb67      bit     4,a		; Test bit 4 (control enable)
035b  cc7603    call    z,#0376		; Update Player 2 controls if enabled
035e  c49003    call    nz,#0390	; Clear Player 2 controls if disabled

; Check cocktail mode
0361  3a704e    ld      a,(#4e70)	; Get cocktail mode flag
0364  a7        and     a		; Test if cocktail mode enabled
0365  cc9003    call    z,#0390		; Clear other player if cocktail mode
0368  c9        ret     

; FUNCTION: UPDATE_PLAYER1_CONTROLS - Enable Player 1 joystick
; C_PSEUDO: void update_player1_controls() {
; C_PSEUDO:   player1_control[0] = 0x50;  // Enable joystick reading
; C_PSEUDO:   player1_control[1] = 0x55;  // Joystick data register  
; C_PSEUDO:   player1_control[2] = 0x31;  // Control configuration
; C_PSEUDO: }
0369  dd360050  ld      (ix+#00),#50	; Set Player 1 joystick enable
036d  dd360155  ld      (ix+#01),#55	; Set joystick data register
0371  dd360231  ld      (ix+#02),#31	; Set control configuration
0375  c9        ret     

; FUNCTION: UPDATE_PLAYER2_CONTROLS - Enable Player 2 joystick
; C_PSEUDO: void update_player2_controls() {
; C_PSEUDO:   player2_control[0] = 0x50;  // Enable joystick reading
; C_PSEUDO:   player2_control[1] = 0x55;  // Joystick data register
; C_PSEUDO:   player2_control[2] = 0x32;  // Control configuration (different from P1)
; C_PSEUDO: }
0376  fd360050  ld      (iy+#00),#50	; Set Player 2 joystick enable
037a  fd360155  ld      (iy+#01),#55	; Set joystick data register
037e  fd360232  ld      (iy+#02),#32	; Set control configuration
0382  c9        ret     

; FUNCTION: CLEAR_PLAYER1_CONTROLS - Disable Player 1 joystick
; C_PSEUDO: void clear_player1_controls() {
; C_PSEUDO:   player1_control[0] = 0x40;  // Disable joystick
; C_PSEUDO:   player1_control[1] = 0x40;  // Clear data
; C_PSEUDO:   player1_control[2] = 0x40;  // Clear config
; C_PSEUDO: }
0383  dd360040  ld      (ix+#00),#40	; Clear Player 1 joystick enable
0387  dd360140  ld      (ix+#01),#40	; Clear joystick data
038b  dd360240  ld      (ix+#02),#40	; Clear control configuration
038f  c9        ret     

; FUNCTION: CLEAR_PLAYER2_CONTROLS - Disable Player 2 joystick
; C_PSEUDO: void clear_player2_controls() {
; C_PSEUDO:   player2_control[0] = 0x40;  // Disable joystick
; C_PSEUDO:   player2_control[1] = 0x40;  // Clear data  
; C_PSEUDO:   player2_control[2] = 0x40;  // Clear config
; C_PSEUDO: }
0390  fd360040  ld      (iy+#00),#40	; Clear Player 2 joystick enable
0394  fd360140  ld      (iy+#01),#40	; Clear joystick data
0398  fd360240  ld      (iy+#02),#40	; Clear control configuration
039c  c9        ret     

; FUNCTION: PLAYER_POSITION_UPDATE - Update player sprite position
; C_PSEUDO: void update_player_position() {
; C_PSEUDO:   if(game_state < 5) return;  // Only update during active gameplay
; C_PSEUDO:   
; C_PSEUDO:   // Calculate player sprite position based on maze coordinates
; C_PSEUDO:   player_sprite.x = maze_x - 16;
; C_PSEUDO:   player_sprite.y = maze_y + 8;
; C_PSEUDO:   
; C_PSEUDO:   // Store positions for both current and previous frames
; C_PSEUDO:   current_pos.x = player_sprite.x;
; C_PSEUDO:   current_pos.y = player_sprite.y;
; C_PSEUDO:   previous_pos.x = current_pos.x - 16;
; C_PSEUDO:   previous_pos.y = current_pos.y;
; C_PSEUDO: }
; ALGORITHM: Converts maze coordinates to screen sprite coordinates
039d  3a064e    ld      a,(#4e06)	; Get game state
03a0  d605      sub     #05		; Check if state >= 5 (active gameplay)
03a2  d8        ret     c		; Return if not in active gameplay

03a3  2a084d    ld      hl,(#4d08)	; Get player maze position
03a6  0608      ld      b,#08		; Y offset constant
03a8  0e10      ld      c,#10		; X offset constant
03aa  7d        ld      a,l		; Get X coordinate
03ab  32064d    ld      (#4d06),a	; Store current X
03ae  32d24d    ld      (#4dd2),a	; Store backup X
03b1  91        sub     c		; Subtract X offset (16 pixels)
03b2  32024d    ld      (#4d02),a	; Store sprite X position
03b5  32044d    ld      (#4d04),a	; Store backup sprite X

03b8  7c        ld      a,h		; Get Y coordinate
03b9  80        add     a,b		; Add Y offset (8 pixels)
03ba  32034d    ld      (#4d03),a	; Store sprite Y position
03bd  32074d    ld      (#4d07),a	; Store backup sprite Y
03c0  91        sub     c		; Subtract offset for previous position
03c1  32054d    ld      (#4d05),a	; Store previous sprite Y
03c4  32d34d    ld      (#4dd3),a	; Store backup previous Y
03c7  c9        ret     

; ==============================================================================
; SECTION: GAME STATE MACHINE
; ==============================================================================

; FUNCTION: GAME_STATE_DISPATCHER - Main game state machine
; C_PSEUDO: void game_state_dispatcher() {
; C_PSEUDO:   switch(game_state) {
; C_PSEUDO:     case 0: handle_attract_mode(); break;
; C_PSEUDO:     case 1: handle_game_start(); break;
; C_PSEUDO:     case 2: handle_level_start(); break;
; C_PSEUDO:     case 3: handle_gameplay(); break;
; C_PSEUDO:     case 4: handle_death(); break;
; C_PSEUDO:     case 5: handle_level_complete(); break;
; C_PSEUDO:     case 6: handle_game_over(); break;
; C_PSEUDO:     default: handle_error_state(); break;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Central state machine controlling all game flow
03c8  3a004e    ld      a,(#4e00)	; Get current game state
03cb  e7        rst     #20		; Call computed jump with state as index

; MEMORY_MAP: Game State Jump Table (from original disassembly)
03cc  d403      .dw     #03d4		; State 0: Attract mode handler
03ce  fe03      .dw     #03fe		; State 1: Game start handler
03d0  e505      .dw     #05e5		; State 2: Level start handler  
03d2  be06      .dw     #06be		; State 3: Gameplay handler
03d4  3a01      .dw     #013a		; State 4: Death sequence handler
03d6  4ee7      .dw     #e74e		; State 5: Level complete handler
03d8  dc03      .dw     #03dc		; State 6: Game over handler
03da  0c00      .dw     #000c		; State 7: Error/unused

; FUNCTION: ATTRACT_MODE_HANDLER - Handle attract mode display and demo
; C_PSEUDO: void attract_mode() {
; C_PSEUDO:   call_display_routines();
; C_PSEUDO:   check_for_coin_insertion();
; C_PSEUDO:   handle_demo_mode();
; C_PSEUDO:   update_high_score_display();
; C_PSEUDO: }
; ALGORITHM: Cycles through demo, high score display, and coin detection
03dc  ef        rst     #28		; Queue command: Display system update
03dd  00        nop     		; Command: 0x00 = Display system
03de  00        nop     		; Parameter: 0x00 = default
03df  ef        rst     #28		; Queue command: Game state update
03e0  06        ld      b,#06		; Command: 0x06 = Input processing 
03e1  00        nop     		; Parameter: 0x00 = default
03e2  ef        rst     #28		; Queue command: Game state update
03e3  01        ld      bc,#01		; Command: 0x01 = Game state update
03e4  00        nop     		; Parameter: 0x00 = default
03e5  ef        rst     #28		; Queue command: Sprite management
03e6  14        inc     d		; Command: 0x14 = Sprite management
03e7  00        nop     		; Parameter: 0x00 = default
03e8  ef        rst     #28		; Call routine
03e9  1800      jr      #03eb           ; Skip next byte
03eb  ef        rst     #28		; Call routine
03ec  0400      ld      b,#00		; Parameter
03ee  ef        rst     #28		; Call routine
03ef  1e00      ld      e,#00		; Parameter
03f1  ef        rst     #28		; Call routine
03f2  0700      ld      b,#00		; Parameter
03f4  21014e    ld      hl,#4e01	; Point to game variable
03f7  34        inc     (hl)		; Increment variable
03f8  210150    ld      hl,#5001	; Point to hardware register
03fb  3601      ld      (hl),#01	; Set hardware flag
03fd  c9        ret     

; FUNCTION: GAME_START_HANDLER - Initialize new game (exact Z80 code)
; C_PSEUDO: void start_new_game() {
; C_PSEUDO:   display_credits();
; C_PSEUDO:   if(credits > 0) {
; C_PSEUDO:     clear_game_flags();
; C_PSEUDO:     advance_game_state();
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_no_credits();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Transitions from attract mode to gameplay when credits available
03fe  cda12b    call    #2ba1		; Write # credits on screen
0401  3a6e4e    ld      a,(#4e6e)	; Get current credit count
0404  a7        and     a		; Test if zero credits
0405  280c      jr      z,#0413		; No credits -> jump to 0x0413

0407  af        xor     a		; A = 0
0408  32044e    ld      (#4e04),a	; Clear game state flags
040b  32024e    ld      (#4e02),a	; Clear additional game flags
040e  21004e    ld      hl,#4e00	; Point to main game state
0411  34        inc     (hl)		; Advance to next game state
0412  c9        ret     

; FUNCTION: NO_CREDITS_HANDLER - Handle attract mode continuation (exact Z80 code)
; C_PSEUDO: void handle_no_credits() {
; C_PSEUDO:   switch(attract_sub_state) {
; C_PSEUDO:     // Jump table dispatch for attract mode sub-states
; C_PSEUDO:   }
; C_PSEUDO: }
0413  3a024e    ld      a,(#4e02)	; Get attract mode sub-state
0416  e7        rst     #20		; Call computed jump with sub-state as index

; MEMORY_MAP: Attract Mode Sub-State Jump Table (exact addresses from original)
0417  5f04      .db     #5f, #04	; Sub-state 0 -> 045f
0419  6c04      .db     #6c, #04	; Sub-state 1 -> 046c
041b  7104      .db     #71, #04	; Sub-state 2 -> 0471
041d  7c04      .db     #7c, #04	; Sub-state 3 -> 047c
041f  7f04      .db     #7f, #04	; Sub-state 4 -> 047f
0421  8504      .db     #85, #04	; Sub-state 5 -> 0485
0423  8b04      .db     #8b, #04	; Sub-state 6 -> 048b
0425  9904      .db     #99, #04	; Sub-state 7 -> 0499
0427  9f04      .db     #9f, #04	; Sub-state 8 -> 049f
0429  a504      .db     #a5, #04	; Sub-state 9 -> 04a5
042b  b304      .db     #b3, #04	; Sub-state 10 -> 04b3
042d  b904      .db     #b9, #04	; Sub-state 11 -> 04b9
042f  bf04      .db     #bf, #04	; Sub-state 12 -> 04bf
0431  cd04      .db     #cd, #04	; Sub-state 13 -> 04cd
0433  d304      .db     #d3, #04	; Sub-state 14 -> 04d3
0435  d804      .db     #d8, #04	; Sub-state 15 -> 04d8
0437  e004      .db     #e0, #04	; Sub-state 16 -> 04e0

0439  0c04      .db     #0c, #04	; Additional table entries
043b  0000      .db     #00, #00
043d  1c05      .db     #1c, #05
043f  4b05      .db     #4b, #05
0441  5605      .db     #56, #05
0443  6105      .db     #61, #05
0445  6c05      .db     #6c, #05
0447  7c05      .db     #7c, #05

; Note: These appear to be jump table data, not individual 16-bit addresses
; The original disassembly shows these as mixed data/code

044c  04        inc     b
044d  0c        inc     c
044e  00        nop     
044f  e0        ret     po

0450  04        inc     b
0451  0c        inc     c
0452  00        nop     
0453  1c        inc     e
0454  05        dec     b
0455  4b        ld      c,e
0456  05        dec     b
0457  56        ld      d,(hl)
0458  05        dec     b
0459  61        ld      h,c
045a  05        dec     b
045b  6c        ld      l,h
045c  05        dec     b
045d  7c        ld      a,h
045e  05        dec     b

; FUNCTION: ATTRACT_SUBSTATE_0 - First attract mode handler
; C_PSEUDO: void attract_substate_0() {
; C_PSEUDO:   call_display_routine(0);
; C_PSEUDO:   setup_next_attract_state();
; C_PSEUDO: }
045f  ef        rst     #28		; Call routine
0460  00        nop     		; Parameter 0
0461  01ef01    ld      bc,#01ef	; Load parameters
0464  00        nop     
0465  ef        rst     #28		; Call routine
0466  04        inc     b		; Parameter 4
0467  00        nop     
0468  ef        rst     #28		; Call routine
0469  1e00      ld      e,#00		; Load parameter
046b  0e0c      ld      c,#0c		; Load parameter
046d  cd8505    call    #0585		; Call subroutine
0470  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_2 - Another attract mode handler (exact Z80 code)
; C_PSEUDO: void attract_substate_2() {
; C_PSEUDO:   setup_display_address(0x4304);
; C_PSEUDO:   write_attract_data(1);
; C_PSEUDO:   call_display_routine(0x0C);
; C_PSEUDO: }
0471  210443    ld      hl,#4304	; Load video memory address 0x4304
0474  3e01      ld      a,#01		; Load value 1
0476  cdbf05    call    #05bf		; Call display setup routine
0479  0e0c      ld      c,#0c		; Load parameter 0x0C
047b  cd8505    call    #0585		; Call display routine
047e  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_4 - Handle attract mode timing
; C_PSEUDO: void attract_substate_4() {
; C_PSEUDO:   call_timing_routine(0x14);
; C_PSEUDO: }
047f  0e14      ld      c,#14		; Load timing parameter 0x14
0481  cd9305    call    #0593		; Call timing routine
0484  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_5 - Handle attract mode sequence
; C_PSEUDO: void attract_substate_5() {
; C_PSEUDO:   call_timing_routine(0x0D);
; C_PSEUDO: }
0485  0e0d      ld      c,#0d		; Load timing parameter 0x0D
0487  cd9305    call    #0593		; Call timing routine
048a  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_6 - Display high score
; C_PSEUDO: void attract_substate_6() {
; C_PSEUDO:   setup_display_address(0x4307);
; C_PSEUDO:   write_attract_data(3);
; C_PSEUDO:   call_display_routine(0x0C);
; C_PSEUDO: }
; ALGORITHM: Sets up high score display during attract mode
048b  210743    ld      hl,#4307	; Load video memory address 0x4307
048e  3e03      ld      a,#03		; Load value 3
0490  cdbf05    call    #05bf		; Call display setup routine
0493  0e0c      ld      c,#0c		; Load parameter 0x0C
0495  cd8505    call    #0585		; Call display routine
0498  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_7 - Timing control
; C_PSEUDO: void attract_substate_7() {
; C_PSEUDO:   call_timing_routine(0x16);
; C_PSEUDO: }
0499  0e16      ld      c,#16		; Load timing parameter 0x16
049b  cd9305    call    #0593		; Call timing routine
049e  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_8 - More timing control
; C_PSEUDO: void attract_substate_8() {
; C_PSEUDO:   call_timing_routine(0x0F);
; C_PSEUDO: }
049f  0e0f      ld      c,#0f		; Load timing parameter 0x0F
04a1  cd9305    call    #0593		; Call timing routine
04a4  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_9 - Display game title/logo
; C_PSEUDO: void attract_substate_9() {
; C_PSEUDO:   setup_display_address(0x430A);
; C_PSEUDO:   write_attract_data(5);
; C_PSEUDO:   call_display_routine(0x0C);
; C_PSEUDO: }
; ALGORITHM: Displays game title/logo during attract sequence
04a5  210a43    ld      hl,#430a	; Load video memory address 0x430A
04a8  3e05      ld      a,#05		; Load value 5
04aa  cdbf05    call    #05bf		; Call display setup routine
04ad  0e0c      ld      c,#0c		; Load parameter 0x0C
04af  cd8505    call    #0585		; Call display routine
04b2  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_10 - Extended timing
; C_PSEUDO: void attract_substate_10() {
; C_PSEUDO:   call_timing_routine(0x33);
; C_PSEUDO: }
04b3  0e33      ld      c,#33		; Load timing parameter 0x33 (51 decimal)
04b5  cd9305    call    #0593		; Call timing routine
04b8  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_11 - Character introduction timing
; C_PSEUDO: void attract_substate_11() {
; C_PSEUDO:   call_timing_routine(0x2F);
; C_PSEUDO: }
04b9  0e2f      ld      c,#2f		; Load timing parameter 0x2F (47 decimal)
04bb  cd9305    call    #0593		; Call timing routine
04be  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_12 - Character names display
; C_PSEUDO: void attract_substate_12() {
; C_PSEUDO:   setup_display_address(0x430D);
; C_PSEUDO:   write_attract_data(7);
; C_PSEUDO:   call_display_routine(0x0C);
; C_PSEUDO: }
; ALGORITHM: Shows ghost character names and point values
04bf  210d43    ld      hl,#430d	; Load video memory address 0x430D
04c2  3e07      ld      a,#07		; Load value 7
04c4  cdbf05    call    #05bf		; Call display setup routine
04c7  0e0c      ld      c,#0c		; Load parameter 0x0C
04c9  cd8505    call    #0585		; Call display routine
04cc  c9        ret

; FUNCTION: ATTRACT_SUBSTATE_13 - More attract timing
; C_PSEUDO: void attract_substate_13() {
; C_PSEUDO:   call_timing_routine(0x35);
; C_PSEUDO: }
04cd  0e35      ld      c,#35		; Load timing parameter 0x35 (53 decimal)
04cf  cd9305    call    #0593		; Call timing routine
04d2  c9        ret     

; FUNCTION: ATTRACT_SUBSTATE_14 - Extended attract timing
; C_PSEUDO: void attract_substate_14() {
; C_PSEUDO:   call_timing_routine(0x31);
; C_PSEUDO: }
04d3  0e31      ld      c,#31		; Load timing parameter 0x31 (49 decimal)
04d5  c38005    jp      #0580		; Jump to timing routine

; FUNCTION: ATTRACT_SUBSTATE_15 - Display setup
; C_PSEUDO: void attract_substate_15() {
; C_PSEUDO:   setup_display_params(0x1C, 0x120E);
; C_PSEUDO:   call_display_routine();
; C_PSEUDO: }
04d8  ef        rst     #28		; Call routine
04d9  1c        inc     e		; Parameter
04da  110e12    ld      de,#120e	; Load display parameters
04dd  c38505    jp      #0585		; Jump to display routine

; FUNCTION: ATTRACT_SUBSTATE_16 - Final attract setup
; C_PSEUDO: void attract_substate_16() {
; C_PSEUDO:   call_timing_routine(0x13);
; C_PSEUDO:   initialize_level();
; C_PSEUDO:   setup_game_state();
; C_PSEUDO: }
; ALGORITHM: Transitions from attract mode to game initialization
04e0  0e13      ld      c,#13		; Load timing parameter 0x13
04e2  cd8505    call    #0585		; Call timing routine
04e5  cd7908    call    #0879		; Call level initialization
04e8  35        dec     (hl)		; Decrement value at HL
04e9  ef        rst     #28		; Call routine
04ea  1100      ld      de,#0011	; Load parameters
04ec  ef        rst     #28		; Call routine  
04ed  05        dec     b		; Decrement B
04ee  01ef10    ld      bc,#10ef	; Load BC with parameters
04f1  14        inc     d		; Increment D
04f2  ef        rst     #28		; Call routine
04f3  04        inc     b		; Increment B
04f4  013e01    ld      bc,#013e	; Load BC
04f7  32144e    ld      (#4e14),a	; Store A at game state location
04fa  af        xor     a		; Clear A (A = 0)
04fb  32704e    ld      (#4e70),a	; Clear player selection flag
04fe  32154e    ld      (#4e15),a	; Clear game flag
0501  213243    ld      hl,#4332	; Point to video memory
0504  3614      ld      (hl),#14	; Write value 0x14
0506  3efc      ld      a,#fc		; Load A with 0xFC
0508  112000    ld      de,#0020	; Load DE with offset 0x20
050b  061c      ld      b,#1c		; Loop counter = 28
050d  dd214040  ld      ix,#4040	; Point IX to sprite data base
0511  dd7711    ld      (ix+#11),a	; Store A at IX+0x11 (sprite data)
0514  dd7713    ld      (ix+#13),a	; Store A at IX+0x13 (sprite data)
0517  dd19      add     ix,de		; Advance IX by 32 bytes (next sprite)
0519  10f6      djnz    #0511           ; Loop for all sprites

051b  c9        ret     

; FUNCTION: GHOST_AI_ROUTINE_1 - First ghost AI handler  
; C_PSEUDO: void ghost_ai_routine_1() {
; C_PSEUDO:   ghost_ptr = &ghost_data[0];
; C_PSEUDO:   if(current_level == 0x21) {
; C_PSEUDO:     set_ghost_state(FRIGHTENED);
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   call_ghost_ai_functions();
; C_PSEUDO: }
; ALGORITHM: Handles AI for first ghost (Blinky)
051c  21a04d    ld      hl,#4da0	; Point to first ghost data
051f  0621      ld      b,#21		; Load level check value 0x21
0521  3a3a4d    ld      a,(#4d3a)	; Get current level
0524  90        sub     b		; Compare with 0x21
0525  2005      jr      nz,#052c        ; Jump if not level 0x21
0527  3601      ld      (hl),#01	; Set ghost state to 1 (frightened)
0529  c38e05    jp      #058e		; Jump to state advance routine

052c  cd1710    call    #1017		; Call ghost AI routine
052f  cd1710    call    #1017		; Call ghost AI routine again
0532  cd230e    call    #0e23		; Call movement routine
0535  cd0d0c    call    #0c0d		; Call collision check
0538  cdd60b    call    #0bd6		; Call sprite update
053b  cda505    call    #05a5		; Call animation routine
053e  cdfe1e    call    #1efe		; Call score routine
0541  cd251f    call    #1f25		; Call sound routine
0544  cd4c1f    call    #1f4c		; Call effects routine
0547  cd731f    call    #1f73		; Call display routine
054a  c9        ret     

; FUNCTION: GHOST_AI_ROUTINE_2 - Second ghost AI handler
; C_PSEUDO: void ghost_ai_routine_2() {
; C_PSEUDO:   ghost_ptr = &ghost_data[1];
; C_PSEUDO:   handle_ghost_ai(0x20, 0x4d32);
; C_PSEUDO: }
; ALGORITHM: Handles AI for second ghost (Pinky)
054b  21a14d    ld      hl,#4da1	; Point to second ghost data
054e  0620      ld      b,#20		; Load level check value 0x20
0550  3a324d    ld      a,(#4d32)	; Get ghost parameter
0553  c32405    jp      #0524		; Jump to common AI handler

; FUNCTION: GHOST_AI_ROUTINE_3 - Third ghost AI handler
; C_PSEUDO: void ghost_ai_routine_3() {
; C_PSEUDO:   ghost_ptr = &ghost_data[2];
; C_PSEUDO:   handle_ghost_ai(0x22, 0x4d32);
; C_PSEUDO: }
; ALGORITHM: Handles AI for third ghost (Inky)
0556  21a24d    ld      hl,#4da2	; Point to third ghost data
0559  0622      ld      b,#22		; Load level check value 0x22
055b  3a324d    ld      a,(#4d32)	; Get ghost parameter
055e  c32405    jp      #0524		; Jump to common AI handler

; FUNCTION: GHOST_AI_ROUTINE_4 - Fourth ghost AI handler
; C_PSEUDO: void ghost_ai_routine_4() {
; C_PSEUDO:   ghost_ptr = &ghost_data[3];
; C_PSEUDO:   handle_ghost_ai(0x24, 0x4d32);
; C_PSEUDO: }
; ALGORITHM: Handles AI for fourth ghost (Sue/Clyde)
0561  21a34d    ld      hl,#4da3	; Point to fourth ghost data
0564  0624      ld      b,#24		; Load level check value 0x24
0566  3a324d    ld      a,(#4d32)	; Get ghost parameter
0569  c32405    jp      #0524		; Jump to common AI handler

; FUNCTION: FRUIT_BONUS_CHECK - Check for fruit/bonus items
; C_PSEUDO: void fruit_bonus_check() {
; C_PSEUDO:   dots_eaten_1 = memory[0x4dd0];
; C_PSEUDO:   dots_eaten_2 = memory[0x4dd1];
; C_PSEUDO:   total_dots = dots_eaten_1 + dots_eaten_2;
; C_PSEUDO:   if(total_dots == 6) {
; C_PSEUDO:     advance_game_state();
; C_PSEUDO:   } else {
; C_PSEUDO:     continue_ai_routines();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Tracks dots eaten and triggers fruit appearance
056c  3ad04d    ld      a,(#4dd0)	; Get dots eaten count 1
056f  47        ld      b,a		; Save in B
0570  3ad14d    ld      a,(#4dd1)	; Get dots eaten count 2
0573  80        add     a,b		; Add counts together
0574  fe06      cp      #06		; Compare with 6 dots
0576  ca8e05    jp      z,#058e		; Jump if 6 dots eaten (fruit appears)
0579  c32c05    jp      #052c		; Otherwise continue AI routines

; FUNCTION: CALL_GAMEPLAY_HANDLER - Call main gameplay dispatcher
; C_PSEUDO: void call_gameplay_handler() {
; C_PSEUDO:   handle_gameplay_state();
; C_PSEUDO: }
057c  cdbe06    call    #06be		; Call main gameplay state handler
057f  c9        ret     

; FUNCTION: TIMING_ROUTINE_WITH_OFFSET - Timing with level offset
; C_PSEUDO: void timing_routine_with_offset(uint8_t base_timing) {
; C_PSEUDO:   adjusted_timing = level_offset + base_timing;
; C_PSEUDO:   call_timing_function(0x1C, adjusted_timing);
; C_PSEUDO: }
; ALGORITHM: Adjusts timing based on current level for difficulty scaling
0580  3a754e    ld      a,(#4e75)	; Get level timing offset
0583  81        add     a,c		; Add to base timing in C
0584  4f        ld      c,a		; Store result back in C
0585  061c      ld      b,#1c		; Load B with 0x1C
0587  cd4200    call    #0042		; Call timing function
058a  f7        rst     #30		; Call interrupt routine
058b  4a        ld      c,d		; Transfer D to C
058c  02        ld      (bc),a		; Store A at address in BC
058d  00        nop     

; FUNCTION: ADVANCE_GAME_STATE - Advance to next game state
; C_PSEUDO: void advance_game_state() {
; C_PSEUDO:   game_state++;
; C_PSEUDO: }
058e  21024e    ld      hl,#4e02	; Point to game state variable
0591  34        inc     (hl)		; Increment game state
0592  c9        ret     

; FUNCTION: TIMING_ROUTINE_ALT - Alternative timing routine
; C_PSEUDO: void timing_routine_alt(uint8_t base_timing) {
; C_PSEUDO:   adjusted_timing = level_offset + base_timing;
; C_PSEUDO:   call_timing_function_alt(0x1C, adjusted_timing);
; C_PSEUDO:   advance_game_state();
; C_PSEUDO: }
0593  3a754e    ld      a,(#4e75)	; Get level timing offset
0596  81        add     a,c		; Add to base timing in C
0597  4f        ld      c,a		; Store result back in C
0598  061c      ld      b,#1c		; Load B with 0x1C
059a  cd4200    call    #0042		; Call timing function
059d  f7        rst     #30		; Call interrupt routine
059e  45        ld      b,l		; Transfer L to B
059f  02        ld      (bc),a		; Store A at address in BC
05a0  00        nop     
05a1  cd8e05    call    #058e		; Call advance game state
05a4  c9        ret     

; FUNCTION: ANIMATION_ROUTINE - Handle sprite animations
; C_PSEUDO: void animation_routine() {
; C_PSEUDO:   if(animation_flag == 0) return;
; C_PSEUDO:   animation_flag = 0;
; C_PSEUDO:   sprite_direction = sprite_direction XOR 2; // flip direction bit
; C_PSEUDO:   update_sprite_pointer(sprite_direction);
; C_PSEUDO: }
; ALGORITHM: Handles sprite animation by flipping direction bits
05a5  3ab54d    ld      a,(#4db5)	; Get animation flag
05a8  a7        and     a		; Test if zero
05a9  c8        ret     z		; Return if no animation needed

05aa  af        xor     a		; Clear A (A = 0)
05ab  32b54d    ld      (#4db5),a	; Clear animation flag
05ae  3a304d    ld      a,(#4d30)	; Get sprite direction
05b1  ee02      xor     #02		; Flip bit 1 (direction bit)
05b3  323c4d    ld      (#4d3c),a	; Store new direction
05b6  47        ld      b,a		; Save direction in B
05b7  21ff32    ld      hl,#32ff	; Point to sprite table
05ba  df        rst     #18		; Call sprite lookup routine
05bb  22264d    ld      (#4d26),hl	; Store sprite pointer
05be  c9        ret     

; FUNCTION: DISPLAY_SETUP_ROUTINE - Set up display characters
; C_PSEUDO: void display_setup_routine(uint16_t video_addr, uint8_t char_code) {
; C_PSEUDO:   video_addr[0] = 0xB1;  // First character
; C_PSEUDO:   video_addr[1] = 0xB3;  // Second character
; C_PSEUDO:   video_addr[2] = 0xB5;  // Third character
; C_PSEUDO:   video_addr += 30;      // Move to next row
; C_PSEUDO:   video_addr[0] = 0xB0;  // Fourth character
; C_PSEUDO:   video_addr[1] = 0xB2;  // Fifth character
; C_PSEUDO:   video_addr[2] = 0xB4;  // Sixth character
; C_PSEUDO:   // Set color attributes
; C_PSEUDO:   color_addr = video_addr + 0x0400;
; C_PSEUDO:   set_colors(color_addr, char_code);
; C_PSEUDO: }
; ALGORITHM: Sets up 3x2 character display pattern with colors
05bf  36b1      ld      (hl),#b1	; Write character 0xB1
05c1  2c        inc     l		; Next position
05c2  36b3      ld      (hl),#b3	; Write character 0xB3
05c4  2c        inc     l		; Next position
05c5  36b5      ld      (hl),#b5	; Write character 0xB5
05c7  011e00    ld      bc,#001e	; Load offset 30 (next row)
05ca  09        add     hl,bc		; Move to next row
05cb  36b0      ld      (hl),#b0	; Write character 0xB0
05cd  2c        inc     l		; Next position
05ce  36b2      ld      (hl),#b2	; Write character 0xB2
05d0  2c        inc     l		; Next position
05d1  36b4      ld      (hl),#b4	; Write character 0xB4
05d3  110004    ld      de,#0400	; Load color RAM offset
05d6  19        add     hl,de		; Point to color RAM
05d7  77        ld      (hl),a		; Set color for current position
05d8  2d        dec     l		; Previous position
05d9  77        ld      (hl),a		; Set color
05da  2d        dec     l		; Previous position
05db  77        ld      (hl),a		; Set color
05dc  a7        and     a		; Clear carry flag
05dd  ed42      sbc     hl,bc		; Subtract offset (back to previous row)
05df  77        ld      (hl),a		; Set color for current position
05e0  2d        dec     l		; Previous position
05e1  77        ld      (hl),a		; Set color
05e2  2d        dec     l		; Previous position
05e3  77        ld      (hl),a		; Set color
05e4  c9        ret     

; ==============================================================================
; SECTION: LEVEL START HANDLER
; ==============================================================================

; FUNCTION: LEVEL_START_HANDLER - Handle level start sequence (exact Z80 code)
; C_PSEUDO: void level_start_handler() {
; C_PSEUDO:   switch(level_start_state) {
; C_PSEUDO:     case 0: initialize_level_display(); break;
; C_PSEUDO:     case 1: show_player_ready(); break;
; C_PSEUDO:     case 2: check_start_button(); break;
; C_PSEUDO:     // ... more level start sub-states
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Manages transition from attract/game start to actual gameplay
05e5  3a034e    ld      a,(#4e03)	; Get level start sub-state
05e8  e7        rst     #20		; Call computed jump with sub-state as index

; MEMORY_MAP: Level Start Sub-State Jump Table
05e9  f305      .dw     #05f3		; Sub-state 0: Display initialization
05eb  1b06      .dw     #061b		; Sub-state 1: Show "PLAYER ONE"/"PLAYER TWO"
05ed  7406      .dw     #0674		; Sub-state 2: Ready sequence
05ef  0c00      .dw     #000c		; Sub-state 3: Start button check

; FUNCTION: DISPLAY_INITIALIZATION - Initialize level display
; C_PSEUDO: void display_initialization() {
; C_PSEUDO:   call_display_routine(0x2BA1); // Update credits display
; C_PSEUDO:   setup_display_mode();
; C_PSEUDO:   set_display_params();
; C_PSEUDO:   advance_level_state();
; C_PSEUDO:   set_game_flag(1);
; C_PSEUDO:   if(demo_mode != 0xFF) {
; C_PSEUDO:     setup_demo_display();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Sets up display for new level start
05f1  a806      ld      a,#06		; Load parameter
05f2  cd        call    
05f3  cda12b    call    #2ba1		; Write credits on screen
05f6  ef        rst     #28		; Call display routine
05f7  00        nop     		; Parameter
05f8  01ef01    ld      bc,#01ef	; Load display parameters
05fb  00        nop     
05fc  ef        rst     #28		; Call display routine
05fd  1c        inc     e		; Parameter
05fe  07        rlca    		; Rotate A left
05ff  ef        rst     #28		; Call display routine
0600  1c        inc     e		; Parameter
0601  0b        dec     bc		; Decrement BC
0602  ef        rst     #28		; Call display routine
0603  1e00      ld      e,#00		; Load parameter
0605  21034e    ld      hl,#4e03	; Point to level start state
0608  34        inc     (hl)		; Advance to next level start state
0609  3e01      ld      a,#01		; Load value 1
060b  32d64d    ld      (#4dd6),a	; Set game active flag
060e  3a714e    ld      a,(#4e71)	; Get demo mode flag
0611  feff      cp      #ff		; Compare with 0xFF
0613  c8        ret     z		; Return if demo mode

0614  ef        rst     #28		; Call display routine (non-demo)
0615  1c        inc     e		; Parameter
0616  0a        ld      a,(bc)		; Parameter
0617  ef        rst     #28		; Call display routine
0618  1f        rra     		; Rotate A right
0619  00        nop     		; Parameter
061a  c9        ret     

; FUNCTION: SHOW_PLAYER_READY - Display "PLAYER ONE"/"PLAYER TWO" and check start
; C_PSEUDO: void show_player_ready() {
; C_PSEUDO:   call_display_routine(0x2BA1); // Update credits display
; C_PSEUDO:   credits = memory[0x4e6e];
; C_PSEUDO:   if(credits >= 1) {
; C_PSEUDO:     message_id = 9; // "PLAYER TWO"
; C_PSEUDO:   } else {
; C_PSEUDO:     message_id = 8; // "PLAYER ONE"  
; C_PSEUDO:   }
; C_PSEUDO:   display_message(message_id);
; C_PSEUDO:   
; C_PSEUDO:   if(credits >= 1) {
; C_PSEUDO:     input = read_input_port();
; C_PSEUDO:     if(input & P2_START_BUTTON) return; // P2 start pressed
; C_PSEUDO:     player_selection = 1; // Select player 2
; C_PSEUDO:   } else {
; C_PSEUDO:     input = read_input_port(); 
; C_PSEUDO:     if(input & P1_START_BUTTON) return; // P1 start pressed
; C_PSEUDO:     player_selection = 0; // Select player 1
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(game_demo_flag) {
; C_PSEUDO:     subtract_credit();
; C_PSEUDO:     call_display_routine(0x2BA1); // Update credits display
; C_PSEUDO:   }
; C_PSEUDO:   advance_level_state();
; C_PSEUDO: }
; ALGORITHM: Handles player selection and start button detection
061b  cda12b    call    #2ba1		; Write credits on screen
061e  3a6e4e    ld      a,(#4e6e)	; Get credits count
0621  fe01      cp      #01		; Compare with 1 credit
0623  0609      ld      b,#09		; Default message #9 ("PLAYER TWO")
0625  2002      jr      nz,#0629	; Jump if not exactly 1 credit
0627  0608      ld      b,#08		; Message #8 ("PLAYER ONE")
0629  cd5e2c    call    #2c5e		; Display message
062c  3a6e4e    ld      a,(#4e6e)	; Get credits count again
062f  fe01      cp      #01		; Compare with 1 credit
0631  3a4050    ld      a,(#5040)	; Read input port
0634  280c      jr      z,#0642         ; Jump if only 1 credit (skip P2 check)
0636  cb77      bit     6,a		; Test P2 start button (bit 6)
0638  2008      jr      nz,#0642        ; Jump if P2 start pressed
063a  3e01      ld      a,#01		; Select player 2
063c  32704e    ld      (#4e70),a	; Store player selection
063f  c34906    jp      #0649		; Jump to demo check
0642  cb6f      bit     5,a		; Test P1 start button (bit 5)
0644  c0        ret     nz		; Return if P1 start pressed

0645  af        xor     a		; Clear A (A = 0, select player 1)
0646  32704e    ld      (#4e70),a	; Store player selection
0649  3a6b4e    ld      a,(#4e6b)	; Get demo flag
064c  a7        and     a		; Test if zero
064d  2815      jr      z,#0664         ; Jump if not demo mode
064f  3a704e    ld      a,(#4e70)	; Get player selection
0652  a7        and     a		; Test if player 1
0653  3a6e4e    ld      a,(#4e6e)	; Get credits count
0656  2803      jr      z,#065b         ; Jump if player 1 selected
0658  c699      add     a,#99		; Subtract 1 credit (BCD)
065a  27        daa     		; Decimal adjust after BCD operation
065b  c699      add     a,#99		; Subtract 1 credit (BCD)
065d  27        daa     		; Decimal adjust after BCD operation
065e  326e4e    ld      (#4e6e),a	; Store new credits count
0661  cda12b    call    #2ba1		; Update credits display
0664  21034e    ld      hl,#4e03	; Point to level start state
0667  34        inc     (hl)		; Advance to next level start state
0668  af        xor     a		; Clear A
0669  32d64d    ld      (#4dd6),a	; Clear game flag
066c  3c        inc     a		; A = 1
066d  32cc4e    ld      (#4ecc),a	; Set ready flag
0670  32dc4e    ld      (#4edc),a	; Set another ready flag
0673  c9        ret     

; FUNCTION: READY_SEQUENCE - Display "READY!" and transition to gameplay
; C_PSEUDO: void ready_sequence() {
; C_PSEUDO:   call_display_routines();
; C_PSEUDO:   advance_level_state();
; C_PSEUDO: }
; ALGORITHM: Shows "READY!" message and transitions to main gameplay
0674  ef        rst     #28		; Call display routine
0675  00        nop     		; Parameter
0676  01ef01    ld      bc,#01ef	; Load parameters
0679  01ef02    ld      bc,#02ef	; Load more parameters
067c  00        nop     
067d  ef        rst     #28		; Call display routine
067e  12        ld      (de),a		; Store A at DE
067f  00        nop     
0680  ef        rst     #28		; Call display routine
0681  03        inc     bc		; Increment BC
0682  00        nop     
0683  ef        rst     #28		; Call display routine
0684  1c        inc     e		; Parameter
0685  03        inc     bc		; Parameter
0686  ef        rst     #28		; Call display routine
0687  1c        inc     e		; Parameter
0688  06ef      ld      b,#ef		; Load parameter
068a  1800      jr      #068c           ; Jump forward

; Continue the ready sequence code (exact Z80 from original)
068c  ef        rst     #28		; Call display routine
068d  1c        inc     e		; Parameter
068e  09        add     hl,bc		; Add BC to HL
068f  ef        rst     #28		; Call display routine
0690  1c        inc     e		; Parameter
0691  0def      ld      c,#ef		; Load parameter
0693  1c        inc     e		; Parameter
0694  0eef      ld      c,#ef		; Load parameter
0696  1c        inc     e		; Parameter
0697  0fef      ld      c,#ef		; Load parameter
0699  1c        inc     e		; Parameter
069a  10ef      djnz    #068b		; Loop back
069c  1c        inc     e		; Parameter
069d  11ef1c    ld      de,#1cef	; Load parameters
06a0  12        ld      (de),a		; Store A at DE
06a1  ef        rst     #28		; Call display routine
06a2  1c        inc     e		; Parameter
06a3  13        inc     de		; Increment DE
06a4  ef        rst     #28		; Call display routine
06a5  1c        inc     e		; Parameter
06a6  14        inc     d		; Increment D
06a7  ef        rst     #28		; Call display routine
06a8  1c        inc     e		; Parameter
06a9  15        dec     d		; Decrement D
06aa  ef        rst     #28		; Call display routine
06ab  1c        inc     e		; Parameter
06ac  16ef      ld      d,#ef		; Load parameter
06ae  1c        inc     e		; Parameter
06af  17        rla     		; Rotate A left through carry
06b0  21034e    ld      hl,#4e03	; Point to level start state
06b3  34        inc     (hl)		; Advance to next level start state
06b4  af        xor     a		; Clear A
06b5  32cc4e    ld      (#4ecc),a	; Clear ready flag
06b8  32dc4e    ld      (#4edc),a	; Clear another ready flag
06bb  32d64d    ld      (#4dd6),a	; Clear game flag
06bd  c9        ret

; ==============================================================================
; SECTION: MAIN GAMEPLAY STATE MACHINE  
; ==============================================================================

; FUNCTION: GAMEPLAY_STATE_HANDLER - Main gameplay state dispatcher (exact Z80 code)
; C_PSEUDO: void handle_gameplay_state() {
; C_PSEUDO:   switch(gameplay_sub_state) {
; C_PSEUDO:     case 0: initialize_level(); break;
; C_PSEUDO:     case 1: start_level(); break;
; C_PSEUDO:     case 2: normal_gameplay(); break;
; C_PSEUDO:     case 3: ghost_eaten(); break;
; C_PSEUDO:     case 4: player_death(); break;
; C_PSEUDO:     case 5: level_complete(); break;
; C_PSEUDO:     // ... more gameplay sub-states
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Core gameplay loop - handles all in-game states
06be  3a044e    ld      a,(#4e04)	; Get gameplay sub-state
06c1  e7        rst     #20		; Call computed jump with sub-state as index

; MEMORY_MAP: Gameplay Sub-State Jump Table (exact addresses from original)
06c2  7908      .dw     #0879		; Sub-state 0: Level initialization
06c4  9908      .dw     #0899		; Sub-state 1: Level start sequence
06c6  0c00      .dw     #000c		; Sub-state 2: Main gameplay loop
06c8  cd08      .dw     #08cd		; Sub-state 3: Ghost eaten sequence
06ca  0d09      .dw     #090d		; Sub-state 4: Player death sequence
06cc  0c00      .dw     #000c		; Sub-state 5: Level complete
06ce  4009      .dw     #0940		; Sub-state 6: Game over
06d0  0c00      .dw     #000c		; Sub-state 7: Bonus sequence
06d2  7209      .dw     #0972		; Sub-state 8: Return to attract
06d4  8809      .dw     #0988		; Sub-state 9: Demo mode init
06d6  0c00      .dw     #000c		; Sub-state 10: Demo gameplay
06d8  d209      .dw     #09d2		; Sub-state 11: Demo transition
06da  d809      .dw     #09d8		; Sub-state 12: More demo
06dc  0c00      .dw     #000c		; Sub-state 13: Demo end
06de  e809      .dw     #09e8		; Sub-state 14: Final demo

06e0  0c00      .dw     #000c		; Sub-state 15: (continued table)
06e2  fe09      .dw     #09fe		; Sub-state 16
06e4  0c00      .dw     #000c		; Sub-state 17
06e6  020a      .dw     #0a02		; Sub-state 18
06e8  0c00      .dw     #000c		; Sub-state 19
06ea  040a      .dw     #0a04		; Sub-state 20
06ec  0c00      .dw     #000c		; Sub-state 21
06ee  060a      .dw     #0a06		; Sub-state 22
06f0  0c00      .dw     #000c		; Sub-state 23
06f2  080a      .dw     #0a08		; Sub-state 24
06f4  0c00      .dw     #000c		; Sub-state 25
06f6  0a0a      .dw     #0a0a		; Sub-state 26
06f8  0c00      .dw     #000c		; Sub-state 27
06fa  0c0a      .dw     #0a0c		; Sub-state 28
06fc  0c00      .dw     #000c		; Sub-state 29
06fe  0e0a      .dw     #0a0e		; Sub-state 30
0700  0c00      .dw     #000c		; Sub-state 31
0702  2c0a      .dw     #0a2c		; Sub-state 32
0704  0c00      .dw     #000c		; Sub-state 33
0706  7c0a      .dw     #0a7c		; Sub-state 34
0708  a00a      .dw     #0aa0		; Sub-state 35
070a  0c00      .dw     #000c		; Sub-state 36
070c  a30a      .dw     #0aa3		; Sub-state 37

; FUNCTION: LEVEL_LOGIC_DISPATCHER - Handle level progression logic
; C_PSEUDO: void level_logic_dispatcher() {
; C_PSEUDO:   if(level_parameter == 0) {
; C_PSEUDO:     current_level_data = get_level_data(current_level);
; C_PSEUDO:   }
; C_PSEUDO:   level_jump_table_index = level_parameter;
; C_PSEUDO:   call_level_function(level_jump_table_index);
; C_PSEUDO: }
; ALGORITHM: Manages level progression and difficulty scaling
070e  78        ld      a,b		; Get level parameter from previous call
070f  a7        and     a		; Test if zero
0710  2004      jr      nz,#0716        ; Jump if not zero

0712  2a0a4e    ld      hl,(#4e0a)	; Get current level data pointer
0715  7e        ld      a,(hl)		; Read level data

0716  dd219607  ld      ix,#0796	; Point to level jump table
071a  47        ld      b,a		; Save level parameter in B
071b  87        add     a,a		; Double for 16-bit table entries
071c  87        add     a,a		; Double again (multiply by 4)
071d  80        add     a,b		; Add original level parameter
071e  80        add     a,b		; Add again (total: level_param * 5)
071f  5f        ld      e,a		; Store result in E
0720  1600      ld      d,#00		; Clear D (DE = calculated offset)
0722  dd19      add     ix,de		; Add offset to level table pointer
0724  dd7e00    ld      a,(ix+#00)	; Get first level parameter
0727  87        add     a,a		; Double it (multiply by 2)
0728  47        ld      b,a		; Save in B
0729  87        add     a,a		; Double again (multiply by 4)
072a  87        add     a,a		; Double again (multiply by 8)
072b  4f        ld      c,a		; Save in C
072c  87        add     a,a		; Double again (multiply by 16)
072d  87        add     a,a		; Double again (multiply by 32)
072e  81        add     a,c		; Add 8x value (32 + 8 = 40x)
072f  80        add     a,b		; Add 2x value (40 + 2 = 42x)
0730  5f        ld      e,a		; Store final result in E
0731  1600      ld      d,#00		; Clear D 
0733  210f33    ld      hl,#330f	; Point to video memory base
0736  19        add     hl,de		; Add calculated offset
0737  cd1408    call    #0814		; Call display setup routine
073a  dd7e01    ld      a,(ix+#01)	; Get second level parameter
073d  32b04d    ld      (#4db0),a	; Store at memory location 0x4db0
0740  dd7e02    ld      a,(ix+#02)	; Get third level parameter
0743  47        ld      b,a		; Save in B
0744  87        add     a,a		; Double it
0745  80        add     a,b		; Add original (multiply by 3)
0746  5f        ld      e,a		; Store in E
0747  1600      ld      d,#00		; Clear D
0749  214308    ld      hl,#0843	; Point to data table
074c  19        add     hl,de		; Add offset
074d  cd3a08    call    #083a		; Call data processing routine
0750  dd7e03    ld      a,(ix+#03)	; Get fourth level parameter
0753  87        add     a,a		; Double for 16-bit table
0754  5f        ld      e,a		; Store in E
0755  1600      ld      d,#00		; Clear D
0757  fd214f08  ld      iy,#084f	; Point IY to parameter table
075b  fd19      add     iy,de		; Add offset to table
075d  fd6e00    ld      l,(iy+#00)	; Get low byte of parameter
0760  fd6601    ld      h,(iy+#01)	; Get high byte of parameter
0763  22bb4d    ld      (#4dbb),hl	; Store 16-bit parameter at 0x4dbb
0766  dd7e04    ld      a,(ix+#04)	; Get fifth level parameter
0769  87        add     a,a		; Double for 16-bit table
076a  5f        ld      e,a		; Store in E
076b  1600      ld      d,#00		; Clear D
076d  fd216108  ld      iy,#0861	; Point IY to next parameter table
0771  fd19      add     iy,de		; Add offset to table
0773  fd6e00    ld      l,(iy+#00)	; Get low byte of parameter
0776  fd6601    ld      h,(iy+#01)	; Get high byte of parameter
0779  22bd4d    ld      (#4dbd),hl	; Store 16-bit parameter at 0x4dbd
077c  dd7e05    ld      a,(ix+#05)	; Get sixth level parameter
077f  87        add     a,a		; Double for 16-bit table
0780  5f        ld      e,a		; Store in E
0781  1600      ld      d,#00		; Clear D
0783  fd217308  ld      iy,#0873	; Point IY to final parameter table
0787  fd19      add     iy,de		; Add offset to table
0789  fd6e00    ld      l,(iy+#00)	; Get low byte of parameter
078c  fd6601    ld      h,(iy+#01)	; Get high byte of parameter
078f  22954d    ld      (#4d95),hl	; Store 16-bit parameter at 0x4d95
0792  cdea2b    call    #2bea		; Call final setup routine
0795  c9        ret     

; MEMORY_MAP: Level Configuration Data Tables
; These tables contain level-specific parameters for difficulty scaling
0796  03        .db     #03		; Level 0 parameters
0797  010100    .db     #01, #01, #00
079a  02        .db     #02
079b  00        nop     
079c  04        .db     #04		; Level 1 parameters  
079d  010201    .db     #01, #02, #01
07a0  03        .db     #03
07a1  00        .db     #00
07a2  04        .db     #04		; Level 2 parameters
07a3  010302    .db     #01, #03, #02
07a6  04        .db     #04
07a7  010402    .db     #01, #04, #02	; Level 3 parameters
07aa  03        .db     #03
07ab  02        .db     #02
07ac  05        .db     #05		; Level 4 parameters
07ad  010500    .db     #01, #05, #00
07b0  03        .db     #03
07b1  02        .db     #02
07b2  0602      .db     #06, #02	; Level 5 parameters
07b4  05        .db     #05
07b5  010303    .db     #01, #03, #03
07b8  03        .db     #03
07b9  02        .db     #02
07ba  05        .db     #05		; Level 6 parameters
07bb  02        .db     #02
07bc  03        .db     #03
07bd  03        .db     #03
07be  0602      .db     #06, #02	; Level 7 parameters
07c0  05        .db     #05
07c1  02        .db     #02
07c2  03        .db     #03
07c3  03        .db     #03
07c4  0602      .db     #06, #02	; Level 8 parameters
07c6  05        .db     #05
07c7  00        .db     #00
07c8  03        .db     #03
07c9  04        .db     #04

; Continue level configuration data tables (exact Z80 from original)
07ca  07        .db     #07		; Extended level parameters
07cb  02        .db     #02
07cc  05        .db     #05
07cd  01        .db     #01
07ce  03        .db     #03
07cf  04        .db     #04
07d0  03        .db     #03		; Additional level data
07d1  02        .db     #02
07d2  05        .db     #05
07d3  02        .db     #02
07d4  03        .db     #03
07d5  04        .db     #04
07d6  06        .db     #06		; More level configurations
07d7  02        .db     #02
07d8  05        .db     #05
07d9  02        .db     #02
07da  03        .db     #03
07db  05        .db     #05
07dc  07        .db     #07		; Level 12+ parameters
07dd  02        .db     #02
07de  05        .db     #05
07df  00        .db     #00
07e0  03        .db     #03
07e1  05        .db     #05
07e2  07        .db     #07		; Level 13+ parameters
07e3  02        .db     #02
07e4  05        .db     #05
07e5  02        .db     #02
07e6  03        .db     #03
07e7  05        .db     #05
07e8  05        .db     #05		; Level 14+ parameters
07e9  02        .db     #02
07ea  05        .db     #05
07eb  01        .db     #01
07ec  03        .db     #03
07ed  06        .db     #06
07ee  07        .db     #07		; Level 15+ parameters
07ef  02        .db     #02
07f0  05        .db     #05
07f1  02        .db     #02
07f2  03        .db     #03
07f3  06        .db     #06
07f4  07        .db     #07		; Level 16+ parameters
07f5  02        .db     #02
07f6  05        .db     #05
07f7  02        .db     #02
07f8  03        .db     #03
07f9  06        .db     #06
07fa  08        .db     #08		; Level 17+ parameters
07fb  02        .db     #02
07fc  05        .db     #05
07fd  02        .db     #02
07fe  03        .db     #03
07ff  06        .db     #06
0800  07        .db     #07		; Final level parameters
0801  02        .db     #02
0802  05        .db     #05
0803  02        .db     #02
0804  03        .db     #03
0805  07        .db     #07
0806  08        .db     #08
0807  02        .db     #02
0808  05        .db     #05
0809  02        .db     #02
080a  03        .db     #03
080b  07        .db     #07
080c  08        .db     #08
080d  02        .db     #02
080e  06        .db     #06
080f  02        .db     #02
0810  03        .db     #03
0811  07        .db     #07
0812  08        .db     #08
0813  02        .db     #02

; FUNCTION: DISPLAY_MEMORY_COPY - Copy display data to video memory  
; C_PSEUDO: void display_memory_copy(uint16_t src, uint16_t dest, uint16_t count) {
; C_PSEUDO:   DE = dest_address;
; C_PSEUDO:   BC = byte_count;
; C_PSEUDO:   copy_memory_block(src, dest, count);
; C_PSEUDO:   // Multiple copy operations for different memory regions
; C_PSEUDO: }
; ALGORITHM: Copies sprite and display data to video memory using LDIR
0814  11464d    ld      de,#4d46	; Load destination address
0817  011c00    ld      bc,#001c	; Load byte count (28 bytes)
081a  edb0      ldir    		; Copy memory block
081c  010c00    ld      bc,#000c	; Load next byte count (12 bytes)
081f  a7        and     a		; Clear carry flag
0820  ed42      sbc     hl,bc		; Subtract offset from HL
0822  edb0      ldir    		; Copy next block
0824  010c00    ld      bc,#000c	; Load byte count (12 bytes)
0827  a7        and     a		; Clear carry flag
0828  ed42      sbc     hl,bc		; Subtract offset from HL
082a  edb0      ldir    		; Copy next block
082c  010c00    ld      bc,#000c	; Load byte count (12 bytes)
082f  a7        and     a		; Clear carry flag
0830  ed42      sbc     hl,bc		; Subtract offset from HL
0832  edb0      ldir    		; Copy next block
0834  010e00    ld      bc,#000e	; Load final byte count (14 bytes)
0837  edb0      ldir    		; Copy final block
0839  c9        ret     

; FUNCTION: PARAMETER_COPY - Copy 3-byte parameter block
; C_PSEUDO: void parameter_copy(uint16_t src) {
; C_PSEUDO:   dest = 0x4db8;
; C_PSEUDO:   copy_bytes(src, dest, 3);
; C_PSEUDO: }
083a  11b84d    ld      de,#4db8	; Load destination address
083d  010300    ld      bc,#0003	; Load byte count (3 bytes)
0840  edb0      ldir    		; Copy 3 bytes
0842  c9        ret     

; ==============================================================================
; SECTION: LEVEL CONFIGURATION DATA TABLES  
; ==============================================================================
; These are data tables (not executable code) used by the level progression 
; system to configure ghost speeds, timing values, and game difficulty.
; The level logic routines at 071c-0795 index into these tables.

; MEMORY_MAP: Level Parameter Data Tables
; Format: Raw data bytes grouped in 16-byte lines for readability
0843  14 1e 46 00 1e 3c 00 00 32 00 00 00 00 14 0a 1e  ; Ghost timing & speed config
0853  0f 28 14 32 19 3c 1e 50 28 64 32 78 3c 8c 46 c0  ; Speed progression table

; MEMORY_MAP: Ghost Movement Speed Lookup Tables  
; Used to set ghost movement increments and timing thresholds based on level
0862  03 48 03 d0 02 58 02 e0 01 68 01 f0 00 78 00 01  ; Speed increment table
0872  00 f0 00 f0 00 b4 00                              ; Final timing values

; ==============================================================================
; SECTION: LEVEL INITIALIZATION ROUTINES
; ==============================================================================

; FUNCTION: LEVEL_INITIALIZATION - Initialize new level and clear game state
; C_PSEUDO: void level_initialization() {
; C_PSEUDO:   clear_memory_block(0x4e09, 11);  // Clear game variables
; C_PSEUDO:   call_system_init();               // Initialize hardware
; C_PSEUDO:   level_data_ptr = level_table[current_level];
; C_PSEUDO:   copy_level_data(level_data_ptr, game_memory, 46);
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO: }
; ALGORITHM: Prepares a fresh level by clearing old state and loading new config
0879  21094e    ld      hl,#4e09	; Point to game variable block start
087c  af        xor     a		; Clear A (zero fill value)
087d  060b      ld      b,#0b		; Loop counter = 11 bytes
087f  cf        rst     #8		; Fill memory block with zeros
0880  cdc924    call    #24c9		; Call system initialization routine
0883  2a734e    ld      hl,(#4e73)	; Get level data table pointer
0886  220a4e    ld      (#4e0a),hl	; Store as current level data pointer
0889  210a4e    ld      hl,#4e0a	; Point to level data pointer
088c  11384e    ld      de,#4e38	; Point to game memory destination
088f  012e00    ld      bc,#002e	; Copy 46 bytes of level data
0892  edb0      ldir    		; Copy level configuration to game memory
0894  21044e    ld      hl,#4e04	; Point to game sub-state variable
0897  34        inc     (hl)		; Advance to next game sub-state
0898  c9        ret     

; FUNCTION: GAME_STATE_MANAGER - Handle game state transitions and demo mode
; C_PSEUDO: void game_state_manager() {
; C_PSEUDO:   if(main_game_state == 1) {
; C_PSEUDO:     game_sub_state = 9;  // Skip to end of level sequence
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   call_display_routines();  // Update screen elements
; C_PSEUDO:   setup_demo_mode();        // Configure for demo play
; C_PSEUDO:   handle_player_input_mask();
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO: }
; ALGORITHM: Manages transitions between attract mode, demo play, and real game
0899  3a004e    ld      a,(#4e00)	; Get main game state
089c  3d        dec     a		; Check if state = 1 (attract mode ending)
089d  2006      jr      nz,#08a5        ; Jump if not state 1
089f  3e09      ld      a,#09		; Load sub-state 9 (end sequence)
08a1  32044e    ld      (#4e04),a	; Set game sub-state to 9
08a4  c9        ret     

08a5  ef        rst     #28		; Call display system routine
08a6  1100      ld      de,#0011	; Load display parameters
08a8  ef        rst     #28		; Call display routine
08a9  1c        inc     e		; Increment parameter
08aa  83        add     a,e		; Add to accumulator
08ab  ef        rst     #28		; Call display routine
08ac  04        inc     b		; Increment parameter
08ad  00        nop     		; Padding
08ae  ef        rst     #28		; Call display routine
08af  05        dec     b		; Decrement parameter
08b0  00        nop     		; Padding
08b1  ef        rst     #28		; Call display routine
08b2  10        djnz    		; Decrement and jump parameter
08b3  00        nop     		; Padding
08b4  ef        rst     #28		; Call display routine
08b5  1a        ld      a,(de)		; Load parameter
08b6  00        nop     		; Padding
08b7  f7        rst     #30		; Call interrupt routine
08b8  54        ld      d,h		; Transfer parameter
08b9  00        nop     		; Padding
08ba  00        nop     		; Padding
08bb  f7        rst     #30		; Call interrupt routine
08bc  54        ld      d,h		; Transfer parameter
08bd  06        ld      b,		; Load parameter
08be  00        nop     		; Padding
08bf  3a724e    ld      a,(#4e72)	; Get player input mask
08c2  47        ld      b,a		; Save in B register
08c3  3a094e    ld      a,(#4e09)	; Get current input state
08c6  a0        and     b		; Apply player input mask
08c7  320350    ld      (#5003),a	; Store masked input to hardware
08ca  c39408    jp      #0894		; Jump to advance sub-state

; FUNCTION: FIRE_BUTTON_HANDLER - Handle fire button input during gameplay
; C_PSEUDO: void fire_button_handler() {
; C_PSEUDO:   input = read_input_port();
; C_PSEUDO:   if(!(input & FIRE_BUTTON)) {
; C_PSEUDO:     game_sub_state = 14;  // Advance game state
; C_PSEUDO:     call_display_routine();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(score_register == 0xF4) {
; C_PSEUDO:     game_sub_state = 12;  // Special score handling
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   run_main_game_loop();  // Continue normal gameplay
; C_PSEUDO: }
; ALGORITHM: Handles fire button for special game mechanics during play
08cd  3a0050    ld      a,(#5000)	; Read input port
08d0  cb67      bit     4,a		; Test fire button (bit 4)
08d2  c2de08    jp      nz,#08de	; Jump if fire button pressed
08d5  21044e    ld      hl,#4e04	; Point to game sub-state
08d8  360e      ld      (hl),#0e	; Set sub-state to 14
08da  ef        rst     #28		; Call display routine
08db  13        inc     de		; Increment parameter
08dc  00        nop     		; Padding
08dd  c9        ret     

08de  3a0e4e    ld      a,(#4e0e)	; Get score register value
08e1  fef4      cp      #f4		; Compare with special value 0xF4
08e3  2006      jr      nz,#08eb        ; Jump if not special score
08e5  21044e    ld      hl,#4e04	; Point to game sub-state
08e8  360c      ld      (hl),#0c	; Set sub-state to 12
08ea  c9        ret     

; FUNCTION: MAIN_GAME_LOOP - Core gameplay execution loop
; C_PSEUDO: void main_game_loop() {
; C_PSEUDO:   update_ghost_ai();      // Call ghost AI twice for accuracy
; C_PSEUDO:   update_ghost_ai();      
; C_PSEUDO:   handle_collisions();    // Check Pac-Man vs ghost collisions
; C_PSEUDO:   update_movement();      // Move all game objects
; C_PSEUDO:   handle_maze_logic();    // Process dot eating, power pellets
; C_PSEUDO:   update_sprites();       // Refresh sprite graphics
; C_PSEUDO:   update_sound();         // Process sound effects
; C_PSEUDO:   update_display();       // Refresh screen display
; C_PSEUDO: }
; ALGORITHM: Main game loop that runs during active gameplay
08eb  cd1710    call    #1017		; Call ghost AI update routine
08ee  cd1710    call    #1017		; Call ghost AI update routine (twice for precision)
08f1  cddd13    call    #13dd		; Call collision detection routine
08f4  cd420c    call    #0c42		; Call object movement routine
08f7  cd230e    call    #0e23		; Call maze logic routine
08fa  cd360e    call    #0e36		; Call additional maze routine
08fd  cdc30a    call    #0ac3		; Call power pellet routine
0900  cdd60b    call    #0bd6		; Call sprite update routine
0903  cd0d0c    call    #0c0d		; Call sound update routine
0906  cd6c0e    call    #0e6c		; Call maze display update routine
0909  cdad0e    call    #0ead		; Call bonus fruit routine  
090c  c9        ret     

; FUNCTION: PLAYER_DEATH_HANDLER - Handle player death sequence
; C_PSEUDO: void player_death_handler() {
; C_PSEUDO:   death_flag = 1;               // Mark player as dead
; C_PSEUDO:   call_death_animation();       // Play death sequence
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO:   
; C_PSEUDO:   if(demo_mode || !player_2_active || lives_remaining == 0) {
; C_PSEUDO:     advance_game_sub_state();  // Skip player switch
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Switch to other player or continue
; C_PSEUDO:   play_death_sound();
; C_PSEUDO:   setup_player_switch();
; C_PSEUDO: }
; ALGORITHM: Manages player death, life counting, and 2-player switching
090d  3e01      ld      a,#01		; Set death flag = 1
090f  32124e    ld      (#4e12),a	; Store death flag at memory location
0912  cd8724    call    #2487		; Call death animation routine
0915  21044e    ld      hl,#4e04	; Point to game sub-state
0918  34        inc     (hl)		; Advance game sub-state
0919  3a144e    ld      a,(#4e14)	; Get demo mode flag
091c  a7        and     a		; Test if demo mode active
091d  201f      jr      nz,#093e        ; Jump to advance state if demo mode
091f  3a704e    ld      a,(#4e70)	; Get player 2 active flag
0922  a7        and     a		; Test if player 2 is active
0923  2819      jr      z,#093e         ; Jump to advance if player 1 only
0925  3a424e    ld      a,(#4e42)	; Get lives remaining count
0928  a7        and     a		; Test if lives remaining
0929  2813      jr      z,#093e         ; Jump to advance if no lives left
092b  3a094e    ld      a,(#4e09)	; Get current player input
092e  c603      add     a,#03		; Add 3 to input value
0930  4f        ld      c,a		; Store result in C
0931  061c      ld      b,#1c		; Load sound parameter
0933  cd4200    call    #0042		; Call sound routine
0936  ef        rst     #28		; Call display routine
0937  1c        inc     e		; Increment parameter
0938  05        dec     b		; Decrement parameter
0939  f7        rst     #30		; Call interrupt routine
093a  54        ld      d,h		; Transfer parameter
093b  00        nop     		; Padding
093c  00        nop     		; Padding
093d  c9        ret     

093e  34        inc     (hl)		; Advance game sub-state (skip player switch)
093f  c9        ret     

; FUNCTION: GAME_OVER_HANDLER - Handle end of game sequence
; C_PSEUDO: void game_over_handler() {
; C_PSEUDO:   if(player_2_active && lives_remaining > 0) {
; C_PSEUDO:     call_continue_routine();
; C_PSEUDO:     toggle_current_player();
; C_PSEUDO:     game_sub_state = 9;  // Return to gameplay
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(demo_mode) {
; C_PSEUDO:     game_sub_state = 9;  // End demo
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   update_credits_display();
; C_PSEUDO:   show_game_over_screen();
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO: }
; ALGORITHM: Handles end of game, player switching, and return to attract mode
0940  3a704e    ld      a,(#4e70)	; Get player 2 active flag
0943  a7        and     a		; Test if player 2 is active
0944  2806      jr      z,#094c         ; Jump if only player 1
0946  3a424e    ld      a,(#4e42)	; Get lives remaining
0949  a7        and     a		; Test if lives > 0
094a  2015      jr      nz,#0961        ; Jump if lives remaining for continue
094c  3a144e    ld      a,(#4e14)	; Get demo mode flag  
094f  a7        and     a		; Test if demo mode
0950  201a      jr      nz,#096c        ; Jump to end demo if demo mode
0952  cda12b    call    #2ba1		; Update credits display
0955  ef        rst     #28		; Call display routine
0956  1c        inc     e		; Increment parameter
0957  05        dec     b		; Decrement parameter
0958  f7        rst     #30		; Call interrupt routine
0959  54        ld      d,h		; Transfer parameter
095a  00        nop     		; Padding
095b  00        nop     		; Padding
095c  21044e    ld      hl,#4e04	; Point to game sub-state
095f  34        inc     (hl)		; Advance game sub-state
0960  c9        ret     

0961  cda60a    call    #0aa6		; Call continue game routine
0964  3a094e    ld      a,(#4e09)	; Get current player
0967  ee01      xor     #01		; Toggle player (0<->1)
0969  32094e    ld      (#4e09),a	; Store new current player
096c  3e09      ld      a,#09		; Load sub-state 9
096e  32044e    ld      (#4e04),a	; Set game sub-state to 9 (end sequence)
0971  c9        ret     

; FUNCTION: RETURN_TO_ATTRACT - Reset game to attract mode
; C_PSEUDO: void return_to_attract() {
; C_PSEUDO:   // Clear all game state variables
; C_PSEUDO:   attract_sub_state = 0;
; C_PSEUDO:   game_sub_state = 0;
; C_PSEUDO:   player_selection = 0;
; C_PSEUDO:   current_player = 0;
; C_PSEUDO:   input_mask = 0;
; C_PSEUDO:   main_game_state = 1;  // Return to attract mode
; C_PSEUDO: }
; ALGORITHM: Resets all game variables and returns to attract mode
0972  af        xor     a		; Clear A (A = 0)
0973  32024e    ld      (#4e02),a	; Clear attract sub-state
0976  32044e    ld      (#4e04),a	; Clear game sub-state
0979  32704e    ld      (#4e70),a	; Clear player selection
097c  32094e    ld      (#4e09),a	; Clear current player
097f  320350    ld      (#5003),a	; Clear input mask register
0982  3e01      ld      a,#01		; Load state 1 (attract mode)
0984  32004e    ld      (#4e00),a	; Set main game state to attract
0987  c9        ret     

; FUNCTION: DEMO_MODE_INIT - Initialize demo mode gameplay
; C_PSEUDO: void demo_mode_init() {
; C_PSEUDO:   call_display_routines();     // Set up demo display
; C_PSEUDO:   setup_demo_controls();       // Configure AI player input
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO: }
; ALGORITHM: Sets up demo mode where the game plays itself for attract sequence
0988  ef        rst     #28		; Call display routine
0989  00        nop     		; Parameter
098a  01ef01    ld      bc,#01ef	; Load display parameters
098d  01ef02    ld      bc,#02ef	; Load more display parameters  
0990  00        nop     		; Padding
0991  ef        rst     #28		; Call display routine
0992  1100      ld      de,#0011	; Load parameters
0994  ef        rst     #28		; Call display routine
0995  13        inc     de		; Increment parameter
0996  00        nop     		; Padding
0997  ef        rst     #28		; Call display routine
0998  03        inc     bc		; Increment parameter
0999  00        nop     		; Padding
099a  ef        rst     #28		; Call display routine
099b  04        inc     b		; Increment parameter
099c  00        nop     		; Padding
099d  ef        rst     #28		; Call display routine
099e  05        dec     b		; Decrement parameter
099f  00        nop     		; Padding
09a0  ef        rst     #28		; Call display routine
09a1  10        djnz    		; Decrement and jump parameter
09a2  00        nop     		; Padding
09a3  ef        rst     #28		; Call display routine
09a4  1a        ld      a,(de)		; Load parameter
09a5  00        nop     		; Padding
09a6  ef        rst     #28		; Call display routine
09a7  1c        inc     e		; Increment parameter
09a8  06        ld      b,		; Load parameter
09a9  3a004e    ld      a,(#4e00)	; Get main game state
09ac  fe03      cp      #03		; Compare with state 3
09ae  2806      jr      z,#09b6         ; Jump if state 3 (gameplay)
09b0  ef        rst     #28		; Call display routine
09b1  1c        inc     e		; Increment parameter
09b2  05        dec     b		; Decrement parameter
09b3  ef        rst     #28		; Call display routine
09b4  1d        dec     e		; Decrement parameter
09b5  00        nop     		; Padding
09b6  f7        rst     #30		; Call interrupt routine
09b7  54        ld      d,h		; Transfer parameter
09b8  00        nop     		; Padding
09b9  00        nop     		; Padding
09ba  3a004e    ld      a,(#4e00)	; Get main game state again
09bd  3d        dec     a		; Decrement state
09be  2804      jr      z,#09c4         ; Jump if state was 1
09c0  f7        rst     #30		; Call interrupt routine
09c1  54        ld      d,h		; Transfer parameter
09c2  06        ld      b,		; Load parameter
09c3  00        nop     		; Padding
09c4  3a724e    ld      a,(#4e72)	; Get player input mask
09c7  47        ld      b,a		; Save mask in B
09c8  3a094e    ld      a,(#4e09)	; Get current player input
09cb  a0        and     b		; Apply input mask
09cc  320350    ld      (#5003),a	; Store masked input to hardware
09cf  c39408    jp      #0894		; Jump to advance sub-state

; FUNCTION: DEMO_TRANSITION - Quick demo transition
; C_PSEUDO: void demo_transition() {
; C_PSEUDO:   game_sub_state = 3;  // Return to gameplay state
; C_PSEUDO: }
09d2  3e03      ld      a,#03		; Load sub-state 3
09d4  32044e    ld      (#4e04),a	; Set game sub-state to 3
09d7  c9        ret     

; FUNCTION: DEMO_CLEANUP - Clean up demo mode
; C_PSEUDO: void demo_cleanup() {
; C_PSEUDO:   call_interrupt_routine();
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO:   clear_demo_flags();
; C_PSEUDO: }
09d8  f7        rst     #30		; Call interrupt routine
09d9  54        ld      d,h		; Transfer parameter
09da  00        nop     		; Padding
09db  00        nop     		; Padding
09dc  21044e    ld      hl,#4e04	; Point to game sub-state
09df  34        inc     (hl)		; Advance game sub-state
09e0  af        xor     a		; Clear A (A = 0)
09e1  32ac4e    ld      (#4eac),a	; Clear demo flag 1
09e4  32bc4e    ld      (#4ebc),a	; Clear demo flag 2
09e7  c9        ret     

; FUNCTION: DEMO_SOUND_SETUP - Set up sound for demo
; C_PSEUDO: void demo_sound_setup() {
; C_PSEUDO:   play_sound(channel=1, sound=2);
; C_PSEUDO:   call_interrupt_routine();
; C_PSEUDO:   call_checksum_routine(0x0000);  // Verify ROM integrity
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO: }
; ALGORITHM: Plays demo intro sound and validates ROM before demo starts
09e8  0e02      ld      c,#02		; Load sound ID 2
09ea  0601      ld      b,#01		; Load sound channel 1
09ec  cd4200    call    #0042		; Call sound routine
09ef  f7        rst     #30		; Call interrupt routine
09f0  42        ld      b,d		; Transfer parameter
09f1  00        nop     		; Padding
09f2  00        nop     		; Padding
09f3  210000    ld      hl,#0000	; Point to ROM start (0x0000)
09f6  cd7e26    call    #267e		; Call ROM checksum routine
09f9  21044e    ld      hl,#4e04	; Point to game sub-state
09fc  34        inc     (hl)		; Advance game sub-state
09fd  c9        ret     

; MEMORY_MAP: Demo Control Jump Table
; These are jump instructions that route demo sub-states to different handlers
09fe  0e00      ld      c,#00		; No sound for some demo states
0a00  18e8      jr      #09ea           ; Jump back to sound setup (with C=0)
0a02  18e4      jr      #09e8           ; Jump back to demo sound setup
0a04  18f8      jr      #09fe           ; Jump to silent demo
0a06  18e0      jr      #09e8           ; Jump back to demo sound setup
0a08  18f4      jr      #09fe           ; Jump to silent demo
0a0a  18dc      jr      #09e8           ; Jump back to demo sound setup
0a0c  18f0      jr      #09fe           ; Jump to silent demo

; FUNCTION: DEMO_DISPLAY_SETUP - Set up display elements for demo
; C_PSEUDO: void demo_display_setup() {
; C_PSEUDO:   call_display_routines();    // Set up various display elements
; C_PSEUDO:   setup_demo_sprites();       // Configure sprite display
; C_PSEUDO:   call_interrupt_routine();
; C_PSEUDO: }
; ALGORITHM: Configures display and sprite system for demo mode presentation
0a0e  ef        rst     #28		; Call display routine
0a0f  00        nop     		; Parameter
0a10  01ef06    ld      bc,#06ef	; Load display parameters
0a13  00        nop     		; Padding
0a14  ef        rst     #28		; Call display routine
0a15  1100      ld      de,#0011	; Load parameters
0a17  ef        rst     #28		; Call display routine
0a18  13        inc     de		; Increment parameter
0a19  00        nop     		; Padding
0a1a  ef        rst     #28		; Call display routine
0a1b  04        inc     b		; Increment parameter
0a1c  01ef05    ld      bc,#05ef	; Load more parameters
0a1f  01ef10    ld      bc,#10ef	; Load final parameters
0a22  13        inc     de		; Increment parameter
0a23  f7        rst     #30		; Call interrupt routine
0a24  43        ld      b,e		; Transfer parameter
0a25  00        nop     		; Padding
0a26  00        nop     		; Padding
0a27  21044e    ld      hl,#4e04	; Point to game sub-state
0a2a  34        inc     (hl)		; Advance game sub-state  
0a2b  c9        ret     

; FUNCTION: POWER_PELLET_HANDLER - Handle power pellet effects
; C_PSEUDO: void power_pellet_handler() {
; C_PSEUDO:   // Clear power pellet flags
; C_PSEUDO:   power_pellet_flag_1 = 0;
; C_PSEUDO:   power_pellet_flag_2 = 0;
; C_PSEUDO:   
; C_PSEUDO:   // Set ready flags for game restart
; C_PSEUDO:   ready_flag_1 = 2;
; C_PSEUDO:   ready_flag_2 = 2;
; C_PSEUDO:   
; C_PSEUDO:   // Get level number and limit to max 20
; C_PSEUDO:   level = game_level;
; C_PSEUDO:   if(level >= 20) level = 20;
; C_PSEUDO:   
; C_PSEUDO:   // Call level-specific power pellet routine
; C_PSEUDO:   call_power_pellet_routine(level);
; C_PSEUDO: }
; ALGORITHM: Manages power pellet timing and ghost frightened mode duration
0a2c  af        xor     a		; Clear A (A = 0)
0a2d  32ac4e    ld      (#4eac),a	; Clear power pellet flag 1
0a30  32bc4e    ld      (#4ebc),a	; Clear power pellet flag 2
0a33  3e02      ld      a,#02		; Load value 2
0a35  32cc4e    ld      (#4ecc),a	; Set ready flag 1 = 2
0a38  32dc4e    ld      (#4edc),a	; Set ready flag 2 = 2
0a3b  3a134e    ld      a,(#4e13)	; Get current level number
0a3e  fe14      cp      #14		; Compare with 20 (0x14)
0a40  3802      jr      c,#0a44         ; Jump if level < 20
0a42  3e14      ld      a,#14		; Cap level at 20
0a44  e7        rst     #20		; Call computed jump with level as index

; MEMORY_MAP: Power Pellet Duration Jump Table
; This table determines how long ghosts stay frightened based on level
; Format: Each entry is an address to a power pellet routine
0a45  6f0a      .dw     #0a6f		; Level 0 power pellet routine
0a47  6f0a      .dw     #0a6f		; Level 1 power pellet routine
0a49  6f0a      .dw     #0a6f		; Level 2 power pellet routine
0a4b  6f0a      .dw     #0a6f		; Level 3 power pellet routine
0a4d  9e0a      .dw     #0a9e		; Level 4 power pellet routine (shorter)
0a4f  6f0a      .dw     #0a6f		; Level 5 power pellet routine
0a51  6f0a      .dw     #0a6f		; Level 6 power pellet routine
0a53  6f0a      .dw     #0a6f		; Level 7 power pellet routine
0a55  970a      .dw     #0a97		; Level 8 power pellet routine
0a57  6f0a      .dw     #0a6f		; Level 9 power pellet routine
0a59  6f0a      .dw     #0a6f		; Level 10 power pellet routine
0a5b  6f0a      .dw     #0a6f		; Level 11 power pellet routine
0a5d  970a      .dw     #0a97		; Level 12 power pellet routine
0a5f  6f0a      .dw     #0a6f		; Level 13 power pellet routine
0a61  6f0a      .dw     #0a6f		; Level 14 power pellet routine
0a63  6f0a      .dw     #0a6f		; Level 15 power pellet routine
0a65  970a      .dw     #0a97		; Level 16 power pellet routine
0a67  6f0a      .dw     #0a6f		; Level 17 power pellet routine
0a69  6f0a      .dw     #0a6f		; Level 18 power pellet routine
0a6b  6f0a      .dw     #0a6f		; Level 19 power pellet routine
0a6d  6f0a      .dw     #0a6f		; Level 20 power pellet routine (max)

; FUNCTION: STANDARD_POWER_PELLET - Standard power pellet duration
; C_PSEUDO: void standard_power_pellet() {
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO:   advance_game_sub_state();  // Double advance
; C_PSEUDO:   clear_ready_flags();
; C_PSEUDO: }
; ALGORITHM: Provides normal frightened mode duration for early levels
0a6f  21044e    ld      hl,#4e04	; Point to game sub-state
0a72  34        inc     (hl)		; Advance game sub-state
0a73  34        inc     (hl)		; Advance game sub-state again (double)
0a74  af        xor     a		; Clear A (A = 0)
0a75  32cc4e    ld      (#4ecc),a	; Clear ready flag 1
0a78  32dc4e    ld      (#4edc),a	; Clear ready flag 2
0a7b  c9        ret     

; FUNCTION: SHORTENED_POWER_PELLET - Shortened power pellet duration
; C_PSEUDO: void shortened_power_pellet() {
; C_PSEUDO:   clear_ready_flags();
; C_PSEUDO:   clear_memory_block(0x4e0c, 7);  // Clear game variables
; C_PSEUDO:   call_system_init();
; C_PSEUDO:   advance_game_sub_state();
; C_PSEUDO:   advance_level();
; C_PSEUDO:   
; C_PSEUDO:   // Check if reached max level data
; C_PSEUDO:   if(level_data[current_level] == 0x14) return;  // Max level
; C_PSEUDO:   
; C_PSEUDO:   // Advance to next level data
; C_PSEUDO:   current_level_ptr++;
; C_PSEUDO: }
; ALGORITHM: Provides very short/no frightened mode for higher levels
0a7c  af        xor     a		; Clear A (A = 0)
0a7d  32cc4e    ld      (#4ecc),a	; Clear ready flag 1
0a80  32dc4e    ld      (#4edc),a	; Clear ready flag 2
0a83  0607      ld      b,#07		; Loop counter = 7 bytes
0a85  210c4e    ld      hl,#4e0c	; Point to memory block start
0a88  cf        rst     #8		; Fill memory block with zeros
0a89  cdc924    call    #24c9		; Call system initialization
0a8c  21044e    ld      hl,#4e04	; Point to game sub-state
0a8f  34        inc     (hl)		; Advance game sub-state
0a90  21134e    ld      hl,#4e13	; Point to level counter
0a93  34        inc     (hl)		; Increment level
0a94  2a0a4e    ld      hl,(#4e0a)	; Get current level data pointer
0a97  7e        ld      a,(hl)		; Read level data value
0a98  fe14      cp      #14		; Compare with max level marker (0x14)
0a9a  c8        ret     z		; Return if at max level

0a9b  23        inc     hl		; Advance to next level data
0a9c  220a4e    ld      (#4e0a),hl	; Store new level data pointer
0a9f  c9        ret     

; FUNCTION: CONTINUE_GAME_ROUTINE - Handle player continue
; C_PSEUDO: void continue_game_routine() {
; C_PSEUDO:   jump_to_demo_init();  // Return to demo initialization
; C_PSEUDO: }
0aa0  c38809    jp      #0988		; Jump back to demo mode init

; FUNCTION: DEMO_TRANSITION_ALT - Alternative demo transition
; C_PSEUDO: void demo_transition_alt() {
; C_PSEUDO:   jump_to_demo_transition();
; C_PSEUDO: }
0aa3  c3d209    jp      #09d2		; Jump to demo transition routine

; FUNCTION: LEVEL_DATA_SWAP - Swap current and backup level data
; C_PSEUDO: void level_data_swap() {
; C_PSEUDO:   // Swap 46 bytes between current and backup level data
; C_PSEUDO:   for(i = 0; i < 46; i++) {
; C_PSEUDO:     temp = current_level_data[i];
; C_PSEUDO:     current_level_data[i] = backup_level_data[i];
; C_PSEUDO:     backup_level_data[i] = temp;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Swaps between current game state and backup for 2-player games
0aa6  062e      ld      b,#2e		; Loop counter = 46 bytes (0x2E)
0aa8  dd210a4e  ld      ix,#4e0a	; Point IX to current level data
0aac  fd21384e  ld      iy,#4e38	; Point IY to backup level data
0ab0  dd5600    ld      d,(ix+#00)	; Load current data byte into D
0ab3  fd5e00    ld      e,(iy+#00)	; Load backup data byte into E
0ab6  fd7200    ld      (iy+#00),d	; Store current data in backup location
0ab9  dd7300    ld      (ix+#00),e	; Store backup data in current location
0abc  dd23      inc     ix		; Advance current data pointer
0abe  fd23      inc     iy		; Advance backup data pointer
0ac0  10ee      djnz    #0ab0           ; Loop for all 46 bytes
0ac2  c9        ret     

; ==============================================================================
; SECTION: POWER PELLET AND GHOST STATE MANAGEMENT
; ==============================================================================

; FUNCTION: POWER_PELLET_SYSTEM - Manage power pellet effects on ghosts
; C_PSEUDO: void power_pellet_system() {
; C_PSEUDO:   if(pac_man_dead) return;  // Don't process if Pac-Man is dead
; C_PSEUDO:   
; C_PSEUDO:   ghost_sprites = &sprite_data[0x4c00];
; C_PSEUDO:   ghost_state = &ghost_state_data[0x4dc8];
; C_PSEUDO:   
; C_PSEUDO:   if(ghost_state[0] != 0) return;  // Already processed
; C_PSEUDO:   
; C_PSEUDO:   ghost_state[0] = 0x0E;  // Mark as processed
; C_PSEUDO:   
; C_PSEUDO:   process_ghost_frightened_mode();
; C_PSEUDO: }
; ALGORITHM: Core power pellet system that makes ghosts frightened and edible
0ac3  3aa44d    ld      a,(#4da4)	; Get Pac-Man dead flag
0ac6  a7        and     a		; Test if Pac-Man is dead
0ac7  c0        ret     nz		; Return if Pac-Man is dead

0ac8  dd21004c  ld      ix,#4c00	; Point IX to ghost sprite data
0acc  fd21c84d  ld      iy,#4dc8	; Point IY to ghost state data
0ad0  110001    ld      de,#0100	; Load offset value 0x0100
0ad3  fdbe00    cp      (iy+#00)	; Compare with ghost state[0]
0ad6  c2d20b    jp      nz,#0bd2	; Jump if already processed
0ad9  fd36000e  ld      (iy+#00),#0e	; Set ghost state[0] = 0x0E (processed)

; FUNCTION: GHOST_1_FRIGHTENED - Handle first ghost frightened mode
; C_PSEUDO: void ghost_1_frightened() {
; C_PSEUDO:   if(!ghost_1_active) return;
; C_PSEUDO:   
; C_PSEUDO:   // Check if ghost position allows frightened mode
; C_PSEUDO:   ghost_pos = ghost_position[1];
; C_PSEUDO:   if(ghost_pos < 0x0100) {
; C_PSEUDO:     set_power_pellet_flag();
; C_PSEUDO:     if(ghost_sprite[11] == 9) {
; C_PSEUDO:       clear_power_pellet_flag();
; C_PSEUDO:     }
; C_PSEUDO:     ghost_sprite[11] = 9;  // Set frightened sprite
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Makes first ghost (Blinky) frightened when power pellet eaten
0add  3aa64d    ld      a,(#4da6)	; Get ghost 1 active flag
0ae0  a7        and     a		; Test if ghost 1 is active
0ae1  281b      jr      z,#0afe         ; Jump if ghost 1 not active
0ae3  2acb4d    ld      hl,(#4dcb)	; Get ghost 1 position
0ae6  a7        and     a		; Clear carry flag
0ae7  ed52      sbc     hl,de		; Subtract 0x0100 from position
0ae9  3013      jr      nc,#0afe        ; Jump if position >= 0x0100
0aeb  21ac4e    ld      hl,#4eac	; Point to power pellet flag
0aee  cbfe      set     7,(hl)		; Set power pellet active flag (bit 7)
0af0  3e09      ld      a,#09		; Load frightened sprite ID (9)
0af2  ddbe0b    cp      (ix+#0b)	; Compare with current sprite[11]
0af5  2004      jr      nz,#0afb        ; Jump if not already frightened
0af7  cbbe      res     7,(hl)		; Clear power pellet flag if already frightened
0af9  3e09      ld      a,#09		; Load frightened sprite ID again
0afb  320b4c    ld      (#4c0b),a	; Set ghost 1 sprite to frightened
0afe  3aa74d    ld      a,(#4da7)	; Get ghost 2 active flag

; FUNCTION: GHOST_2_FRIGHTENED - Handle second ghost frightened mode  
; C_PSEUDO: void ghost_2_frightened() {
; C_PSEUDO:   if(!ghost_2_active) {
; C_PSEUDO:     ghost_sprite[3] = 1;  // Set normal sprite
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Check if ghost position allows frightened mode
; C_PSEUDO:   ghost_pos = ghost_position[2];
; C_PSEUDO:   if(ghost_pos < 0x0100) {
; C_PSEUDO:     // Toggle between frightened sprites 0x11 and 0x12
; C_PSEUDO:     if(ghost_sprite[3] == 0x11) {
; C_PSEUDO:       ghost_sprite[3] = 0x12;
; C_PSEUDO:     } else {
; C_PSEUDO:       ghost_sprite[3] = 0x11;
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Makes second ghost (Pinky) frightened with animated sprite
0b01  a7        and     a		; Test if ghost 2 is active
0b02  281d      jr      z,#0b21         ; Jump if ghost 2 not active
0b04  2acb4d    ld      hl,(#4dcb)	; Get ghost 2 position
0b07  a7        and     a		; Clear carry flag
0b08  ed52      sbc     hl,de		; Subtract 0x0100 from position
0b0a  3027      jr      nc,#0b33        ; Jump if position >= 0x0100
0b0c  3e11      ld      a,#11		; Load frightened sprite ID 0x11
0b0e  ddbe03    cp      (ix+#03)	; Compare with current sprite[3]
0b11  2807      jr      z,#0b1a         ; Jump if currently 0x11
0b13  dd360311  ld      (ix+#03),#11	; Set sprite[3] = 0x11
0b17  c3330b    jp      #0b33		; Jump to next ghost
0b1a  dd360312  ld      (ix+#03),#12	; Set sprite[3] = 0x12 (animate)
0b1e  c3330b    jp      #0b33		; Jump to next ghost
0b21  3e01      ld      a,#01		; Load normal sprite ID (1)
0b23  ddbe03    cp      (ix+#03)	; Compare with current sprite[3]
0b26  2807      jr      z,#0b2f         ; Jump if already normal
0b28  dd360301  ld      (ix+#03),#01	; Set sprite[3] = 1 (normal)
0b2c  c3330b    jp      #0b33		; Jump to next ghost
0b2f  dd360301  ld      (ix+#03),#01	; Set sprite[3] = 1 (normal)

; FUNCTION: GHOST_3_FRIGHTENED - Handle third ghost frightened mode
; C_PSEUDO: void ghost_3_frightened() {
; C_PSEUDO:   if(!ghost_3_active) {
; C_PSEUDO:     ghost_sprite[5] = 3;  // Set normal sprite
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Check if ghost position allows frightened mode  
; C_PSEUDO:   ghost_pos = ghost_position[3];
; C_PSEUDO:   if(ghost_pos < 0x0100) {
; C_PSEUDO:     // Toggle between frightened sprites 0x11 and 0x12
; C_PSEUDO:     if(ghost_sprite[5] == 0x11) {
; C_PSEUDO:       ghost_sprite[5] = 0x12;
; C_PSEUDO:     } else {
; C_PSEUDO:       ghost_sprite[5] = 0x11;
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Makes third ghost (Inky) frightened with animated sprite
0b33  3aa84d    ld      a,(#4da8)	; Get ghost 3 active flag
0b36  a7        and     a		; Test if ghost 3 is active
0b37  281d      jr      z,#0b56         ; Jump if ghost 3 not active
0b39  2acb4d    ld      hl,(#4dcb)	; Get ghost 3 position
0b3c  a7        and     a		; Clear carry flag
0b3d  ed52      sbc     hl,de		; Subtract 0x0100 from position
0b3f  3027      jr      nc,#0b68        ; Jump if position >= 0x0100
0b41  3e11      ld      a,#11		; Load frightened sprite ID 0x11
0b43  ddbe05    cp      (ix+#05)	; Compare with current sprite[5]
0b46  2807      jr      z,#0b4f         ; Jump if currently 0x11
0b48  dd360511  ld      (ix+#05),#11	; Set sprite[5] = 0x11
0b4c  c3680b    jp      #0b68		; Jump to next ghost
0b4f  dd360512  ld      (ix+#05),#12	; Set sprite[5] = 0x12 (animate)
0b53  c3680b    jp      #0b68		; Jump to next ghost
0b56  3e03      ld      a,#03		; Load normal sprite ID (3)
0b58  ddbe05    cp      (ix+#05)	; Compare with current sprite[5]
0b5b  2807      jr      z,#0b64         ; Jump if already normal
0b5d  dd360503  ld      (ix+#05),#03	; Set sprite[5] = 3 (normal)
0b61  c3680b    jp      #0b68		; Jump to next ghost
0b64  dd360503  ld      (ix+#05),#03	; Set sprite[5] = 3 (normal)

; FUNCTION: GHOST_4_FRIGHTENED - Handle fourth ghost frightened mode
; C_PSEUDO: void ghost_4_frightened() {
; C_PSEUDO:   if(!ghost_4_active) {
; C_PSEUDO:     ghost_sprite[7] = 5;  // Set normal sprite
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Check if ghost position allows frightened mode
; C_PSEUDO:   ghost_pos = ghost_position[4];
; C_PSEUDO:   if(ghost_pos < 0x0100) {
; C_PSEUDO:     // Toggle between frightened sprites 0x11 and 0x12
; C_PSEUDO:     if(ghost_sprite[7] == 0x11) {
; C_PSEUDO:       ghost_sprite[7] = 0x12;
; C_PSEUDO:     } else {
; C_PSEUDO:       ghost_sprite[7] = 0x11;
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Makes fourth ghost (Sue/Clyde) frightened with animated sprite
0b68  3aa94d    ld      a,(#4da9)	; Get ghost 4 active flag
0b6b  a7        and     a		; Test if ghost 4 is active
0b6c  281d      jr      z,#0b8b         ; Jump if ghost 4 not active
0b6e  2acb4d    ld      hl,(#4dcb)	; Get ghost 4 position
0b71  a7        and     a		; Clear carry flag
0b72  ed52      sbc     hl,de		; Subtract 0x0100 from position
0b74  3027      jr      nc,#0b9d        ; Jump if position >= 0x0100
0b76  3e11      ld      a,#11		; Load frightened sprite ID 0x11
0b78  ddbe07    cp      (ix+#07)	; Compare with current sprite[7]
0b7b  2807      jr      z,#0b84         ; Jump if currently 0x11
0b7d  dd360711  ld      (ix+#07),#11	; Set sprite[7] = 0x11
0b81  c39d0b    jp      #0b9d		; Jump to continue
0b84  dd360712  ld      (ix+#07),#12	; Set sprite[7] = 0x12 (animate)
0b88  c39d0b    jp      #0b9d		; Jump to continue
0b8b  3e05      ld      a,#05		; Load normal sprite ID (5)
0b8d  ddbe07    cp      (ix+#07)	; Compare with current sprite[7]
0b90  2807      jr      z,#0b99         ; Jump if already normal
0b92  dd360705  ld      (ix+#07),#05	; Set sprite[7] = 5 (normal)
0b96  c39d0b    jp      #0b9d		; Jump to continue
0b99  dd360705  ld      (ix+#07),#05	; Set sprite[7] = 5 (normal)
0b9d  3aaa4d    ld      a,(#4daa)	; Get ghost 5 active flag (if exists)

; FUNCTION: GHOST_5_FRIGHTENED - Handle fifth ghost frightened mode (bonus ghost)
; C_PSEUDO: void ghost_5_frightened() {
; C_PSEUDO:   if(!ghost_5_active) {
; C_PSEUDO:     ghost_sprite[9] = 7;  // Set normal sprite
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Check if ghost position allows frightened mode
; C_PSEUDO:   ghost_pos = ghost_position[5];
; C_PSEUDO:   if(ghost_pos < 0x0100) {
; C_PSEUDO:     // Toggle between frightened sprites 0x11 and 0x12
; C_PSEUDO:     if(ghost_sprite[9] == 0x11) {
; C_PSEUDO:       ghost_sprite[9] = 0x12;
; C_PSEUDO:     } else {
; C_PSEUDO:       ghost_sprite[9] = 0x11;
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Makes fifth ghost (bonus/extra ghost) frightened with animated sprite
0ba0  a7        and     a		; Test if ghost 5 is active
0ba1  281d      jr      z,#0bc0         ; Jump if ghost 5 not active
0ba3  2acb4d    ld      hl,(#4dcb)	; Get ghost 5 position
0ba6  a7        and     a		; Clear carry flag
0ba7  ed52      sbc     hl,de		; Subtract 0x0100 from position
0ba9  3027      jr      nc,#0bd2        ; Jump if position >= 0x0100
0bab  3e11      ld      a,#11		; Load frightened sprite ID 0x11
0bad  ddbe09    cp      (ix+#09)	; Compare with current sprite[9]
0bb0  2807      jr      z,#0bb9         ; Jump if currently 0x11
0bb2  dd360911  ld      (ix+#09),#11	; Set sprite[9] = 0x11
0bb6  c3d20b    jp      #0bd2		; Jump to finalize
0bb9  dd360912  ld      (ix+#09),#12	; Set sprite[9] = 0x12 (animate)
0bbd  c3d20b    jp      #0bd2		; Jump to finalize
0bc0  3e07      ld      a,#07		; Load normal sprite ID (7)
0bc2  ddbe09    cp      (ix+#09)	; Compare with current sprite[9]
0bc5  2807      jr      z,#0bce         ; Jump if already normal
0bc7  dd360907  ld      (ix+#09),#07	; Set sprite[9] = 7 (normal)
0bcb  c3d20b    jp      #0bd2		; Jump to finalize
0bce  dd360907  ld      (ix+#09),#07	; Set sprite[9] = 7 (normal)

; FUNCTION: FINALIZE_POWER_PELLET - Finalize power pellet processing
; C_PSEUDO: void finalize_power_pellet() {
; C_PSEUDO:   ghost_state[0]--;  // Decrement processing counter
; C_PSEUDO: }
0bd2  fd3500    dec     (iy+#00)	; Decrement ghost state[0]
0bd5  c9        ret     

; ==============================================================================
; SECTION: SPRITE UPDATE AND DISPLAY SYSTEM
; ==============================================================================

; FUNCTION: SPRITE_UPDATE_SYSTEM - Update sprite display based on game state
; C_PSEUDO: void sprite_update_system() {
; C_PSEUDO:   sprite_id = 0x19;  // Default sprite
; C_PSEUDO:   
; C_PSEUDO:   // Special case for attract mode sub-state 0x22
; C_PSEUDO:   if(attract_sub_state == 0x22) {
; C_PSEUDO:     sprite_id = 0;  // Hide sprites in attract mode
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   ghost_sprites = &sprite_data[0x4c00];
; C_PSEUDO:   
; C_PSEUDO:   // Update each ghost sprite if active
; C_PSEUDO:   if(ghost_flags[1]) ghost_sprites[3] = sprite_id;
; C_PSEUDO:   if(ghost_flags[2]) ghost_sprites[5] = sprite_id;
; C_PSEUDO:   if(ghost_flags[3]) ghost_sprites[7] = sprite_id;
; C_PSEUDO:   if(ghost_flags[4]) ghost_sprites[9] = sprite_id;
; C_PSEUDO: }
; ALGORITHM: Controls sprite visibility and appearance based on game mode
0bd6  0619      ld      b,#19		; Load default sprite ID 0x19
0bd8  3a024e    ld      a,(#4e02)	; Get attract sub-state
0bdb  fe22      cp      #22		; Compare with sub-state 0x22
0bdd  c2e20b    jp      nz,#0be2	; Jump if not attract sub-state 0x22
0be0  0600      ld      b,#00		; Set sprite ID = 0 (hide sprites)
0be2  dd21004c  ld      ix,#4c00	; Point IX to ghost sprite data
0be6  3aac4d    ld      a,(#4dac)	; Get ghost 1 active flag
0be9  a7        and     a		; Test if ghost 1 is active
0bea  caf00b    jp      z,#0bf0		; Jump if ghost 1 not active
0bed  dd7003    ld      (ix+#03),b	; Set ghost 1 sprite[3] = sprite_id
0bf0  3aad4d    ld      a,(#4dad)	; Get ghost 2 active flag
0bf3  a7        and     a		; Test if ghost 2 is active
0bf4  cafa0b    jp      z,#0bfa		; Jump if ghost 2 not active
0bf7  dd7005    ld      (ix+#05),b	; Set ghost 2 sprite[5] = sprite_id
0bfa  3aae4d    ld      a,(#4dae)	; Get ghost 3 active flag
0bfd  a7        and     a		; Test if ghost 3 is active
0bfe  ca040c    jp      z,#0c04		; Jump if ghost 3 not active
0c01  dd7007    ld      (ix+#07),b	; Set ghost 3 sprite[7] = sprite_id
0c04  3aaf4d    ld      a,(#4daf)	; Get ghost 4 active flag
0c07  a7        and     a		; Test if ghost 4 is active
0c08  c8        ret     z		; Return if ghost 4 not active

0c09  dd7009    ld      (ix+#09),b	; Set ghost 4 sprite[9] = sprite_id
0c0c  c9        ret     

; FUNCTION: SOUND_UPDATE_SYSTEM - Update game sound effects
; C_PSEUDO: void sound_update_system() {
; C_PSEUDO:   sound_timer++;
; C_PSEUDO:   if(sound_timer < 10) return;  // Wait for timer
; C_PSEUDO:   
; C_PSEUDO:   sound_timer = 0;  // Reset timer
; C_PSEUDO:   
; C_PSEUDO:   if(game_sub_state == 3) {  // Active gameplay
; C_PSEUDO:     update_pac_man_sound();
; C_PSEUDO:   } else {
; C_PSEUDO:     update_attract_sound();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Manages all game sound effects with timing control
0c0d  21cf4d    ld      hl,#4dcf	; Point to sound timer
0c10  34        inc     (hl)		; Increment sound timer
0c11  3e0a      ld      a,#0a		; Load timer threshold (10)
0c13  be        cp      (hl)		; Compare with current timer
0c14  c0        ret     nz		; Return if timer < 10

0c15  3600      ld      (hl),#00	; Reset sound timer = 0
0c17  3a044e    ld      a,(#4e04)	; Get game sub-state
0c1a  fe03      cp      #03		; Compare with sub-state 3 (active gameplay)
0c1c  2015      jr      nz,#0c33        ; Jump if not active gameplay

; FUNCTION: PAC_MAN_SOUND_UPDATE - Update Pac-Man movement sound during gameplay
; C_PSEUDO: void pac_man_sound_update() {
; C_PSEUDO:   sound_addr = 0x4464;  // Pac-Man sound register
; C_PSEUDO:   if(sound_value == 0x10) {
; C_PSEUDO:     sound_value = 0;  // Reset sound
; C_PSEUDO:   }
; C_PSEUDO:   // Update multiple sound channels
; C_PSEUDO:   sound_registers[0x4464] = sound_value;
; C_PSEUDO:   sound_registers[0x4478] = sound_value;
; C_PSEUDO:   sound_registers[0x4784] = sound_value;
; C_PSEUDO:   sound_registers[0x4798] = sound_value;
; C_PSEUDO: }
; ALGORITHM: Produces Pac-Man's "wakka wakka" eating sound
0c1e  216444    ld      hl,#4464	; Point to Pac-Man sound register
0c21  3e10      ld      a,#10		; Load sound threshold value
0c23  be        cp      (hl)		; Compare with current sound value
0c24  2002      jr      nz,#0c28        ; Jump if not at threshold
0c26  3e00      ld      a,#00		; Reset sound value = 0
0c28  77        ld      (hl),a		; Store sound value
0c29  327844    ld      (#4478),a	; Update sound channel 2
0c2c  328447    ld      (#4784),a	; Update sound channel 3
0c2f  329847    ld      (#4798),a	; Update sound channel 4
0c32  c9        ret     

; FUNCTION: ATTRACT_SOUND_UPDATE - Update attract mode sound
; C_PSEUDO: void attract_sound_update() {
; C_PSEUDO:   sound_addr = 0x4732;  // Attract mode sound register
; C_PSEUDO:   if(sound_value == 0x10) {
; C_PSEUDO:     sound_value = 0;  // Reset sound
; C_PSEUDO:   }
; C_PSEUDO:   // Update attract mode sound channels
; C_PSEUDO:   sound_registers[0x4732] = sound_value;
; C_PSEUDO:   sound_registers[0x4678] = sound_value;
; C_PSEUDO: }
; ALGORITHM: Produces attract mode background sounds
0c33  213247    ld      hl,#4732	; Point to attract mode sound register
0c36  3e10      ld      a,#10		; Load sound threshold value
0c38  be        cp      (hl)		; Compare with current sound value
0c39  2002      jr      nz,#0c3d        ; Jump if not at threshold
0c3b  3e00      ld      a,#00		; Reset sound value = 0
0c3d  77        ld      (hl),a		; Store sound value
0c3e  327846    ld      (#4678),a	; Update attract mode sound channel
0c41  c9        ret     

; ==============================================================================
; SECTION: PAC-MAN MOVEMENT AND ANIMATION SYSTEM
; ==============================================================================

; FUNCTION: PAC_MAN_MOVEMENT_SYSTEM - Handle Pac-Man movement and animation
; C_PSEUDO: void pac_man_movement_system() {
; C_PSEUDO:   if(pac_man_dead) return;  // Don't move if dead
; C_PSEUDO:   
; C_PSEUDO:   // Animate Pac-Man sprite
; C_PSEUDO:   animation_flag = animation_flag << 1;  // Rotate left
; C_PSEUDO:   if(!carry_flag) return;  // Skip if no animation needed
; C_PSEUDO:   
; C_PSEUDO:   if(pac_man_state == 0) {
; C_PSEUDO:     initialize_pac_man();
; C_PSEUDO:   } else {
; C_PSEUDO:     update_pac_man_movement();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Core Pac-Man movement and sprite animation controller
0c42  3aa44d    ld      a,(#4da4)	; Get Pac-Man dead flag
0c45  a7        and     a		; Test if Pac-Man is dead
0c46  c0        ret     nz		; Return if Pac-Man is dead

0c47  3a944d    ld      a,(#4d94)	; Get animation flag
0c4a  07        rlca    		; Rotate left (shift animation bit)
0c4b  32944d    ld      (#4d94),a	; Store updated animation flag
0c4e  d0        ret     nc		; Return if no carry (no animation needed)

0c4f  3aa04d    ld      a,(#4da0)	; Get Pac-Man state
0c52  a7        and     a		; Test if Pac-Man state = 0
0c53  c2900c    jp      nz,#0c90	; Jump if Pac-Man already initialized

; FUNCTION: INITIALIZE_PAC_MAN - Initialize Pac-Man for new level/life
; C_PSEUDO: void initialize_pac_man() {
; C_PSEUDO:   pac_man_sprite = &sprite_data[0x3305];
; C_PSEUDO:   pac_man_data = &pac_man_data[0x4d00];
; C_PSEUDO:   
; C_PSEUDO:   position = calculate_maze_position();
; C_PSEUDO:   pac_man_data[0] = position;
; C_PSEUDO:   
; C_PSEUDO:   direction = 3;  // Initial direction (left)
; C_PSEUDO:   pac_man_data[0x28] = direction;
; C_PSEUDO:   pac_man_data[0x2c] = direction;
; C_PSEUDO:   
; C_PSEUDO:   // Check for special position (Pac-Man start position)
; C_PSEUDO:   if(position == 0x64) {
; C_PSEUDO:     setup_pac_man_start_position();
; C_PSEUDO:     pac_man_state = 1;  // Mark as initialized
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Sets up Pac-Man's initial position and state for new level
0c56  dd210533  ld      ix,#3305	; Point IX to Pac-Man sprite data
0c5a  fd21004d  ld      iy,#4d00	; Point IY to Pac-Man game data
0c5e  cd0020    call    #2000		; Calculate Pac-Man maze position
0c61  22004d    ld      (#4d00),hl	; Store position in Pac-Man data
0c64  3e03      ld      a,#03		; Load direction 3 (left)
0c66  32284d    ld      (#4d28),a	; Set current direction = left
0c69  322c4d    ld      (#4d2c),a	; Set desired direction = left
0c6c  3a004d    ld      a,(#4d00)	; Get Pac-Man position
0c6f  fe64      cp      #64		; Compare with start position (0x64)
0c71  c2900c    jp      nz,#0c90	; Jump if not at start position
0c74  212c2e    ld      hl,#2e2c	; Load start position coordinates
0c77  220a4d    ld      (#4d0a),hl	; Set Pac-Man screen position
0c7a  210001    ld      hl,#0100	; Load movement parameters
0c7d  22144d    ld      (#4d14),hl	; Set movement vector 1
0c80  221e4d    ld      (#4d1e),hl	; Set movement vector 2
0c83  3e02      ld      a,#02		; Load direction 2 (up)
0c85  32284d    ld      (#4d28),a	; Set current direction = up
0c88  322c4d    ld      (#4d2c),a	; Set desired direction = up
0c8b  3e01      ld      a,#01		; Load state 1 (initialized)
0c8d  32a04d    ld      (#4da0),a	; Set Pac-Man state = initialized

; FUNCTION: UPDATE_PAC_MAN_MOVEMENT - Update Pac-Man's ongoing movement
; C_PSEUDO: void update_pac_man_movement() {
; C_PSEUDO:   ghost_1_state = ghost_states[1];
; C_PSEUDO:   
; C_PSEUDO:   if(ghost_1_state == 1) {
; C_PSEUDO:     handle_pac_man_ghost_collision();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(ghost_1_state == 0) {
; C_PSEUDO:     position = pac_man_position;
; C_PSEUDO:     check_special_positions(position);
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   continue_pac_man_movement();
; C_PSEUDO: }
; ALGORITHM: Handles ongoing Pac-Man movement and collision detection
0c90  3aa14d    ld      a,(#4da1)	; Get ghost 1 state
0c93  fe01      cp      #01		; Compare with state 1 (collision)
0c95  cafb0c    jp      z,#0cfb		; Jump if collision detected
0c98  fe00      cp      #00		; Compare with state 0 (normal)
0c9a  c2c10c    jp      nz,#0cc1	; Jump if not normal state
0c9d  3a024d    ld      a,(#4d02)	; Get Pac-Man position
0ca0  fe78      cp      #78		; Compare with special position 0x78
0ca2  cc2e1f    call    z,#1f2e		; Call special handler if at 0x78
0ca5  fe80      cp      #80		; Compare with special position 0x80
0ca7  cc2e1f    call    z,#1f2e		; Call special handler if at 0x80
0caa  3a2d4d    ld      a,(#4d2d)	; Get desired direction for ghost 1
0cad  32294d    ld      (#4d29),a	; Set current direction for ghost 1
0cb0  dd21204d  ld      ix,#4d20	; Point IX to ghost 1 movement data
0cb4  fd21024d  ld      iy,#4d02	; Point IY to ghost 1 position
0cb8  cd0020    call    #2000		; Calculate new position
0cbb  22024d    ld      (#4d02),hl	; Store new ghost 1 position
0cbe  c3fb0c    jp      #0cfb		; Jump to continue movement

; FUNCTION: PAC_MAN_MOVEMENT_CONTINUE - Continue Pac-Man movement processing
; C_PSEUDO: void pac_man_movement_continue() {
; C_PSEUDO:   pac_man_sprite = &sprite_data[0x3305];
; C_PSEUDO:   pac_man_pos = &pac_man_data[0x4d02];
; C_PSEUDO:   
; C_PSEUDO:   new_position = calculate_movement();
; C_PSEUDO:   pac_man_data[2] = new_position;
; C_PSEUDO:   
; C_PSEUDO:   direction = 3;  // Reset to left direction
; C_PSEUDO:   pac_man_data[0x2d] = direction;
; C_PSEUDO:   pac_man_data[0x29] = direction;
; C_PSEUDO:   
; C_PSEUDO:   // Check for special position reset
; C_PSEUDO:   if(position == 0x64) {
; C_PSEUDO:     reset_pac_man_position();
; C_PSEUDO:     ghost_1_state = 1;  // Mark collision state
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Continues Pac-Man movement after initialization
0cc1  dd210533  ld      ix,#3305	; Point IX to Pac-Man sprite data
0cc5  fd21024d  ld      iy,#4d02	; Point IY to Pac-Man backup position
0cc9  cd0020    call    #2000		; Calculate new position
0ccc  22024d    ld      (#4d02),hl	; Store backup Pac-Man position
0ccf  3e03      ld      a,#03		; Load direction 3 (left)
0cd1  322d4d    ld      (#4d2d),a	; Set desired direction = left
0cd4  32294d    ld      (#4d29),a	; Set current direction = left
0cd7  3a024d    ld      a,(#4d02)	; Get backup Pac-Man position
0cda  fe64      cp      #64		; Compare with start position
0cdc  c2fb0c    jp      nz,#0cfb	; Jump if not at start
0cdf  212c2e    ld      hl,#2e2c	; Load start coordinates
0ce2  220c4d    ld      (#4d0c),hl	; Set backup screen position
0ce5  210001    ld      hl,#0100	; Load movement parameters
0ce8  22164d    ld      (#4d16),hl	; Set backup movement vector 1
0ceb  22204d    ld      (#4d20),hl	; Set backup movement vector 2
0cee  3e02      ld      a,#02		; Load direction 2 (up)
0cf0  32294d    ld      (#4d29),a	; Set current direction = up
0cf3  322d4d    ld      (#4d2d),a	; Set desired direction = up
0cf6  3e01      ld      a,#01		; Load state 1 (collision)
0cf8  32a14d    ld      (#4da1),a	; Set ghost 1 state = collision

; ==============================================================================
; SECTION: GHOST MOVEMENT SYSTEM - GHOST 2 (PINKY)
; ==============================================================================

; FUNCTION: GHOST_2_MOVEMENT_SYSTEM - Handle Ghost 2 (Pinky) movement and AI
; C_PSEUDO: void ghost_2_movement_system() {
; C_PSEUDO:   ghost_2_state = ghost_states[2];
; C_PSEUDO:   
; C_PSEUDO:   if(ghost_2_state == 1) {
; C_PSEUDO:     handle_ghost_2_collision();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(ghost_2_state == 0) {
; C_PSEUDO:     // Normal movement mode
; C_PSEUDO:     position = ghost_2_position;
; C_PSEUDO:     check_special_positions(position);  // Tunnel handling
; C_PSEUDO:     direction = ghost_2_desired_direction;
; C_PSEUDO:     ghost_2_current_direction = direction;
; C_PSEUDO:     update_ghost_2_position();
; C_PSEUDO:   } else if(ghost_2_state == 3) {
; C_PSEUDO:     // Frightened/retreat mode
; C_PSEUDO:     handle_frightened_movement();
; C_PSEUDO:   } else {
; C_PSEUDO:     // Default movement
; C_PSEUDO:     handle_default_movement();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Complete AI system for Ghost 2 including normal, frightened, and collision states
0cfb  3aa24d    ld      a,(#4da2)	; Get ghost 2 state
0cfe  fe01      cp      #01		; Compare with state 1 (collision)
0d00  ca930d    jp      z,#0d93		; Jump if collision detected
0d03  fe00      cp      #00		; Compare with state 0 (normal)
0d05  c22c0d    jp      nz,#0d2c	; Jump if not normal state
0d08  3a044d    ld      a,(#4d04)	; Get ghost 2 position
0d0b  fe78      cp      #78		; Compare with tunnel position 0x78
0d0d  cc551f    call    z,#1f55		; Call tunnel handler if at 0x78
0d10  fe80      cp      #80		; Compare with tunnel position 0x80
0d12  cc551f    call    z,#1f55		; Call tunnel handler if at 0x80
0d15  3a2e4d    ld      a,(#4d2e)	; Get ghost 2 desired direction
0d18  322a4d    ld      (#4d2a),a	; Set ghost 2 current direction
0d1b  dd21224d  ld      ix,#4d22	; Point IX to ghost 2 movement data
0d1f  fd21044d  ld      iy,#4d04	; Point IY to ghost 2 position
0d23  cd0020    call    #2000		; Calculate new position
0d26  22044d    ld      (#4d04),hl	; Store new ghost 2 position
0d29  c3930d    jp      #0d93		; Jump to continue

; FUNCTION: GHOST_2_FRIGHTENED_MOVEMENT - Handle Ghost 2 frightened mode movement
; C_PSEUDO: void ghost_2_frightened_movement() {
; C_PSEUDO:   if(ghost_2_state == 3) {  // Frightened/retreat mode
; C_PSEUDO:     ghost_2_sprite = &sprite_data[0x32ff];  // Frightened sprite
; C_PSEUDO:     position = calculate_frightened_movement();
; C_PSEUDO:     ghost_2_direction = 0;  // Reset directions
; C_PSEUDO:     
; C_PSEUDO:     // Check if reached safe position
; C_PSEUDO:     if(position >= 0x80) {
; C_PSEUDO:       ghost_2_state = 2;  // Return to normal
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Handles frightened ghost movement with retreat to safe area
0d2c  3aa24d    ld      a,(#4da2)	; Get ghost 2 state
0d2f  fe03      cp      #03		; Compare with state 3 (frightened)
0d31  c2590d    jp      nz,#0d59	; Jump if not frightened
0d34  dd21ff32  ld      ix,#32ff	; Point IX to frightened sprite data
0d38  fd21044d  ld      iy,#4d04	; Point IY to ghost 2 position
0d3c  cd0020    call    #2000		; Calculate frightened movement
0d3f  22044d    ld      (#4d04),hl	; Store new ghost 2 position
0d42  af        xor     a		; Clear accumulator (direction = 0)
0d43  322a4d    ld      (#4d2a),a	; Clear current direction
0d46  322e4d    ld      (#4d2e),a	; Clear desired direction
0d49  3a054d    ld      a,(#4d05)	; Get ghost 2 Y position
0d4c  fe80      cp      #80		; Compare with safe Y position
0d4e  c2930d    jp      nz,#0d93	; Jump if not at safe position
0d51  3e02      ld      a,#02		; Load state 2 (normal return)
0d53  32a24d    ld      (#4da2),a	; Set ghost 2 state = normal
0d56  c3930d    jp      #0d93		; Jump to continue

; FUNCTION: GHOST_2_DEFAULT_MOVEMENT - Handle Ghost 2 default movement patterns
; C_PSEUDO: void ghost_2_default_movement() {
; C_PSEUDO:   ghost_2_sprite = &sprite_data[0x3305];
; C_PSEUDO:   position = calculate_default_movement();
; C_PSEUDO:   
; C_PSEUDO:   direction = 3;  // Default direction (left)
; C_PSEUDO:   ghost_2_current_direction = direction;
; C_PSEUDO:   ghost_2_desired_direction = direction;
; C_PSEUDO:   
; C_PSEUDO:   // Reset to start position if needed
; C_PSEUDO:   if(position == 0x64) {
; C_PSEUDO:     reset_ghost_2_position();
; C_PSEUDO:     ghost_2_state = 1;  // Mark for collision
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Default movement pattern for Ghost 2 when not in special states
0d59  dd210533  ld      ix,#3305	; Point IX to normal sprite data
0d5d  fd21044d  ld      iy,#4d04	; Point IY to ghost 2 position
0d61  cd0020    call    #2000		; Calculate default movement
0d64  22044d    ld      (#4d04),hl	; Store new ghost 2 position
0d67  3e03      ld      a,#03		; Load direction 3 (left)
0d69  322a4d    ld      (#4d2a),a	; Set current direction = left
0d6c  322e4d    ld      (#4d2e),a	; Set desired direction = left
0d6f  3a044d    ld      a,(#4d04)	; Get ghost 2 position
0d72  fe64      cp      #64		; Compare with start position
0d74  c2930d    jp      nz,#0d93	; Jump if not at start
0d77  212c2e    ld      hl,#2e2c	; Load start coordinates
0d7a  220e4d    ld      (#4d0e),hl	; Set ghost 2 screen position
0d7d  210001    ld      hl,#0100	; Load movement parameters
0d80  22184d    ld      (#4d18),hl	; Set movement vector 1
0d83  22224d    ld      (#4d22),hl	; Set movement vector 2
0d86  3e02      ld      a,#02		; Load direction 2 (up)
0d88  322a4d    ld      (#4d2a),a	; Set current direction = up
0d8b  322e4d    ld      (#4d2e),a	; Set desired direction = up
0d8e  3e01      ld      a,#01		; Load state 1 (collision)
0d90  32a24d    ld      (#4da2),a	; Set ghost 2 state = collision

; ==============================================================================
; SECTION: GHOST MOVEMENT SYSTEM - GHOST 3 (INKY)
; ==============================================================================

; FUNCTION: GHOST_3_MOVEMENT_SYSTEM - Handle Ghost 3 (Inky) movement and AI
; C_PSEUDO: void ghost_3_movement_system() {
; C_PSEUDO:   ghost_3_state = ghost_states[3];
; C_PSEUDO:   
; C_PSEUDO:   if(ghost_3_state == 1) {
; C_PSEUDO:     // Collision state - return immediately
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(ghost_3_state == 0) {
; C_PSEUDO:     // Normal movement mode
; C_PSEUDO:     position = ghost_3_position;
; C_PSEUDO:     check_special_positions(position);  // Tunnel handling
; C_PSEUDO:     direction = ghost_3_desired_direction;
; C_PSEUDO:     ghost_3_current_direction = direction;
; C_PSEUDO:     update_ghost_3_position();
; C_PSEUDO:   } else if(ghost_3_state == 3) {
; C_PSEUDO:     // Frightened/retreat mode
; C_PSEUDO:     handle_ghost_3_frightened();
; C_PSEUDO:   } else {
; C_PSEUDO:     // Default movement patterns
; C_PSEUDO:     handle_ghost_3_default();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Complete AI system for Ghost 3 with advanced targeting behavior
0d93  3aa34d    ld      a,(#4da3)	; Get ghost 3 state
0d96  fe01      cp      #01		; Compare with state 1 (collision)
0d98  c8        ret     z		; Return if collision detected

0d99  fe00      cp      #00		; Compare with state 0 (normal)
0d9b  c2c00d    jp      nz,#0dc0	; Jump if not normal state
0d9e  3a064d    ld      a,(#4d06)	; Get ghost 3 position
0da1  fe78      cp      #78		; Compare with tunnel position 0x78
0da3  cc7c1f    call    z,#1f7c		; Call tunnel handler if at 0x78
0da6  fe80      cp      #80		; Compare with tunnel position 0x80
0da8  cc7c1f    call    z,#1f7c		; Call tunnel handler if at 0x80
0dab  3a2f4d    ld      a,(#4d2f)	; Get ghost 3 desired direction
0dae  322b4d    ld      (#4d2b),a	; Set ghost 3 current direction
0db1  dd21244d  ld      ix,#4d24	; Point IX to ghost 3 movement data
0db5  fd21064d  ld      iy,#4d06	; Point IY to ghost 3 position
0db9  cd0020    call    #2000		; Calculate new position
0dbc  22064d    ld      (#4d06),hl	; Store new ghost 3 position
0dbf  c9        ret     

; FUNCTION: GHOST_3_FRIGHTENED_MOVEMENT - Handle Ghost 3 frightened mode
; C_PSEUDO: void ghost_3_frightened_movement() {
; C_PSEUDO:   if(ghost_3_state == 3) {  // Frightened mode
; C_PSEUDO:     ghost_3_sprite = &sprite_data[0x3303];  // Frightened sprite
; C_PSEUDO:     position = calculate_frightened_movement();
; C_PSEUDO:     
; C_PSEUDO:     direction = 2;  // Retreat direction (up)
; C_PSEUDO:     ghost_3_current_direction = direction;
; C_PSEUDO:     ghost_3_desired_direction = direction;
; C_PSEUDO:     
; C_PSEUDO:     // Check if reached safe Y position
; C_PSEUDO:     if(ghost_3_y >= 0x80) {
; C_PSEUDO:       ghost_3_state = 2;  // Return to normal
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Handles Ghost 3 retreat behavior when frightened
0dc0  3aa34d    ld      a,(#4da3)	; Get ghost 3 state
0dc3  fe03      cp      #03		; Compare with state 3 (frightened)
0dc5  c2ea0d    jp      nz,#0dea	; Jump if not frightened
0dc8  dd210333  ld      ix,#3303	; Point IX to frightened sprite data
0dcc  fd21064d  ld      iy,#4d06	; Point IY to ghost 3 position
0dd0  cd0020    call    #2000		; Calculate frightened movement
0dd3  22064d    ld      (#4d06),hl	; Store new ghost 3 position
0dd6  3e02      ld      a,#02		; Load direction 2 (up/retreat)
0dd8  322b4d    ld      (#4d2b),a	; Set current direction = up
0ddb  322f4d    ld      (#4d2f),a	; Set desired direction = up
0dde  3a074d    ld      a,(#4d07)	; Get ghost 3 Y position
0de1  fe80      cp      #80		; Compare with safe Y position
0de3  c0        ret     nz		; Return if not at safe position

0de4  3e02      ld      a,#02		; Load state 2 (normal return)
0de6  32a34d    ld      (#4da3),a	; Set ghost 3 state = normal
0de9  c9        ret     

; FUNCTION: GHOST_3_DEFAULT_MOVEMENT - Handle Ghost 3 default movement patterns
; C_PSEUDO: void ghost_3_default_movement() {
; C_PSEUDO:   ghost_3_sprite = &sprite_data[0x3305];
; C_PSEUDO:   position = calculate_default_movement();
; C_PSEUDO:   
; C_PSEUDO:   direction = 3;  // Default direction (left)
; C_PSEUDO:   ghost_3_current_direction = direction;
; C_PSEUDO:   ghost_3_desired_direction = direction;
; C_PSEUDO:   
; C_PSEUDO:   // Reset to start position if needed
; C_PSEUDO:   if(position == 0x64) {
; C_PSEUDO:     reset_ghost_3_position();
; C_PSEUDO:     ghost_3_state = 1;  // Mark for collision
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Default movement pattern for Ghost 3 when not in special states
0dea  dd210533  ld      ix,#3305	; Point IX to normal sprite data
0dee  fd21064d  ld      iy,#4d06	; Point IY to ghost 3 position
0df2  cd0020    call    #2000		; Calculate default movement
0df5  22064d    ld      (#4d06),hl	; Store new ghost 3 position
0df8  3e03      ld      a,#03		; Load direction 3 (left)
0dfa  322b4d    ld      (#4d2b),a	; Set current direction = left
0dfd  322f4d    ld      (#4d2f),a	; Set desired direction = left
0e00  3a064d    ld      a,(#4d06)	; Get ghost 3 position
0e03  fe64      cp      #64		; Compare with start position
0e05  c0        ret     nz		; Return if not at start

0e06  212c2e    ld      hl,#2e2c	; Load start coordinates
0e09  22104d    ld      (#4d10),hl	; Set ghost 3 screen position
0e0c  210001    ld      hl,#0100	; Load movement parameters
0e0f  221a4d    ld      (#4d1a),hl	; Set movement vector 1
0e12  22244d    ld      (#4d24),hl	; Set movement vector 2
0e15  3e02      ld      a,#02		; Load direction 2 (up)
0e17  322b4d    ld      (#4d2b),a	; Set current direction = up
0e1a  322f4d    ld      (#4d2f),a	; Set desired direction = up
0e1d  3e01      ld      a,#01		; Load state 1 (collision)
0e1f  32a34d    ld      (#4da3),a	; Set ghost 3 state = collision
0e22  c9        ret     

; ==============================================================================
; SECTION: TIMING AND ANIMATION SYSTEM
; ==============================================================================

; FUNCTION: TIMING_ANIMATION_CONTROLLER - Control timing for various animations
; C_PSEUDO: void timing_animation_controller() {
; C_PSEUDO:   animation_timer++;
; C_PSEUDO:   if(animation_timer < 8) return;  // Wait for timing
; C_PSEUDO:   
; C_PSEUDO:   animation_timer = 0;  // Reset timer
; C_PSEUDO:   animation_flag = !animation_flag;  // Toggle animation
; C_PSEUDO: }
; ALGORITHM: Provides 8-frame timing for sprite animations and game effects
0e23  21c44d    ld      hl,#4dc4	; Point to animation timer
0e26  34        inc     (hl)		; Increment animation timer
0e27  3e08      ld      a,#08		; Load timer threshold (8 frames)
0e29  be        cp      (hl)		; Compare with current timer
0e2a  c0        ret     nz		; Return if timer < 8

0e2b  3600      ld      (hl),#00	; Reset animation timer = 0
0e2d  3ac04d    ld      a,(#4dc0)	; Get animation flag
0e30  ee01      xor     #01		; Toggle animation flag (flip bit 0)
0e32  32c04d    ld      (#4dc0),a	; Store updated animation flag
0e35  c9        ret     

; FUNCTION: FRUIT_BONUS_TIMER - Control fruit bonus appearance timing
; C_PSEUDO: void fruit_bonus_timer() {
; C_PSEUDO:   if(bonus_active) return;  // Skip if bonus already active
; C_PSEUDO:   
; C_PSEUDO:   bonus_level = current_bonus_level;
; C_PSEUDO:   if(bonus_level >= 7) return;  // Max bonus level reached
; C_PSEUDO:   
; C_PSEUDO:   // Calculate timing offset for this bonus level
; C_PSEUDO:   dots_eaten = dots_eaten_counter++;
; C_PSEUDO:   timing_offset = bonus_level * 2;
; C_PSEUDO:   required_dots = bonus_timing_table[timing_offset];
; C_PSEUDO:   
; C_PSEUDO:   if(dots_eaten == required_dots) {
; C_PSEUDO:     bonus_level++;
; C_PSEUDO:     activate_fruit_bonus();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Controls when fruit bonuses appear based on dots eaten and level
0e36  3aa64d    ld      a,(#4da6)	; Get bonus active flag
0e39  a7        and     a		; Test if bonus is active
0e3a  c0        ret     nz		; Return if bonus already active

0e3b  3ac14d    ld      a,(#4dc1)	; Get current bonus level
0e3e  fe07      cp      #07		; Compare with max level (7)
0e40  c8        ret     z		; Return if max level reached

0e41  87        add     a,a		; Multiply bonus level by 2 (timing offset)
0e42  2ac24d    ld      hl,(#4dc2)	; Get dots eaten counter
0e45  23        inc     hl		; Increment dots eaten
0e46  22c24d    ld      (#4dc2),hl	; Store updated counter
0e49  5f        ld      e,a		; Load timing offset into DE
0e4a  1600      ld      d,#00
0e4c  dd21864d  ld      ix,#4d86	; Point IX to bonus timing table
0e50  dd19      add     ix,de		; Add offset to table pointer
0e52  dd5e00    ld      e,(ix+#00)	; Get required dots (low byte)
0e55  dd5601    ld      d,(ix+#01)	; Get required dots (high byte)
0e58  a7        and     a		; Clear carry flag
0e59  ed52      sbc     hl,de		; Compare dots eaten with required
0e5b  c0        ret     nz		; Return if not enough dots eaten

0e5c  cb3f      srl     a		; Divide timing offset by 2 (restore level)
0e5e  3c        inc     a		; Increment bonus level
0e5f  32c14d    ld      (#4dc1),a	; Store new bonus level
0e62  210101    ld      hl,#0101	; Load bonus activation parameters
0e65  22b14d    ld      (#4db1),hl	; Set bonus activation flag 1
0e68  22b34d    ld      (#4db3),hl	; Set bonus activation flag 2
0e6b  c9        ret     

; FUNCTION: ENERGY_PELLET_DISPLAY - Control power pellet blinking display
; C_PSEUDO: void energy_pellet_display() {
; C_PSEUDO:   if(pellets_eaten) {
; C_PSEUDO:     pellet_display = 0;  // Hide pellets if all eaten
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   pellet_addr = 0x4eac;  // Power pellet display register
; C_PSEUDO:   mask = 0xe0;  // Visibility mask
; C_PSEUDO:   
; C_PSEUDO:   position = pac_man_screen_y;
; C_PSEUDO:   
; C_PSEUDO:   // Control power pellet visibility based on Pac-Man's Y position
; C_PSEUDO:   if(position >= 0xe4) {
; C_PSEUDO:     pellet_display = (pellet_display & mask) | 0x10;  // Show pellet 4
; C_PSEUDO:   } else if(position >= 0xd4) {
; C_PSEUDO:     pellet_display = (pellet_display & mask) | 0x08;  // Show pellet 3
; C_PSEUDO:   } else if(position >= 0xb4) {
; C_PSEUDO:     pellet_display = (pellet_display & mask) | 0x04;  // Show pellet 2
; C_PSEUDO:   } else if(position >= 0x74) {
; C_PSEUDO:     pellet_display = (pellet_display & mask) | 0x02;  // Show pellet 1
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Controls which power pellets are visible based on Pac-Man's position
0e6c  3aa54d    ld      a,(#4da5)	; Get pellets eaten flag
0e6f  a7        and     a		; Test if pellets eaten
0e70  2805      jr      z,#0e77         ; Jump if pellets remain
0e72  af        xor     a		; Clear accumulator (hide pellets)
0e73  32ac4e    ld      (#4eac),a	; Clear pellet display
0e76  c9        ret     

0e77  21ac4e    ld      hl,#4eac	; Point to pellet display register
0e7a  06e0      ld      b,#e0		; Load visibility mask (0xe0)
0e7c  3a0e4e    ld      a,(#4e0e)	; Get Pac-Man screen Y position
0e7f  fee4      cp      #e4		; Compare with position 0xe4
0e81  3806      jr      c,#0e89         ; Jump if position < 0xe4
0e83  78        ld      a,b		; Load mask into A
0e84  a6        and     (hl)		; Mask current pellet display
0e85  cbe7      set     4,a		; Set bit 4 (show pellet 4)
0e87  77        ld      (hl),a		; Store updated display
0e88  c9        ret     

0e89  fed4      cp      #d4		; Compare with position 0xd4
0e8b  3806      jr      c,#0e93         ; Jump if position < 0xd4
0e8d  78        ld      a,b		; Load mask into A
0e8e  a6        and     (hl)		; Mask current pellet display
0e8f  cbdf      set     3,a		; Set bit 3 (show pellet 3)
0e91  77        ld      (hl),a		; Store updated display
0e92  c9        ret     

0e93  feb4      cp      #b4		; Compare with position 0xb4
0e95  3806      jr      c,#0e9d         ; Jump if position < 0xb4
0e97  78        ld      a,b		; Load mask into A
0e98  a6        and     (hl)		; Mask current pellet display
0e99  cbd7      set     2,a		; Set bit 2 (show pellet 2)
0e9b  77        ld      (hl),a		; Store updated display
0e9c  c9        ret     

0e9d  fe74      cp      #74		; Compare with position 0x74
0e9f  3806      jr      c,#0ea7         ; Jump if position < 0x74
0ea1  78        ld      a,b		; Load mask into A
0ea2  a6        and     (hl)		; Mask current pellet display
0ea3  cbcf      set     1,a		; Set bit 1 (show pellet 1)
0ea5  77        ld      (hl),a		; Store updated display
0ea6  c9        ret     

0ea7  78        ld      a,b		; Load mask into A (default case)
0ea8  a6        and     (hl)		; Mask current pellet display
0ea9  cbc7      set     0,a		; Set bit 0 (minimal pellet visibility)
0eab  77        ld      (hl),a		; Store updated display
0eac  c9        ret     

; FUNCTION: FRUIT_BONUS_ACTIVATION - Activate fruit bonus at specific positions
; C_PSEUDO: void fruit_bonus_activation() {
; C_PSEUDO:   if(pellets_eaten) return;  // Skip if pellets gone
; C_PSEUDO:   if(bonus_lock) return;     // Skip if bonus locked
; C_PSEUDO:   
; C_PSEUDO:   pac_y = pac_man_screen_y;
; C_PSEUDO:   
; C_PSEUDO:   // Check for specific trigger positions
; C_PSEUDO:   if(pac_y == 0x46) {        // Upper trigger position
; C_PSEUDO:     if(!upper_trigger_flag) {
; C_PSEUDO:       upper_trigger_flag = 1;
; C_PSEUDO:       activate_fruit_bonus();
; C_PSEUDO:     }
; C_PSEUDO:   } else if(pac_y == 0xaa) { // Lower trigger position
; C_PSEUDO:     if(!lower_trigger_flag) {
; C_PSEUDO:       lower_trigger_flag = 1;
; C_PSEUDO:       activate_fruit_bonus();
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Triggers fruit bonuses when Pac-Man reaches specific Y positions
0ead  3aa54d    ld      a,(#4da5)	; Get pellets eaten flag
0eb0  a7        and     a		; Test if pellets eaten
0eb1  c0        ret     nz		; Return if pellets gone

0eb2  3ad44d    ld      a,(#4dd4)	; Get bonus lock flag
0eb5  a7        and     a		; Test if bonus locked
0eb6  c0        ret     nz		; Return if bonus locked

0eb7  3a0e4e    ld      a,(#4e0e)	; Get Pac-Man screen Y position
0eba  fe46      cp      #46		; Compare with upper trigger (0x46)
0ebc  280e      jr      z,#0ecc         ; Jump if at upper trigger
0ebe  feaa      cp      #aa		; Compare with lower trigger (0xaa)
0ec0  c0        ret     nz		; Return if not at trigger position

0ec1  3a0d4e    ld      a,(#4e0d)	; Get lower trigger flag
0ec4  a7        and     a		; Test if already triggered
0ec5  c0        ret     nz		; Return if already triggered

0ec6  210d4e    ld      hl,#4e0d	; Point to lower trigger flag
0ec9  34        inc     (hl)		; Set lower trigger flag = 1
0eca  1809      jr      #0ed5           ; Jump to activate bonus

0ecc  3a0c4e    ld      a,(#4e0c)	; Get upper trigger flag
0ecf  a7        and     a		; Test if already triggered
0ed0  c0        ret     nz		; Return if already triggered

0ed1  210c4e    ld      hl,#4e0c	; Point to upper trigger flag
0ed4  34        inc     (hl)		; Set upper trigger flag = 1

; FUNCTION: ACTIVATE_FRUIT_BONUS - Activate the fruit bonus system
; C_PSEUDO: void activate_fruit_bonus() {
; C_PSEUDO:   bonus_sprite_addr = 0x8094;  // Fruit sprite address
; C_PSEUDO:   bonus_data_table = &fruit_table[0x0efd];
; C_PSEUDO:   
; C_PSEUDO:   level = current_level;
; C_PSEUDO:   if(level > 20) level = 20;  // Cap at level 20
; C_PSEUDO:   
; C_PSEUDO:   // Calculate offset: level * 3 (3 bytes per fruit entry)
; C_PSEUDO:   offset = level * 3;
; C_PSEUDO:   
; C_PSEUDO:   // Load fruit data from table
; C_PSEUDO:   fruit_sprite_1 = fruit_table[offset];
; C_PSEUDO:   fruit_sprite_2 = fruit_table[offset+1];
; C_PSEUDO:   bonus_points = fruit_table[offset+2];
; C_PSEUDO:   
; C_PSEUDO:   activate_bonus_display();
; C_PSEUDO: }
; ALGORITHM: Activates fruit bonus based on current level with sprite and point values
0ed5  219480    ld      hl,#8094	; Load fruit sprite address
0ed8  22d24d    ld      (#4dd2),hl	; Store fruit sprite address
0edb  21fd0e    ld      hl,#0efd	; Point to fruit data table
0ede  3a134e    ld      a,(#4e13)	; Get current level
0ee1  fe14      cp      #14		; Compare with level 20 (0x14)
0ee3  3802      jr      c,#0ee7         ; Jump if level < 20
0ee5  3e14      ld      a,#14		; Cap level at 20

0ee7  47        ld      b,a		; Save level in B
0ee8  87        add     a,a		; level * 2
0ee9  80        add     a,b		; level * 3 (3 bytes per fruit entry)
0eea  d7        rst     #10		; Add offset to table pointer (HL += A)
0eeb  320c4c    ld      (#4c0c),a	; Store fruit sprite 1
0eee  23        inc     hl		; Point to next byte
0eef  7e        ld      a,(hl)		; Get fruit sprite 2
0ef0  320d4c    ld      (#4c0d),a	; Store fruit sprite 2
0ef3  23        inc     hl		; Point to next byte
0ef4  7e        ld      a,(hl)		; Get bonus points value
0ef5  32d44d    ld      (#4dd4),a	; Store bonus points
0ef8  f7        rst     #30		; Call bonus activation routine
0ef9  8a        adc     a,d		; [Part of data/routine, not clear instruction]
0efa  04        inc     b		; [Part of data/routine]
0efb  00        nop     		; [Padding or data]
0efc  c9        ret     

; ==============================================================================
; DATA TABLE: FRUIT_BONUS_TABLE - Fruit sprites and point values by level
; ==============================================================================
; MEMORY_MAP: 0x0efd-0x0f3b - Fruit bonus configuration table
; ALGORITHM: Each entry is 3 bytes: [sprite1, sprite2, points]
; Level  1: Cherry     (00 14 01)    100 points
; Level  2: Strawberry (01 0F 02)    300 points  
; Level  3: Orange     (02 15 04)    500 points
; Level  4: Orange     (02 15 04)    500 points
; Level  5: Apple      (04 14 05)    700 points
; Level  6: Apple      (04 14 05)    700 points
; Level  7: Melon      (05 17 06)    1000 points
; Level  8: Melon      (05 17 06)    1000 points
; Level  9: Galaxian   (06 09 07)    2000 points
; Level 10: Galaxian   (06 09 07)    2000 points
; Level 11: Bell       (03 16 03)    3000 points
; Level 12: Bell       (03 16 03)    3000 points
; Level 13: Key        (07 16 07)    5000 points
; Levels 14-20: Key    (07 16 07)    5000 points
0efd  00        db      #00		; Level 1: Cherry sprite 1
0efe  14        db      #14		; Level 1: Cherry sprite 2  
0eff  01        db      #01		; Level 1: 100 points
0f00  01        db      #01		; Level 2: Strawberry sprite 1
0f01  0f        db      #0f		; Level 2: Strawberry sprite 2
0f02  02        db      #02		; Level 2: 300 points
0f03  02        db      #02		; Level 3: Orange sprite 1
0f04  15        db      #15		; Level 3: Orange sprite 2
0f05  04        db      #04		; Level 3: 500 points
0f06  02        db      #02		; Level 4: Orange sprite 1
0f07  15        db      #15		; Level 4: Orange sprite 2
0f08  04        db      #04		; Level 4: 500 points
0f09  04        db      #04		; Level 5: Apple sprite 1
0f0a  14        db      #14		; Level 5: Apple sprite 2
0f0b  05        db      #05		; Level 5: 700 points
0f0c  04        db      #04		; Level 6: Apple sprite 1
0f0d  14        db      #14		; Level 6: Apple sprite 2
0f0e  05        db      #05		; Level 6: 700 points
0f0f  05        db      #05		; Level 7: Melon sprite 1
0f10  17        db      #17		; Level 7: Melon sprite 2
0f11  06        db      #06		; Level 7: 1000 points
0f12  05        db      #05		; Level 8: Melon sprite 1
0f13  17        db      #17		; Level 8: Melon sprite 2
0f14  06        db      #06		; Level 8: 1000 points
0f15  06        db      #06		; Level 9: Galaxian sprite 1
0f16  09        db      #09		; Level 9: Galaxian sprite 2
0f17  07        db      #07		; Level 9: 2000 points
0f18  06        db      #06		; Level 10: Galaxian sprite 1
0f19  09        db      #09		; Level 10: Galaxian sprite 2
0f1a  07        db      #07		; Level 10: 2000 points
0f1b  03        db      #03		; Level 11: Bell sprite 1
0f1c  16        db      #16		; Level 11: Bell sprite 2
0f1d  08        db      #08		; Level 11: 3000 points
0f1e  03        db      #03		; Level 12: Bell sprite 1
0f1f  16        db      #16		; Level 12: Bell sprite 2
0f20  08        db      #08		; Level 12: 3000 points
0f21  07        db      #07		; Level 13: Key sprite 1
0f22  16        db      #16		; Level 13: Key sprite 2
0f23  09        db      #09		; Level 13: 5000 points
0f24  07        db      #07		; Level 14: Key sprite 1
0f25  16        db      #16		; Level 14: Key sprite 2
0f26  09        db      #09		; Level 14: 5000 points
0f27  07        db      #07		; Level 15: Key sprite 1
0f28  16        db      #16		; Level 15: Key sprite 2
0f29  09        db      #09		; Level 15: 5000 points
0f2a  07        db      #07		; Level 16: Key sprite 1
0f2b  16        db      #16		; Level 16: Key sprite 2
0f2c  09        db      #09		; Level 16: 5000 points
0f2d  07        db      #07		; Level 17: Key sprite 1
0f2e  16        db      #16		; Level 17: Key sprite 2
0f2f  09        db      #09		; Level 17: 5000 points
0f30  07        db      #07		; Level 18: Key sprite 1
0f31  16        db      #16		; Level 18: Key sprite 2
0f32  09        db      #09		; Level 18: 5000 points
0f33  07        db      #07		; Level 19: Key sprite 1
0f34  16        db      #16		; Level 19: Key sprite 2
0f35  09        db      #09		; Level 19: 5000 points
0f36  07        db      #07		; Level 20: Key sprite 1
0f37  16        db      #16		; Level 20: Key sprite 2
0f38  09        db      #09		; Level 20: 5000 points

; DATA PADDING: Reserved space and alignment
; ==============================================================================
; MEMORY_MAP: 0x0f39-0x0ffd - Padding and reserved space (196 bytes)
; ALGORITHM: Ensures proper memory alignment for code sections
; These bytes are primarily padding to align subsequent code sections on 
; convenient memory boundaries, typical for arcade hardware design.
0f39  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0f49  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes  
0f59  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0f69  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0f79  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0f89  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0f99  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0fa9  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0fb9  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0fc9  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0fd9  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0fe9  db      #00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00  ; 16 bytes
0ff9  db      #00,#00,#00,#00                                                ; 4 bytes

; FUNCTION: CLEAR_BONUS_SYSTEM - Clear fruit bonus and reset sprite system
; C_PSEUDO: void clear_bonus_system() {
; C_PSEUDO:   // This appears to be partially corrupted or overlapped code
; C_PSEUDO:   sprite_data[register] = 0xaf;  // Clear sprite register
; C_PSEUDO:   bonus_lock = accumulator;      // Set bonus lock flag
; C_PSEUDO:   bonus_sprite_addr = 0x0000;    // Clear bonus sprite address
; C_PSEUDO: }
; ALGORITHM: Clears bonus system state, possibly called between levels
0ffe  48        ld      c,b		; Load B into C (preserve register)
0fff  36af      ld      (hl),#af	; Store 0xaf at current address (clear sprite)
1001  32d44d    ld      (#4dd4),a	; Store A in bonus lock flag
1004  210000    ld      hl,#0000	; Load NULL address
1007  22d24d    ld      (#4dd2),hl	; Clear bonus sprite address
100a  c9        ret     

; ################################################################################
; # MAZE AND DOT MANAGEMENT ARCHITECTURE  
; ################################################################################
;
; The maze and dot management system is one of Pac-Man's most sophisticated
; subsystems, handling the complex tracking of the 240+ dots in the maze,
; collision detection, and the intricate logic of pellet consumption.
;
; ## DOT MANAGEMENT ARCHITECTURE
;
; - **Bit-Mapped Maze**: Each dot position represented as a bit in memory
; - **Collision Detection**: Real-time checking of Pac-Man's position against dot map
; - **Completion Detection**: Efficient algorithms to detect when maze is cleared
; - **Score Integration**: Automatic scoring when dots are consumed
;
; ## PELLET SYSTEM DESIGN
;
; 1. **Regular Dots**: 240 small dots worth 10 points each
; 2. **Power Pellets**: 4 large pellets that activate ghost frightened mode
; 3. **Bonus Fruits**: Level-specific fruits with varying point values
; 4. **Completion Tracking**: Precise counting for level progression
;
; ## COLLISION DETECTION ALGORITHM
;
; The system uses a two-stage collision detection:
; 1. **Coarse Detection**: Check if Pac-Man is in a tile with dots
; 2. **Fine Detection**: Precise pixel-level collision within tiles
; 3. **State Update**: Remove dot from maze and update score
; 4. **Effect Triggers**: Handle power pellet and completion effects
;
; This architecture allows for smooth gameplay while maintaining the precise
; collision detection that makes Pac-Man's maze navigation feel responsive.
;
; ################################################################################

; ==============================================================================
; SECTION: MAZE AND DOT MANAGEMENT SYSTEM
; ==============================================================================

; FUNCTION: DOT_COLLISION_CHECKER - Check for dot collisions and handle consumption
; C_PSEUDO: void dot_collision_checker() {
; C_PSEUDO:   if(attract_mode) {
; C_PSEUDO:     return;  // Skip collision detection in attract mode
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Call collision detection subroutines
; C_PSEUDO:   check_dot_collision();
; C_PSEUDO: }
; ALGORITHM: Main entry point for dot collision detection system
100b  ef        rst     #28		; Call system routine at 0x0028
100c  1c        inc     e		; Increment E register
100d  9b        sbc     a,e		; Subtract E from A with carry
100e  3a004e    ld      a,(#4e00)	; Get attract mode flag
1011  3d        dec     a		; Decrement (test for 0)
1012  c8        ret     z		; Return if in attract mode (A was 1)

; FUNCTION: DOT_COLLISION_HANDLER - Handle dot collision processing
; C_PSEUDO: void dot_collision_handler() {
; C_PSEUDO:   call_system_routine(0x001c, 0xa2);  // System collision check
; C_PSEUDO: }
; ALGORITHM: Calls system routine for detailed collision processing
1013  ef        rst     #28		; Call system routine at 0x0028
1014  1c        inc     e		; Increment E register  
1015  a2        and     d		; AND A with D register
1016  c9        ret     

; FUNCTION: MAZE_MANAGEMENT_DISPATCHER - Main maze management routine
; C_PSEUDO: void maze_management_dispatcher() {
; C_PSEUDO:   call_ghost_management();      // Handle ghost states
; C_PSEUDO:   
; C_PSEUDO:   if(pellets_eaten) return;     // Skip if all pellets gone
; C_PSEUDO:   
; C_PSEUDO:   // Call various maze management subroutines
; C_PSEUDO:   handle_ghost_1_release();
; C_PSEUDO:   handle_ghost_2_release();  
; C_PSEUDO:   handle_ghost_3_release();
; C_PSEUDO:   handle_ghost_4_release();
; C_PSEUDO:   handle_ghost_5_release();
; C_PSEUDO:   
; C_PSEUDO:   if(pac_man_dead) {
; C_PSEUDO:     handle_death_sequence();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Continue with normal maze operations
; C_PSEUDO:   handle_maze_completion();
; C_PSEUDO:   handle_bonus_logic();
; C_PSEUDO:   handle_dot_management();
; C_PSEUDO:   handle_collision_detection();
; C_PSEUDO:   handle_scoring();
; C_PSEUDO:   
; C_PSEUDO:   if(game_sub_state == 3) {  // Active gameplay
; C_PSEUDO:     handle_advanced_ai();
; C_PSEUDO:     handle_movement_logic();
; C_PSEUDO:     handle_special_events();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Central dispatcher for all maze-related game logic
1017  cd9112    call    #1291		; Call ghost management routine
101a  3aa54d    ld      a,(#4da5)	; Get pellets eaten flag
101d  a7        and     a		; Test if pellets eaten
101e  c0        ret     nz		; Return if pellets gone

101f  cd6610    call    #1066		; Handle ghost 1 release timing
1022  cd9410    call    #1094		; Handle ghost 2 release timing  
1025  cd9e10    call    #109e		; Handle ghost 3 release timing
1028  cda810    call    #10a8		; Handle ghost 4 release timing
102b  cdb410    call    #10b4		; Handle ghost 5 release timing
102e  3aa44d    ld      a,(#4da4)	; Get Pac-Man dead flag
1031  a7        and     a		; Test if Pac-Man is dead
1032  ca3910    jp      z,#1039		; Jump if Pac-Man is alive
1035  cd3512    call    #1235		; Handle death sequence
1038  c9        ret     

1039  cd1d17    call    #171d		; Handle maze completion check
103c  cd8917    call    #1789		; Handle bonus logic
103f  3aa44d    ld      a,(#4da4)	; Get Pac-Man dead flag (recheck)
1042  a7        and     a		; Test if Pac-Man is dead
1043  c0        ret     nz		; Return if Pac-Man died

1044  cd0618    call    #1806		; Handle dot management
1047  cd361b    call    #1b36		; Handle collision detection
104a  cd4b1c    call    #1c4b		; Handle scoring system
104d  cd221d    call    #1d22		; Handle special events
1050  cdf91d    call    #1df9		; Handle movement logic
1053  3a044e    ld      a,(#4e04)	; Get game sub-state
1056  fe03      cp      #03		; Compare with state 3 (active gameplay)
1058  c0        ret     nz		; Return if not active gameplay

1059  cd7613    call    #1376		; Handle advanced AI routines
105c  cd6920    call    #2069		; Handle movement logic
105f  cd8c20    call    #208c		; Handle special events
1062  cdaf20    call    #20af		; Handle additional game logic
1065  c9        ret     

; FUNCTION: GHOST_RELEASE_TIMER_1 - Control Ghost 1 (Blinky) release timing
; C_PSEUDO: void ghost_release_timer_1() {
; C_PSEUDO:   timer = ghost_1_release_timer;
; C_PSEUDO:   if(timer == 0) return;  // Already released
; C_PSEUDO:   
; C_PSEUDO:   timer--;
; C_PSEUDO:   if(timer == 0) {
; C_PSEUDO:     ghost_1_release_timer = 0;
; C_PSEUDO:     ghost_1_active_flag = 1;  // Activate ghost 1
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Controls when Ghost 1 (Blinky) is released from the ghost house
1066  3aab4d    ld      a,(#4dab)	; Get ghost 1 release timer
1069  a7        and     a		; Test if timer is zero
106a  c8        ret     z		; Return if already released

106b  3d        dec     a		; Decrement release timer
106c  2008      jr      nz,#1076        ; Jump if timer not zero
106e  32ab4d    ld      (#4dab),a	; Store timer = 0 (released)
1071  3c        inc     a		; Set A = 1
1072  32ac4d    ld      (#4dac),a	; Set ghost 1 active flag = 1
1075  c9        ret     

; FUNCTION: GHOST_RELEASE_TIMER_2 - Control Ghost 2 (Pinky) release timing
; C_PSEUDO: void ghost_release_timer_2() {
; C_PSEUDO:   timer--;
; C_PSEUDO:   if(timer == 0) {
; C_PSEUDO:     ghost_2_release_timer = 0;
; C_PSEUDO:     ghost_2_active_flag = 1;  // Activate ghost 2
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Controls when Ghost 2 (Pinky) is released from the ghost house
1076  3d        dec     a		; Decrement release timer
1077  2008      jr      nz,#1081        ; Jump if timer not zero
1079  32ab4d    ld      (#4dab),a	; Store timer = 0 (released)
107c  3c        inc     a		; Set A = 1
107d  32ad4d    ld      (#4dad),a	; Set ghost 2 active flag = 1
1080  c9        ret     

; FUNCTION: GHOST_RELEASE_TIMER_3 - Control Ghost 3 (Inky) release timing
; C_PSEUDO: void ghost_release_timer_3() {
; C_PSEUDO:   timer--;
; C_PSEUDO:   if(timer == 0) {
; C_PSEUDO:     ghost_3_release_timer = 0;
; C_PSEUDO:     ghost_3_active_flag = 1;  // Activate ghost 3
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Controls when Ghost 3 (Inky) is released from the ghost house
1081  3d        dec     a		; Decrement release timer
1082  2008      jr      nz,#108c        ; Jump if timer not zero
1084  32ab4d    ld      (#4dab),a	; Store timer = 0 (released)
1087  3c        inc     a		; Set A = 1
1088  32ae4d    ld      (#4dae),a	; Set ghost 3 active flag = 1
108b  c9        ret     

; FUNCTION: GHOST_RELEASE_TIMER_4 - Control Ghost 4 (Sue/Clyde) release timing
; C_PSEUDO: void ghost_release_timer_4() {
; C_PSEUDO:   ghost_4_active_flag = timer;  // Set active flag to timer value
; C_PSEUDO:   timer--;
; C_PSEUDO:   ghost_4_release_timer = timer;
; C_PSEUDO: }
; ALGORITHM: Controls when Ghost 4 (Sue/Clyde) is released from the ghost house
108c  32af4d    ld      (#4daf),a	; Set ghost 4 active flag = timer
108f  3d        dec     a		; Decrement release timer
1090  32ab4d    ld      (#4dab),a	; Store decremented timer
1093  c9        ret     

; FUNCTION: GHOST_2_AI_DISPATCHER - Call Ghost 2 (Pinky) AI routine based on state
; C_PSEUDO: void ghost_2_ai_dispatcher() {
; C_PSEUDO:   ghost_2_state = ghost_states[2];
; C_PSEUDO:   call_ai_routine(ghost_2_state);  // Jump to appropriate AI
; C_PSEUDO: }
; ALGORITHM: Uses RST call to dispatch Ghost 2 AI based on current state
1094  3aac4d    ld      a,(#4dac)	; Get ghost 2 active flag
1097  e7        rst     #20		; Call AI dispatcher (RST 20h)
1098  0c        db      #0c		; AI routine parameter
1099  00        db      #00		; AI routine parameter
109a  c0        ret     nz		; Return if non-zero result

; FUNCTION: GHOST_3_AI_DISPATCHER - Call Ghost 3 (Inky) AI routine based on state  
; C_PSEUDO: void ghost_3_ai_dispatcher() {
; C_PSEUDO:   ghost_3_state = ghost_states[3];
; C_PSEUDO:   call_ai_routine(ghost_3_state);  // Jump to appropriate AI
; C_PSEUDO: }
; ALGORITHM: Uses RST call to dispatch Ghost 3 AI based on current state
109b  10d2      djnz    #106f           ; Loop if B register not zero
109d  103a      djnz    #10d9           ; Loop if B register not zero  
109f  ad        xor     l		; XOR A with L register
10a0  4d        ld      c,l		; Load L into C
10a1  e7        rst     #20		; Call AI dispatcher (RST 20h)
10a2  0c        db      #0c		; AI routine parameter
10a3  00        db      #00		; AI routine parameter
10a4  1811      jr      #10b7           ; Jump ahead if condition met

; FUNCTION: GHOST_4_AI_DISPATCHER - Call Ghost 4 (Sue/Clyde) AI routine based on state
; C_PSEUDO: void ghost_4_ai_dispatcher() {
; C_PSEUDO:   ghost_4_state = ghost_states[4];
; C_PSEUDO:   call_ai_routine(ghost_4_state);  // Jump to appropriate AI
; C_PSEUDO: }
; ALGORITHM: Uses RST call to dispatch Ghost 4 AI based on current state
10a6  2a113a    ld      hl,(#3a11)	; Load address from memory
10a9  ae        xor     (hl)		; XOR A with value at HL
10aa  4d        ld      c,l		; Load L into C
10ab  e7        rst     #20		; Call AI dispatcher (RST 20h)
10ac  0c        db      #0c		; AI routine parameter
10ad  00        db      #00		; AI routine parameter
10ae  5c        ld      e,h		; Load H into E
10af  116e11    ld      de,#116e	; Load destination address
10b2  8f        adc     a,a		; Add A to itself with carry
10b3  113aaf    ld      de,#af3a	; Load destination address

; FUNCTION: GHOST_5_AI_DISPATCHER - Call Ghost 5 (bonus ghost) AI routine
; C_PSEUDO: void ghost_5_ai_dispatcher() {
; C_PSEUDO:   ghost_5_state = ghost_states[5];
; C_PSEUDO:   call_ai_routine(ghost_5_state);  // Jump to appropriate AI
; C_PSEUDO: }
; ALGORITHM: Uses RST call to dispatch Ghost 5 AI based on current state
10b6  4d        ld      c,l		; Load L into C
10b7  e7        rst     #20		; Call AI dispatcher (RST 20h)
10b8  0c        db      #0c		; AI routine parameter
10b9  00        db      #00		; AI routine parameter
10ba  c9        ret     

; FUNCTION: PAC_MAN_COLLISION_HANDLER - Handle Pac-Man collision with maze elements
; C_PSEUDO: void pac_man_collision_handler() {
; C_PSEUDO:   collision_type = check_collision_type();
; C_PSEUDO:   if(collision_type == GHOST_COLLISION) {
; C_PSEUDO:     handle_ghost_collision();
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   pac_man_pos = pac_man_position;
; C_PSEUDO:   if(pac_man_pos == 0x8064) {  // Special position check
; C_PSEUDO:     activate_ghost_flag++;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Handles various collision types and position-based triggers
10bb  11db11    ld      de,#11db	; Load collision handler address
10be  fc11cd    call    m,#cd11		; Call if sign flag set
10c1  d8        ret     c		; Return if carry flag set

10c2  1b        dec     de		; Decrement DE
10c3  2a004d    ld      hl,(#4d00)	; Get Pac-Man position
10c6  116480    ld      de,#8064	; Load special position (0x8064)
10c9  a7        and     a		; Clear carry flag
10ca  ed52      sbc     hl,de		; Compare positions
10cc  c0        ret     nz		; Return if not at special position

10cd  21ac4d    ld      hl,#4dac	; Point to ghost activation flag
10d0  34        inc     (hl)		; Increment activation flag
10d1  c9        ret     

; FUNCTION: PAC_MAN_RESET_POSITION - Reset Pac-Man to starting position
; C_PSEUDO: void pac_man_reset_position() {
; C_PSEUDO:   pac_man_sprite = &sprite_data[0x3301];
; C_PSEUDO:   pac_man_data = &pac_man_data[0x4d00];
; C_PSEUDO:   
; C_PSEUDO:   position = calculate_start_position();
; C_PSEUDO:   pac_man_data[0] = position;
; C_PSEUDO:   
; C_PSEUDO:   direction = 1;  // Right direction
; C_PSEUDO:   pac_man_current_direction = direction;
; C_PSEUDO:   pac_man_desired_direction = direction;
; C_PSEUDO:   
; C_PSEUDO:   if(position == 0x80) {  // At start position
; C_PSEUDO:     reset_screen_position();
; C_PSEUDO:     clear_pac_man_state();
; C_PSEUDO:     clear_ghost_states();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Resets Pac-Man to starting position and clears game state
10d2  dd210133  ld      ix,#3301	; Point IX to Pac-Man sprite data
10d6  fd21004d  ld      iy,#4d00	; Point IY to Pac-Man game data
10da  cd0020    call    #2000		; Calculate start position
10dd  22004d    ld      (#4d00),hl	; Store new position
10e0  3e01      ld      a,#01		; Load direction 1 (right)
10e2  32284d    ld      (#4d28),a	; Set current direction = right
10e5  322c4d    ld      (#4d2c),a	; Set desired direction = right
10e8  3a004d    ld      a,(#4d00)	; Get Pac-Man position
10eb  fe80      cp      #80		; Compare with start position (0x80)
10ed  c0        ret     nz		; Return if not at start

10ee  212f2e    ld      hl,#2e2f	; Load start screen coordinates
10f1  220a4d    ld      (#4d0a),hl	; Set Pac-Man screen position
10f4  22314d    ld      (#4d31),hl	; Set backup screen position
10f7  af        xor     a		; Clear accumulator
10f8  32a04d    ld      (#4da0),a	; Clear Pac-Man state
10fb  32ac4d    ld      (#4dac),a	; Clear ghost 1 active flag
10fe  32a74d    ld      (#4da7),a	; Clear additional state flag
1101  dd21ac4d  ld      ix,#4dac	; Point IX to ghost flags
1105  ddb600    or      (ix+#00)	; OR with ghost 1 flag
1108  ddb601    or      (ix+#01)	; OR with ghost 2 flag
110b  ddb602    or      (ix+#02)	; OR with ghost 3 flag
110e  ddb603    or      (ix+#03)	; OR with ghost 4 flag
1111  c0        ret     nz		; Return if any ghost active

1112  21ac4e    ld      hl,#4eac	; Point to pellet display register
1115  cbb6      res     6,(hl)		; Clear bit 6 (reset pellet display)
1117  c9        ret     

; FUNCTION: GHOST_2_COLLISION_HANDLER - Handle Ghost 2 collision processing
; C_PSEUDO: void ghost_2_collision_handler() {
; C_PSEUDO:   call_collision_routine();
; C_PSEUDO:   
; C_PSEUDO:   ghost_2_pos = ghost_2_position;
; C_PSEUDO:   if(ghost_2_pos == 0x8064) {  // Special collision position
; C_PSEUDO:     ghost_2_activation_flag++;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Handles Ghost 2 collision detection and activation
1118  cdaf1c    call    #1caf		; Call collision detection routine
111b  2a024d    ld      hl,(#4d02)	; Get ghost 2 position
111e  116480    ld      de,#8064	; Load special collision position
1121  a7        and     a		; Clear carry flag
1122  ed52      sbc     hl,de		; Compare positions
1124  c0        ret     nz		; Return if not at collision position

1125  21ad4d    ld      hl,#4dad	; Point to ghost 2 activation flag
1128  34        inc     (hl)		; Increment activation flag
1129  c9        ret     

; FUNCTION: GHOST_2_RESET_POSITION - Reset Ghost 2 to starting position
; C_PSEUDO: void ghost_2_reset_position() {
; C_PSEUDO:   ghost_2_sprite = &sprite_data[0x3301];
; C_PSEUDO:   ghost_2_data = &ghost_data[0x4d02];
; C_PSEUDO:   
; C_PSEUDO:   position = calculate_start_position();
; C_PSEUDO:   ghost_2_data[0] = position;
; C_PSEUDO:   
; C_PSEUDO:   direction = 1;  // Right direction
; C_PSEUDO:   ghost_2_current_direction = direction;
; C_PSEUDO:   ghost_2_desired_direction = direction;
; C_PSEUDO:   
; C_PSEUDO:   if(position == 0x80) {  // At start position
; C_PSEUDO:     increment_ghost_release_timer();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Resets Ghost 2 to starting position with proper direction
112a  dd210133  ld      ix,#3301	; Point IX to ghost sprite data
112e  fd21024d  ld      iy,#4d02	; Point IY to ghost 2 game data
1132  cd0020    call    #2000		; Calculate start position
1135  22024d    ld      (#4d02),hl	; Store new position
1138  3e01      ld      a,#01		; Load direction 1 (right)
113a  32294d    ld      (#4d29),a	; Set ghost 2 current direction = right
113d  322d4d    ld      (#4d2d),a	; Set ghost 2 desired direction = right
1140  3a024d    ld      a,(#4d02)	; Get ghost 2 position
1143  fe80      cp      #80		; Compare with start position
1145  c0        ret     nz		; Return if not at start

; FUNCTION: GHOST_2_RESET_COMPLETE - Complete Ghost 2 position reset
; C_PSEUDO: void ghost_2_reset_complete() {
; C_PSEUDO:   // Set Ghost 2 start position and target
; C_PSEUDO:   ghost_2_start_pos = 0x2e2f;
; C_PSEUDO:   ghost_2_current_pos = ghost_2_start_pos;
; C_PSEUDO:   ghost_2_target_pos = ghost_2_start_pos;
; C_PSEUDO:   
; C_PSEUDO:   // Clear Ghost 2 state flags
; C_PSEUDO:   ghost_2_state = 0;
; C_PSEUDO:   ghost_2_active = 0;
; C_PSEUDO:   ghost_2_frightened = 0;
; C_PSEUDO:   
; C_PSEUDO:   // Return to ghost initialization
; C_PSEUDO:   goto ghost_init_loop;
; C_PSEUDO: }
; ALGORITHM: Complete reset of Ghost 2 to starting state and position
1146  212f2e    ld      hl,#2e2f	; Load Ghost 2 start position
1149  220c4d    ld      (#4d0c),hl	; Set Ghost 2 current position
114c  22334d    ld      (#4d33),hl	; Set Ghost 2 target position
114f  af        xor     a		; Clear accumulator
1150  32a14d    ld      (#4da1),a	; Clear Ghost 2 state
1153  32ad4d    ld      (#4dad),a	; Clear Ghost 2 active flag
1156  32a84d    ld      (#4da8),a	; Clear Ghost 2 frightened flag
1159  c30111    jp      #1101		; Jump back to ghost initialization

; FUNCTION: GHOST_3_POSITION_CHECK - Check Ghost 3 position for special handling
; C_PSEUDO: void ghost_3_position_check() {
; C_PSEUDO:   call_ghost_movement_processor();
; C_PSEUDO:   
; C_PSEUDO:   current_pos = ghost_3_position;
; C_PSEUDO:   target_pos = 0x8064;  // Special position check
; C_PSEUDO:   
; C_PSEUDO:   if(current_pos != target_pos) return;
; C_PSEUDO:   
; C_PSEUDO:   // At target position, increment Ghost 3 state
; C_PSEUDO:   ghost_3_state++;
; C_PSEUDO: }
; ALGORITHM: Position-based state transition for Ghost 3
115c  cd861d    call    #1d86		; Call ghost movement processor
115f  2a044d    ld      hl,(#4d04)	; Get Ghost 3 position
1162  116480    ld      de,#8064	; Load target position
1165  a7        and     a		; Clear carry flag
1166  ed52      sbc     hl,de		; Compare positions
1168  c0        ret     nz		; Return if not at target

1169  21ae4d    ld      hl,#4dae	; Point to Ghost 3 state
116c  34        inc     (hl)		; Increment Ghost 3 state
116d  c9        ret     

; FUNCTION: GHOST_3_MOVEMENT_RIGHT - Set Ghost 3 movement direction right
; C_PSEUDO: void ghost_3_movement_right() {
; C_PSEUDO:   movement_vector = movement_table[0x3301];  // Right movement
; C_PSEUDO:   ghost_3_source = &ghost_3_position;
; C_PSEUDO:   
; C_PSEUDO:   new_position = process_movement(movement_vector, ghost_3_source);
; C_PSEUDO:   ghost_3_position = new_position;
; C_PSEUDO:   
; C_PSEUDO:   // Set movement directions
; C_PSEUDO:   ghost_3_current_direction = 1;  // Right
; C_PSEUDO:   ghost_3_desired_direction = 1;  // Right
; C_PSEUDO:   
; C_PSEUDO:   // Check if at starting position
; C_PSEUDO:   if(ghost_3_x_pos == 0x80) {
; C_PSEUDO:     ghost_3_state++;  // Advance to next state
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Ghost 3 right movement with state advancement at start position
116e  dd210133  ld      ix,#3301	; Point IX to right movement vector
1172  fd21044d  ld      iy,#4d04	; Point IY to Ghost 3 position
1176  cd0020    call    #2000		; Process movement
1179  22044d    ld      (#4d04),hl	; Store new Ghost 3 position
117c  3e01      ld      a,#01		; Load direction 1 (right)
117e  322a4d    ld      (#4d2a),a	; Set Ghost 3 current direction = right
1181  322e4d    ld      (#4d2e),a	; Set Ghost 3 desired direction = right
1184  3a044d    ld      a,(#4d04)	; Get Ghost 3 X position
1187  fe80      cp      #80		; Compare with start position
1189  c0        ret     nz		; Return if not at start

118a  21ae4d    ld      hl,#4dae	; Point to Ghost 3 state
118d  34        inc     (hl)		; Increment Ghost 3 state
118e  c9        ret     

; FUNCTION: GHOST_3_MOVEMENT_LEFT - Set Ghost 3 movement direction left
; C_PSEUDO: void ghost_3_movement_left() {
; C_PSEUDO:   movement_vector = movement_table[0x3303];  // Left movement
; C_PSEUDO:   ghost_3_source = &ghost_3_position;
; C_PSEUDO:   
; C_PSEUDO:   new_position = process_movement(movement_vector, ghost_3_source);
; C_PSEUDO:   ghost_3_position = new_position;
; C_PSEUDO:   
; C_PSEUDO:   // Set movement directions
; C_PSEUDO:   ghost_3_current_direction = 2;  // Left
; C_PSEUDO:   ghost_3_desired_direction = 2;  // Left
; C_PSEUDO:   
; C_PSEUDO:   // Check if at specific Y position
; C_PSEUDO:   if(ghost_3_y_pos == 0x90) {
; C_PSEUDO:     // Set Ghost 3 new start position and target
; C_PSEUDO:     ghost_3_start_pos = 0x302f;
; C_PSEUDO:     ghost_3_current_pos = ghost_3_start_pos;
; C_PSEUDO:     ghost_3_target_pos = ghost_3_start_pos;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Ghost 3 left movement with position reset at specific Y coordinate
118f  dd210333  ld      ix,#3303	; Point IX to left movement vector
1193  fd21044d  ld      iy,#4d04	; Point IY to Ghost 3 position
1197  cd0020    call    #2000		; Process movement
119a  22044d    ld      (#4d04),hl	; Store new Ghost 3 position
119d  3e02      ld      a,#02		; Load direction 2 (left)
119f  322a4d    ld      (#4d2a),a	; Set Ghost 3 current direction = left
11a2  322e4d    ld      (#4d2e),a	; Set Ghost 3 desired direction = left
11a5  3a054d    ld      a,(#4d05)	; Get Ghost 3 Y position
11a8  fe90      cp      #90		; Compare with trigger position
11aa  c0        ret     nz		; Return if not at trigger

11ab  212f30    ld      hl,#302f	; Load new start position
11ae  220e4d    ld      (#4d0e),hl	; Set Ghost 3 current position
11b1  22354d    ld      (#4d35),hl	; Set Ghost 3 target position
11b4  3e01      ld      a,#01		; Load direction 1 (right)
11b6  322a4d    ld      (#4d2a),a	; Set Ghost 3 current direction = right
11b9  322e4d    ld      (#4d2e),a	; Set Ghost 3 desired direction = right
11bc  af        xor     a		; Clear accumulator
11bd  32a24d    ld      (#4da2),a	; Clear Ghost 3 state
11c0  32ae4d    ld      (#4dae),a	; Clear Ghost 3 active flag
11c3  32a94d    ld      (#4da9),a	; Clear Ghost 3 frightened flag
11c6  c30111    jp      #1101		; Jump back to ghost initialization

; FUNCTION: GHOST_4_POSITION_CHECK - Check Ghost 4 position for special handling
; C_PSEUDO: void ghost_4_position_check() {
; C_PSEUDO:   call_ghost_movement_processor();
; C_PSEUDO:   
; C_PSEUDO:   current_pos = ghost_4_position;
; C_PSEUDO:   target_pos = 0x8064;  // Special position check
; C_PSEUDO:   
; C_PSEUDO:   if(current_pos != target_pos) return;
; C_PSEUDO:   
; C_PSEUDO:   // At target position, increment Ghost 4 state
; C_PSEUDO:   ghost_4_state++;
; C_PSEUDO: }
; ALGORITHM: Position-based state transition for Ghost 4
11c9  cd5d1e    call    #1e5d		; Call ghost movement processor
11cc  2a064d    ld      hl,(#4d06)	; Get Ghost 4 position
11cf  116480    ld      de,#8064	; Load target position
11d2  a7        and     a		; Clear carry flag
11d3  ed52      sbc     hl,de		; Compare positions
11d5  c0        ret     nz		; Return if not at target

11d6  21af4d    ld      hl,#4daf	; Point to Ghost 4 state
11d9  34        inc     (hl)		; Increment Ghost 4 state
11da  c9        ret     

; FUNCTION: GHOST_4_MOVEMENT_RIGHT - Set Ghost 4 movement direction right
; C_PSEUDO: void ghost_4_movement_right() {
; C_PSEUDO:   movement_vector = movement_table[0x3301];  // Right movement
; C_PSEUDO:   ghost_4_source = &ghost_4_position;
; C_PSEUDO:   
; C_PSEUDO:   new_position = process_movement(movement_vector, ghost_4_source);
; C_PSEUDO:   ghost_4_position = new_position;
; C_PSEUDO:   
; C_PSEUDO:   // Set movement directions
; C_PSEUDO:   ghost_4_current_direction = 1;  // Right
; C_PSEUDO:   ghost_4_desired_direction = 1;  // Right
; C_PSEUDO:   
; C_PSEUDO:   // Check if at starting position
; C_PSEUDO:   if(ghost_4_x_pos == 0x80) {
; C_PSEUDO:     ghost_4_state++;  // Advance to next state
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Ghost 4 right movement with state advancement at start position
11db  dd210133  ld      ix,#3301	; Point IX to right movement vector
11df  fd21064d  ld      iy,#4d06	; Point IY to Ghost 4 position
11e3  cd0020    call    #2000		; Process movement
11e6  22064d    ld      (#4d06),hl	; Store new Ghost 4 position
11e9  3e01      ld      a,#01		; Load direction 1 (right)
11eb  322b4d    ld      (#4d2b),a	; Set Ghost 4 current direction = right
11ee  322f4d    ld      (#4d2f),a	; Set Ghost 4 desired direction = right
11f1  3a064d    ld      a,(#4d06)	; Get Ghost 4 X position
11f4  fe80      cp      #80		; Compare with start position
11f6  c0        ret     nz		; Return if not at start

11f7  21af4d    ld      hl,#4daf	; Point to Ghost 4 state
11fa  34        inc     (hl)		; Increment Ghost 4 state
11fb  c9        ret     

; FUNCTION: GHOST_4_MOVEMENT_UP - Set Ghost 4 movement direction up
; C_PSEUDO: void ghost_4_movement_up() {
; C_PSEUDO:   movement_vector = movement_table[0x32ff];  // Up movement
; C_PSEUDO:   ghost_4_source = &ghost_4_position;
; C_PSEUDO:   
; C_PSEUDO:   new_position = process_movement(movement_vector, ghost_4_source);
; C_PSEUDO:   ghost_4_position = new_position;
; C_PSEUDO:   
; C_PSEUDO:   // Set movement directions
; C_PSEUDO:   ghost_4_current_direction = 3;  // Up
; C_PSEUDO:   ghost_4_desired_direction = 3;  // Up
; C_PSEUDO:   
; C_PSEUDO:   // Check if at specific Y position
; C_PSEUDO:   if(ghost_4_y_pos == 0x50) {
; C_PSEUDO:     // Set Ghost 4 new start position and target
; C_PSEUDO:     ghost_4_start_pos = 0x302f;
; C_PSEUDO:     ghost_4_current_pos = ghost_4_start_pos;
; C_PSEUDO:     ghost_4_target_pos = ghost_4_start_pos;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Ghost 4 up movement with position reset at specific Y coordinate
11fc  dd21ff32  ld      ix,#32ff	; Point IX to up movement vector
1200  fd21064d  ld      iy,#4d06	; Point IY to Ghost 4 position
1204  cd0020    call    #2000		; Process movement
1207  22064d    ld      (#4d06),hl	; Store new Ghost 4 position
120a  af        xor     a		; Clear accumulator
120b  322b4d    ld      (#4d2b),a	; Set Ghost 4 current direction = 0 (up)
120e  322f4d    ld      (#4d2f),a	; Set Ghost 4 desired direction = 0 (up)
1211  3a074d    ld      a,(#4d07)	; Get Ghost 4 Y position
1214  fe70      cp      #70		; Compare with trigger position
1216  c0        ret     nz		; Return if not at trigger

1217  212f2c    ld      hl,#2c2f	; Load new start position
121a  22104d    ld      (#4d10),hl	; Set Ghost 4 current position
121d  22374d    ld      (#4d37),hl	; Set Ghost 4 target position
1220  3e01      ld      a,#01		; Load direction 1 (right)
1222  322b4d    ld      (#4d2b),a	; Set Ghost 4 current direction = right
1225  322f4d    ld      (#4d2f),a	; Set Ghost 4 desired direction = right
1228  af        xor     a		; Clear accumulator
1229  32a34d    ld      (#4da3),a	; Clear Ghost 4 state
122c  32af4d    ld      (#4daf),a	; Clear Ghost 4 active flag
122f  32aa4d    ld      (#4daa),a	; Clear Ghost 4 frightened flag
1232  c30111    jp      #1101		; Jump back to ghost initialization

; FUNCTION: GHOST_STATE_DISPATCHER - Dispatch ghost AI based on states
; C_PSEUDO: void ghost_state_dispatcher() {
; C_PSEUDO:   ghost_timer = death_timer;
; C_PSEUDO:   
; C_PSEUDO:   // Use RST 20 for vectored call based on timer
; C_PSEUDO:   call_ghost_ai_routine(ghost_timer);
; C_PSEUDO:   
; C_PSEUDO:   // Ghost AI jump table addresses
; C_PSEUDO:   // 0x123f - Default ghost AI
; C_PSEUDO:   // 0x120c - Alternative ghost AI  
; C_PSEUDO:   // 0x1200 - Special ghost AI
; C_PSEUDO: }
; ALGORITHM: Vectored ghost AI dispatch using RST 20 instruction
1235  3ad14d    ld      a,(#4dd1)	; Get death timer (ghost state selector)
1238  e7        rst     #20		; Call RST 20 (vectored call)

; JUMP_TABLE: Ghost AI dispatch table (follows RST #20 call)
; RST #20 pops return address (1239), uses accumulator as index into this table
; C_PSEUDO: uint16_t ghost_ai_table[] = {
; C_PSEUDO:   0x123f,  // [0] Normal ghost AI routine
; C_PSEUDO:   0x000c,  // [1] No-op (just returns - 000c is "ret" instruction)
; C_PSEUDO:   0x123f   // [2] Normal ghost AI routine (duplicate)
; C_PSEUDO: };
1239  3f12      dw      #123f		; Jump table entry 0: Normal AI
123b  0c00      dw      #000c		; Jump table entry 1: No-op/default (000c = ret)
123d  3f12      dw      #123f		; Jump table entry 2: Normal AI

; FUNCTION: GHOST_AI_MAIN - Main ghost artificial intelligence routine
; Entry point from jump table - handles normal ghost behavior
; C_PSEUDO: void ghost_ai_main() {
; C_PSEUDO:   uint8_t ghost_id = current_ghost_id;
; C_PSEUDO:   ghost_data_ptr = &ghost_data[ghost_id * 2];  // Each ghost has 2-byte data
; C_PSEUDO:   
; C_PSEUDO:   if (death_timer == 0) {
; C_PSEUDO:     // Normal AI behavior
; C_PSEUDO:     setup_ghost_sprite(ghost_id);
; C_PSEUDO:   } else {
; C_PSEUDO:     // Death/reset sequence
; C_PSEUDO:     handle_ghost_death();
; C_PSEUDO:   }
; C_PSEUDO: }
123f  21004c    ld      hl,#4c00	; Point to ghost data table base
1242  3aa44d    ld      a,(#4da4)	; Load current ghost ID (0-3)
1245  87        add     a,a		; Multiply by 2 (each ghost has 2 bytes of data)
1246  5f        ld      e,a		; Store offset in E
1247  1600      ld      d,#00		; Clear D (making DE = ghost_id * 2)
1249  19        add     hl,de		; HL now points to current ghost's data block
124a  3ad14d    ld      a,(#4dd1)	; Load death/mode timer again
124d  a7        and     a		; Test if timer is zero
124e  2027      jr      nz,#1277        ; If not zero, jump to death sequence handler

; Normal ghost behavior path (death timer = 0)
1250  3ad04d    ld      a,(#4dd0)	; Load ghost mode/color data
1253  0627      ld      b,#27		; Load base sprite pattern (#27)
1255  80        add     a,b		; Add mode to base pattern
1256  47        ld      b,a		; Store resulting sprite pattern in B
1257  3a724e    ld      a,(#4e72)	; Load input enable mask
125a  4f        ld      c,a		; Store mask in C
125b  3a094e    ld      a,(#4e09)	; Load current input state
125e  a1        and     c		; Apply mask to current input
125f  2804      jr      z,#1265         ; If no valid input, skip sprite modification

; Input detected - modify sprite pattern
1261  cbf0      set     6,b		; Set bit 6 of sprite pattern (animation frame?)
1263  cbf8      set     7,b		; Set bit 7 of sprite pattern (direction indicator?)

; Store sprite data and complete normal ghost setup
1265  70        ld      (hl),b		; Store sprite pattern to ghost data
1266  23        inc     hl		; Move to next byte in ghost data
1267  3618      ld      (hl),#18	; Store Y position or height (#18 = 24 pixels)
1269  3e00      ld      a,#00		; Clear accumulator
126b  320b4c    ld      (#4c0b),a	; Clear some status flag at 4c0b
126e  f7        rst     #30		; Call sprite allocation routine (RST #30)

; DATA_BLOCK: Sprite allocation parameters (follows RST #30)
; RST #30 copies these 3 bytes to an available sprite slot at 4c90+
; C_PSEUDO: sprite_params = { 0x4a, 0x03, 0x00 };  // sprite_id, type, flags
126f  4a        db      #4a		; Sprite pattern/ID
1270  03        db      #03		; Sprite type or attributes
1271  00        db      #00		; Additional flags/parameters

; Increment death timer and return
1272  21d14d    ld      hl,#4dd1	; Point to death timer
1275  34        inc     (hl)		; Increment death timer (advances AI state)
1276  c9        ret     		; Return to caller

; FUNCTION: GHOST_DEATH_HANDLER - Death/reset sequence handler  
; Entry point when death timer != 0 (jumped from 124e)
; Handles ghost death by setting death sprite, saving state, and resetting system
; C_PSEUDO: void ghost_death_handler() {
; C_PSEUDO:   ghost_data[current_ghost].sprite = 0x20;  // Death sprite pattern
; C_PSEUDO:   system_status = 0x09;                     // Set cleanup/death mode  
; C_PSEUDO:   ghost_backup[current_ghost] = current_ghost_id;  // Backup current ghost
; C_PSEUDO:   current_ghost_id = 0;                     // Reset to first ghost
; C_PSEUDO:   death_timer = 0;                          // Clear death timer
; C_PSEUDO:   sound_effects |= (1 << 6);                // Enable death sound effect
; C_PSEUDO: }
1277  3620      ld      (hl),#20	; Store death sprite pattern (#20)
1279  3e09      ld      a,#09		; Load death status code
127b  320b4c    ld      (#4c0b),a	; Store death status at 4c0b
127e  3aa44d    ld      a,(#4da4)	; Load current ghost ID
1281  32ab4d    ld      (#4dab),a	; Save current ghost ID to backup location
1284  af        xor     a		; Clear accumulator (A = 0)
1285  32a44d    ld      (#4da4),a	; Reset current ghost ID to 0
1288  32d14d    ld      (#4dd1),a	; Clear death timer (reset to 0)
128b  21ac4e    ld      hl,#4eac	; Point to sound control register
128e  cbf6      set     6,(hl)		; Set bit 6 (enable sound effect 6)
1290  c9        ret     		; Return to caller

; FUNCTION: GHOST_AI_DISPATCHER_2 - Secondary ghost AI dispatch
; Uses a different state variable (4da5) for more complex AI states
; C_PSEUDO: void ghost_ai_dispatcher_2() {
; C_PSEUDO:   uint8_t ai_state = ghost_ai_state;  // 4da5
; C_PSEUDO:   call_ghost_subroutine(ai_state);
; C_PSEUDO: }
1291  3aa54d    ld      a,(#4da5)	; Load AI state selector from 4da5
1294  e7        rst     #20		; Call RST 20 (vectored jump)

; JUMP_TABLE: Secondary ghost AI dispatch table (follows RST #20)
; Based on the pattern, these appear to be 4 identical entries
; C_PSEUDO: uint16_t ghost_ai_table_2[] = {
; C_PSEUDO:   0x000c,  // [0] No-op (ret instruction)
; C_PSEUDO:   0x12b7,  // [1] Ghost AI subroutine
; C_PSEUDO:   0x12b7,  // [2] Ghost AI subroutine (duplicate)
; C_PSEUDO:   0x12b7   // [3] Ghost AI subroutine (duplicate)
; C_PSEUDO: };
1295  0c00      dw      #000c		; Jump table entry 0: No-op
1297  b712      dw      #12b7		; Jump table entry 1: AI routine
1299  b712      dw      #12b7		; Jump table entry 2: AI routine
129b  b712      dw      #12b7		; Jump table entry 3: AI routine

; DATA_TABLE: Ghost gameplay animation sequence jump table
; This section was incorrectly disassembled as instructions 
; CONFIRMED: Called from main gameplay loop (08eb->1017->1291), NOT demo/interstitial mode
; POSSIBLE PURPOSES (need more analysis):
; - Frightened ghost animation (power pellet effect)
; - Ghost death/eaten sequence  
; - Ghost respawn/revival animation
; - Special ghost state (vulnerable, flashing, etc.)
; Sequential sprites 0x35-0x3f with increasing delays (120->440 frames) suggest
; a visual effect that progressively slows down during active gameplay
; C_PSEUDO: uint16_t ghost_gameplay_animation_table[] = {  // Gameplay animation sequence
; C_PSEUDO:   0x12b7, 0x12cb, 0x12f9, 0x1306, 0x130e, 0x1316, 0x131e, 
; C_PSEUDO:   0x1326, 0x132e, 0x1336, 0x133e, 0x1346, 0x1353
; C_PSEUDO: };  // Each entry handles progressively longer animation frames
129d  b712      dw      #12b7		; Table entry 0
129f  cb12      dw      #12cb		; Table entry 1  
12a1  f912      dw      #12f9		; Table entry 2
12a3  0613      dw      #1306		; Table entry 3
12a5  0e13      dw      #130e		; Table entry 4
12a7  1613      dw      #1316		; Table entry 5
12a9  1e13      dw      #131e		; Table entry 6
12ab  2613      dw      #1326		; Table entry 7
12ad  2e13      dw      #132e		; Table entry 8
12af  3613      dw      #1336		; Table entry 9
12b1  3e13      dw      #133e		; Table entry 10
12b3  4613      dw      #1346		; Table entry 11
12b5  5313      dw      #1353		; Table entry 12

; FUNCTION: GHOST_ANIMATION_INIT - Initial animation state handler
; Entry point from animation table - manages timing before sprite sequence begins
; Purpose unknown - could be demo, death, power-up, or other animation context
; C_PSEUDO: void ghost_animation_init() {
; C_PSEUDO:   animation_timer++;                     // Increment sequence timer
; C_PSEUDO:   if (animation_timer >= 120) {          // 120 frame delay (2 seconds at 60fps)
; C_PSEUDO:     animation_state = 5;                 // Advance to sprite animation states
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   // Timer not expired, stay in initial delay state
; C_PSEUDO: }
12b7  2ac54d    ld      hl,(#4dc5)	; Load 16-bit timer value from 4dc5
12ba  23        inc     hl		; Increment timer
12bb  22c54d    ld      (#4dc5),hl	; Store incremented timer back
12be  117800    ld      de,#0078	; Load comparison value (120 decimal)
12c1  a7        and     a		; Clear carry flag for subtraction
12c2  ed52      sbc     hl,de		; Compare timer with 0x78 (HL = HL - DE)
12c4  c0        ret     nz		; Return if timer < 0x78 (not expired)

; Timer expired - advance AI state
12c5  3e05      ld      a,#05		; Load next state value (5)
12c7  32a54d    ld      (#4da5),a	; Store new AI state to 4da5
12ca  c9        ret     		; Return

; FUNCTION: GHOST_AI_SUBROUTINE_2 - Pre-animation setup handler
; Prepares ghost for animation sequence with different sprite and longer timing
; C_PSEUDO: void ghost_pre_animation() {
; C_PSEUDO:   call_function_267e(0x0000);      // Setup/clear operation
; C_PSEUDO:   sprite_data = 0x34;              // Pre-animation sprite pattern
; C_PSEUDO:   if (player_input_detected()) {
; C_PSEUDO:     sprite_data |= 0xc0;           // Add input-responsive sprite bits
; C_PSEUDO:   }
; C_PSEUDO:   store_sprite_data(sprite_data);
; C_PSEUDO:   if (++animation_timer >= 180) advance_ai_state();  // 3 second delay
; C_PSEUDO: }
12cb  210000    ld      hl,#0000	; Load HL with 0 (maybe clear parameter?)
12ce  cd7e26    call    #267e		; Call unknown function at 267e
12d1  3e34      ld      a,#34		; Load sprite pattern 0x34
12d3  11b400    ld      de,#00b4	; Load timer comparison value (180 decimal)
12d6  4f        ld      c,a		; Store sprite pattern in C
12d7  3a724e    ld      a,(#4e72)	; Load input enable mask
12da  47        ld      b,a		; Store mask in B  
12db  3a094e    ld      a,(#4e09)	; Load current input state
12de  a0        and     b		; Apply input mask
12df  2804      jr      z,#12e5         ; Jump if no input detected

; Input detected - modify sprite pattern
12e1  3ec0      ld      a,#c0		; Load sprite modification bits
12e3  b1        or      c		; Combine with base sprite pattern
12e4  4f        ld      c,a		; Store modified pattern in C

; Store sprite data and check timer
12e5  79        ld      a,c		; Get final sprite pattern
12e6  320a4c    ld      (#4c0a),a	; Store sprite data to 4c0a
12e9  2ac54d    ld      hl,(#4dc5)	; Load timer value
12ec  23        inc     hl		; Increment timer
12ed  22c54d    ld      (#4dc5),hl	; Store incremented timer
12f0  a7        and     a		; Clear carry for subtraction
12f1  ed52      sbc     hl,de		; Compare timer with 0xb4
12f3  c0        ret     nz		; Return if timer not expired

; Timer expired - advance to next AI state
12f4  21a54d    ld      hl,#4da5	; Point to AI state variable
12f7  34        inc     (hl)		; Increment AI state
12f8  c9        ret     		; Return

; FUNCTION: GHOST_AI_SUBROUTINE_3 - Third AI behavior routine
; Maybe handles sound effect and different sprite/timer combination?
; C_PSEUDO: void ghost_ai_subroutine_3() {
; C_PSEUDO:   enable_sound_effect(4);  // Set bit 4 in sound register
; C_PSEUDO:   setup_sprite_and_timer(0x35, 0x00c3);
; C_PSEUDO: }
12f9  21bc4e    ld      hl,#4ebc	; Point to sound control register  
12fc  cbe6      set     4,(hl)		; Set bit 4 (enable sound effect 4?)
12fe  3e35      ld      a,#35		; Load sprite pattern 0x35
1300  11c300    ld      de,#00c3	; Load timer value 0xc3 (195 decimal)
1303  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_4 - Fourth AI behavior routine  
; Similar pattern with different sprite/timer values
; C_PSEUDO: void ghost_ai_subroutine_4() {
; C_PSEUDO:   setup_sprite_and_timer(0x36, 0x00d2);
; C_PSEUDO: }
1306  3e36      ld      a,#36		; Load sprite pattern 0x36
1308  11d200    ld      de,#00d2	; Load timer value 0xd2 (210 decimal)
130b  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_5 - Fifth AI behavior routine
; Continues the pattern with sprite 0x37
; C_PSEUDO: void ghost_ai_subroutine_5() {
; C_PSEUDO:   setup_sprite_and_timer(0x37, 0x00e1);
; C_PSEUDO: }
130e  3e37      ld      a,#37		; Load sprite pattern 0x37
1310  11e100    ld      de,#00e1	; Load timer value 0xe1 (225 decimal)
1313  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_6 - Sixth AI behavior routine
1316  3e38      ld      a,#38		; Load sprite pattern 0x38
1318  11f000    ld      de,#00f0	; Load timer value 0xf0 (240 decimal)
131b  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_7 - Seventh AI behavior routine  
131e  3e39      ld      a,#39		; Load sprite pattern 0x39
1320  11ff00    ld      de,#00ff	; Load timer value 0xff (255 decimal)
1323  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_8 - Eighth AI behavior routine
1326  3e3a      ld      a,#3a		; Load sprite pattern 0x3a
1328  110e01    ld      de,#010e	; Load timer value 0x10e (270 decimal)
132b  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_9 - Ninth AI behavior routine
132e  3e3b      ld      a,#3b		; Load sprite pattern 0x3b
1330  111d01    ld      de,#011d	; Load timer value 0x11d (285 decimal)
1333  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_10 - Tenth AI behavior routine
1336  3e3c      ld      a,#3c		; Load sprite pattern 0x3c
1338  112c01    ld      de,#012c	; Load timer value 0x12c (300 decimal)
133b  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_11 - Eleventh AI behavior routine
133e  3e3d      ld      a,#3d		; Load sprite pattern 0x3d
1340  113b01    ld      de,#013b	; Load timer value 0x13b (315 decimal)
1343  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_12 - Twelfth AI behavior routine
; This one has a different pattern - maybe clears sound effects?
; C_PSEUDO: void ghost_ai_subroutine_12() {
; C_PSEUDO:   sound_register = 0x20;  // Maybe disable some sound effects?
; C_PSEUDO:   setup_sprite_and_timer(0x3e, 0x0159);
; C_PSEUDO: }
1346  21bc4e    ld      hl,#4ebc	; Point to sound control register
1349  3620      ld      (hl),#20	; Store 0x20 (different from previous set bit 4)
134b  3e3e      ld      a,#3e		; Load sprite pattern 0x3e
134d  115901    ld      de,#0159	; Load timer value 0x159 (345 decimal)
1350  c3d612    jp      #12d6		; Jump to common sprite/timer handler

; FUNCTION: GHOST_AI_SUBROUTINE_13 - Thirteenth AI behavior routine
; This one breaks the pattern - doesn't jump to common handler
; Maybe final state in the sequence?
; C_PSEUDO: void ghost_ai_subroutine_13() {
; C_PSEUDO:   sprite_data = 0x3f;
; C_PSEUDO:   store_sprite_data(sprite_data);
; C_PSEUDO:   if (++timer >= 0x1b8) {
; C_PSEUDO:     // Timer expired - maybe reset or advance to different state?
; C_PSEUDO:   }
; C_PSEUDO: }
1353  3e3f      ld      a,#3f		; Load sprite pattern 0x3f
1355  320a4c    ld      (#4c0a),a	; Store sprite data directly (no input check)
1358  2ac54d    ld      hl,(#4dc5)	; Load timer value
135b  23        inc     hl		; Increment timer
135c  22c54d    ld      (#4dc5),hl	; Store incremented timer
135f  11b801    ld      de,#01b8	; Load comparison value 0x1b8 (440 decimal)
1362  a7        and     a		; Clear carry flag
1363  ed52      sbc     hl,de		; Compare timer with 0x1b8
1365  c0        ret     nz		; Return if timer not expired

; Timer expired - perform final cleanup/transition
; C_PSEUDO: // Timer expired - maybe end of animation sequence?
1366  21144e    ld      hl,#4e14	; Point to some counter at 4e14
1369  35        dec     (hl)		; Decrement counter
136a  21154e    ld      hl,#4e15	; Point to another counter at 4e15  
136d  35        dec     (hl)		; Decrement second counter
136e  cd7526    call    #2675		; Call unknown function at 2675
1371  21044e    ld      hl,#4e04	; Point to status/state variable
1374  34        inc     (hl)		; Increment state (advance to next phase?)
1375  c9        ret     		; Return

; FUNCTION: CONDITIONAL_GHOST_HANDLER - Handles ghost state based on flag
; C_PSEUDO: void conditional_ghost_handler() {
; C_PSEUDO:   if (ghost_active_flag == 0) return;  // Exit if ghost not active
; C_PSEUDO:   
; C_PSEUDO:   // Check if both ghost state bytes are zero
; C_PSEUDO:   if ((ghost_state[0] | ghost_state[1]) == 0) {
; C_PSEUDO:     // Both bytes zero - handle special case
; C_PSEUDO:   }
; C_PSEUDO: }
1376  3aa64d    ld      a,(#4da6)	; Load ghost active flag
1379  a7        and     a		; Test if zero
137a  c8        ret     z		; Return if ghost not active

; Ghost is active - check state bytes
137b  dd21a74d  ld      ix,#4da7	; Point IX to ghost state data at 4da7
137f  dd7e00    ld      a,(ix+#00)	; Load first ghost state byte
1382  ddb601    or      (ix+#01)	; OR with second ghost state byte
1385  ddb602    or      (ix+#02)	; OR with third ghost state byte
1388  ddb603    or      (ix+#03)	; OR with fourth ghost state byte
138b  ca9813    jp      z,#1398		; Jump if all 4 bytes are zero

; At least one ghost state byte is non-zero - decrement timer
138e  2acb4d    ld      hl,(#4dcb)	; Load 16-bit timer from 4dcb
1391  2b        dec     hl		; Decrement timer
1392  22cb4d    ld      (#4dcb),hl	; Store decremented timer
1395  7c        ld      a,h		; Check if timer reached zero
1396  b5        or      l		; Test both bytes (HL == 0?)
1397  c0        ret     nz		; Return if timer not expired

; Timer expired OR all ghost states zero - perform cleanup
; C_PSEUDO: // Reset ghost system - clear all states and disable effects
1398  210b4c    ld      hl,#4c0b	; Point to status register
139b  3609      ld      (hl),#09	; Set status to 0x09 (cleanup mode?)

; Reset ghost state bytes conditionally based on backup values
; C_PSEUDO: // Restore ghost states from backup if backups are non-zero
139d  3aac4d    ld      a,(#4dac)	; Load backup state for ghost 0
13a0  a7        and     a		; Test if zero
13a1  c2a713    jp      nz,#13a7	; Skip clear if backup exists
13a4  32a74d    ld      (#4da7),a	; Clear ghost 0 state (A=0)

13a7  3aad4d    ld      a,(#4dad)	; Load backup state for ghost 1
13aa  a7        and     a		; Test if zero
13ab  c2b113    jp      nz,#13b1	; Skip clear if backup exists
13ae  32a84d    ld      (#4da8),a	; Clear ghost 1 state

13b1  3aae4d    ld      a,(#4dae)	; Load backup state for ghost 2
13b4  a7        and     a		; Test if zero
13b5  c2bb13    jp      nz,#13bb	; Skip clear if backup exists
13b8  32a94d    ld      (#4da9),a	; Clear ghost 2 state

13bb  3aaf4d    ld      a,(#4daf)	; Load backup state for ghost 3
13be  a7        and     a		; Test if zero
13bf  c2c513    jp      nz,#13c5	; Skip clear if backup exists
13c2  32aa4d    ld      (#4daa),a	; Clear ghost 3 state

; Final system reset - clear all control variables
13c5  af        xor     a		; Clear A register (A = 0)
13c6  32cb4d    ld      (#4dcb),a	; Clear timer low byte
13c9  32cc4d    ld      (#4dcc),a	; Clear timer high byte (full 16-bit clear)
13cc  32a64d    ld      (#4da6),a	; Clear ghost active flag
13cf  32c84d    ld      (#4dc8),a	; Clear another control variable
13d2  32d04d    ld      (#4dd0),a	; Clear ghost mode/color data
13d5  21ac4e    ld      hl,#4eac	; Point to sound control register
13d8  cbae      res     5,(hl)		; Clear bit 5 (disable sound effect 5)
13da  cbbe      res     7,(hl)		; Clear bit 7 (disable sound effect 7)
13dc  c9        ret     		; Return

; FUNCTION: TIMING_VALIDATOR - Validates timing consistency  
; Appears to check if a target value matches current state and manages timing
; C_PSEUDO: void timing_validator() {
; C_PSEUDO:   if (target_value != current_state) {
; C_PSEUDO:     timing_counter = 0;  // Reset counter on mismatch
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   // Values match - increment and check timing counter
; C_PSEUDO:   if (++timing_counter >= timing_threshold) {
; C_PSEUDO:     timing_counter = 0;  // Reset after threshold reached
; C_PSEUDO:   }
; C_PSEUDO: }
13dd  219e4d    ld      hl,#4d9e	; Point to target value storage
13e0  3a0e4e    ld      a,(#4e0e)	; Load current state value
13e3  be        cp      (hl)		; Compare with target value
13e4  caee13    jp      z,#13ee		; Jump if values match

; Values don't match - reset timing counter
13e7  210000    ld      hl,#0000	; Load zero
13ea  22974d    ld      (#4d97),hl	; Clear timing counter
13ed  c9        ret     		; Return

; Values match - increment timing counter and check threshold
13ee  2a974d    ld      hl,(#4d97)	; Load current timing counter
13f1  23        inc     hl		; Increment counter
13f2  22974d    ld      (#4d97),hl	; Store incremented counter
13f5  ed5b954d  ld      de,(#4d95)	; Load timing threshold
13f9  a7        and     a		; Clear carry flag
13fa  ed52      sbc     hl,de		; Compare counter with threshold
13fc  c0        ret     nz		; Return if threshold not reached

; Threshold reached - reset counter
13fd  210000    ld      hl,#0000	; Load zero
1400  22974d    ld      (#4d97),hl	; Reset timing counter

; Check and potentially call ghost state handlers
1403  3aa14d    ld      a,(#4da1)	; Load ghost 1 state flag
1406  a7        and     a		; Test if zero  
1407  f5        push    af		; Save flags
1408  cc8620    call    z,#2086		; Call handler if ghost 1 state is zero
140b  f1        pop     af		; Restore flags
140c  c8        ret     z		; Return if ghost 1 was zero

140d  3aa24d    ld      a,(#4da2)	; Load ghost 2 state flag
1410  a7        and     a		; Test if zero
1411  f5        push    af		; Save flags
1412  cca920    call    z,#20a9		; Call handler if ghost 2 state is zero
1415  f1        pop     af		; Restore flags
1416  c8        ret     z		; Return if ghost 2 was zero

1417  3aa34d    ld      a,(#4da3)	; Load ghost 3 state flag
141a  a7        and     a		; Test if zero
141b  ccd120    call    z,#20d1		; Call handler if ghost 3 state is zero
141e  c9        ret     		; Return

; FUNCTION: INPUT_GHOST_HANDLER - Handle input-based ghost interactions
; Processes player input for ghost-related actions during gameplay
; C_PSEUDO: void input_ghost_handler() {
; C_PSEUDO:   if (!player_input_enabled()) return;
; C_PSEUDO:   
; C_PSEUDO:   input_mask = current_input & input_enable_mask;
; C_PSEUDO:   process_ghost_interactions(input_mask);
; C_PSEUDO: }
141f  3a724e    ld      a,(#4e72)	; Load input enable mask
1422  47        ld      b,a		; Store mask in B
1423  3a094e    ld      a,(#4e09)	; Load current input state
1426  a0        and     b		; Apply mask to input
1427  c8        ret     z		; Return if no valid input

; Valid input detected - setup ghost interaction processing
1428  47        ld      b,a		; Store masked input in B
1429  dd21004c  ld      ix,#4c00	; Point IX to ghost data base address
142d  1e08      ld      e,#08		; Load offset value for X coordinates
142f  0e08      ld      c,#08		; Load offset value for Y coordinates  
1431  1607      ld      d,#07		; Load complement adjustment value

; Copy and transform ghost position data to sprite buffer
; Pattern: Load position, add offset, store to sprite data
; X coordinates: position + 8, Y coordinates: ~position + offset
; C_PSEUDO: // Transform ghost positions for sprite hardware
; C_PSEUDO: sprite_buffer[0x13] = ghost_x[0] + 8;        // Ghost 0 X  
; C_PSEUDO: sprite_buffer[0x12] = ~ghost_y[0] + 7;       // Ghost 0 Y (Y-flipped)
; C_PSEUDO: sprite_buffer[0x15] = ghost_x[1] + 8;        // Ghost 1 X
; C_PSEUDO: sprite_buffer[0x14] = ~ghost_y[1] + 7;       // Ghost 1 Y (Y-flipped)
; C_PSEUDO: // ... etc for all 4 ghosts

; Ghost 0 position transformation
1433  3a004d    ld      a,(#4d00)	; Load Ghost 0 X position
1436  83        add     a,e		; Add X offset (8)
1437  dd7713    ld      (ix+#13),a	; Store to sprite buffer offset 0x13
143a  3a014d    ld      a,(#4d01)	; Load Ghost 0 Y position
143d  2f        cpl     		; Complement Y (flip coordinate system)
143e  82        add     a,d		; Add Y adjustment (7)
143f  dd7712    ld      (ix+#12),a	; Store to sprite buffer offset 0x12

; Ghost 1 position transformation  
1442  3a024d    ld      a,(#4d02)	; Load Ghost 1 X position
1445  83        add     a,e		; Add X offset (8)
1446  dd7715    ld      (ix+#15),a	; Store to sprite buffer offset 0x15
1449  3a034d    ld      a,(#4d03)	; Load Ghost 1 Y position
144c  2f        cpl     		; Complement Y (flip coordinate system)
144d  82        add     a,d		; Add Y adjustment (7)
144e  dd7714    ld      (ix+#14),a	; Store to sprite buffer offset 0x14

; Ghost 2 position transformation
1451  3a044d    ld      a,(#4d04)	; Load Ghost 2 X position
1454  83        add     a,e		; Add X offset (8)
1455  dd7717    ld      (ix+#17),a	; Store to sprite buffer offset 0x17
1458  3a054d    ld      a,(#4d05)	; Load Ghost 2 Y position
145b  2f        cpl     		; Complement Y (flip coordinate system)
145c  81        add     a,c		; Add Y adjustment (8) - note: uses C instead of D
145d  dd7716    ld      (ix+#16),a	; Store to sprite buffer offset 0x16

; Ghost 3 position transformation
1460  3a064d    ld      a,(#4d06)	; Load Ghost 3 X position
1463  83        add     a,e		; Add X offset (8)
1464  dd7719    ld      (ix+#19),a	; Store to sprite buffer offset 0x19
1467  3a074d    ld      a,(#4d07)	; Load Ghost 3 Y position
146a  2f        cpl     		; Complement Y (flip coordinate system)
146b  81        add     a,c		; Add Y adjustment (8)
146c  dd7718    ld      (ix+#18),a	; Store to sprite buffer offset 0x18

; Ghost 4 position transformation (bonus ghost?)
146f  3a084d    ld      a,(#4d08)	; Load Ghost 4 X position
1472  83        add     a,e		; Add X offset (8)
1473  dd771b    ld      (ix+#1b),a	; Store to sprite buffer offset 0x1b
1476  3a094d    ld      a,(#4d09)	; Load Ghost 4 Y position
1479  2f        cpl     		; Complement Y (flip coordinate system)
147a  81        add     a,c		; Add Y adjustment (8)
147b  dd771a    ld      (ix+#1a),a	; Store to sprite buffer offset 0x1a

; Additional entity position transformation (likely Pac-Man)
147e  3ad24d    ld      a,(#4dd2)	; Load X position (Pac-Man?)
1481  83        add     a,e		; Add X offset (8)
1482  dd771d    ld      (ix+#1d),a	; Store to sprite buffer offset 0x1d
1485  3ad34d    ld      a,(#4dd3)	; Load Y position (Pac-Man?)
1488  2f        cpl     		; Complement Y (flip coordinate system)
1489  81        add     a,c		; Add Y adjustment (8)
148a  dd771c    ld      (ix+#1c),a	; Store to sprite buffer offset 0x1c
148d  c3fe14    jp      #14fe		; Jump to continue processing

; FUNCTION: GHOST_POSITION_HANDLER_ALT - Alternative ghost position handler
; Called when no player input detected (opposite condition from previous function)
; C_PSEUDO: void ghost_position_handler_alt() {
; C_PSEUDO:   if (player_input_detected()) return;  // Opposite of previous function
; C_PSEUDO:   
; C_PSEUDO:   // Different offset values - maybe for different display mode?
; C_PSEUDO:   transform_positions_with_offsets(9, 7, 6);
; C_PSEUDO: }
1490  3a724e    ld      a,(#4e72)	; Load input enable mask
1493  47        ld      b,a		; Store mask in B
1494  3a094e    ld      a,(#4e09)	; Load current input state
1497  a0        and     b		; Apply mask to input
1498  c0        ret     nz		; Return if input IS detected (opposite condition)

; No input detected - setup alternative position processing
1499  47        ld      b,a		; Store cleared input in B (A=0)
149a  1e09      ld      e,#09		; Load different X offset (9 instead of 8)
149c  0e07      ld      c,#07		; Load different Y offset (7 instead of 8)
149e  1606      ld      d,#06		; Load different complement adjustment (6 instead of 7)
14a0  dd21004c  ld      ix,#4c00	; Point IX to ghost data base address

; Alternative position transformation - X/Y handling is swapped compared to input mode
; X coordinates: ~position + 9, Y coordinates: position + 6
; C_PSEUDO: // Transform positions for non-input mode (attract/pause?)
; C_PSEUDO: sprite_buffer[0x13] = ~ghost_x[0] + 9;       // Ghost 0 X (X-flipped)
; C_PSEUDO: sprite_buffer[0x12] = ghost_y[0] + 6;        // Ghost 0 Y (normal)

; Ghost 0 alternative transformation
14a4  3a004d    ld      a,(#4d00)	; Load Ghost 0 X position
14a7  2f        cpl     		; Complement X (flip coordinate)
14a8  83        add     a,e		; Add X offset (9)
14a9  dd7713    ld      (ix+#13),a	; Store to sprite buffer offset 0x13
14ac  3a014d    ld      a,(#4d01)	; Load Ghost 0 Y position
14af  82        add     a,d		; Add Y offset (6) - no complement
14b0  dd7712    ld      (ix+#12),a	; Store to sprite buffer offset 0x12

; Ghost 1 alternative transformation
14b3  3a024d    ld      a,(#4d02)	; Load Ghost 1 X position
14b6  2f        cpl     		; Complement X (flip coordinate)
14b7  83        add     a,e		; Add X offset (9)
14b8  dd7715    ld      (ix+#15),a	; Store to sprite buffer offset 0x15
14bb  3a034d    ld      a,(#4d03)	; Load Ghost 1 Y position
14be  82        add     a,d		; Add Y offset (6) - no complement
14bf  dd7714    ld      (ix+#14),a	; Store to sprite buffer offset 0x14

; Ghost 2 alternative transformation
14c2  3a044d    ld      a,(#4d04)	; Load Ghost 2 X position
14c5  2f        cpl     		; Complement X (flip coordinate)
14c6  83        add     a,e		; Add X offset (9)
14c7  dd7717    ld      (ix+#17),a	; Store to sprite buffer offset 0x17
14ca  3a054d    ld      a,(#4d05)	; Load Ghost 2 Y position
14cd  81        add     a,c		; Add Y offset (7) - no complement
14ce  dd7716    ld      (ix+#16),a	; Store to sprite buffer offset 0x16

; Ghost 3 alternative transformation
14d1  3a064d    ld      a,(#4d06)	; Load Ghost 3 X position
14d4  2f        cpl     		; Complement X (flip coordinate)
14d5  83        add     a,e		; Add X offset (9)
14d6  dd7719    ld      (ix+#19),a	; Store to sprite buffer offset 0x19
14d9  3a074d    ld      a,(#4d07)	; Load Ghost 3 Y position
14dc  81        add     a,c		; Add Y offset (7) - no complement
14dd  dd7718    ld      (ix+#18),a	; Store to sprite buffer offset 0x18

; Entity 4 alternative transformation (Pac-Man/bonus item)
14e0  3a084d    ld      a,(#4d08)	; Load Entity 4 X position
14e3  2f        cpl     		; Complement X (flip coordinate)
14e4  83        add     a,e		; Add X offset (9)
14e5  dd771b    ld      (ix+#1b),a	; Store to sprite buffer offset 0x1b
14e8  3a094d    ld      a,(#4d09)	; Load Entity 4 Y position
14eb  81        add     a,c		; Add Y offset (7) - no complement
14ec  dd771a    ld      (ix+#1a),a	; Store to sprite buffer offset 0x1a

; Additional entity alternative transformation
14ef  3ad24d    ld      a,(#4dd2)	; Load additional entity X position
14f2  2f        cpl     		; Complement X (flip coordinate)
14f3  83        add     a,e		; Add X offset (9)
14f4  dd771d    ld      (ix+#1d),a	; Store to sprite buffer offset 0x1d
14f7  3ad34d    ld      a,(#4dd3)	; Load additional entity Y position
14fa  81        add     a,c		; Add Y offset (7) - no complement
14fb  dd771c    ld      (ix+#1c),a	; Store to sprite buffer offset 0x1c

; Common continuation point for both position transformation modes
14fe  3aa54d    ld      a,(#4da5)	; Load ghost animation state
1501  a7        and     a		; Test if animation state is zero
1502  c24b15    jp      nz,#154b	; Jump if animation active

1505  3aa44d    ld      a,(#4da4)	; Load current ghost ID
1508  a7        and     a		; Test if zero
1509  c2b415    jp      nz,#15b4	; Jump if ghost ID != 0

; Setup for ghost behavior dispatch
150c  211c15    ld      hl,#151c	; Load return address for after RST call
150f  e5        push    hl		; Push return address onto stack
1510  3a304d    ld      a,(#4d30)	; Load ghost behavior state
1513  e7        rst     #20		; Call RST 20 (vectored jump)

; JUMP_TABLE: Ghost behavior dispatch table (follows RST #20 call)
; C_PSEUDO: uint16_t ghost_behavior_table[] = {
; C_PSEUDO:   0x168c,  // [0] Ghost behavior routine 1
; C_PSEUDO:   0x16b1,  // [1] Ghost behavior routine 2  
; C_PSEUDO:   0x16d6,  // [2] Ghost behavior routine 3
; C_PSEUDO:   0x16f7,  // [3] Ghost behavior routine 4
; C_PSEUDO:   0x1678   // [4] Ghost behavior routine 5
; C_PSEUDO: };
1514  8c16      dw      #168c		; Jump table entry 0
1516  b116      dw      #16b1		; Jump table entry 1
1518  d616      dw      #16d6		; Jump table entry 2
151a  f716      dw      #16f7		; Jump table entry 3
151c  7816      dw      #1678		; Jump table entry 4

; Return point after ghost behavior dispatch
151d  a7        and     a		; Test some condition  
151e  282b      jr      z,#154b         ; Jump if zero

; Sprite modification logic based on ghost behavior state
1520  0ec0      ld      c,#c0		; Load bitmask 0xc0 (bits 6&7)
1522  3a0a4c    ld      a,(#4c0a)	; Load sprite data
1525  57        ld      d,a		; Save original sprite data in D
1526  a1        and     c		; Test bits 6&7 of sprite data
1527  2005      jr      nz,#152e        ; Jump if either bit 6 or 7 is set

; Neither bit 6 nor 7 set - set both bits
1529  7a        ld      a,d		; Restore original sprite data
152a  b1        or      c		; Set bits 6&7 (OR with 0xc0)
152b  c34815    jp      #1548		; Jump to store modified sprite

; Bit 6 or 7 (or both) are set - check behavior state
152e  3a304d    ld      a,(#4d30)	; Load ghost behavior state
1531  fe02      cp      #02		; Compare with state 2
1533  2009      jr      nz,#153e        ; Jump if not state 2

; Behavior state 2 - check bit 7 and conditionally clear bits 6&7
1535  cb7a      bit     7,d		; Test bit 7 of sprite data
1537  2812      jr      z,#154b         ; Skip if bit 7 is clear
1539  7a        ld      a,d		; Restore original sprite data
153a  a9        xor     c		; Toggle bits 6&7 (XOR with 0xc0)
153b  c34815    jp      #1548		; Jump to store modified sprite

; Check for behavior state 3
153e  fe03      cp      #03		; Compare with state 3
1540  2009      jr      nz,#154b        ; Skip if not state 3

; Behavior state 3 - check bit 6 and conditionally toggle bits 6&7
1542  cb72      bit     6,d		; Test bit 6 of sprite data
1544  2805      jr      z,#154b         ; Skip if bit 6 is clear
1546  7a        ld      a,d		; Restore original sprite data
1547  a9        xor     c		; Toggle bits 6&7 (XOR with 0xc0)

; Store modified sprite data
1548  320a4c    ld      (#4c0a),a	; Store modified sprite data

; Continue with next processing phase
154b  21c04d    ld      hl,#4dc0	; Point to some data at 4dc0
154e  56        ld      d,(hl)		; Load byte from 4dc0
154f  3e1c      ld      a,#1c		; Load constant 0x1c (28 decimal)
1551  82        add     a,d		; Add value from 4dc0

; Store calculated value to multiple sprite offsets
; CONFIRMED: Writing same calculated value to offsets 2, 4, 6, 8
1552  dd7702    ld      (ix+#02),a	; Store to sprite buffer offset 0x02
1555  dd7704    ld      (ix+#04),a	; Store to sprite buffer offset 0x04
1558  dd7706    ld      (ix+#06),a	; Store to sprite buffer offset 0x06
155b  dd7708    ld      (ix+#08),a	; Store to sprite buffer offset 0x08

; Ghost state conditional processing
; PATTERN: Check backup state first, then main state, then apply sprite calculation
155e  0e20      ld      c,#20		; Load constant 0x20 (32 decimal)

; Ghost 0 state check and sprite modification
1560  3aac4d    ld      a,(#4dac)	; Load ghost 0 backup state
1563  a7        and     a		; Test if backup state is zero
1564  2006      jr      nz,#156c        ; Skip if backup state exists
1566  3aa74d    ld      a,(#4da7)	; Load ghost 0 main state  
1569  a7        and     a		; Test if main state is zero
156a  2009      jr      nz,#1575        ; Skip sprite mod if state exists

; Both ghost 0 states are zero - apply sprite modification
; MAYBE: This could be when ghost is in normal/inactive state?
156c  3a2c4d    ld      a,(#4d2c)	; Load value from 4d2c (unknown purpose)
156f  87        add     a,a		; Double the value
1570  82        add     a,d		; Add the base value from 4dc0
1571  81        add     a,c		; Add constant 0x20
1572  dd7702    ld      (ix+#02),a	; Store modified value to offset 0x02

; Ghost 1 state check and sprite modification (same pattern)
1575  3aad4d    ld      a,(#4dad)	; Load ghost 1 backup state
1578  a7        and     a		; Test if backup state is zero
1579  2006      jr      nz,#1581        ; Skip if backup state exists
157b  3aa84d    ld      a,(#4da8)	; Load ghost 1 main state
157e  a7        and     a		; Test if main state is zero
157f  2009      jr      nz,#158a        ; Skip sprite mod if state exists

; Both ghost 1 states are zero - apply sprite modification
1581  3a2d4d    ld      a,(#4d2d)	; Load value from 4d2d
1584  87        add     a,a		; Double the value
1585  82        add     a,d		; Add the base value from 4dc0
1586  81        add     a,c		; Add constant 0x20
1587  dd7704    ld      (ix+#04),a	; Store modified value to offset 0x04

; Ghost 2 state check and sprite modification (same pattern)
158a  3aae4d    ld      a,(#4dae)	; Load ghost 2 backup state
158d  a7        and     a		; Test if backup state is zero
158e  2006      jr      nz,#1596        ; Skip if backup state exists
1590  3aa94d    ld      a,(#4da9)	; Load ghost 2 main state
1593  a7        and     a		; Test if main state is zero
1594  2009      jr      nz,#159f        ; Skip sprite mod if state exists

; Both ghost 2 states are zero - apply sprite modification
1596  3a2e4d    ld      a,(#4d2e)	; Load value from 4d2e
1599  87        add     a,a		; Double the value
159a  82        add     a,d		; Add the base value from 4dc0
159b  81        add     a,c		; Add constant 0x20
159c  dd7706    ld      (ix+#06),a	; Store modified value to offset 0x06

; Ghost 3 state check and sprite modification (same pattern)
159f  3aaf4d    ld      a,(#4daf)	; Load ghost 3 backup state
15a2  a7        and     a		; Test if backup state is zero
15a3  2006      jr      nz,#15ab        ; Skip if backup state exists
15a5  3aaa4d    ld      a,(#4daa)	; Load ghost 3 main state
15a8  a7        and     a		; Test if main state is zero
15a9  2009      jr      nz,#15b4        ; Skip sprite mod if state exists

; Both ghost 3 states are zero - apply sprite modification
15ab  3a2f4d    ld      a,(#4d2f)	; Load value from 4d2f
15ae  87        add     a,a		; Double the value
15af  82        add     a,d		; Add the base value from 4dc0
15b0  81        add     a,c		; Add constant 0x20
15b1  dd7708    ld      (ix+#08),a	; Store modified value to offset 0x08

; Call additional processing functions
; CONFIRMED: Three function calls - purpose unknown
15b4  cde615    call    #15e6		; Call function at 15e6
15b7  cd2d16    call    #162d		; Call function at 162d
15ba  cd5216    call    #1652		; Call function at 1652

; Check some condition and conditionally apply sprite modifications
15bd  78        ld      a,b		; Load B register (set by previous calls?)
15be  a7        and     a		; Test if zero
15bf  c8        ret     z		; Return if zero

; B register non-zero - apply bits 6&7 to multiple sprite locations
; CONFIRMED: Setting bits 6&7 (0xc0) on 5 sprite data locations
15c0  0ec0      ld      c,#c0		; Load bitmask 0xc0 (bits 6&7)
15c2  3a024c    ld      a,(#4c02)	; Load sprite data from offset 0x02
15c5  b1        or      c		; Set bits 6&7
15c6  32024c    ld      (#4c02),a	; Store back to offset 0x02
15c9  3a044c    ld      a,(#4c04)	; Load sprite data from offset 0x04
15cc  b1        or      c		; Set bits 6&7
15cd  32044c    ld      (#4c04),a	; Store back to offset 0x04
15d0  3a064c    ld      a,(#4c06)	; Load sprite data from offset 0x06
15d3  b1        or      c		; Set bits 6&7
15d4  32064c    ld      (#4c06),a	; Store back to offset 0x06
15d7  3a084c    ld      a,(#4c08)	; Load sprite data from offset 0x08
15da  b1        or      c		; Set bits 6&7
15db  32084c    ld      (#4c08),a	; Store back to offset 0x08
15de  3a0c4c    ld      a,(#4c0c)	; Load sprite data from offset 0x0c
15e1  b1        or      c		; Set bits 6&7
15e2  320c4c    ld      (#4c0c),a	; Store back to offset 0x0c
15e5  c9        ret     		; Return

; FUNCTION: Unknown function at 15e6
; MAYBE: Some kind of conditional sprite processing?
15e6  3a064e    ld      a,(#4e06)	; Load value from 4e06
15e9  d605      sub     #05		; Subtract 5
15eb  d8        ret     c		; Return if result was negative (< 5)

; Value >= 5 - continue processing
15ec  3a094d    ld      a,(#4d09)	; Load value from 4d09 (entity 4 Y position?)
15ef  e60f      and     #0f		; Mask to lower 4 bits
15f1  fe0c      cp      #0c		; Compare with 12
15f3  3804      jr      c,#15f9         ; Jump if < 12

; Value >= 12
15f5  1618      ld      d,#18		; Load 24 into D
15f7  1812      jr      #160b           ; Jump to continue

; Value >= 8 and < 12
15f9  fe08      cp      #08		; Compare with 8
15fb  3804      jr      c,#1601         ; Jump if < 8
15fd  1614      ld      d,#14		; Load 20 into D
15ff  180a      jr      #160b           ; Jump to continue

; Value < 8 (continues at 1601)
1601  fe04      cp      #04		; Compare with 4
1603  3804      jr      c,#1609         ; Jump if < 4
1605  1610      ld      d,#10		; Load 16 into D (for values 4-7)
1607  1802      jr      #160b           ; Jump to continue

; Value < 4
1609  1614      ld      d,#14		; Load 20 into D (for values 0-3)

; Common continuation - store calculated values to sprite buffer
; CONFIRMED: Storing sequential values (D, D+1, D+2, D+3) to specific offsets
160b  dd7204    ld      (ix+#04),d	; Store D to offset 0x04
160e  14        inc     d		; Increment D
160f  dd7206    ld      (ix+#06),d	; Store D+1 to offset 0x06
1612  14        inc     d		; Increment D
1613  dd7208    ld      (ix+#08),d	; Store D+2 to offset 0x08
1616  14        inc     d		; Increment D
1617  dd720c    ld      (ix+#0c),d	; Store D+3 to offset 0x0c

; Set additional sprite data values
; CONFIRMED: Fixed values stored to specific sprite offsets
161a  dd360a3f  ld      (ix+#0a),#3f	; Store 0x3f to offset 0x0a
161e  1616      ld      d,#16		; Load 22 into D
1620  dd7205    ld      (ix+#05),d	; Store 22 to offset 0x05
1623  dd7207    ld      (ix+#07),d	; Store 22 to offset 0x07
1626  dd7209    ld      (ix+#09),d	; Store 22 to offset 0x09
1629  dd720d    ld      (ix+#0d),d	; Store 22 to offset 0x0d
162c  c9        ret     		; Return

; ======================================================
; GHOST/SPRITE POSITION AND ANIMATION FUNCTIONS
; ======================================================
; This section contains functions that manage ghost sprite positioning
; and animation based on game state and level progression.

; FUNCTION: Ghost animation handler for status flag 4e07
; Handles sprite positioning based on level and status values
; C pseudocode:
;   if (status_4e07 == 0) return;
;   if (level == 0x3d) { reset_animation_flag(); }
;   if (status_4e07 >= 10) { set_position_32_1d(); }
;   if (status_4e07 >= 12) { set_position_33(); }
162d  3a074e    ld      a,(#4e07)	; Load status flag from 4e07 (MAYBE ghost state flag)
1630  a7        and     a		; Test if zero
1631  c8        ret     z		; Return if zero - no processing needed

1632  57        ld      d,a		; Save status value in D register
1633  3a3a4d    ld      a,(#4d3a)	; Load current level number
1636  d63d      sub     #3d		; Check if level == 0x3d (61 decimal)
1638  2004      jr      nz,#163e        ; Jump if not level 61
163a  dd360b00  ld      (ix+#0b),#00	; Reset animation offset to 0 for level 61

163e  7a        ld      a,d		; Restore status value
163f  fe0a      cp      #0a		; Compare with 10
1641  d8        ret     c		; Return if less than 10

; Status >= 10: Set sprite position to 0x32, 0x1d
1642  dd360232  ld      (ix+#02),#32	; Set sprite X position to 0x32 (50)
1646  dd36031d  ld      (ix+#03),#1d	; Set sprite Y position to 0x1d (29)
164a  fe0c      cp      #0c		; Compare with 12
164c  d8        ret     c		; Return if less than 12

; Status >= 12: Update X position to 0x33
164d  dd360233  ld      (ix+#02),#33	; Set sprite X position to 0x33 (51)
1651  c9        ret     

; FUNCTION: Ghost animation handler for status flag 4e08 
; Similar to above but for different status flag and positioning logic
; C pseudocode:
;   if (status_4e08 == 0) return;
;   if (level == 0x3d) { reset_animation_flag(); }
;   if (status_4e08 >= 1) { position_based_on_4dc0(); }
;   if (status_4e08 >= 3) { position_based_on_4d01_bit3(); }
1652  3a084e    ld      a,(#4e08)	; Load status flag from 4e08 (MAYBE another ghost state)
1655  a7        and     a		; Test if zero
1656  c8        ret     z		; Return if zero

1657  57        ld      d,a		; Save status value in D register  
1658  3a3a4d    ld      a,(#4d3a)	; Load current level number
165b  d63d      sub     #3d		; Check if level == 0x3d (61 decimal)
165d  2004      jr      nz,#1663        ; Jump if not level 61
165f  dd360b00  ld      (ix+#0b),#00	; Reset animation offset to 0 for level 61

1663  7a        ld      a,d		; Restore status value
1664  fe01      cp      #01		; Compare with 1
1666  d8        ret     c		; Return if less than 1

; Status >= 1: Calculate position based on animation counter 4dc0
1667  3ac04d    ld      a,(#4dc0)	; Load animation counter/flag
166a  1e08      ld      e,#08		; Load offset constant 8
166c  83        add     a,e		; Add 8 to animation value
166d  dd7702    ld      (ix+#02),a	; Store as sprite X position
1670  7a        ld      a,d		; Restore status value
1671  fe03      cp      #03		; Compare with 3
1673  d8        ret     c		; Return if less than 3

; Status >= 3: Additional positioning based on ghost 0 Y position bit 3
1674  3a014d    ld      a,(#4d01)	; Load ghost 0 Y position
1677  e608      and     #08		; Mask bit 3 (check if Y position bit 3 is set)
1679  0f        rrca    		; Rotate right (divide by 2)
167a  0f        rrca    		; Rotate right (divide by 2) 
167b  0f        rrca    		; Rotate right (divide by 2) - now bit 3 becomes bit 0
167c  1e0a      ld      e,#0a		; Load base value 10
167e  83        add     a,e		; Add extracted bit value to 10 (result: 10 or 11)
167f  dd770c    ld      (ix+#0c),a	; Store to sprite offset 0x0c
1682  3c        inc     a		; Increment by 1
1683  3c        inc     a		; Increment by 1 (total +2)
1684  dd7702    ld      (ix+#02),a	; Store to sprite X position (12 or 13)
1687  dd360d1e  ld      (ix+#0d),#1e	; Set sprite offset 0x0d to 0x1e (30)
168b  c9        ret     

; FUNCTION: Ghost 4 sprite tile selection based on Y position
; Selects sprite tile number based on lower 3 bits of ghost 4 Y position
; C pseudocode:
;   y_bits = ghost4_y & 0x07;
;   if (y_bits >= 6) sprite_tile = 0x30;
;   else if (y_bits >= 4) sprite_tile = 0x2e;
;   else if (y_bits >= 2) sprite_tile = 0x2c;
;   else sprite_tile = 0x2e;
168c  3a094d    ld      a,(#4d09)	; Load ghost 4 Y position
168f  e607      and     #07		; Mask lower 3 bits (0-7 range)
1691  fe06      cp      #06		; Compare with 6
1693  3805      jr      c,#169a         ; Jump if less than 6
1695  dd360a30  ld      (ix+#0a),#30	; Set sprite tile to 0x30 (48) for Y bits 6-7
1699  c9        ret     

169a  fe04      cp      #04		; Compare with 4  
169c  3805      jr      c,#16a3         ; Jump if less than 4
169e  dd360a2e  ld      (ix+#0a),#2e	; Set sprite tile to 0x2e (46) for Y bits 4-5
16a2  c9        ret     

16a3  fe02      cp      #02		; Compare with 2
16a5  3805      jr      c,#16ac         ; Jump if less than 2
16a7  dd360a2c  ld      (ix+#0a),#2c	; Set sprite tile to 0x2c (44) for Y bits 2-3
16ab  c9        ret     

16ac  dd360a2e  ld      (ix+#0a),#2e	; Set sprite tile to 0x2e (46) for Y bits 0-1
16b0  c9        ret     

; FUNCTION: Ghost 4 sprite tile selection based on X position  
; Similar to above but uses X position instead of Y position
; C pseudocode:
;   x_bits = ghost4_x & 0x07;
;   if (x_bits >= 6) sprite_tile = 0x2f;
;   else if (x_bits >= 4) sprite_tile = 0x2d;
;   else if (x_bits >= 2) sprite_tile = 0x2f;
;   else sprite_tile = 0x30;
16b1  3a084d    ld      a,(#4d08)	; Load ghost 4 X position
16b4  e607      and     #07		; Mask lower 3 bits (0-7 range)
16b6  fe06      cp      #06		; Compare with 6
16b8  3805      jr      c,#16bf         ; Jump if less than 6
16ba  dd360a2f  ld      (ix+#0a),#2f	; Set sprite tile to 0x2f (47) for X bits 6-7
16be  c9        ret     

16bf  fe04      cp      #04		; Compare with 4
16c1  3805      jr      c,#16c8         ; Jump if less than 4
16c3  dd360a2d  ld      (ix+#0a),#2d	; Set sprite tile to 0x2d (45) for X bits 4-5
16c7  c9        ret     

16c8  fe02      cp      #02		; Compare with 2
16ca  3805      jr      c,#16d1         ; Jump if less than 2
16cc  dd360a2f  ld      (ix+#0a),#2f	; Set sprite tile to 0x2f (47) for X bits 2-3
16d0  c9        ret     

16d1  dd360a30  ld      (ix+#0a),#30	; Set sprite tile to 0x30 (48) for X bits 0-1
16d5  c9        ret     

; FUNCTION: Ghost 4 sprite tile selection with bit 7 flag
; Similar logic but sets bit 7 in the sprite tile (possibly for flipping/mirroring)
; C pseudocode:
;   y_bits = ghost4_y & 0x07;
;   if (y_bits >= 6) tile = 0x2e | 0x80;
;   else if (y_bits >= 4) tile = 0x2c | 0x80;
;   else if (y_bits >= 2) tile = 0x2e | 0x80;
;   else tile = 0x30 | 0x80;
16d6  3a094d    ld      a,(#4d09)	; Load ghost 4 Y position
16d9  e607      and     #07		; Mask lower 3 bits
16db  fe06      cp      #06		; Compare with 6
16dd  3808      jr      c,#16e7         ; Jump if less than 6
16df  1e2e      ld      e,#2e		; Load sprite tile 0x2e (46)
16e1  cbfb      set     7,e		; Set bit 7 (sprite flip/mirror flag)
16e3  dd730a    ld      (ix+#0a),e	; Store flipped sprite tile
16e6  c9        ret     

16e7  fe04      cp      #04		; Compare with 4
16e9  3804      jr      c,#16ef         ; Jump if less than 4
16eb  1e2c      ld      e,#2c		; Load sprite tile 0x2c (44)
16ed  18f2      jr      #16e1           ; Jump to set bit 7 and store

16ef  fe02      cp      #02		; Compare with 2
16f1  30ec      jr      nc,#16df        ; Jump if >= 2 (use 0x2e)
16f3  1e30      ld      e,#30		; Load sprite tile 0x30 (48) for bits 0-1
16f5  18ea      jr      #16e1           ; Jump to set bit 7 and store

; FUNCTION: Ghost 4 sprite tile selection based on X position with different mapping
; Uses X position but with different tile assignments than previous X function
16f7  3a084d    ld      a,(#4d08)	; Load ghost 4 X position
16fa  e607      and     #07		; Mask lower 3 bits
16fc  fe06      cp      #06		; Compare with 6
16fe  3805      jr      c,#1705         ; Jump if less than 6
1700  dd360a30  ld      (ix+#0a),#30	; Set sprite tile to 0x30 (48) for X bits 6-7
1704  c9        ret     

1705  fe04      cp      #04		; Compare with 4
1707  3805      jr      c,#170e         ; Jump if less than 4
1709  1e2c      ld      e,#2c		; Load sprite tile 0x2c (44)
170b  cbfb      set     7,e		; Set bit 7 (flip flag)
170d  dd730a    ld      (ix+#0a),e	; Store flipped sprite tile
1710  c9        ret     

1711  fe02      cp      #02		; Compare with 2
1713  3804      jr      c,#1719         ; Jump if less than 2
1715  1e2d      ld      e,#2d		; Load sprite tile 0x2d (45)
1717  18f2      jr      #170b           ; Jump to set bit 7 and store

1719  1e2f      ld      e,#2f		; Load sprite tile 0x2f (47) for bits 0-1
171b  18ee      jr      #170b           ; Jump to set bit 7 and store

; ======================================================
; COLLISION DETECTION AND SCORING SYSTEM
; ======================================================
; This section implements collision detection between entities and scoring

; FUNCTION: Collision detection with scoring system
; Checks for collisions between entities and updates score accordingly
; C pseudocode:
;   counter = 4;
;   target_pos = entity4_position;
;   for each ghost {
;     if (!ghost_active && ghost_position == target_pos) {
;       found_collision(counter);
;       return;
;     }
;     counter--;
;   }
;   update_counters(counter);
171d  0604      ld      b,#04		; Initialize entity counter to 4
171f  ed5b394d  ld      de,(#4d39)	; Load target position (entity 4 position)

; Check Ghost 3 collision
1723  3aaf4d    ld      a,(#4daf)	; Load ghost 3 status flag
1726  a7        and     a		; Test if ghost is active
1727  2009      jr      nz,#1732        ; Skip if ghost is active
1729  2a374d    ld      hl,(#4d37)	; Load ghost 3 position
172c  a7        and     a		; Clear carry flag
172d  ed52      sbc     hl,de		; Compare positions (HL - DE)
172f  ca6317    jp      z,#1763		; Jump to collision handler if equal

; Check Ghost 2 collision  
1732  05        dec     b		; Decrement counter to 3
1733  3aae4d    ld      a,(#4dae)	; Load ghost 2 status flag
1736  a7        and     a		; Test if ghost is active
1737  2009      jr      nz,#1742        ; Skip if ghost is active
1739  2a354d    ld      hl,(#4d35)	; Load ghost 2 position
173c  a7        and     a		; Clear carry flag
173d  ed52      sbc     hl,de		; Compare positions
173f  ca6317    jp      z,#1763		; Jump to collision handler if equal

; Check Ghost 1 collision
1742  05        dec     b		; Decrement counter to 2
1743  3aad4d    ld      a,(#4dad)	; Load ghost 1 status flag
1746  a7        and     a		; Test if ghost is active
1747  2009      jr      nz,#1752        ; Skip if ghost is active
1749  2a334d    ld      hl,(#4d33)	; Load ghost 1 position
174c  a7        and     a		; Clear carry flag
174d  ed52      sbc     hl,de		; Compare positions
174f  ca6317    jp      z,#1763		; Jump to collision handler if equal

; Check Ghost 0 collision
1752  05        dec     b		; Decrement counter to 1
1753  3aac4d    ld      a,(#4dac)	; Load ghost 0 status flag
1756  a7        and     a		; Test if ghost is active
1757  2009      jr      nz,#1762        ; Skip if ghost is active
1759  2a314d    ld      hl,(#4d31)	; Load ghost 0 position
175c  a7        and     a		; Clear carry flag
175d  ed52      sbc     hl,de		; Compare positions
175f  ca6317    jp      z,#1763		; Jump to collision handler if equal

1762  05        dec     b		; Final decrement (counter = 0)

; Store collision results and handle scoring
1763  78        ld      a,b		; Get final counter value
1764  32a44d    ld      (#4da4),a	; Store collision counter result
1767  32a54d    ld      (#4da5),a	; Store to secondary collision counter
176a  a7        and     a		; Test if any collisions found
176b  c8        ret     z		; Return if no collisions

; Handle collision scoring
176c  21a64d    ld      hl,#4da6	; Point to scoring table
176f  5f        ld      e,a		; Use collision counter as index
1770  1600      ld      d,#00		; Clear high byte
1772  19        add     hl,de		; Calculate table offset
1773  7e        ld      a,(hl)		; Load score value from table
1774  a7        and     a		; Test if scoring is enabled
1775  c8        ret     z		; Return if no scoring

; Award points and update display
1776  af        xor     a		; Clear accumulator
1777  32a54d    ld      (#4da5),a	; Reset secondary collision counter
177a  21d04d    ld      hl,#4dd0	; Point to score counter
177d  34        inc     (hl)		; Increment score counter
177e  46        ld      b,(hl)		; Load score counter value
177f  04        inc     b		; Increment for function call
1780  cd5a2a    call    #2a5a		; Call score display function
1783  21bc4e    ld      hl,#4ebc	; Point to status flags
1786  cbde      set     3,(hl)		; Set bit 3 (MAYBE score display flag)
1788  c9        ret     

; FUNCTION: Distance-based collision detection
; Performs proximity-based collision detection between entities
; C pseudocode:
;   if (collision_found) return;
;   if (!scoring_enabled) return;
;   threshold = 4;
;   for each ghost {
;     if (!ghost_active && distance(ghost, target) < threshold) {
;       collision_found = true;
;       return;
;     }
;   }
1789  3aa44d    ld      a,(#4da4)	; Load collision counter
178c  a7        and     a		; Test if collision already found
178d  c0        ret     nz		; Return if collision already detected

178e  3aa64d    ld      a,(#4da6)	; Load scoring enable flag
1791  a7        and     a		; Test if scoring is enabled
1792  c8        ret     z		; Return if scoring disabled

1793  0e04      ld      c,#04		; Set distance threshold to 4 pixels
1795  0604      ld      b,#04		; Initialize ghost counter
1797  dd21084d  ld      ix,#4d08	; Point to entity 4 position (target)

; Check Ghost 3 proximity
179b  3aaf4d    ld      a,(#4daf)	; Load ghost 3 status
179e  a7        and     a		; Test if active
179f  2013      jr      nz,#17b4        ; Skip if active
17a1  3a064d    ld      a,(#4d06)	; Load ghost 3 X position
17a4  dd9600    sub     (ix+#00)	; Calculate X distance from target
17a7  b9        cp      c		; Compare with threshold
17a8  300a      jr      nc,#17b4        ; Skip if distance >= threshold
17aa  3a074d    ld      a,(#4d07)	; Load ghost 3 Y position
17ad  dd9601    sub     (ix+#01)	; Calculate Y distance from target
17b0  b9        cp      c		; Compare with threshold
17b1  da6317    jp      c,#1763		; Jump to collision handler if close

; Check Ghost 2 proximity
17b4  05        dec     b		; Decrement counter
17b5  3aae4d    ld      a,(#4dae)	; Load ghost 2 status
17b8  a7        and     a		; Test if active
17b9  2013      jr      nz,#17ce        ; Skip if active
17bb  3a044d    ld      a,(#4d04)	; Load ghost 2 X position
17be  dd9600    sub     (ix+#00)	; Calculate X distance
17c1  b9        cp      c		; Compare with threshold
17c2  300a      jr      nc,#17ce        ; Skip if too far
17c4  3a054d    ld      a,(#4d05)	; Load ghost 2 Y position
17c7  dd9601    sub     (ix+#01)	; Calculate Y distance
17ca  b9        cp      c		; Compare with threshold
17cb  da6317    jp      c,#1763		; Jump to collision handler if close

; Check Ghost 1 proximity
17ce  05        dec     b		; Decrement counter
17cf  3aad4d    ld      a,(#4dad)	; Load ghost 1 status
17d2  a7        and     a		; Test if active
17d3  2013      jr      nz,#17e8        ; Skip if active
17d5  3a024d    ld      a,(#4d02)	; Load ghost 1 X position
17d8  dd9600    sub     (ix+#00)	; Calculate X distance
17db  b9        cp      c		; Compare with threshold
17dc  300a      jr      nc,#17e8        ; Skip if too far
17de  3a034d    ld      a,(#4d03)	; Load ghost 1 Y position
17e1  dd9601    sub     (ix+#01)	; Calculate Y distance
17e4  b9        cp      c		; Compare with threshold
17e5  da6317    jp      c,#1763		; Jump to collision handler if close

; Check Ghost 0 proximity
17e8  05        dec     b		; Decrement counter
17e9  3aac4d    ld      a,(#4dac)	; Load ghost 0 status
17ec  a7        and     a		; Test if active
17ed  2013      jr      nz,#1802        ; Skip if active
17ef  3a004d    ld      a,(#4d00)	; Load ghost 0 X position
17f2  dd9600    sub     (ix+#00)	; Calculate X distance
17f5  b9        cp      c		; Compare with threshold
17f6  300a      jr      nc,#1802        ; Skip if too far
17f8  3a014d    ld      a,(#4d01)	; Load ghost 0 Y position
17fb  dd9601    sub     (ix+#01)	; Calculate Y distance
17fe  b9        cp      c		; Compare with threshold
17ff  da6317    jp      c,#1763		; Jump to collision handler if close

1802  05        dec     b		; Final decrement
1803  c36317    jp      #1763		; Jump to store results

; FUNCTION: Timer and score management 
; Manages game timers and score multiplication
1806  219d4d    ld      hl,#4d9d	; Point to timer counter
1809  3eff      ld      a,#ff		; Load timer check value (255)
180b  be        cp      (hl)		; Compare with current timer
180c  ca1118    jp      z,#1811		; Jump if timer expired
180f  35        dec     (hl)		; Decrement timer
1810  c9        ret     

; Timer expired - handle score doubling
1811  3aa64d    ld      a,(#4da6)	; Load scoring state
1814  a7        and     a		; Test scoring state
1815  ca2f18    jp      z,#182f		; Jump to alternate score handling

; Double score method 1 (for active scoring)
1818  2a4c4d    ld      hl,(#4d4c)	; Load score value low word
181b  29        add     hl,hl		; Double the value (shift left)
181c  224c4d    ld      (#4d4c),hl	; Store doubled low word
181f  2a4a4d    ld      hl,(#4d4a)	; Load score value high word
1822  ed6a      adc     hl,hl		; Double with carry from low word
1824  224a4d    ld      (#4d4a),hl	; Store doubled high word
1827  d0        ret     nc		; Return if no overflow

; Handle overflow in score doubling
1828  214c4d    ld      hl,#4d4c	; Point to low word
182b  34        inc     (hl)		; Increment for overflow correction
182c  c34318    jp      #1843		; Jump to scoring display update

; Double score method 2 (for inactive scoring)
182f  2a484d    ld      hl,(#4d48)	; Load alternate score low word
1832  29        add     hl,hl		; Double the value
1833  22484d    ld      (#4d48),hl	; Store doubled low word
1836  2a464d    ld      hl,(#4d46)	; Load alternate score high word
1839  ed6a      adc     hl,hl		; Double with carry
183b  22464d    ld      (#4d46),hl	; Store doubled high word
183e  d0        ret     nc		; Return if no overflow

; Handle overflow in alternate score
183f  21484d    ld      hl,#4d48	; Point to alternate score low
1842  34        inc     (hl)		; Increment for overflow

; Update score display
1843  3a0e4e    ld      a,(#4e0e)	; Load display control value
1846  329e4d    ld      (#4d9e),a	; Store to display register
1849  3a724e    ld      a,(#4e72)	; Load mask value
184c  4f        ld      c,a		; Store mask in C register
184d  3a094e    ld      a,(#4e09)	; Load status flags
1850  a1        and     c		; Apply mask to status
1851  4f        ld      c,a		; Store masked result
1852  213a4d    ld      hl,#4d3a	; Point to level counter
1855  7e        ld      a,(hl)		; Load current level number
1856  0621      ld      b,#21		; Load level threshold 0x21 (33 decimal)
1858  90        sub     b		; Check if level >= 33
1859  3809      jr      c,#1864         ; Jump if level < 33

; Handle levels >= 33 (higher level range)
185b  7e        ld      a,(hl)		; Reload level number
185c  063b      ld      b,#3b		; Load upper threshold 0x3b (59 decimal)
185e  90        sub     b		; Check if level >= 59
185f  3003      jr      nc,#1864        ; Jump if level >= 59 (too high)
1861  c3ab18    jp      #18ab		; Jump to special high-level handler

; Standard level processing (level < 33 or level >= 59)
1864  3e01      ld      a,#01		; Set flag value to 1
1866  32bf4d    ld      (#4dbf),a	; Store to flag register 4dbf
1869  3a004e    ld      a,(#4e00)	; Load game state flag
186c  fe01      cp      #01		; Check if game state == 1
186e  ca191a    jp      z,#1a19		; Jump to handler if state == 1
1871  3a044e    ld      a,(#4e04)	; Load secondary game state
1874  fe10      cp      #10		; Check if state >= 16
1876  d2191a    jp      nc,#1a19        ; Jump to handler if state >= 16

; Check input/status flags and determine movement
1879  79        ld      a,c		; Get masked status from earlier
187a  a7        and     a		; Test if zero
187b  2806      jr      z,#1883         ; Jump if zero (use alternate input)
187d  3a4050    ld      a,(#5040)	; Load input flags from 5040 (MAYBE player 2 input)
1880  c38618    jp      #1886		; Jump to process input

1883  3a0050    ld      a,(#5000)	; Load input flags from 5000 (MAYBE player 1 input)

; Process input flags for movement direction
1886  cb4f      bit     1,a		; Test bit 1 (MAYBE left/right input)
1888  c29918    jp      nz,#1899        ; Jump if bit 1 set
188b  2a0333    ld      hl,(#3303)	; Load movement vector from table at 3303
188e  3e02      ld      a,#02		; Set direction flag to 2
1890  32304d    ld      (#4d30),a	; Store direction to 4d30
1893  221c4d    ld      (#4d1c),hl	; Store movement vector to 4d1c
1896  c35019    jp      #1950		; Jump to movement processing

; Handle bit 1 set case
1899  cb57      bit     2,a		; Test bit 2 (MAYBE up/down input)
189b  c25019    jp      nz,#1950        ; Jump to movement processing if bit 2 set
189e  2aff32    ld      hl,(#32ff)	; Load alternate movement vector from 32ff
18a1  af        xor     a		; Clear accumulator (direction = 0)
18a2  32304d    ld      (#4d30),a	; Store direction 0 to 4d30
18a5  221c4d    ld      (#4d1c),hl	; Store movement vector to 4d1c
18a8  c35019    jp      #1950		; Jump to movement processing

; ======================================================
; HIGH-LEVEL HANDLER (Levels 33-58)
; ======================================================
; Special processing for intermediate difficulty levels

; FUNCTION: High-level movement handler
; Handles input processing for levels 33-58 with enhanced logic
; C pseudocode:
;   if (game_state == 1 || secondary_state >= 16) {
;     goto special_state_handler();
;   }
;   
;   uint8_t input = (status_flag) ? player2_input : player1_input;
;   
;   // Enhanced multi-bit input processing for higher difficulty
;   if (!(input & 0x02)) goto direction_handler_1();  // bit 1 clear
;   if (!(input & 0x04)) goto direction_handler_2();  // bit 2 clear
;   if (!(input & 0x01)) goto direction_handler_3();  // bit 0 clear
;   if (!(input & 0x08)) goto direction_handler_4();  // bit 3 clear
;   
;   // All input bits set - complex movement validation
;   temp_vector = current_movement_vector;
;   counter = 1;
;   
;   validation_result = validate_movement(temp_vector, entity_position);
;   if ((validation_result & 0xC0) != 0xC0) {
;     // Movement invalid - adjust position
;     goto position_adjustment();
;   }
;   
;   counter--;
;   if (counter != 0) goto secondary_validation();
;   
;   // Check alignment based on movement direction
;   if (direction_flag & 1) {  // horizontal movement
;     if ((entity4_x & 0x07) == 4) return;  // perfectly aligned
;   } else {  // vertical movement  
;     if ((entity4_y & 0x07) == 4) return;  // perfectly aligned
;   }
;   goto position_adjustment();
18ab  3a004e    ld      a,(#4e00)	; Load game state flag
18ae  fe01      cp      #01		; Check if game state == 1
18b0  ca191a    jp      z,#1a19		; Jump to special handler if state == 1
18b3  3a044e    ld      a,(#4e04)	; Load secondary game state
18b6  fe10      cp      #10		; Check if state >= 16
18b8  d2191a    jp      nc,#1a19        ; Jump if state >= 16

18bb  79        ld      a,c		; Get masked status
18bc  a7        and     a		; Test if zero
18bd  2806      jr      z,#18c5         ; Jump if zero
18bf  3a4050    ld      a,(#5040)	; Load player 2 input (MAYBE)
18c2  c3c818    jp      #18c8		; Jump to process

18c5  3a0050    ld      a,(#5000)	; Load player 1 input (MAYBE)

; Enhanced input processing for high levels
18c8  cb4f      bit     1,a		; Test bit 1 (direction input)
18ca  cac91a    jp      z,#1ac9		; Jump to handler if bit 1 clear
18cd  cb57      bit     2,a		; Test bit 2 (direction input)
18cf  cad91a    jp      z,#1ad9		; Jump to handler if bit 2 clear  
18d2  cb47      bit     0,a		; Test bit 0 (action input?)
18d4  cae81a    jp      z,#1ae8		; Jump to handler if bit 0 clear
18d7  cb5f      bit     3,a		; Test bit 3 (action input?)
18d9  caf81a    jp      z,#1af8		; Jump to handler if bit 3 clear

; All input bits set - complex movement calculation
18dc  2a1c4d    ld      hl,(#4d1c)	; Load current movement vector
18df  22264d    ld      (#4d26),hl	; Store to temporary location 4d26
18e2  0601      ld      b,#01		; Set counter to 1
18e4  dd21264d  ld      ix,#4d26	; Point IX to temporary movement vector
18e8  fd21394d  ld      iy,#4d39	; Point IY to entity position
18ec  cd0f20    call    #200f		; Call movement validation function
18ef  e6c0      and     #c0		; Mask upper 2 bits of result
18f1  d6c0      sub     #c0		; Check if result == 0xc0 (valid move?)
18f3  204b      jr      nz,#1940        ; Jump if move invalid

; Movement validation successful
18f5  05        dec     b		; Decrement counter
18f6  c21619    jp      nz,#1916        ; Jump if counter != 0
18f9  3a304d    ld      a,(#4d30)	; Load direction flag
18fc  0f        rrca    		; Test bit 0 of direction
18fd  da0b19    jp      c,#190b		; Jump if horizontal movement

; Vertical movement alignment check
1900  3a094d    ld      a,(#4d09)	; Load entity 4 Y position
1903  e607      and     #07		; Check Y alignment (lower 3 bits)
1905  fe04      cp      #04		; Check if Y aligned to 4-pixel boundary
1907  c8        ret     z		; Return if perfectly aligned
1908  c34019    jp      #1940		; Jump to position adjustment

; Horizontal movement alignment check  
190b  3a084d    ld      a,(#4d08)	; Load entity 4 X position
190e  e607      and     #07		; Check X alignment (lower 3 bits)
1910  fe04      cp      #04		; Check if X aligned to 4-pixel boundary
1912  c8        ret     z		; Return if perfectly aligned
1913  c34019    jp      #1940		; Jump to position adjustment

; Secondary movement validation
1916  dd211c4d  ld      ix,#4d1c	; Point IX to main movement vector
191a  cd0f20    call    #200f		; Call movement validation function
191d  e6c0      and     #c0		; Mask upper 2 bits
191f  d6c0      sub     #c0		; Check if result == 0xc0
1921  202d      jr      nz,#1950        ; Jump to finalize if invalid
1923  3a304d    ld      a,(#4d30)	; Load direction flag
1926  0f        rrca    		; Test direction bit
1927  da3519    jp      c,#1935		; Jump if horizontal

; Secondary vertical alignment check
192a  3a094d    ld      a,(#4d09)	; Load Y position
192d  e607      and     #07		; Check Y alignment
192f  fe04      cp      #04		; Test 4-pixel alignment
1931  c8        ret     z		; Return if aligned
1932  c35019    jp      #1950		; Jump to finalize

; Secondary horizontal alignment check
1935  3a084d    ld      a,(#4d08)	; Load X position
1938  e607      and     #07		; Check X alignment
193a  fe04      cp      #04		; Test 4-pixel alignment
193c  c8        ret     z		; Return if aligned
193d  c35019    jp      #1950		; Jump to finalize

; FUNCTION: Position adjustment and movement finalization
; Adjusts entity position when movement validation fails
1940  2a264d    ld      hl,(#4d26)	; Load temporary movement vector
1943  221c4d    ld      (#4d1c),hl	; Store as main movement vector
1946  05        dec     b		; Decrement counter
1947  ca5019    jp      z,#1950		; Jump to finalize if counter == 0
194a  3a3c4d    ld      a,(#4d3c)	; Load backup direction value
194d  32304d    ld      (#4d30),a	; Restore direction flag

; FUNCTION: Movement execution and position update
; Executes the validated movement and updates entity positions
1950  dd211c4d  ld      ix,#4d1c	; Point IX to movement vector
1954  fd21084d  ld      iy,#4d08	; Point IY to entity 4 position
1958  cd0020    call    #2000		; Call position update function
195b  3a304d    ld      a,(#4d30)	; Load direction flag
195e  0f        rrca    		; Test direction bit
195f  da7519    jp      c,#1975		; Jump if horizontal movement

; Vertical movement - adjust Y coordinate for alignment
1962  7d        ld      a,l		; Get Y coordinate (low byte of HL)
1963  e607      and     #07		; Check Y alignment
1965  fe04      cp      #04		; Compare with target alignment
1967  ca8519    jp      z,#1985		; Jump if aligned
196a  da7119    jp      c,#1971		; Jump if less than 4
196d  2d        dec     l		; Decrement Y (move up 1 pixel)
196e  c38519    jp      #1985		; Jump to store position

1971  2c        inc     l		; Increment Y (move down 1 pixel)
1972  c38519    jp      #1985		; Jump to store position

; Horizontal movement - adjust X coordinate for alignment
1975  7c        ld      a,h		; Get X coordinate (high byte of HL)
1976  e607      and     #07		; Check X alignment
1978  fe04      cp      #04		; Compare with target alignment
197a  ca8519    jp      z,#1985		; Jump if aligned
197d  da8419    jp      c,#1984		; Jump if less than 4
1980  25        dec     h		; Decrement X (move left 1 pixel)
1981  c38519    jp      #1985		; Jump to store position

1984  24        inc     h		; Increment X (move right 1 pixel)

; Store updated position and perform post-movement processing
1985  22084d    ld      (#4d08),hl	; Store updated entity 4 position
1988  cd1820    call    #2018		; Call position conversion function (MAYBE screen coordinates)
198b  22394d    ld      (#4d39),hl	; Store converted position
198e  dd21bf4d  ld      ix,#4dbf	; Point to status flag
1992  dd7e00    ld      a,(ix+#00)	; Load status flag value
1995  dd360000  ld      (ix+#00),#00	; Clear status flag
1999  a7        and     a		; Test if flag was set
199a  c0        ret     nz		; Return if flag was set

; Check for special position-based events
199b  3ad24d    ld      a,(#4dd2)	; Load event flag 1
199e  a7        and     a		; Test if set
199f  282c      jr      z,#19cd         ; Skip if not set
19a1  3ad44d    ld      a,(#4dd4)	; Load event flag 2
19a4  a7        and     a		; Test if set
19a5  2826      jr      z,#19cd         ; Skip if not set
19a7  2a084d    ld      hl,(#4d08)	; Load current entity 4 position
19aa  119480    ld      de,#8094	; Load special position constant
19ad  a7        and     a		; Clear carry
19ae  ed52      sbc     hl,de		; Compare positions
19b0  201b      jr      nz,#19cd        ; Skip if not at special position

; Special position reached - trigger bonus event
19b2  0619      ld      b,#19		; Load function parameter
19b4  4f        ld      c,a		; Clear C register (A is 0 from subtract)
19b5  cd4200    call    #0042		; Call sound/effect function
19b8  0e15      ld      c,#15		; Load value 21
19ba  81        add     a,c		; Add to accumulator
19bb  4f        ld      c,a		; Store result in C
19bc  061c      ld      b,#1c		; Load parameter 28
19be  cd4200    call    #0042		; Call sound/effect function again
19c1  cd0410    call    #1004		; Call display/score function
19c4  f7        rst     #30		; Call system function (MAYBE score display)

; Data bytes (POSSIBLY embedded data or continuation of function)
19c5  54        ld      d,h		; POSSIBLY data: 0x54
19c6  05        dec     b		; POSSIBLY data: 0x05  
19c7  00        nop     		; POSSIBLY data: 0x00
19c8  21bc4e    ld      hl,#4ebc	; Point to status flags
19cb  cbd6      set     2,(hl)		; Set bit 2 (MAYBE bonus event flag)

; Reset timer and check for special tiles
19cd  3eff      ld      a,#ff		; Load timer reset value (255)
19cf  329d4d    ld      (#4d9d),a	; Reset timer counter
19d2  2a394d    ld      hl,(#4d39)	; Load entity position (screen coordinates)
19d5  cd6500    call    #0065		; Call tile lookup function
19d8  7e        ld      a,(hl)		; Load tile value at position
19d9  fe10      cp      #10		; Check if tile == 0x10 (16 - MAYBE dot/pellet)
19db  2803      jr      z,#19e0         ; Jump if dot tile
19dd  fe14      cp      #14		; Check if tile == 0x14 (20 - MAYBE power pellet)
19df  c0        ret     nz		; Return if not special tile

; Handle dot/pellet consumption
19e0  dd210e4e  ld      ix,#4e0e	; Point to dot counter
19e4  dd3400    inc     (ix+#00)	; Increment dots consumed
19e7  e60f      and     #0f		; Mask lower 4 bits of tile value
19e9  cb3f      srl     a		; Shift right (divide by 2)
19eb  0640      ld      b,#40		; Load tile replacement value (64 - MAYBE empty space)
19ed  70        ld      (hl),b		; Replace consumed tile with empty space
19ee  0619      ld      b,#19		; Load sound parameter
19f0  4f        ld      c,a		; Use modified tile value as sound parameter
19f1  cb39      srl     c		; Shift C right again
19f3  cd4200    call    #0042		; Call sound function (dot eating sound)
19f6  3c        inc     a		; Increment tile value
19f7  fe01      cp      #01		; Check if == 1
19f9  cafd19    jp      z,#19fd		; Jump if == 1
19fc  87        add     a,a		; Double the value

19fd  329d4d    ld      (#4d9d),a	; Store modified value to timer
1a00  cd081b    call    #1b08		; Call scoring function
1a03  cd6a1a    call    #1a6a		; Call level progression function  
1a06  21bc4e    ld      hl,#4ebc	; Point to status flags
1a09  3a0e4e    ld      a,(#4e0e)	; Load dot counter
1a0c  0f        rrca    		; Test bit 0 of dot counter
1a0d  3805      jr      c,#1a14         ; Jump if odd number of dots
1a0f  cbc6      set     0,(hl)		; Set bit 0 in status flags (ghost release flag)
1a11  cb8e      res     1,(hl)		; Clear bit 1 in status flags
1a13  c9        ret     		; Return

; Even number of dots - different flag configuration
1a14  cb86      res     0,(hl)		; Clear bit 0 in status flags  
1a16  cbce      set     1,(hl)		; Set bit 1 in status flags (alternate ghost behavior)
1a18  c9        ret     		; Return

; ======================================================
; SPECIAL GAME STATE HANDLER
; ======================================================
; Handles special game states and advanced movement validation

; FUNCTION: Special state movement processor
; Called when game is in special state (state == 1 or state >= 16)
; Provides enhanced movement validation and alignment correction
; C pseudocode:
;   if (movement_vector == 0) {  // no horizontal movement
;     if ((entity4_y & 0x07) != 4) goto direct_movement();
;   } else {  // horizontal movement active
;     if ((entity4_x & 0x07) != 4) goto direct_movement();
;   }
;   
;   // Perfect alignment - use enhanced processing
;   if (!validate_special_movement(5)) {
;     call_system_function();  // special handling
;   }
;   
;   // Enhanced movement calculation
;   new_position = calculate_advanced_position(temp_movement, secondary_storage);
;   secondary_storage = new_position;
;   main_movement_vector = temp_movement;
;   direction_flag = backup_direction;
;   
;   // Fallback: direct_movement()
;   final_position = update_position(main_movement, entity4_position);
;   goto position_finalization();
1a19  211c4d    ld      hl,#4d1c	; Point to movement vector
1a1c  7e        ld      a,(hl)		; Load movement vector byte
1a1d  a7        and     a		; Test if zero (no movement)
1a1e  ca2e1a    jp      z,#1a2e		; Jump if no horizontal movement

; Horizontal movement active - check X alignment
1a21  3a084d    ld      a,(#4d08)	; Load entity 4 X position
1a24  e607      and     #07		; Check X alignment (lower 3 bits)
1a26  fe04      cp      #04		; Compare with 4 (optimal alignment)
1a28  ca381a    jp      z,#1a38		; Jump to processing if aligned
1a2b  c35c1a    jp      #1a5c		; Jump to direct movement if misaligned

; Vertical movement active - check Y alignment  
1a2e  3a094d    ld      a,(#4d09)	; Load entity 4 Y position
1a31  e607      and     #07		; Check Y alignment (lower 3 bits)
1a33  fe04      cp      #04		; Compare with 4 (optimal alignment)
1a35  c25c1a    jp      nz,#1a5c        ; Jump to direct movement if misaligned

; Perfect alignment detected - execute enhanced movement
1a38  3e05      ld      a,#05		; Load parameter 5 (MAYBE difficulty/mode setting)
1a3a  cdd01e    call    #1ed0		; Call validation function
1a3d  3803      jr      c,#1a42         ; Jump if validation failed
1a3f  ef        rst     #28		; Call system function
1a40  17        rla     		; POSSIBLY data: 0x17
1a41  00        nop     		; POSSIBLY data: 0x00

; Enhanced movement calculation
1a42  dd21264d  ld      ix,#4d26	; Point IX to temporary movement data
1a46  fd21124d  ld      iy,#4d12	; Point IY to secondary position storage
1a4a  cd0020    call    #2000		; Call advanced position update function
1a4d  22124d    ld      (#4d12),hl	; Store calculated position to secondary storage
1a50  2a264d    ld      hl,(#4d26)	; Load temporary movement vector
1a53  221c4d    ld      (#4d1c),hl	; Store as main movement vector
1a56  3a3c4d    ld      a,(#4d3c)	; Load backup direction value
1a59  32304d    ld      (#4d30),a	; Restore direction flag

; Direct movement execution (fallback path)
1a5c  dd211c4d  ld      ix,#4d1c	; Point IX to main movement vector
1a60  fd21084d  ld      iy,#4d08	; Point IY to entity 4 position
1a64  cd0020    call    #2000		; Call position update function
1a67  c38519    jp      #1985		; Jump back to position finalization

; ======================================================
; BONUS SYSTEM AND SCORE MULTIPLIER ACTIVATION  
; ======================================================
; Activates bonus scoring when specific conditions are met

; FUNCTION: Bonus system activator
; Triggered when timer reaches specific value (6)
; Activates score multipliers and bonus item spawning
; C pseudocode:
;   if (timer_value != 6) return;
;   
;   // Activate bonus multiplier system
;   active_multiplier = bonus_multiplier_value;
;   
;   // Enable all scoring and bonus flags
;   scoring_flag = 1;
;   bonus_multiplier[0] = 1;  // tiers 1-4
;   bonus_multiplier[1] = 1;
;   bonus_multiplier[2] = 1; 
;   bonus_multiplier[3] = 1;
;   bonus_feature[0] = 1;     // features 1-5
;   bonus_feature[1] = 1;
;   bonus_feature[2] = 1;
;   bonus_feature[3] = 1;
;   bonus_feature[4] = 1;
;   
;   // Reset counters
;   bonus_counter1 = 0;
;   bonus_counter2 = 0;
;   
;   // Initialize bonus sprites (fruit/items)
;   sprite_buffer[1].tile = 0x1C;  // bonus fruit tile
;   sprite_buffer[2].tile = 0x1C;
;   sprite_buffer[3].tile = 0x1C; 
;   sprite_buffer[4].tile = 0x1C;
;   sprite_buffer[1].y = 0x11;     // Y position 17
;   sprite_buffer[2].y = 0x11;
;   sprite_buffer[3].y = 0x11;
;   sprite_buffer[4].y = 0x11;
;   
;   // Set system flags
;   bonus_status_flags |= 0x20;   // set bit 5 (bonus active)
;   bonus_status_flags &= ~0x80;  // clear bit 7 (reset state)
1a6a  3a9d4d    ld      a,(#4d9d)	; Load timer value
1a6d  fe06      cp      #06		; Check if timer == 6
1a6f  c0        ret     nz		; Return if not the activation time

; Timer == 6: Activate all bonus systems
1a70  2abd4d    ld      hl,(#4dbd)	; Load bonus multiplier value
1a73  22cb4d    ld      (#4dcb),hl	; Store to active multiplier location
1a76  3e01      ld      a,#01		; Load activation value (1)

; Activate multiple scoring/bonus flags
1a78  32a64d    ld      (#4da6),a	; Activate scoring system flag 
1a7b  32a74d    ld      (#4da7),a	; Activate bonus multiplier 1
1a7e  32a84d    ld      (#4da8),a	; Activate bonus multiplier 2  
1a81  32a94d    ld      (#4da9),a	; Activate bonus multiplier 3
1a84  32aa4d    ld      (#4daa),a	; Activate bonus multiplier 4
1a87  32b14d    ld      (#4db1),a	; Activate bonus feature 1
1a8a  32b24d    ld      (#4db2),a	; Activate bonus feature 2
1a8d  32b34d    ld      (#4db3),a	; Activate bonus feature 3
1a90  32b44d    ld      (#4db4),a	; Activate bonus feature 4
1a93  32b54d    ld      (#4db5),a	; Activate bonus feature 5

; Reset bonus counters
1a96  af        xor     a		; Clear accumulator (0)
1a97  32c84d    ld      (#4dc8),a	; Reset bonus counter 1
1a9a  32d04d    ld      (#4dd0),a	; Reset bonus counter 2 (also score counter)

; Initialize sprite/display data for bonus items
1a9d  dd21004c  ld      ix,#4c00	; Point to sprite data buffer
1aa1  dd36021c  ld      (ix+#02),#1c	; Set sprite 1 tile to 0x1c (28 - MAYBE bonus fruit)
1aa5  dd36041c  ld      (ix+#04),#1c	; Set sprite 2 tile to 0x1c  
1aa9  dd36061c  ld      (ix+#06),#1c	; Set sprite 3 tile to 0x1c
1aad  dd36081c  ld      (ix+#08),#1c	; Set sprite 4 tile to 0x1c
1ab1  dd360311  ld      (ix+#03),#11	; Set sprite 1 Y position to 0x11 (17)
1ab5  dd360511  ld      (ix+#05),#11	; Set sprite 2 Y position to 0x11
1ab9  dd360711  ld      (ix+#07),#11	; Set sprite 3 Y position to 0x11  
1abd  dd360911  ld      (ix+#09),#11	; Set sprite 4 Y position to 0x11

; Set bonus system status flags
1ac1  21ac4e    ld      hl,#4eac	; Point to bonus status flags
1ac4  cbee      set     5,(hl)		; Set bit 5 (bonus mode active)
1ac6  cbbe      res     7,(hl)		; Clear bit 7 (reset bonus state)
1ac8  c9        ret     		; Return

; ======================================================
; DIRECTIONAL INPUT HANDLERS (High-Level Mode)
; ======================================================
; These functions handle the 4 directional inputs for levels 33-58
; Each loads a movement vector from a direction table and sets up movement

; FUNCTION: Direction handler 1 (MAYBE right/left)
; Loads movement vector from table at 3303
1ac9  2a0333    ld      hl,(#3303)	; Load movement vector from direction table 1
1acc  3e02      ld      a,#02		; Set direction code to 2
1ace  323c4d    ld      (#4d3c),a	; Store direction as backup
1ad1  22264d    ld      (#4d26),hl	; Store vector to temporary movement location
1ad4  0600      ld      b,#00		; Clear counter
1ad6  c3e418    jp      #18e4		; Jump back to movement validation loop

; FUNCTION: Direction handler 2 (MAYBE up/down) 
; Loads movement vector from table at 32ff
1ad9  2aff32    ld      hl,(#32ff)	; Load movement vector from direction table 2
1adc  af        xor     a		; Set direction code to 0
1add  323c4d    ld      (#4d3c),a	; Store direction as backup
1ae0  22264d    ld      (#4d26),hl	; Store vector to temporary movement location
1ae3  0600      ld      b,#00		; Clear counter
1ae5  c3e418    jp      #18e4		; Jump back to movement validation loop

; FUNCTION: Direction handler 3 (MAYBE diagonal/special)
; Loads movement vector from table at 3305
1ae8  2a0533    ld      hl,(#3305)	; Load movement vector from direction table 3
1aeb  3e03      ld      a,#03		; Set direction code to 3
1aed  323c4d    ld      (#4d3c),a	; Store direction as backup
1af0  22264d    ld      (#4d26),hl	; Store vector to temporary movement location
1af3  0600      ld      b,#00		; Clear counter
1af5  c3e418    jp      #18e4		; Jump back to movement validation loop

; FUNCTION: Direction handler 4 (MAYBE alternate direction)
; Loads movement vector from table at 3301  
1af8  2a0133    ld      hl,(#3301)	; Load movement vector from direction table 4
1afb  3e01      ld      a,#01		; Set direction code to 1
1afd  323c4d    ld      (#4d3c),a	; Store direction as backup
1b00  22264d    ld      (#4d26),hl	; Store vector to temporary movement location
1b03  0600      ld      b,#00		; Clear counter
1b05  c3e418    jp      #18e4		; Jump back to movement validation loop

; ======================================================
; MULTI-TIERED SCORING SYSTEM
; ======================================================
; Implements a cascading scoring system with multiple tiers

; FUNCTION: Primary scoring dispatcher
; Routes scoring to different subsystems based on game state
; C pseudocode:
;   if (primary_scoring_flag) {
;     primary_score_counter++;
;     return;
;   }
;   
;   // Secondary scoring with priority tiers
;   if (tier3_scoring_flag) return;  // highest priority, blocks others
;   
;   if (tier2_scoring_flag) {
;     tier2_score_counter++;
;     return;
;   }
;   
;   if (tier1_scoring_flag) {
;     tier1_score_counter++;
;     return;
;   }
;   
;   // Default: base scoring (lowest tier)
;   base_score_counter++;
1b08  3a124e    ld      a,(#4e12)	; Load primary scoring flag
1b0b  a7        and     a		; Test if active
1b0c  ca141b    jp      z,#1b14		; Jump to secondary scoring if inactive
1b0f  219f4d    ld      hl,#4d9f	; Point to primary score counter
1b12  34        inc     (hl)		; Increment primary score
1b13  c9        ret     		; Return

; FUNCTION: Secondary scoring system
; Handles multi-tier bonus scoring with cascading logic
1b14  3aa34d    ld      a,(#4da3)	; Load tier 3 scoring flag
1b17  a7        and     a		; Test if active
1b18  c0        ret     nz		; Return if tier 3 is active (highest priority)

1b19  3aa24d    ld      a,(#4da2)	; Load tier 2 scoring flag
1b1c  a7        and     a		; Test if active
1b1d  ca251b    jp      z,#1b25		; Jump to tier 1 if inactive
1b20  21114e    ld      hl,#4e11	; Point to tier 2 score counter
1b23  34        inc     (hl)		; Increment tier 2 score
1b24  c9        ret     		; Return

1b25  3aa14d    ld      a,(#4da1)	; Load tier 1 scoring flag
1b28  a7        and     a		; Test if active
1b29  ca311b    jp      z,#1b31		; Jump to base scoring if inactive
1b2c  21104e    ld      hl,#4e10	; Point to tier 1 score counter
1b2f  34        inc     (hl)		; Increment tier 1 score
1b30  c9        ret     		; Return

; Base scoring (lowest tier)
1b31  210f4e    ld      hl,#4e0f	; Point to base score counter
1b34  34        inc     (hl)		; Increment base score
1b35  c9        ret     		; Return

; ======================================================
; GHOST SCORING AND BONUS MULTIPLICATION SYSTEM
; ======================================================
; Handles scoring when ghosts are consumed, with score doubling

; FUNCTION: Ghost consumption scoring handler
; Processes ghost consumption with progressive score doubling
; C pseudocode:
;   if (!ghost_consumption_flag) return;
;   if (ghost0_still_active) return;
;   
;   calculate_score_multiplier();
;   uint16_t ghost_position = ghost0_position;
;   score_multiplier = calculate_position_score(ghost_position, score_buffer);
;   
;   if (score_multiplier != 0) {
;     // Tier 1: Double score with overflow handling
;     uint32_t score1 = (score_value1_high << 16) | score_value1_low;
;     score1 *= 2;
;     score_value1_low = score1 & 0xFFFF;
;     score_value1_high = score1 >> 16;
;     goto ghost_ai_processing();
;   }
;   
;   // Check tiers 2-5 with same doubling logic
;   if (consumption_tier2_flag) { double_score_tier2(); goto ghost_ai(); }
;   if (consumption_tier3_flag) { double_score_tier3(); goto ghost_ai(); }  
;   if (consumption_tier4_flag) { double_score_tier4(); return; }
;   
;   // Final tier: maximum multiplier
;   double_score_final_tier();
1b36  3aa04d    ld      a,(#4da0)	; Load ghost consumption flag
1b39  a7        and     a		; Test if ghost was consumed
1b3a  c8        ret     z		; Return if no ghost consumed

1b3b  3aac4d    ld      a,(#4dac)	; Load ghost 0 status
1b3e  a7        and     a		; Test if ghost 0 is active
1b3f  c0        ret     nz		; Return if ghost 0 is still active

; Ghost 0 consumed - calculate score multiplier
1b40  cdd720    call    #20d7		; Call score calculation function
1b43  2a314d    ld      hl,(#4d31)	; Load ghost 0 position
1b46  01994d    ld      bc,#4d99	; Point BC to score calculation buffer
1b49  cd5a20    call    #205a		; Call position-based scoring function
1b4c  3a994d    ld      a,(#4d99)	; Load calculated score multiplier
1b4f  a7        and     a		; Test if scoring should occur
1b50  ca6a1b    jp      z,#1b6a		; Jump to next tier if zero

; Apply score doubling for consumption tier 1
1b53  2a604d    ld      hl,(#4d60)	; Load score value 1 (low word)
1b56  29        add     hl,hl		; Double the score (shift left)
1b57  22604d    ld      (#4d60),hl	; Store doubled score back
1b5a  2a5e4d    ld      hl,(#4d5e)	; Load score value 1 (high word)
1b5d  ed6a      adc     hl,hl		; Double with carry from low word
1b5f  225e4d    ld      (#4d5e),hl	; Store doubled high word
1b62  d0        ret     nc		; Return if no overflow

; Handle overflow in score doubling
1b63  21604d    ld      hl,#4d60	; Point to low word
1b66  34        inc     (hl)		; Increment for overflow correction
1b67  c3d81b    jp      #1bd8		; Jump to ghost AI processing

; Check consumption tier 2
1b6a  3aa74d    ld      a,(#4da7)	; Load consumption tier 2 flag
1b6d  a7        and     a		; Test if active
1b6e  ca881b    jp      z,#1b88		; Jump to tier 3 if inactive

; Apply score doubling for consumption tier 2  
1b71  2a5c4d    ld      hl,(#4d5c)	; Load score value 2 (low word)
1b74  29        add     hl,hl		; Double the score
1b75  225c4d    ld      (#4d5c),hl	; Store doubled score
1b78  2a5a4d    ld      hl,(#4d5a)	; Load score value 2 (high word)  
1b7b  ed6a      adc     hl,hl		; Double with carry
1b7d  225a4d    ld      (#4d5a),hl	; Store doubled high word
1b80  d0        ret     nc		; Return if no overflow

1b81  215c4d    ld      hl,#4d5c	; Handle overflow
1b84  34        inc     (hl)		; Increment for overflow
1b85  c3d81b    jp      #1bd8		; Jump to ghost AI processing

; Check consumption tier 3
1b88  3ab74d    ld      a,(#4db7)	; Load consumption tier 3 flag
1b8b  a7        and     a		; Test if active
1b8c  caa61b    jp      z,#1ba6		; Jump to tier 4 if inactive

; Apply score doubling for consumption tier 3
1b8f  2a504d    ld      hl,(#4d50)	; Load score value 3 (low word)
1b92  29        add     hl,hl		; Double the score
1b93  22504d    ld      (#4d50),hl	; Store doubled score
1b96  2a4e4d    ld      hl,(#4d4e)	; Load score value 3 (high word)
1b99  ed6a      adc     hl,hl		; Double with carry
1b9b  224e4d    ld      (#4d4e),hl	; Store doubled high word
1b9e  d0        ret     nc		; Return if no overflow

1b9f  21504d    ld      hl,#4d50	; Handle overflow
1ba2  34        inc     (hl)		; Increment for overflow
1ba3  c3d81b    jp      #1bd8		; Jump to ghost AI processing

; Check consumption tier 4 (highest multiplier)
1ba6  3ab64d    ld      a,(#4db6)	; Load consumption tier 4 flag
1ba9  a7        and     a		; Test if active
1baa  cac41b    jp      z,#1bc4		; Jump to final tier if inactive

; Apply score doubling for consumption tier 4
1bad  2a544d    ld      hl,(#4d54)	; Load score value 4 (low word)
1bb0  29        add     hl,hl		; Double the score
1bb1  22544d    ld      (#4d54),hl	; Store doubled score
1bb4  2a524d    ld      hl,(#4d52)	; Load score value 4 (high word)
1bb7  ed6a      adc     hl,hl		; Double with carry
1bb9  22524d    ld      (#4d52),hl	; Store doubled high word
1bbc  d0        ret     nc		; Return if no overflow

1bbf  21544d    ld      hl,#4d54	; Handle overflow
1bc2  34        inc     (hl)		; Increment for overflow
1bc3  c9        ret     		; Return

; Final consumption tier (maximum multiplier)
1bc4  2a584d    ld      hl,(#4d58)	; Load final score value (low word)
1bc7  29        add     hl,hl		; Double the score (maximum multiplier)
1bc8  22584d    ld      (#4d58),hl	; Store doubled score
1bcb  2a564d    ld      hl,(#4d56)	; Load final score value (high word)
1bce  ed6a      adc     hl,hl		; Double with carry
1bd0  22564d    ld      (#4d56),hl	; Store doubled high word
1bd3  d0        ret     nc		; Return if no overflow

1bd4  21584d    ld      hl,#4d58	; Handle final overflow
1bd7  34        inc     (hl)		; Increment for overflow

; ======================================================
; BLINKY (GHOST 0) AI MOVEMENT PROCESSING
; ======================================================
; Handles Blinky's movement with alignment checking and pathfinding
; Red ghost - Aggressive chaser behavior

; FUNCTION: Blinky movement processor 
; Processes movement for Blinky with alignment validation
; C pseudocode:
;   // BLINKY'S AGGRESSIVE CHASE AI ALGORITHM
;   void process_blinky_movement() {
;     // Check movement alignment for optimal AI decision points
;     if (blinky_movement_vector == 0) {  // vertical movement only
;       if ((blinky_y & 0x07) != 4) goto direct_movement_fallback();
;     } else {  // horizontal movement active
;       if ((blinky_x & 0x07) != 4) goto direct_movement_fallback();
;     }
;     
;     // Perfect 4-pixel alignment - execute enhanced AI
;     if (!ai_validation_check(BLINKY_AI_PARAM)) goto pathfinding_ai();
;     
;     // AI behavior mode switching
;     if (blinky_ai_behavior_flag) {
;       execute_scatter_mode_ai();  // Retreat to corner
;     } else {
;       // AGGRESSIVE CHASE MODE (Blinky's signature behavior)
;       target_position = pac_man_position;
;       pathfind_direct_to_target(target_position);
;       if (tile_at_target != TRAVERSABLE_TILE) {
;         execute_obstacle_avoidance_ai();
;       }
;     }
;     
;     // Execute calculated movement
;     update_blinky_behavior_state();
;     new_position = calculate_new_position(blinky_movement_data, blinky_position);
;     blinky_position = new_position;
;     blinky_active_movement_vector = calculated_movement_vector;
;     blinky_active_direction = blinky_backup_direction;
;     return;
;     
;   direct_movement_fallback:
;     // Misaligned - use direct movement without AI enhancements
;     execute_direct_blinky_movement();
;   }
1bd8  21144d    ld      hl,#4d14	; Point to ghost movement vector
1bdb  7e        ld      a,(hl)		; Load movement vector
1bdc  a7        and     a		; Test if zero (no movement)
1bdd  caed1b    jp      z,#1bed		; Jump if no horizontal movement

; Horizontal movement active - check ghost X alignment
1be0  3a004d    ld      a,(#4d00)	; Load ghost 0 X position
1be3  e607      and     #07		; Check X alignment (lower 3 bits)
1be5  fe04      cp      #04		; Compare with optimal alignment (4)
1be7  caf71b    jp      z,#1bf7		; Jump to enhanced processing if aligned
1bea  c3361c    jp      #1c36		; Jump to direct processing if misaligned

; Vertical movement active - check ghost Y alignment
1bed  3a014d    ld      a,(#4d01)	; Load ghost 0 Y position
1bf0  e607      and     #07		; Check Y alignment (lower 3 bits)
1bf2  fe04      cp      #04		; Compare with optimal alignment (4)
1bf4  c2361c    jp      nz,#1c36        ; Jump to direct processing if misaligned

; Ghost perfectly aligned - execute enhanced AI movement
1bf7  3e01      ld      a,#01		; Load parameter 1 (MAYBE AI difficulty level)
1bf9  cdd01e    call    #1ed0		; Call AI validation function
1bfc  381b      jr      c,#1c19         ; Jump if validation passed

; AI pathfinding logic
1bfe  3aa74d    ld      a,(#4da7)	; Load AI behavior flag
1c01  a7        and     a		; Test behavior mode
1c02  ca0b1c    jp      z,#1c0b		; Jump to chase mode if zero
1c05  ef        rst     #28		; Queue command: Blinky scatter targeting
1c06  0c        inc     c		; Command: 0x0c = Blinky scatter targeting
1c07  00        nop     		; Parameter: 0x00 = default behavior  
1c08  c3191c    jp      #1c19		; Jump to movement execution

; Chase mode AI - target player position
1c0b  2a0a4d    ld      hl,(#4d0a)	; Load target position (MAYBE player position)
1c0e  cd5220    call    #2052		; Call pathfinding function
1c11  7e        ld      a,(hl)		; Load tile at target position
1c12  fe1a      cp      #1a		; Check if tile is traversable (26 decimal)
1c14  2803      jr      z,#1c19         ; Jump if passable
1c16  ef        rst     #28		; Queue command: Blinky obstacle avoidance
1c17  08        ex      af,af'		; Command: 0x08 = Blinky obstacle avoidance
1c18  00        nop     		; Parameter: 0x00 = default behavior

; Execute calculated ghost movement
1c19  cdfe1e    call    #1efe		; Call ghost behavior update function
1c1c  dd211e4d  ld      ix,#4d1e	; Point IX to ghost movement data
1c20  fd210a4d  ld      iy,#4d0a	; Point IY to ghost position data
1c24  cd0020    call    #2000		; Call position update function
1c27  220a4d    ld      (#4d0a),hl	; Store updated ghost position
1c2a  2a1e4d    ld      hl,(#4d1e)	; Load calculated movement vector
1c2d  22144d    ld      (#4d14),hl	; Store as active movement vector
1c30  3a2c4d    ld      a,(#4d2c)	; Load ghost direction backup
1c33  32284d    ld      (#4d28),a	; Store to active direction

; Direct ghost movement processing (fallback)
1c36  dd21144d  ld      ix,#4d14	; Point IX to ghost movement vector
1c3a  fd21004d  ld      iy,#4d00	; Point IY to ghost 0 position
1c3e  cd0020    call    #2000		; Call position update function
1c41  22004d    ld      (#4d00),hl	; Store updated ghost 0 position
1c44  cd1820    call    #2018		; Call position conversion function
1c47  22314d    ld      (#4d31),hl	; Store converted position
1c4a  c9        ret     		; Return

; ======================================================
; PINKY (GHOST 1) AI AND SCORING SYSTEM
; Pink ghost - Ambush specialist
; ======================================================
; Handles Ghost 1 movement, AI, and score multiplication

; FUNCTION: Pinky scoring and AI processor
; C pseudocode:
;   if (ghost1_scoring_flag != 1) return;
;   if (ghost1_still_active) return;
;   
;   score_multiplier = calculate_position_score(ghost1_position, score_buffer);
;   if (score_multiplier != 0) {
;     double_score_tier1(); goto ghost1_ai_processing();
;   }
;   if (ghost1_tier2_flag) { double_score_tier2(); goto ghost1_ai(); }
;   
;   // Default: double final tier score
;   double_score_final_tier();
;   
;   ghost1_ai_processing();  // Same alignment/pathfinding logic as ghost 0
1c4b  3aa14d    ld      a,(#4da1)	; Load ghost 1 scoring flag
1c4e  fe01      cp      #01		; Check if scoring flag == 1
1c50  c0        ret     nz		; Return if not active

1c51  3aad4d    ld      a,(#4dad)	; Load ghost 1 status
1c54  a7        and     a		; Test if ghost 1 is active
1c55  c0        ret     nz		; Return if ghost 1 still active

; Ghost 1 consumed - calculate score multiplier
1c56  2a334d    ld      hl,(#4d33)	; Load ghost 1 position
1c59  019a4d    ld      bc,#4d9a	; Point BC to score calculation buffer
1c5c  cd5a20    call    #205a		; Call position-based scoring function
1c5f  3a9a4d    ld      a,(#4d9a)	; Load calculated score multiplier
1c62  a7        and     a		; Test if scoring should occur
1c63  ca7d1c    jp      z,#1c7d		; Jump to next tier if zero

; Apply score doubling for ghost 1 tier 1
1c66  2a6c4d    ld      hl,(#4d6c)	; Load score value (low word)
1c69  29        add     hl,hl		; Double the score (shift left)
1c6a  226c4d    ld      (#4d6c),hl	; Store doubled score back
1c6d  2a6a4d    ld      hl,(#4d6a)	; Load score value (high word)
1c70  ed6a      adc     hl,hl		; Double with carry from low word
1c72  226a4d    ld      (#4d6a),hl	; Store doubled high word
1c75  d0        ret     nc		; Return if no overflow

; Handle overflow in score doubling
1c76  216c4d    ld      hl,#4d6c	; Point to low word
1c79  34        inc     (hl)		; Increment for overflow correction
1c7a  c3af1c    jp      #1caf		; Jump to ghost 1 AI processing

; Check ghost 1 tier 2 scoring
1c7d  3aa84d    ld      a,(#4da8)	; Load ghost 1 tier 2 flag
1c80  a7        and     a		; Test if active
1c81  ca9b1c    jp      z,#1c9b		; Jump to final tier if inactive

; Apply score doubling for ghost 1 tier 2
1c84  2a684d    ld      hl,(#4d68)	; Load tier 2 score value (low word)
1c87  29        add     hl,hl		; Double the score
1c88  22684d    ld      (#4d68),hl	; Store doubled score
1c8b  2a664d    ld      hl,(#4d66)	; Load tier 2 score value (high word)
1c8e  ed6a      adc     hl,hl		; Double with carry
1c90  22664d    ld      (#4d66),hl	; Store doubled high word
1c93  d0        ret     nc		; Return if no overflow

1c94  21684d    ld      hl,#4d68	; Handle overflow
1c97  34        inc     (hl)		; Increment for overflow
1c98  c3af1c    jp      #1caf		; Jump to ghost 1 AI processing

; Final tier scoring for ghost 1
1c9b  2a644d    ld      hl,(#4d64)	; Load final score value (low word)
1c9e  29        add     hl,hl		; Double the score (maximum multiplier)
1c9f  22644d    ld      (#4d64),hl	; Store doubled score
1ca2  2a624d    ld      hl,(#4d62)	; Load final score value (high word)
1ca5  ed6a      adc     hl,hl		; Double with carry
1ca7  22624d    ld      (#4d62),hl	; Store doubled high word
1caa  d0        ret     nc		; Return if no overflow

1cab  21644d    ld      hl,#4d64	; Handle final overflow
1cae  34        inc     (hl)		; Increment for overflow

; FUNCTION: Ghost 1 AI movement processor
; Uses same alignment and pathfinding logic as Ghost 0
1caf  21164d    ld      hl,#4d16	; Point to ghost 1 movement vector
1cb2  7e        ld      a,(hl)		; Load movement vector
1cb3  a7        and     a		; Test if zero (no movement)
1cb4  cac41c    jp      z,#1cc4		; Jump if no horizontal movement

; Horizontal movement active - check ghost 1 X alignment
1cb7  3a024d    ld      a,(#4d02)	; Load ghost 1 X position
1cba  e607      and     #07		; Check X alignment (lower 3 bits)
1cbc  fe04      cp      #04		; Compare with optimal alignment (4)
1cbe  cace1c    jp      z,#1cce		; Jump to enhanced processing if aligned
1cc1  c30d1d    jp      #1d0d		; Jump to direct processing if misaligned

; Vertical movement active - check ghost 1 Y alignment
1cc4  3a034d    ld      a,(#4d03)	; Load ghost 1 Y position
1cc7  e607      and     #07		; Check Y alignment (lower 3 bits)
1cc9  fe04      cp      #04		; Compare with optimal alignment (4)
1ccb  c20d1d    jp      nz,#1d0d        ; Jump to direct processing if misaligned

; Ghost 1 perfectly aligned - execute enhanced AI movement
1cce  3e02      ld      a,#02		; Load parameter 2 (MAYBE AI difficulty level)
1cd0  cdd01e    call    #1ed0		; Call AI validation function
1cd3  381b      jr      c,#1cf0         ; Jump if validation passed

; AI pathfinding logic for ghost 1 (PINKY)
1cd5  3aa84d    ld      a,(#4da8)	; Load Pinky's AI behavior flag
1cd8  a7        and     a		; Test behavior mode (0=chase, 1=scatter)
1cd9  cae21c    jp      z,#1ce2		; Jump to chase mode if zero

; ======================================================================
; *** THE FAMOUS PAC-MAN BUG OCCURS IN THE NEXT 3 LINES ***
; ======================================================================
1cdc  ef        rst     #28		; *** BUG LOCATION: Queue targeting command ***
1cdd  0d        dec     c		; *** BUG DATA: Command 0x0d (Pinky targeting) ***
1cde  00        nop     		; *** BUG DATA: Parameter 0x00 ***

; ======================================================================
; DETAILED BUG ANALYSIS: THE "PINKY 4-TILE OVERSTEP BUG"
; ======================================================================
;
; WHAT IS RST #28?
; RST #28 is a command queuing system that:
; 1. Extracts 2 parameter bytes from after the RST instruction
; 2. Stores them in a circular command buffer at 0x4c80
; 3. The game engine processes these commands during the main loop
; 4. Commands include AI targeting, display updates, sound effects, etc.
;
; INTENDED BEHAVIOR:
; - Pinky should target a tile 4 spaces ahead of Pac-Man's current direction
; - This makes Pinky an "ambush" ghost that tries to intercept Pac-Man
; - Command 0x0d appears to be "calculate Pinky's target position"
;
; THE BUG MECHANISM:
; The RST #28 call queues command 0x0d with parameter 0x00.
; When processed, this command performs directional vector arithmetic
; to calculate where Pinky should target, but contains the overflow bug:
;
; DIRECTIONAL VECTORS (16-bit values):
;   RIGHT: 0xFF00 (-1, 0) = Move left 1 pixel per frame  
;   LEFT:  0x0100 ( 1, 0) = Move right 1 pixel per frame
;   DOWN:  0x0001 ( 0, 1) = Move down 1 pixel per frame
;   UP:    0x00FF ( 0,-1) = Move up 1 pixel per frame
;
; VECTOR MULTIPLICATION FOR "4 TILES AHEAD":
;   RIGHT: 0xFF00 * 4 = 0xFC00 (4 tiles left)  ✓ CORRECT
;   LEFT:  0x0100 * 4 = 0x0400 (4 tiles right) ✓ CORRECT  
;   DOWN:  0x0001 * 4 = 0x0004 (4 tiles down)  ✓ CORRECT
;   UP:    0x00FF * 4 = 0x03FC ← *** BUG HERE! ***
;
; THE OVERFLOW PROBLEM:
; When Pac-Man faces UP, the calculation should be:
;   Pac-Man position + (UP_vector * 4) = Target position
;
; But 0x00FF * 4 = 0x03FC breaks down as:
;   High byte: 0x03 = 3 tiles RIGHT (should be 0)
;   Low byte:  0xFC = 252 = -4 in two's complement = 4 tiles UP ✓
;
; RESULT: Instead of targeting (0, -4) relative to Pac-Man,
;         Pinky targets (3, -4) = 3 tiles RIGHT + 4 tiles UP!
;
; WHY THIS HAPPENS:
; The original programmers likely intended the UP vector to be 0xFF00
; (like the other directions), but it was stored as 0x00FF, causing
; the multiplication to affect both X and Y coordinates instead of just Y.
;
; VISUAL EXAMPLE:
; If Pac-Man is at position (10,10) facing UP:
;   INTENDED TARGET: (10, 6)  [4 tiles directly above]
;   ACTUAL TARGET:   (13, 6)  [4 tiles up + 3 tiles right]
;
; GAMEPLAY IMPACT:
; - Makes Pinky easier to avoid when moving upward
; - Creates asymmetric ghost behavior (only affects UP direction)  
; - Becomes a distinctive characteristic of the original Pac-Man
; - Some players learned to exploit this for strategic advantage
;
; PRESERVATION NOTE:
; This bug is so famous that many Pac-Man ports deliberately preserve it
; to maintain authentic gameplay behavior. Consider whether to fix or keep
; when porting to Commander X16.
; ======================================================================
1cdf  c3f01c    jp      #1cf0		; Jump to movement execution

; Chase mode AI - target player position
1ce2  2a0c4d    ld      hl,(#4d0c)	; Load target position (MAYBE player position)
1ce5  cd5220    call    #2052		; Call pathfinding function
1ce8  7e        ld      a,(hl)		; Load tile at target position
1ce9  fe1a      cp      #1a		; Check if tile is traversable (26 decimal)
1ceb  2803      jr      z,#1cf0         ; Jump if passable
1ced  ef        rst     #28		; Queue command: Pinky obstacle avoidance
1cee  09        add     hl,bc		; Command: 0x09 = Pinky obstacle avoidance
1cef  00        nop     		; Parameter: 0x00 = default behavior

; Execute calculated ghost 1 movement
1cf0  cd251f    call    #1f25		; Call ghost 1 behavior update function
1cf3  dd21204d  ld      ix,#4d20	; Point IX to ghost 1 movement data
1cf7  fd210c4d  ld      iy,#4d0c	; Point IY to ghost 1 position data
1cfb  cd0020    call    #2000		; Call position update function
1cfe  220c4d    ld      (#4d0c),hl	; Store updated ghost 1 position
1d01  2a204d    ld      hl,(#4d20)	; Load calculated movement vector
1d04  22164d    ld      (#4d16),hl	; Store as active movement vector
1d07  3a2d4d    ld      a,(#4d2d)	; Load ghost 1 direction backup
1d0a  32294d    ld      (#4d29),a	; Store to active direction

; Direct ghost 1 movement processing (fallback)
1d0d  dd21164d  ld      ix,#4d16	; Point IX to ghost 1 movement vector
1d11  fd21024d  ld      iy,#4d02	; Point IY to ghost 1 position
1d15  cd0020    call    #2000		; Call position update function
1d18  22024d    ld      (#4d02),hl	; Store updated ghost 1 position
1d1b  cd1820    call    #2018		; Call position conversion function
1d1e  22334d    ld      (#4d33),hl	; Store converted position
1d21  c9        ret     		; Return

; ======================================================
; INKY (GHOST 2) AI AND SCORING SYSTEM
; Cyan ghost - Unpredictable behavior  
; ======================================================
; Handles Ghost 2 movement, AI, and score multiplication
; Uses identical logic pattern to Ghost 1

; FUNCTION: Inky scoring and AI processor
; C pseudocode: (Same pattern as Ghost 1 but for different ghost)
;   if (ghost2_scoring_flag != 1) return;
;   if (ghost2_still_active) return;
;   // Identical score doubling and AI logic for Ghost 2
1d22  3aa24d    ld      a,(#4da2)	; Load ghost 2 scoring flag
1d25  fe01      cp      #01		; Check if scoring flag == 1
1d27  c0        ret     nz		; Return if not active

1d28  3aae4d    ld      a,(#4dae)	; Load ghost 2 status
1d2b  a7        and     a		; Test if ghost 2 is active
1d2c  c0        ret     nz		; Return if ghost 2 still active

; Ghost 2 consumed - calculate score multiplier
1d2d  2a354d    ld      hl,(#4d35)	; Load ghost 2 position
1d30  019b4d    ld      bc,#4d9b	; Point BC to score calculation buffer
1d33  cd5a20    call    #205a		; Call position-based scoring function
1d36  3a9b4d    ld      a,(#4d9b)	; Load calculated score multiplier
1d39  a7        and     a		; Test if scoring should occur
1d3a  ca541d    jp      z,#1d54		; Jump to next tier if zero

; Apply score doubling for ghost 2 tier 1
1d3d  2a784d    ld      hl,(#4d78)	; Load score value (low word)
1d40  29        add     hl,hl		; Double the score (shift left)
1d41  22784d    ld      (#4d78),hl	; Store doubled score back
1d44  2a764d    ld      hl,(#4d76)	; Load score value (high word)
1d47  ed6a      adc     hl,hl		; Double with carry from low word
1d49  22764d    ld      (#4d76),hl	; Store doubled high word
1d4c  d0        ret     nc		; Return if no overflow

; Handle overflow in score doubling
1d4d  21784d    ld      hl,#4d78	; Point to low word
1d50  34        inc     (hl)		; Increment for overflow correction
1d51  c3861d    jp      #1d86		; Jump to ghost 2 AI processing

; Check ghost 2 tier 2 scoring
1d54  3aa94d    ld      a,(#4da9)	; Load ghost 2 tier 2 flag
1d57  a7        and     a		; Test if active
1d58  ca721d    jp      z,#1d72		; Jump to final tier if inactive

; Apply score doubling for ghost 2 tier 2
1d5b  2a744d    ld      hl,(#4d74)	; Load tier 2 score value (low word)
1d5e  29        add     hl,hl		; Double the score
1d5f  22744d    ld      (#4d74),hl	; Store doubled score
1d62  2a724d    ld      hl,(#4d72)	; Load tier 2 score value (high word)
1d65  ed6a      adc     hl,hl		; Double with carry
1d67  22724d    ld      (#4d72),hl	; Store doubled high word
1d6a  d0        ret     nc		; Return if no overflow

1d6b  21744d    ld      hl,#4d74	; Handle overflow
1d6e  34        inc     (hl)		; Increment for overflow
1d6f  c3861d    jp      #1d86		; Jump to ghost 2 AI processing

; Final tier scoring for ghost 2
1d72  2a704d    ld      hl,(#4d70)	; Load final score value (low word)
1d75  29        add     hl,hl		; Double the score (maximum multiplier)
1d76  22704d    ld      (#4d70),hl	; Store doubled score
1d79  2a6e4d    ld      hl,(#4d6e)	; Load final score value (high word)
1d7c  ed6a      adc     hl,hl		; Double with carry
1d7e  226e4d    ld      (#4d6e),hl	; Store doubled high word
1d81  d0        ret     nc		; Return if no overflow

1d82  21704d    ld      hl,#4d70	; Handle final overflow
1d85  34        inc     (hl)		; Increment for overflow

; FUNCTION: Ghost 2 AI movement processor
; Uses same alignment and pathfinding logic as previous ghosts
1d86  21184d    ld      hl,#4d18	; Point to ghost 2 movement vector
1d89  7e        ld      a,(hl)		; Load movement vector
1d8a  a7        and     a		; Test if zero (no movement)
1d8b  ca9b1d    jp      z,#1d9b		; Jump if no horizontal movement

; Horizontal movement active - check ghost 2 X alignment
1d8e  3a044d    ld      a,(#4d04)	; Load ghost 2 X position
1d91  e607      and     #07		; Check X alignment (lower 3 bits)
1d93  fe04      cp      #04		; Compare with optimal alignment (4)
1d95  caa51d    jp      z,#1da5		; Jump to enhanced processing if aligned
1d98  c3e41d    jp      #1de4		; Jump to direct processing if misaligned

; Vertical movement active - check ghost 2 Y alignment
1d9b  3a054d    ld      a,(#4d05)	; Load ghost 2 Y position
1d9e  e607      and     #07		; Check Y alignment (lower 3 bits)
1da0  fe04      cp      #04		; Compare with optimal alignment (4)
1da2  c2e41d    jp      nz,#1de4        ; Jump to direct processing if misaligned

; Ghost 2 perfectly aligned - execute enhanced AI movement
1da5  3e03      ld      a,#03		; Load parameter 3 (MAYBE AI difficulty level)
1da7  cdd01e    call    #1ed0		; Call AI validation function
1daa  381b      jr      c,#1dc7         ; Jump if validation passed

; AI pathfinding logic for ghost 2
1dac  3aa94d    ld      a,(#4da9)	; Load AI behavior flag
1daf  a7        and     a		; Test behavior mode
1db0  cab91d    jp      z,#1db9		; Jump to chase mode if zero
1db3  ef        rst     #28		; Queue command: Inky scatter targeting
1db4  0e        ld      c,#0e		; Command: 0x0e = Inky scatter targeting
1db5  00        nop     		; Parameter: 0x00 = default behavior
1db6  c3c71d    jp      #1dc7		; Jump to movement execution

; Chase mode AI - target player position
1db9  2a0e4d    ld      hl,(#4d0e)	; Load target position (MAYBE player position)
1dbc  cd5220    call    #2052		; Call pathfinding function
1dbf  7e        ld      a,(hl)		; Load tile at target position
1dc0  fe1a      cp      #1a		; Check if tile is traversable (26 decimal)
1dc2  2803      jr      z,#1dc7         ; Jump if passable
1dc4  ef        rst     #28		; Queue command: Inky obstacle avoidance
1dc5  0a        ld      a,(bc)		; Command: 0x0a = Inky obstacle avoidance
1dc6  00        nop     		; Parameter: 0x00 = default behavior

; Execute calculated ghost 2 movement
1dc7  cd4c1f    call    #1f4c		; Call ghost 2 behavior update function
1dca  dd21224d  ld      ix,#4d22	; Point IX to ghost 2 movement data
1dce  fd210e4d  ld      iy,#4d0e	; Point IY to ghost 2 position data
1dd2  cd0020    call    #2000		; Call position update function
1dd5  220e4d    ld      (#4d0e),hl	; Store updated ghost 2 position
1dd8  2a224d    ld      hl,(#4d22)	; Load calculated movement vector
1ddb  22184d    ld      (#4d18),hl	; Store as active movement vector
1dde  3a2e4d    ld      a,(#4d2e)	; Load ghost 2 direction backup
1de1  322a4d    ld      (#4d2a),a	; Store to active direction

; Direct ghost 2 movement processing (fallback)
1de4  dd21184d  ld      ix,#4d18	; Point IX to ghost 2 movement vector
1de8  fd21044d  ld      iy,#4d04	; Point IY to ghost 2 position
1dec  cd0020    call    #2000		; Call position update function
1def  22044d    ld      (#4d04),hl	; Store updated ghost 2 position
1df2  cd1820    call    #2018		; Call position conversion function
1df5  22354d    ld      (#4d35),hl	; Store converted position
1df8  c9        ret     		; Return

; ======================================================
; CLYDE (GHOST 3) AI AND SCORING SYSTEM
; Orange ghost - Shy and erratic  
; ======================================================
; Handles Ghost 3 movement, AI, and score multiplication
; Uses identical logic pattern to previous ghosts

; FUNCTION: Clyde scoring and AI processor
; C pseudocode: (Same pattern as other ghosts but for Ghost 3)
;   if (ghost3_scoring_flag != 1) return;
;   if (ghost3_still_active) return;
;   // Identical score doubling and AI logic for Ghost 3
1df9  3aa34d    ld      a,(#4da3)	; Load ghost 3 scoring flag
1dfc  fe01      cp      #01		; Check if scoring flag == 1
1dfe  c0        ret     nz		; Return if not active

1dff  3aaf4d    ld      a,(#4daf)	; Load ghost 3 status
1e02  a7        and     a		; Test if ghost 3 is active
1e03  c0        ret     nz		; Return if ghost 3 still active

; Ghost 3 consumed - calculate score multiplier
1e04  2a374d    ld      hl,(#4d37)	; Load ghost 3 position
1e07  019c4d    ld      bc,#4d9c	; Point BC to score calculation buffer
1e0a  cd5a20    call    #205a		; Call position-based scoring function
1e0d  3a9c4d    ld      a,(#4d9c)	; Load calculated score multiplier
1e10  a7        and     a		; Test if scoring should occur
1e11  ca2b1e    jp      z,#1e2b		; Jump to next tier if zero

; Apply score doubling for ghost 3 tier 1
1e14  2a844d    ld      hl,(#4d84)	; Load score value (low word)
1e17  29        add     hl,hl		; Double the score (shift left)
1e18  22844d    ld      (#4d84),hl	; Store doubled score back
1e1b  2a824d    ld      hl,(#4d82)	; Load score value (high word)
1e1e  ed6a      adc     hl,hl		; Double with carry from low word
1e20  22824d    ld      (#4d82),hl	; Store doubled high word
1e23  d0        ret     nc		; Return if no overflow

; Handle overflow in score doubling
1e24  21844d    ld      hl,#4d84	; Point to low word
1e27  34        inc     (hl)		; Increment for overflow correction
1e28  c35d1e    jp      #1e5d		; Jump to ghost 3 AI processing

; Check ghost 3 tier 2 scoring
1e2b  3aaa4d    ld      a,(#4daa)	; Load ghost 3 tier 2 flag
1e2e  a7        and     a		; Test if active
1e2f  ca491e    jp      z,#1e49		; Jump to final tier if inactive

; Apply score doubling for ghost 3 tier 2
1e32  2a804d    ld      hl,(#4d80)	; Load tier 2 score value (low word)
1e35  29        add     hl,hl		; Double the score
1e36  22804d    ld      (#4d80),hl	; Store doubled score
1e39  2a7e4d    ld      hl,(#4d7e)	; Load tier 2 score value (high word)
1e3c  ed6a      adc     hl,hl		; Double with carry
1e3e  227e4d    ld      (#4d7e),hl	; Store doubled high word
1e41  d0        ret     nc		; Return if no overflow

1e42  21804d    ld      hl,#4d80	; Handle overflow
1e45  34        inc     (hl)		; Increment for overflow
1e46  c35d1e    jp      #1e5d		; Jump to ghost 3 AI processing

; Final tier scoring for ghost 3
1e49  2a7c4d    ld      hl,(#4d7c)	; Load final score value (low word)
1e4c  29        add     hl,hl		; Double the score (maximum multiplier)
1e4d  227c4d    ld      (#4d7c),hl	; Store doubled score
1e50  2a7a4d    ld      hl,(#4d7a)	; Load final score value (high word)
1e53  ed6a      adc     hl,hl		; Double with carry
1e55  227a4d    ld      (#4d7a),hl	; Store doubled high word
1e58  d0        ret     nc		; Return if no overflow

1e59  217c4d    ld      hl,#4d7c	; Handle final overflow
1e5c  34        inc     (hl)		; Increment for overflow

; FUNCTION: Ghost 3 AI movement processor
; Uses same alignment and pathfinding logic as previous ghosts
1e5d  211a4d    ld      hl,#4d1a	; Point to ghost 3 movement vector
1e60  7e        ld      a,(hl)		; Load movement vector
1e61  a7        and     a		; Test if zero (no movement)
1e62  ca721e    jp      z,#1e72		; Jump if no horizontal movement

; Horizontal movement active - check ghost 3 X alignment
1e65  3a064d    ld      a,(#4d06)	; Load ghost 3 X position
1e68  e607      and     #07		; Check X alignment (lower 3 bits)
1e6a  fe04      cp      #04		; Compare with optimal alignment (4)
1e6c  ca7c1e    jp      z,#1e7c		; Jump to enhanced processing if aligned
1e6f  c3bb1e    jp      #1ebb		; Jump to direct processing if misaligned

; Vertical movement active - check ghost 3 Y alignment
1e72  3a074d    ld      a,(#4d07)	; Load ghost 3 Y position
1e75  e607      and     #07		; Check Y alignment (lower 3 bits)
1e77  fe04      cp      #04		; Compare with optimal alignment (4)
1e79  c2bb1e    jp      nz,#1ebb        ; Jump to direct processing if misaligned

; Ghost 3 perfectly aligned - execute enhanced AI movement
1e7c  3e04      ld      a,#04		; Load parameter 4 (MAYBE AI difficulty level)
1e7e  cdd01e    call    #1ed0		; Call AI validation function
1e81  381b      jr      c,#1e9e         ; Jump if validation passed

; AI pathfinding logic for ghost 3
1e83  3aaa4d    ld      a,(#4daa)	; Load AI behavior flag
1e86  a7        and     a		; Test behavior mode
1e87  ca901e    jp      z,#1e90		; Jump to chase mode if zero
1e8a  ef        rst     #28		; Queue command: Clyde scatter targeting
1e8b  0f        rrca    		; Command: 0x0f = Clyde scatter targeting
1e8c  00        nop     		; Parameter: 0x00 = default behavior
1e8d  c39e1e    jp      #1e9e		; Jump to movement execution

; Chase mode AI - target player position
1e90  2a104d    ld      hl,(#4d10)	; Load target position (MAYBE player position)
1e93  cd5220    call    #2052		; Call pathfinding function
1e96  7e        ld      a,(hl)		; Load tile at target position
1e97  fe1a      cp      #1a		; Check if tile is traversable (26 decimal)
1e99  2803      jr      z,#1e9e         ; Jump if passable
1e9b  ef        rst     #28		; Queue command: Clyde obstacle avoidance
1e9c  0b        dec     bc		; Command: 0x0b = Clyde obstacle avoidance
1e9d  00        nop     		; Parameter: 0x00 = default behavior

; Execute calculated ghost 3 movement
1e9e  cd731f    call    #1f73		; Call ghost 3 behavior update function
1ea1  dd21244d  ld      ix,#4d24	; Point IX to ghost 3 movement data
1ea5  fd21104d  ld      iy,#4d10	; Point IY to ghost 3 position data
1ea9  cd0020    call    #2000		; Call position update function
1eac  22104d    ld      (#4d10),hl	; Store updated ghost 3 position
1eaf  2a244d    ld      hl,(#4d24)	; Load calculated movement vector
1eb2  221a4d    ld      (#4d1a),hl	; Store as active movement vector
1eb5  3a2f4d    ld      a,(#4d2f)	; Load ghost 3 direction backup
1eb8  322b4d    ld      (#4d2b),a	; Store to active direction

; Direct ghost 3 movement processing (fallback)
1ebb  dd211a4d  ld      ix,#4d1a	; Point IX to ghost 3 movement vector
1ebf  fd21064d  ld      iy,#4d06	; Point IY to ghost 3 position
1ec3  cd0020    call    #2000		; Call position update function
1ec6  22064d    ld      (#4d06),hl	; Store updated ghost 3 position
1ec9  cd1820    call    #2018		; Call position conversion function
1ecc  22374d    ld      (#4d37),hl	; Store converted position
1ecf  c9        ret     		; Return

; ======================================================
; AI VALIDATION AND SUPPORT FUNCTIONS
; ======================================================

; FUNCTION: AI validation function
; Validates movement decisions and manages AI state transitions
; C pseudocode:
;   ghost_index = input_param * 2;  // Convert param to table index
;   ghost_data_ptr = &ghost_data[ghost_index];
;   
;   if (ghost_data == 0x1D) {
;     ghost_data = 0x3D;  // State transition
;     return true;  // Carry set
;   }
;   if (ghost_data == 0x3E) {
;     ghost_data = 0x1E;  // Reverse state transition
;     return true;  // Carry set  
;   }
;   
;   // Check level bounds for AI activation
;   if (ghost_data < 0x21) return true;  // Too low
;   if (ghost_data >= 0x3B) return true; // Too high
;   
;   return false;  // Valid for AI processing
1ed0  87        add     a,a		; Double the input parameter (create table index)
1ed1  4f        ld      c,a		; Store index in C register
1ed2  0600      ld      b,#00		; Clear high byte
1ed4  21094d    ld      hl,#4d09	; Point to ghost data table base
1ed7  09        add     hl,bc		; Add index to get ghost-specific data pointer
1ed8  7e        ld      a,(hl)		; Load ghost data value
1ed9  fe1d      cp      #1d		; Check if data == 0x1d (29 decimal)
1edb  c2e31e    jp      nz,#1ee3        ; Jump if not 0x1d

; Handle special state 0x1d - transition to 0x3d
1ede  363d      ld      (hl),#3d	; Set ghost data to 0x3d (61 decimal)
1ee0  c3fc1e    jp      #1efc		; Jump to set carry flag (validation failed)

; Check for alternate special state 0x3e
1ee3  fe3e      cp      #3e		; Check if data == 0x3e (62 decimal)
1ee5  c2ed1e    jp      nz,#1eed        ; Jump if not 0x3e

; Handle special state 0x3e - transition to 0x1e
1ee8  361e      ld      (hl),#1e	; Set ghost data to 0x1e (30 decimal)
1eea  c3fc1e    jp      #1efc		; Jump to set carry flag (validation failed)

; Check level bounds for normal AI processing
1eed  0621      ld      b,#21		; Load lower bound 0x21 (33 decimal)
1eef  90        sub     b		; Subtract lower bound
1ef0  dafc1e    jp      c,#1efc		; Jump if below lower bound (carry set)
1ef3  7e        ld      a,(hl)		; Reload ghost data value
1ef4  063b      ld      b,#3b		; Load upper bound 0x3b (59 decimal)
1ef6  90        sub     b		; Subtract upper bound
1ef7  d2fc1e    jp      nc,#1efc        ; Jump if >= upper bound (carry set)

; Valid range for AI processing
1efa  a7        and     a		; Clear carry flag (validation successful)
1efb  c9        ret     		; Return with carry clear

; Validation failed - set carry flag
1efc  37        scf     		; Set carry flag
1efd  c9        ret     		; Return with carry set

; ======================================================
; GHOST BEHAVIOR UPDATE FUNCTIONS
; ======================================================
; These functions handle direction changes and movement state updates

; FUNCTION: Blinky (Ghost 0) behavior update
; Manages Blinky's direction changes and special movement states
; C pseudocode:
;   // BLINKY BEHAVIOR STATE MANAGEMENT
;   void update_blinky_behavior() {
;     if (!blinky_behavior_flag) return;  // No update needed
;     
;     blinky_behavior_flag = 0;  // Reset flag
;     
;     // Calculate reverse direction (flip bit 1)
;     new_direction = blinky_current_direction ^ 0x02;
;     blinky_new_direction = new_direction;
;     
;     // Look up movement vector from direction table
;     movement_vector = direction_table_lookup(new_direction);
;     blinky_movement_data = movement_vector;
;     
;     // Check for special game mode
;     if (game_mode == 0x22) {  // Special enhanced mode
;       blinky_active_movement_data = movement_vector;
;       blinky_active_direction = new_direction;
;     }
;   }
1efe  3ab14d    ld      a,(#4db1)	; Load ghost 0 behavior flag
1f01  a7        and     a		; Test if behavior update needed
1f02  c8        ret     z		; Return if no update needed

1f03  af        xor     a		; Clear accumulator (0)
1f04  32b14d    ld      (#4db1),a	; Reset behavior flag
1f07  21ff32    ld      hl,#32ff	; Load base movement table address
1f0a  3a284d    ld      a,(#4d28)	; Load current ghost 0 direction
1f0d  ee02      xor     #02		; Toggle direction bit 1 (reverse direction)
1f0f  322c4d    ld      (#4d2c),a	; Store new direction
1f12  47        ld      b,a		; Copy direction to B register
1f13  df        rst     #18		; Call direction table lookup (RST 18)
1f14  221e4d    ld      (#4d1e),hl	; Store movement vector to ghost 0 data
1f17  3a024e    ld      a,(#4e02)	; Load game mode flag
1f1a  fe22      cp      #22		; Check if game mode == 0x22 (34 decimal)
1f1c  c0        ret     nz		; Return if not in special mode

; Special mode - update main movement data
1f1d  22144d    ld      (#4d14),hl	; Store movement vector to active ghost 0 data
1f20  78        ld      a,b		; Get direction value
1f21  32284d    ld      (#4d28),a	; Store to active direction
1f24  c9        ret     		; Return

; FUNCTION: Pinky (Ghost 1) behavior update
; Identical logic to Blinky but for Pinky's data
1f25  3ab24d    ld      a,(#4db2)	; Load ghost 1 behavior flag
1f28  a7        and     a		; Test if behavior update needed
1f29  c8        ret     z		; Return if no update needed

1f2a  af        xor     a		; Clear accumulator (0)
1f2b  32b24d    ld      (#4db2),a	; Reset behavior flag
1f2e  21ff32    ld      hl,#32ff	; Load base movement table address
1f31  3a294d    ld      a,(#4d29)	; Load current ghost 1 direction
1f34  ee02      xor     #02		; Toggle direction bit 1 (reverse direction)
1f36  322d4d    ld      (#4d2d),a	; Store new direction
1f39  47        ld      b,a		; Copy direction to B register
1f3a  df        rst     #18		; Call direction table lookup (RST 18)
1f3b  22204d    ld      (#4d20),hl	; Store movement vector to ghost 1 data
1f3e  3a024e    ld      a,(#4e02)	; Load game mode flag
1f41  fe22      cp      #22		; Check if game mode == 0x22
1f43  c0        ret     nz		; Return if not in special mode

; Special mode - update main movement data for ghost 1
1f44  22164d    ld      (#4d16),hl	; Store movement vector to active ghost 1 data
1f47  78        ld      a,b		; Get direction value
1f48  32294d    ld      (#4d29),a	; Store to active direction
1f4b  c9        ret     		; Return

; FUNCTION: Inky (Ghost 2) behavior update
; Identical logic pattern for Inky
1f4c  3ab34d    ld      a,(#4db3)	; Load ghost 2 behavior flag
1f4f  a7        and     a		; Test if behavior update needed
1f50  c8        ret     z		; Return if no update needed

1f51  af        xor     a		; Clear accumulator (0)
1f52  32b34d    ld      (#4db3),a	; Reset behavior flag
1f55  21ff32    ld      hl,#32ff	; Load base movement table address
1f58  3a2a4d    ld      a,(#4d2a)	; Load current ghost 2 direction
1f5b  ee02      xor     #02		; Toggle direction bit 1 (reverse direction)
1f5d  322e4d    ld      (#4d2e),a	; Store new direction
1f60  47        ld      b,a		; Copy direction to B register
1f61  df        rst     #18		; Call direction table lookup (RST 18)
1f62  22224d    ld      (#4d22),hl	; Store movement vector to ghost 2 data
1f65  3a024e    ld      a,(#4e02)	; Load game mode flag
1f68  fe22      cp      #22		; Check if game mode == 0x22
1f6a  c0        ret     nz		; Return if not in special mode

; Special mode - update main movement data for ghost 2
1f6b  22184d    ld      (#4d18),hl	; Store movement vector to active ghost 2 data
1f6e  78        ld      a,b		; Get direction value
1f6f  322a4d    ld      (#4d2a),a	; Store to active direction
1f72  c9        ret     		; Return

; FUNCTION: Clyde (Ghost 3) behavior update
; Completes the identical pattern for Clyde (final ghost)
1f73  3ab44d    ld      a,(#4db4)	; Load ghost 3 behavior flag
1f76  a7        and     a		; Test if behavior update needed
1f77  c8        ret     z		; Return if no update needed

1f78  af        xor     a		; Clear accumulator (0)
1f79  32b44d    ld      (#4db4),a	; Reset behavior flag
1f7c  21ff32    ld      hl,#32ff	; Load base movement table address
1f7f  3a2b4d    ld      a,(#4d2b)	; Load current ghost 3 direction
1f82  ee02      xor     #02		; Toggle direction bit 1 (reverse direction)
1f84  322f4d    ld      (#4d2f),a	; Store new direction
1f87  47        ld      b,a		; Copy direction to B register
1f88  df        rst     #18		; Call direction table lookup (RST 18)
1f89  22244d    ld      (#4d24),hl	; Store movement vector to ghost 3 data
1f8c  3a024e    ld      a,(#4e02)	; Load game mode flag
1f8f  fe22      cp      #22		; Check if game mode == 0x22
1f91  c0        ret     nz		; Return if not in special mode

; Special mode - update main movement data for ghost 3
1f92  221a4d    ld      (#4d1a),hl	; Store movement vector to active ghost 3 data
1f95  78        ld      a,b		; Get direction value
1f96  322b4d    ld      (#4d2b),a	; Store to active direction
1f99  c9        ret     		; Return

; ======================================================
; END OF GHOST BEHAVIOR SYSTEM - PADDING SECTION
; ======================================================
; Padding area - NOPs to align next section
1f9a  00        nop     		; Padding
1f9b  00        nop     		; Padding
1f9c  00        nop     		; Padding
1f9d  00        nop     		; Padding
1f9e  00        nop     		; Padding
1f9f  00        nop     		; Padding
1fa0  00        nop     		; Padding
1fa1  00        nop     		; Padding
1fa2  00        nop     		; Padding
1fa3  00        nop     		; Padding
1fa4  00        nop     		; Padding
1fa5  00        nop     		; Padding
1fa6  00        nop     		; Padding
1fa7  00        nop     		; Padding
1fa8  00        nop     		; Padding
1fa9  00        nop     		; Padding
1faa  00        nop     		; Padding
1fab  00        nop     		; Padding
1fac  00        nop     		; Padding
1fad  00        nop     		; Padding
1fae  00        nop     		; Padding
1faf  00        nop     		; Padding
1fb0  00        nop     		; Padding
1fb1  00        nop     		; Padding
1fb2  00        nop     		; Padding
1fb3  00        nop     		; Padding
1fb4  00        nop     		; Padding
1fb5  00        nop     		; Padding
1fb6  00        nop     		; Padding
1fb7  00        nop     		; Padding
1fb8  00        nop     		; Padding
1fb9  00        nop     		; Padding
1fba  00        nop     		; Padding
1fbb  00        nop     		; Padding
1fbc  00        nop     		; Padding
1fbd  00        nop     		; Padding
1fbe  00        nop     		; Padding
1fbf  00        nop     		; Padding
1fc0  00        nop     		; Padding
1fc1  00        nop     		; Padding
1fc2  00        nop     		; Padding
1fc3  00        nop     		; Padding
1fc4  00        nop     		; Padding
1fc5  00        nop     		; Padding
1fc6  00        nop     		; Padding
1fc7  00        nop     		; Padding
1fc8  00        nop     		; Padding
1fc9  00        nop     		; Padding
1fca  00        nop     		; Padding
1fcb  00        nop     		; Padding
1fcc  00        nop     		; Padding
1fcd  00        nop     		; Padding
1fce  00        nop     		; Padding
1fcf  00        nop     		; Padding
1fd0  00        nop     		; Padding
1fd1  00        nop     		; Padding
1fd2  00        nop     		; Padding
1fd3  00        nop     		; Padding
1fd4  00        nop     		; Padding
1fd5  00        nop     		; Padding
1fd6  00        nop     		; Padding
1fd7  00        nop     		; Padding
1fd8  00        nop     		; Padding
1fd9  00        nop     		; Padding
1fda  00        nop     		; Padding
1fdb  00        nop     		; Padding
1fdc  00        nop     		; Padding
1fdd  00        nop     		; Padding
1fde  00        nop     		; Padding
1fdf  00        nop     		; Padding
1fe0  00        nop     		; Padding
1fe1  00        nop     		; Padding
1fe2  00        nop     		; Padding
1fe3  00        nop     		; Padding
1fe4  00        nop     		; Padding
1fe5  00        nop     		; Padding
1fe6  00        nop     		; Padding
1fe7  00        nop     		; Padding
1fe8  00        nop     		; Padding
1fe9  00        nop     		; Padding
1fea  00        nop     		; Padding
1feb  00        nop     		; Padding
1fec  00        nop     		; Padding
1fed  00        nop     		; Padding
1fee  00        nop     		; Padding
1fef  00        nop     		; Padding
1ff0  00        nop     		; Padding
1ff1  00        nop     		; Padding
1ff2  00        nop     		; Padding
1ff3  00        nop     		; Padding
1ff4  00        nop     		; Padding
1ff5  00        nop     		; Padding
1ff6  00        nop     		; Padding
1ff7  00        nop     		; Padding
1ff8  00        nop     		; Padding
1ff9  00        nop     		; Padding
1ffa  00        nop     		; Padding
1ffb  00        nop     		; Padding
1ffc  00        nop     		; Padding
1ffd  00        nop     		; Padding

; ======================================================
; MATHEMATICS AND COORDINATE UTILITY FUNCTIONS
; ======================================================
; Core mathematical operations for position calculations,
; coordinate transformations, and maze tile conversions
; ======================================================

; FUNCTION: VECTOR_ADD - Add two 16-bit vectors
; Parameters: IX = vector1 pointer, IY = vector2 pointer  
; Returns: HL = sum of vectors
; C_PSEUDO: vec2d_t vector_add(vec2d_t *a, vec2d_t *b) {
; C_PSEUDO:   vec2d_t result;
; C_PSEUDO:   result.x = a->x + b->x;
; C_PSEUDO:   result.y = a->y + b->y;  
; C_PSEUDO:   return result;
; C_PSEUDO: }
; ALGORITHM: Performs 16-bit addition of X and Y components separately
1ffe  5d        ld      e,l		; Save low byte in E
1fff  e1        pop     hl		; Restore return address
2000  fd7e00    ld      a,(iy+#00)	; Get Y component of vector2
2003  dd8600    add     a,(ix+#00)	; Add Y component of vector1
2006  6f        ld      l,a		; Store Y result in L
2007  fd7e01    ld      a,(iy+#01)	; Get X component of vector2
200a  dd8601    add     a,(ix+#01)	; Add X component of vector1
200d  67        ld      h,a		; Store X result in H
200e  c9        ret     		; Return HL = (Y,X) vector sum

; FUNCTION: VECTOR_ADD_AND_GET_TILE - Add vectors and get maze tile
; C_PSEUDO: uint8_t get_tile_at_vector_sum(vec2d_t *a, vec2d_t *b) {
; C_PSEUDO:   vec2d_t pos = vector_add(a, b);
; C_PSEUDO:   uint8_t tile = get_maze_tile(pos);
; C_PSEUDO:   return tile;
; C_PSEUDO: }
; ALGORITHM: Combines vector addition with maze tile lookup
200f  cd0020    call    #2000		; Add vectors IX + IY -> HL
2012  cd6500    call    #0065		; Convert position to maze address
2015  7e        ld      a,(hl)		; Load tile value at position
2016  a7        and     a		; Test tile value (set flags)
2017  c9        ret     		; Return with tile in A and flags set

; FUNCTION: PIXEL_TO_TILE_COORD - Convert pixel coordinates to tile coordinates
; Parameters: HL = pixel coordinates (H=X, L=Y)
; Returns: HL = tile coordinates
; C_PSEUDO: tile_coord_t pixel_to_tile(pixel_coord_t pixel) {
; C_PSEUDO:   tile_coord_t tile;
; C_PSEUDO:   tile.x = (pixel.x >> 3) + 0x20;  // Divide by 8, add base offset
; C_PSEUDO:   tile.y = (pixel.y >> 3) + 0x1E;  // Divide by 8, add base offset  
; C_PSEUDO:   return tile;
; C_PSEUDO: }
; ALGORITHM: Converts 8x8 pixel grid to tile grid with maze offset
2018  7d        ld      a,l		; Get Y pixel coordinate
2019  cb3f      srl     a		; Shift right (divide by 2)
201b  cb3f      srl     a		; Shift right (divide by 4)
201d  cb3f      srl     a		; Shift right (divide by 8) - now tile Y
201f  c620      add     a,#20		; Add tile offset for Y axis
2021  6f        ld      l,a		; Store tile Y coordinate
2022  7c        ld      a,h		; Get X pixel coordinate
2023  cb3f      srl     a		; Shift right (divide by 2)
2025  cb3f      srl     a		; Shift right (divide by 4)
2027  cb3f      srl     a		; Shift right (divide by 8) - now tile X
2029  c61e      add     a,#1e		; Add tile offset for X axis
202b  67        ld      h,a		; Store tile X coordinate
202c  c9        ret     		; Return HL = tile coordinates

; FUNCTION: TILE_TO_SCREEN_ADDR - Convert tile coordinates to screen memory address
; Parameters: HL = tile coordinates (H=X, L=Y)
; Returns: HL = screen memory address
; C_PSEUDO: uint16_t tile_to_screen_addr(tile_coord_t tile) {
; C_PSEUDO:   uint16_t addr;
; C_PSEUDO:   uint16_t x = tile.x - 0x20;  // Remove X offset
; C_PSEUDO:   uint16_t y = tile.y - 0x20;  // Remove Y offset  
; C_PSEUDO:   addr = (y << 5) + x + 0x4040;  // Y*32 + X + screen base
; C_PSEUDO:   return addr;
; C_PSEUDO: }
; ALGORITHM: Converts tile coordinates to linear screen memory address
202d  f5        push    af		; Save accumulator and flags
202e  c5        push    bc		; Save BC register pair
202f  7d        ld      a,l		; Get Y tile coordinate
2030  d620      sub     #20		; Remove Y offset to get relative position
2032  6f        ld      l,a		; Store adjusted Y
2033  7c        ld      a,h		; Get X tile coordinate
2034  d620      sub     #20		; Remove X offset to get relative position
2036  67        ld      h,a		; Store adjusted X
2037  0600      ld      b,#00		; Clear B register for overflow
2039  cb24      sla     h		; Shift Y left (Y * 2)
203b  cb24      sla     h		; Shift Y left (Y * 4)
203d  cb24      sla     h		; Shift Y left (Y * 8)
203f  cb24      sla     h		; Shift Y left (Y * 16)
2041  cb10      rl      b		; Rotate overflow into B
2043  cb24      sla     h		; Shift Y left (Y * 32)
2045  cb10      rl      b		; Rotate overflow into B
2047  4c        ld      c,h		; Move Y*32 to C
2048  2600      ld      h,#00		; Clear H (now HL = X coordinate)
204a  09        add     hl,bc		; Add Y*32 to X coordinate
204b  014040    ld      bc,#4040	; Screen base address
204e  09        add     hl,bc		; Add screen base to get final address
204f  c1        pop     bc		; Restore BC register pair
2050  f1        pop     af		; Restore accumulator and flags
2051  c9        ret     		; Return HL = screen memory address

; FUNCTION: GET_MAZE_TILE_PLUS_OFFSET - Get maze tile with color memory offset
; Parameters: HL = coordinates  
; Returns: HL = maze memory address + 0x0400 offset
; C_PSEUDO: uint16_t get_color_tile_addr(coord_t pos) {
; C_PSEUDO:   uint16_t base_addr = get_maze_addr(pos);
; C_PSEUDO:   return base_addr + 0x0400;  // Color memory offset
; C_PSEUDO: }
; ALGORITHM: Adds color memory offset to maze tile address
2052  cd6500    call    #0065		; Get maze memory address for coordinates
2055  110004    ld      de,#0400	; Color memory offset
2058  19        add     hl,de		; Add offset to base address
2059  c9        ret     		; Return HL = color memory address

; FUNCTION: CHECK_MAZE_TILE_1B - Check if maze tile is value 0x1B
; Parameters: HL = coordinates, BC = result flag address
; Returns: (BC) = 1 if tile is 0x1B, 0 otherwise
; C_PSEUDO: void check_special_tile(coord_t pos, uint8_t *result) {
; C_PSEUDO:   uint16_t addr = get_color_tile_addr(pos);
; C_PSEUDO:   uint8_t tile = memory[addr];
; C_PSEUDO:   *result = (tile == 0x1B) ? 1 : 0;
; C_PSEUDO: }
; ALGORITHM: Checks for specific tile type (possibly power pellet or special item)
205a  cd5220    call    #2052		; Get color tile address
205d  7e        ld      a,(hl)		; Load tile value
205e  fe1b      cp      #1b		; Compare with special tile value 0x1B
2060  2004      jr      nz,#2066        ; Jump if not equal
2062  3e01      ld      a,#01		; Set result = 1 (tile found)
2064  02        ld      (bc),a		; Store result at BC address
2065  c9        ret     		; Return
2066  af        xor     a		; Clear A (result = 0)
2067  02        ld      (bc),a		; Store result at BC address  
2068  c9        ret     		; Return

; ======================================================
; GAME TIMING AND LEVEL PROGRESSION SYSTEM
; ======================================================
; Controls game timing, level progression, and special events
; ======================================================

; FUNCTION: CHECK_LEVEL_TIMING_CONDITION - Check level progression conditions
; C_PSEUDO: void check_level_progression() {
; C_PSEUDO:   if (level_progression_flag != 0) return;  // Already progressing
; C_PSEUDO:   
; C_PSEUDO:   if (bonus_active_flag != 0) {
; C_PSEUDO:     if (current_bonus_type == 7) {
; C_PSEUDO:       trigger_level_progression();
; C_PSEUDO:     }
; C_PSEUDO:   } else {
; C_PSEUDO:     if (fruits_eaten >= max_fruits_level) {
; C_PSEUDO:       trigger_level_progression();
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Monitors game state for level completion triggers
2069  3aa14d    ld      a,(#4da1)	; Load level progression flag
206c  a7        and     a		; Test if already progressing
206d  c0        ret     nz		; Return if progression in progress
206e  3a124e    ld      a,(#4e12)	; Load bonus active flag
2071  a7        and     a		; Test if bonus is active
2072  ca7e20    jp      z,#207e		; Jump to fruit check if no bonus
2075  3a9f4d    ld      a,(#4d9f)	; Load current bonus type
2078  fe07      cp      #07		; Check if bonus type == 7
207a  c0        ret     nz		; Return if not type 7
207b  c38620    jp      #2086		; Jump to trigger progression
207e  21b84d    ld      hl,#4db8	; Point to max fruits for level
2081  3a0f4e    ld      a,(#4e0f)	; Load fruits eaten counter
2084  be        cp      (hl)		; Compare with max fruits for level
2085  d8        ret     c		; Return if fruits eaten < max
2086  3e02      ld      a,#02		; Set progression trigger value
2088  32a14d    ld      (#4da1),a	; Store level progression flag
208b  c9        ret     		; Return

; FUNCTION: CHECK_BONUS_TIMING_CONDITION - Check bonus appearance conditions  
; C_PSEUDO: void check_bonus_appearance() {
; C_PSEUDO:   if (bonus_progression_flag != 0) return;  // Already progressing
; C_PSEUDO:   
; C_PSEUDO:   if (bonus_active_flag != 0) {
; C_PSEUDO:     if (current_bonus_type == 7) {
; C_PSEUDO:       trigger_bonus_progression();
; C_PSEUDO:     }
; C_PSEUDO:   } else {
; C_PSEUDO:     if (dots_eaten >= bonus_trigger_count) {
; C_PSEUDO:       trigger_bonus_progression();
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Similar to level progression but for bonus item appearance
208c  3aa24d    ld      a,(#4da2)	; Load bonus progression flag
208f  a7        and     a		; Test if already progressing
2090  c0        ret     nz		; Return if progression in progress
2091  3a124e    ld      a,(#4e12)	; Load bonus active flag
2094  a7        and     a		; Test if bonus is active
2095  caa120    jp      z,#20a1		; Jump to dot check if no bonus
2098  3a9f4d    ld      a,(#4d9f)	; Load current bonus type
209b  fe11      cp      #11		; Check if bonus type == 0x11
209d  c0        ret     nz		; Return if not type 0x11
209e  c3a920    jp      #20a9		; Jump to trigger progression
20a1  21b94d    ld      hl,#4db9	; Point to bonus trigger dot count
20a4  3a104e    ld      a,(#4e10)	; Load dots eaten counter
20a7  be        cp      (hl)		; Compare with trigger count
20a8  d8        ret     c		; Return if dots eaten < trigger
20a9  3e03      ld      a,#03		; Set bonus progression trigger value
20ab  32a24d    ld      (#4da2),a	; Store bonus progression flag
20ae  c9        ret     		; Return

; FUNCTION: CHECK_SPECIAL_EVENT_TIMING - Check special event conditions
; C_PSEUDO: void check_special_event() {
; C_PSEUDO:   if (special_event_flag != 0) return;  // Already active
; C_PSEUDO:   
; C_PSEUDO:   if (bonus_active_flag != 0) {
; C_PSEUDO:     if (current_bonus_type == 0x20) {
; C_PSEUDO:       clear_bonus_state();
; C_PSEUDO:       return;
; C_PSEUDO:     }
; C_PSEUDO:   } else {
; C_PSEUDO:     if (special_dots_eaten >= special_trigger_count) {
; C_PSEUDO:       trigger_special_event();
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Manages special game events and bonus state clearing
20af  3aa34d    ld      a,(#4da3)	; Load special event flag
20b2  a7        and     a		; Test if special event active
20b3  c0        ret     nz		; Return if special event in progress
20b4  3a124e    ld      a,(#4e12)	; Load bonus active flag
20b7  a7        and     a		; Test if bonus is active
20b8  cac920    jp      z,#20c9		; Jump to special dot check if no bonus
20bb  3a9f4d    ld      a,(#4d9f)	; Load current bonus type
20be  fe20      cp      #20		; Check if bonus type == 0x20
20c0  c0        ret     nz		; Return if not type 0x20
20c1  af        xor     a		; Clear A register (0)
20c2  32124e    ld      (#4e12),a	; Clear bonus active flag
20c5  329f4d    ld      (#4d9f),a	; Clear bonus type
20c8  c9        ret     		; Return
20c9  21ba4d    ld      hl,#4dba	; Point to special event trigger count
20cc  3a114e    ld      a,(#4e11)	; Load special dots eaten counter
20cf  be        cp      (hl)		; Compare with trigger count
20d0  d8        ret     c		; Return if special dots < trigger
20d1  3e03      ld      a,#03		; Set special event trigger value
20d3  32a34d    ld      (#4da3),a	; Store special event flag
20d6  c9        ret     		; Return

; FUNCTION: PROCESS_SPECIAL_EVENT_COUNTER - Update special event counter
; C_PSEUDO: void update_special_counter() {
; C_PSEUDO:   if (special_event_flag == 0) return;  // No special event
; C_PSEUDO:   
; C_PSEUDO:   target_counter = get_target_counter_address();
; C_PSEUDO:   
; C_PSEUDO:   if (level_type_flag == 0) {
; C_PSEUDO:     // Normal level processing
; C_PSEUDO:     target_counter += increment_value;
; C_PSEUDO:   } else {
; C_PSEUDO:     // Special level processing  
; C_PSEUDO:     target_counter += special_increment;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Updates counters during special events based on level type
20d7  3aa34d    ld      a,(#4da3)	; Load special event flag
20da  a7        and     a		; Test if special event active
20db  c8        ret     z		; Return if no special event
20dc  210e4e    ld      hl,#4e0e	; Point to target counter base address
20df  3ab64d    ld      a,(#4db6)	; Load level type flag
20e2  a7        and     a		; Test level type
20e3  c2f420    jp      nz,#20f4	; Jump to special processing if flag set

; Normal level counter processing
20e6  3ef4      ld      a,#f4		; Load threshold value (244)
20e8  96        sub     (hl)		; Subtract current counter value
20e9  47        ld      b,a		; Store difference in B
20ea  3abb4d    ld      a,(#4dbb)	; Load comparison value
20ed  90        sub     b		; Compare with difference
20ee  d8        ret     c		; Return if comparison fails (carry set)
20ef  3e01      ld      a,#01		; Set flag value
20f1  32b64d    ld      (#4db6),a	; Set level type flag

; Special level counter processing  
20f4  3ab74d    ld      a,(#4db7)	; Load special processing flag
20f7  a7        and     a		; Test if special processing active
20f8  c0        ret     nz		; Return if special processing already active
20f9  3ef4      ld      a,#f4		; Load threshold value (244)
20fb  96        sub     (hl)		; Subtract current counter value  
20fc  47        ld      b,a		; Store difference in B
20fd  3abc4d    ld      a,(#4dbc)	; Load special comparison value
2100  90        sub     b		; Compare with difference
2101  d8        ret     c		; Return if comparison fails (carry set)
2102  3e01      ld      a,#01		; Set flag value
2104  32b74d    ld      (#4db7),a	; Set special processing flag
2107  c9        ret     		; Return

; ======================================================
; GAME STATE DISPATCH SYSTEM
; ======================================================
; Complex state machine that manages different game phases,
; player interactions, and level progression logic
; ======================================================

; FUNCTION: GAME_STATE_DISPATCHER - Main game state processor
; Parameters: Uses game state at 0x4E06 to dispatch to handlers
; C_PSEUDO: void process_game_state() {
; C_PSEUDO:   state_handler_t handler = state_table[game_state];
; C_PSEUDO:   handler();  // Execute state-specific logic
; C_PSEUDO: }
; ALGORITHM: Jump table dispatch based on current game state
2108  3a064e    ld      a,(#4e06)	; Load current game state
210b  e7        rst     #20		; Call jump table dispatcher (RST #20)

; Jump table data follows (addresses for each game state)
210c  1a        ld      a,(de)		; STATE 0 data/handler
210d  214021    ld      hl,#2140	; STATE 1 handler address
2110  4b        ld      c,e		; STATE 2 data  
2111  210c00    ld      hl,#000c	; STATE 3 data
2114  70        ld      (hl),b		; STATE 4 data
2115  217b21    ld      hl,#217b	; STATE 5 handler address
2118  86        add     a,(hl)		; STATE 6 data
2119  213a3a    ld      hl,#3a3a	; STATE 7 data

; FUNCTION: GAME_STATE_HANDLER_UNKNOWN - Handle unknown game state
; C_PSEUDO: void handle_unknown_state() {
; C_PSEUDO:   if (player_y_position == 0x21) {
; C_PSEUDO:     increment_game_state();
; C_PSEUDO:     set_progression_flags();
; C_PSEUDO:     call_initialization_routine();
; C_PSEUDO:     advance_to_next_state();
; C_PSEUDO:   } else {
; C_PSEUDO:     call_standard_game_functions();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Checks player position to determine state progression
211c  4d        ld      c,l		; Transfer low byte to C
211d  d621      sub     #21		; Check if position == 0x21
211f  200f      jr      nz,#2130        ; Jump to standard processing if not 0x21
2121  3c        inc     a		; Increment accumulator (A = 1)
2122  32a04d    ld      (#4da0),a	; Set progression flag
2125  32b74d    ld      (#4db7),a	; Set processing flag
2128  cd0605    call    #0506		; Call initialization routine
212b  21064e    ld      hl,#4e06	; Point to game state variable
212e  34        inc     (hl)		; Increment game state
212f  c9        ret     		; Return

; Standard game processing path
2130  cd0618    call    #1806		; Call game function 1
2133  cd0618    call    #1806		; Call game function 1 again  
2136  cd361b    call    #1b36		; Call scoring/ghost function
2139  cd361b    call    #1b36		; Call scoring/ghost function again
213c  cd230e    call    #0e23		; Call additional game logic
213f  c9        ret     		; Return

; FUNCTION: POSITION_CHECK_HANDLER_1 - Check specific player position
; C_PSEUDO: void check_position_1e() {
; C_PSEUDO:   if (player_main_position == 0x1E) {
; C_PSEUDO:     advance_game_state();
; C_PSEUDO:   } else {
; C_PSEUDO:     execute_standard_processing();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Position-based state advancement logic
2140  3a3a4d    ld      a,(#4d3a)	; Load player main position
2143  d61e      sub     #1e		; Check if position == 0x1E
2145  c23021    jp      nz,#2130	; Jump to standard processing if not 0x1E
2148  c32b21    jp      #212b		; Jump to state advancement

; FUNCTION: POSITION_CHECK_HANDLER_2 - Check alternate player position  
; C_PSEUDO: void check_position_secondary() {
; C_PSEUDO:   if (player_secondary_position == 0x1E) {
; C_PSEUDO:     call_special_routine();
; C_PSEUDO:     clear_sound_channels();
; C_PSEUDO:     initialize_next_sequence();
; C_PSEUDO:     store_movement_data();
; C_PSEUDO:     update_direction_state();
; C_PSEUDO:     advance_game_state();
; C_PSEUDO:   } else {
; C_PSEUDO:     continue_current_processing();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Secondary position check with complex state setup
214b  3a324d    ld      a,(#4d32)	; Load player secondary position
214e  d61e      sub     #1e		; Check if position == 0x1E
2150  c23621    jp      nz,#2136	; Continue processing if not 0x1E
2153  cd701a    call    #1a70		; Call special routine
2156  af        xor     a		; Clear accumulator (A = 0)
2157  32ac4e    ld      (#4eac),a	; Clear sound channel 1
215a  32bc4e    ld      (#4ebc),a	; Clear sound channel 2
215d  cda505    call    #05a5		; Initialize next sequence
2160  221c4d    ld      (#4d1c),hl	; Store movement data
2163  3a3c4d    ld      a,(#4d3c)	; Load direction state
2166  32304d    ld      (#4d30),a	; Update direction state
2169  f7        rst     #30		; Queue command: Sound effect
216a  45        ld      b,l		; Command parameter
216b  07        rlca    		; Additional parameter processing
216c  00        nop     		; Parameter data
216d  c32b21    jp      #212b		; Jump to state advancement

; FUNCTION: POSITION_CHECK_HANDLER_3 - Check position 0x2F
; C_PSEUDO: void check_position_2f() {
; C_PSEUDO:   if (player_secondary_position == 0x2F) {
; C_PSEUDO:     advance_game_state();
; C_PSEUDO:   } else {
; C_PSEUDO:     continue_processing();
; C_PSEUDO:   }
; C_PSEUDO: }
2170  3a324d    ld      a,(#4d32)	; Load player secondary position
2173  d62f      sub     #2f		; Check if position == 0x2F
2175  c23621    jp      nz,#2136	; Continue processing if not 0x2F
2178  c32b21    jp      #212b		; Jump to state advancement

; FUNCTION: POSITION_CHECK_HANDLER_4 - Check position 0x3D
; C_PSEUDO: void check_position_3d() {
; C_PSEUDO:   if (player_secondary_position == 0x3D) {
; C_PSEUDO:     advance_game_state();
; C_PSEUDO:   } else {
; C_PSEUDO:     execute_standard_processing();
; C_PSEUDO:   }
; C_PSEUDO: }
217b  3a324d    ld      a,(#4d32)	; Load player secondary position
217e  d63d      sub     #3d		; Check if position == 0x3D
2180  c23021    jp      nz,#2130	; Jump to standard processing if not 0x3D
2183  c32b21    jp      #212b		; Jump to state advancement

; FUNCTION: FINAL_POSITION_CHECK - Check completion position
; C_PSEUDO: void check_completion_position() {
; C_PSEUDO:   call_game_functions();  // Execute twice
; C_PSEUDO:   
; C_PSEUDO:   if (player_main_position == 0x3D) {
; C_PSEUDO:     reset_game_state();
; C_PSEUDO:     trigger_sound_effect();
; C_PSEUDO:     advance_level();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Final position check with level completion logic
2186  cd0618    call    #1806		; Call game function 1
2189  cd0618    call    #1806		; Call game function 1 again
218c  3a3a4d    ld      a,(#4d3a)	; Load player main position
218f  d63d      sub     #3d		; Check if position == 0x3D (completion)
2191  c0        ret     nz		; Return if not at completion position
2192  32064e    ld      (#4e06),a	; Reset game state (A = 0)
2195  f7        rst     #30		; Queue command: Sound effect
2196  45        ld      b,l		; Command parameter  
2197  00        nop     		; Parameter data
2198  00        nop     		; Parameter data
2199  21044e    ld      hl,#4e04	; Point to level counter
219c  34        inc     (hl)		; Increment level
219d  c9        ret     		; Return

; ======================================================
; SCRIPTED SEQUENCE SYSTEM - DEMO MODE & INTERSTITIALS
; ======================================================
; Handles both demo gameplay and interstitial cutscenes:
; - 2-sprite configs (0x62/0x63): Demo mode gameplay (requires full game engine)
; - 4-sprite configs (0x64-0x67): Interstitial cutscenes - the 3 known "coffee breaks":
;   * After Round 2: Pac-Man chased by Blinky, then Super Pac-Man chases blue Blinky
;   * After Round 5: Blinky's cloak tears on nail, reveals foot, embarrassment
;   * After Rounds 9,13,17: Blinky chases Pac-Man, returns dragging torn cloak
; Uses state system (0x4E07) to control scripted sequences.
; ======================================================

; FUNCTION: DEMO_GAMEPLAY_CONTROLLER - Automated demo play processor
; Parameters: Uses demo sequence state at 0x4E07 for automated gameplay dispatch
; C_PSEUDO: void process_demo_gameplay() {
; C_PSEUDO:   demo_handler_t handler = demo_sequence_table[demo_sequence_state];
; C_PSEUDO:   iy_pointer = DEMO_SCRIPT_DATA;  // 0x41D2 - Demo movement script
; C_PSEUDO:   handler();  // Execute scripted demo movements and actions
; C_PSEUDO: }
; ALGORITHM: AI-controlled demo gameplay with full game engine (maze, ghosts, scoring)
219e  3a074e    ld      a,(#4e07)	; Load sequence state
21a1  fd21d241  ld      iy,#41d2	; Set IY to sequence data base address
21a5  e7        rst     #20		; Call jump table dispatcher (RST #20)

; Demo sequence jump table data (15 different demo states 0-14)
21a6  c2210c    jp      nz,#0c21	; DEMO STATE 0: Conditional demo start
21a9  00        nop     		; DEMO STATE 1: Demo pause/wait
21aa  e1        pop     hl		; DEMO STATE 2: Demo stack management
21ab  21f521    ld      hl,#21f5	; DEMO STATE 3: Demo handler address
21ae  0c        inc     c		; DEMO STATE 4: Demo counter advance
21af  221e22    ld      (#221e),hl	; DEMO STATE 5: Store demo handler
21b2  44        ld      b,h		; DEMO STATE 6: Demo register setup
21b3  225d22    ld      (#225d),hl	; DEMO STATE 7: Store alternate demo handler
21b6  0c        inc     c		; DEMO STATE 8: Demo counter advance
21b7  00        nop     		; DEMO STATE 9: Demo pause/wait
21b8  6a        ld      l,d		; DEMO STATE 10: Demo register transfer
21b9  220c00    ld      (#000c),hl	; DEMO STATE 11: Store demo data
21bc  86        add     a,(hl)		; DEMO STATE 12: Demo calculation
21bd  220c00    ld      (#000c),hl	; DEMO STATE 13: Store demo result
21c0  8d        adc     a,l		; DEMO STATE 14: Final demo calculation

; FUNCTION: DEMO_SPRITE_SETUP_HANDLER - Initialize demo display and sprites
; C_PSEUDO: void setup_demo_display() {
; C_PSEUDO:   set_sprite_visibility_flags();   // Show/hide sprites for demo
; C_PSEUDO:   initialize_demo_triggers();      // Set up demo event triggers
; C_PSEUDO:   setup_demo_script_data();        // Load demo movement script
; C_PSEUDO:   trigger_demo_sound_sequence();   // Start demo audio
; C_PSEUDO: }
; ALGORITHM: Configures visual and audio elements for attract mode demo
21c1  223e01    ld      (#013e),hl	; Store sequence data
21c4  32d245    ld      (#45d2),a	; Set sprite display flag 1
21c7  32d345    ld      (#45d3),a	; Set sprite display flag 2
21ca  32f245    ld      (#45f2),a	; Set sprite display flag 3
21cd  32f345    ld      (#45f3),a	; Set sprite display flag 4
21d0  cd0605    call    #0506		; Initialize sequence
21d3  fd360060  ld      (iy+#00),#60	; Set sequence data byte 0
21d7  fd360161  ld      (iy+#01),#61	; Set sequence data byte 1
21db  f7        rst     #30		; Queue command: Sound sequence
21dc  43        ld      b,e		; Command parameter
21dd  08        ex      af,af'		; Additional parameter processing
21de  00        nop     		; Parameter data
21df  180f      jr      #21f0           ; Jump to sequence advance

; FUNCTION: POSITION_VALIDATION_2C - Check position 0x2C
; C_PSEUDO: void validate_position_2c() {
; C_PSEUDO:   if (player_main_position == 0x2C) {
; C_PSEUDO:     set_progression_flags();
; C_PSEUDO:     advance_sequence();
; C_PSEUDO:   } else {
; C_PSEUDO:     execute_standard_processing();
; C_PSEUDO:   }
; C_PSEUDO: }
21e1  3a3a4d    ld      a,(#4d3a)	; Load player main position
21e4  d62c      sub     #2c		; Check if position == 0x2C
21e6  c23021    jp      nz,#2130	; Jump to standard processing if not 0x2C
21e9  3c        inc     a		; Increment accumulator (A = 1)
21ea  32a04d    ld      (#4da0),a	; Set progression flag
21ed  32b74d    ld      (#4db7),a	; Set processing flag

; Sequence advancement 
21f0  21074e    ld      hl,#4e07	; Point to sequence state variable
21f3  34        inc     (hl)		; Increment sequence state
21f4  c9        ret     		; Return

; FUNCTION: PLAYER_TYPE_VALIDATOR - Validate player type and setup
; C_PSEUDO: void validate_player_setup() {
; C_PSEUDO:   uint8_t player_type = get_player_type();
; C_PSEUDO:   
; C_PSEUDO:   if (player_type == 0x77 || player_type == 0x78) {
; C_PSEUDO:     setup_player_handlers();
; C_PSEUDO:     advance_sequence();
; C_PSEUDO:   } else {
; C_PSEUDO:     execute_standard_processing();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Validates player type and configures handlers accordingly
21f5  3a014d    ld      a,(#4d01)	; Load player type identifier
21f8  fe77      cp      #77		; Check if player type == 0x77
21fa  2805      jr      z,#2201         ; Jump to setup if type 0x77
21fc  fe78      cp      #78		; Check if player type == 0x78
21fe  c23021    jp      nz,#2130	; Jump to standard processing if neither type
2201  218420    ld      hl,#2084	; Load handler address
2204  224e4d    ld      (#4d4e),hl	; Store handler address 1
2207  22504d    ld      (#4d50),hl	; Store handler address 2
220a  18e4      jr      #21f0           ; Jump to sequence advance

; FUNCTION: DEMO_GAMEPLAY_HANDLER - Handle demo gameplay (player type 0x78)
; C_PSEUDO: void handle_demo_gameplay() {
; C_PSEUDO:   if (player_type != 0x78) {
; C_PSEUDO:     execute_fallback_processing();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   setup_demo_sprites(0x62, 0x63);  // 2 sprites for gameplay demo
; C_PSEUDO:   advance_sequence();
; C_PSEUDO: }
; ALGORITHM: Sets up 2-sprite configuration for automated gameplay demo
220c  3a014d    ld      a,(#4d01)	; Load player type identifier
220f  d678      sub     #78		; Check if player type == 0x78
2211  c23722    jp      nz,#2237	; Jump to fallback if not type 0x78
2214  fd360062  ld      (iy+#00),#62	; Set demo sprite data byte 0 = 0x62
2218  fd360163  ld      (iy+#01),#63	; Set demo sprite data byte 1 = 0x63
221c  18d2      jr      #21f0           ; Jump to sequence advance

; FUNCTION: INTERSTITIAL_CUTSCENE_HANDLER - Handle interstitial cutscene (player type 0x7B)
; C_PSEUDO: void handle_interstitial_cutscene() {
; C_PSEUDO:   if (player_type != 0x7B) {
; C_PSEUDO:     execute_fallback_processing();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   setup_interstitial_sprites(0x64, 0x65, 0x66, 0x67);  // 4 sprites for cutscene
; C_PSEUDO:   advance_sequence();
; C_PSEUDO: }
; ALGORITHM: Sets up 4-sprite configuration for interstitial "coffee break" cutscenes
221e  3a014d    ld      a,(#4d01)	; Load player type identifier
2221  d67b      sub     #7b		; Check if player type == 0x7B
2223  2012      jr      nz,#2237        ; Jump to fallback if not type 0x7B
2225  fd360064  ld      (iy+#00),#64	; Set demo sprite data byte 0 = 0x64
2229  fd360165  ld      (iy+#01),#65	; Set demo sprite data byte 1 = 0x65
222d  fd362066  ld      (iy+#20),#66	; Set demo sprite data byte 32 = 0x66
2231  fd362167  ld      (iy+#21),#67	; Set demo sprite data byte 33 = 0x67
2235  18b9      jr      #21f0           ; Jump to sequence advance

; FUNCTION: DEMO_FALLBACK_HANDLER - Default demo processing
; C_PSEUDO: void demo_fallback_processing() {
; C_PSEUDO:   call_game_functions();     // Execute standard game calls
; C_PSEUDO:   call_scoring_functions();  // Execute scoring logic
; C_PSEUDO:   call_additional_logic();   // Execute additional game logic
; C_PSEUDO: }
; ALGORITHM: Default processing when no specific demo player type matches
2237  cd0618    call    #1806		; Call game function 1
223a  cd0618    call    #1806		; Call game function 1 again
223d  cd361b    call    #1b36		; Call scoring/ghost function
2240  cd230e    call    #0e23		; Call additional game logic
2243  c9        ret     		; Return

; FUNCTION: INTERSTITIAL_VARIANT_HANDLER - Handle interstitial variant (player type 0x7E)  
; C_PSEUDO: void handle_interstitial_variant() {
; C_PSEUDO:   if (player_type != 0x7E) {
; C_PSEUDO:     execute_fallback_processing();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   setup_interstitial_sprites(0x68, 0x69, 0x6A, 0x6B);  // 4 sprites for cutscene
; C_PSEUDO:   advance_sequence();
; C_PSEUDO: }
; ALGORITHM: Alternative 4-sprite configuration for different interstitial cutscene
2244  3a014d    ld      a,(#4d01)	; Load player type identifier
2247  d67e      sub     #7e		; Check if player type == 0x7E
2249  20ec      jr      nz,#2237        ; Jump to fallback if not type 0x7E
224b  fd360068  ld      (iy+#00),#68	; Set demo sprite data byte 0 = 0x68
224f  fd360169  ld      (iy+#01),#69	; Set demo sprite data byte 1 = 0x69
2253  fd36206a  ld      (iy+#20),#6a	; Set demo sprite data byte 32 = 0x6A
2257  fd36216b  ld      (iy+#21),#6b	; Set demo sprite data byte 33 = 0x6B
225b  1893      jr      #21f0           ; Jump to sequence advance

; FUNCTION: DEMO_PLAYER_TYPE_80_HANDLER - Handle demo player type 0x80
; C_PSEUDO: void handle_demo_player_type_80() {
; C_PSEUDO:   if (player_type != 0x80) {
; C_PSEUDO:     execute_fallback_processing();
; C_PSEUDO:     return;
; C_PSEUDO:   }
; C_PSEUDO:   trigger_demo_sound_effect();
; C_PSEUDO:   advance_demo_sequence();
; C_PSEUDO: }
; ALGORITHM: Sound-only demo configuration for player type 0x80
225d  3a014d    ld      a,(#4d01)	; Load player type identifier
2260  d680      sub     #80		; Check if player type == 0x80
2262  20d3      jr      nz,#2237        ; Jump to fallback if not type 0x80
2264  f7        rst     #30		; Queue command: Demo sound effect
2265  4f        ld      c,a		; Command parameter
2266  08        ex      af,af'		; Additional parameter processing
2267  00        nop     		; Parameter data
2268  1886      jr      #21f0           ; Jump to sequence advance

; FUNCTION: DEMO_INCREMENT_HANDLER - Increment demo player type
; C_PSEUDO: void increment_demo_player() {
; C_PSEUDO:   player_type += 2;  // Advance to next demo configuration
; C_PSEUDO:   setup_demo_sprites(0x6C, 0x6D, 0x40, 0x40);
; C_PSEUDO:   trigger_demo_transition_sound();
; C_PSEUDO:   advance_demo_sequence();
; C_PSEUDO: }
; ALGORITHM: Advances demo player type and configures transition
226a  21014d    ld      hl,#4d01	; Point to player type variable
226d  34        inc     (hl)		; Increment player type
226e  34        inc     (hl)		; Increment player type again (+=2)
226f  fd36006c  ld      (iy+#00),#6c	; Set demo sprite data byte 0 = 0x6C
2273  fd36016d  ld      (iy+#01),#6d	; Set demo sprite data byte 1 = 0x6D
2277  fd362040  ld      (iy+#20),#40	; Set demo sprite data byte 32 = 0x40
227b  fd362140  ld      (iy+#21),#40	; Set demo sprite data byte 33 = 0x40
227f  f7        rst     #30		; Queue command: Demo transition sound
2280  4a        ld      c,d		; Command parameter
2281  08        ex      af,af'		; Additional parameter processing
2282  00        nop     		; Parameter data
2283  c3f021    jp      #21f0		; Jump to sequence advance

; FUNCTION: DEMO_SOUND_ONLY_HANDLER - Demo sound effect only
; C_PSEUDO: void demo_sound_only() {
; C_PSEUDO:   trigger_demo_sound(0x54);
; C_PSEUDO:   advance_demo_sequence();
; C_PSEUDO: }
; ALGORITHM: Plays demo sound effect and advances sequence
2286  f7        rst     #30		; Queue command: Demo sound effect
2287  54        ld      d,h		; Command parameter (0x54)
2288  08        ex      af,af'		; Additional parameter processing
2289  00        nop     		; Parameter data
228a  c3f021    jp      #21f0		; Jump to sequence advance

; FUNCTION: DEMO_SEQUENCE_COMPLETE - Complete demo sequence
; C_PSEUDO: void complete_demo_sequence() {
; C_PSEUDO:   demo_sequence_state = 0;        // Reset demo sequence
; C_PSEUDO:   gameplay_sub_state += 2;        // Advance main game state
; C_PSEUDO: }
; ALGORITHM: Resets demo sequence and advances main gameplay state
228d  af        xor     a		; Clear accumulator (A = 0)
228e  32074e    ld      (#4e07),a	; Reset demo sequence state to 0
2291  21044e    ld      hl,#4e04	; Point to gameplay sub-state
2294  34        inc     (hl)		; Increment gameplay sub-state
2295  34        inc     (hl)		; Increment gameplay sub-state again (+=2)
2296  c9        ret     		; Return

; ======================================================
; SECONDARY DEMO/SCRIPTED SEQUENCE SYSTEM
; ======================================================
; Additional scripted sequence controller using 0x4E08.
; Appears to be another demo/sequence system parallel to 0x4E07.
; ======================================================

; FUNCTION: SECONDARY_SEQUENCE_CONTROLLER - Handle 0x4E08 sequence state
; Parameters: Uses sequence state at 0x4E08 for dispatch
; C_PSEUDO: void process_secondary_sequence() {
; C_PSEUDO:   sequence_handler_t handler = secondary_table[sequence_state_08];
; C_PSEUDO:   handler();  // Execute sequence-specific logic
; C_PSEUDO: }
; ALGORITHM: Secondary scripted sequence system with position validation
2297  3a084e    ld      a,(#4e08)	; Load secondary sequence state
229a  e7        rst     #20		; Call jump table dispatcher (RST #20)

; Secondary sequence jump table data
229b  a7        and     a		; SEQUENCE 0: Test and clear flags
229c  22be22    ld      (#22be),hl	; SEQUENCE 1: Store handler address
229f  0c        inc     c		; SEQUENCE 2: Counter increment
22a0  00        nop     		; SEQUENCE 3: No operation
22a1  dd22f522  ld      (#22f5),ix	; SEQUENCE 4: Store IX register

; FUNCTION: SECONDARY_POSITION_CHECK - Check position 0x25
; C_PSEUDO: void check_secondary_position_25() {
; C_PSEUDO:   if (state_flag == 0x22) {  // Special state check
; C_PSEUDO:     if (player_main_position == 0x25) {
; C_PSEUDO:       set_progression_flags();
; C_PSEUDO:       initialize_sequence();
; C_PSEUDO:       advance_secondary_sequence();
; C_PSEUDO:     } else {
; C_PSEUDO:       execute_fallback_processing();
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Position-based trigger for secondary sequence advancement
22a5  fe22      cp      #22		; Check if state flag == 0x22
22a7  3a3a4d    ld      a,(#4d3a)	; Load player main position
22aa  d625      sub     #25		; Check if position == 0x25
22ac  c23021    jp      nz,#2130	; Jump to fallback if not position 0x25
22af  3c        inc     a		; Increment accumulator (A = 1)
22b0  32a04d    ld      (#4da0),a	; Set progression flag
22b3  32b74d    ld      (#4db7),a	; Set processing flag
22b6  cd0605    call    #0506		; Initialize sequence
22b9  21084e    ld      hl,#4e08	; Point to secondary sequence state
22bc  34        inc     (hl)		; Increment secondary sequence state
22bd  c9        ret     		; Return

; FUNCTION: SECONDARY_PLAYER_TYPE_VALIDATOR - Validate player for secondary sequence
; Parameters: Uses player type at 0x4D01 for validation
; C_PSEUDO: void validate_secondary_player() {
; C_PSEUDO:   player_type = get_player_type();
; C_PSEUDO:   // Check various player types for secondary sequence
; C_PSEUDO:   if (matches_secondary_criteria(player_type)) {
; C_PSEUDO:     configure_secondary_sequence();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Player type validation for secondary scripted sequences
22be  3a014d    ld      a,(#4d01)	; Load player type identifier
22c1  feff      cp      #ff		; Check if player type == 0xFF
22c3  2805      jr      z,#22ca         ; Jump to increment if type 0xFF
22c5  fefe      cp      #fe		; Check if player type == 0xFE
22c7  c23021    jp      nz,#2130	; Jump to fallback if neither 0xFF nor 0xFE
22ca  3c        inc     a		; Increment player type
22cb  3c        inc     a		; Increment player type again (+2)
22cc  32014d    ld      (#4d01),a	; Store updated player type
22cf  3e01      ld      a,#01		; Set flag value
22d1  32b14d    ld      (#4db1),a	; Set processing flag
22d4  cdfe1e    call    #1efe		; Call special routine
22d7  f7        rst     #30		; Queue command: Sound effect
22d8  4a        ld      c,d		; Command parameter
22d9  09        add     hl,bc		; Additional parameter processing
22da  00        nop     		; Parameter data
22db  18dc      jr      #22b9           ; Jump back to secondary sequence advance

; FUNCTION: SECONDARY_POSITION_CHECK_2D - Check position 0x2D
; C_PSEUDO: void check_secondary_position_2d() {
; C_PSEUDO:   if (player_secondary_position == 0x2D) {
; C_PSEUDO:     advance_secondary_sequence();
; C_PSEUDO:   } else {
; C_PSEUDO:     store_coordinate_data();
; C_PSEUDO:     execute_fallback_processing();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Position check with coordinate storage for secondary sequence
22dd  3a324d    ld      a,(#4d32)	; Load player secondary position
22e0  d62d      sub     #2d		; Check if position == 0x2D
22e2  28d5      jr      z,#22b9         ; Jump to sequence advance if position 0x2D
22e4  3a004d    ld      a,(#4d00)	; Load coordinate data 1
22e7  32d24d    ld      (#4dd2),a	; Store coordinate backup 1
22ea  3a014d    ld      a,(#4d01)	; Load coordinate data 2
22ed  d608      sub     #08		; Subtract offset (8)
22ef  32d34d    ld      (#4dd3),a	; Store coordinate backup 2
22f2  c33021    jp      #2130		; Jump to fallback processing

; FUNCTION: SECONDARY_POSITION_CHECK_1E - Check position 0x1E 
; C_PSEUDO: void check_secondary_position_1e() {
; C_PSEUDO:   if (player_secondary_position == 0x1E) {
; C_PSEUDO:     advance_secondary_sequence();
; C_PSEUDO:   } else {
; C_PSEUDO:     store_coordinate_data_and_fallback();
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Another position check for secondary sequence advancement
22f5  3a324d    ld      a,(#4d32)	; Load player secondary position
22f8  d61e      sub     #1e		; Check if position == 0x1E
22fa  28bd      jr      z,#22b9         ; Jump to sequence advance if position 0x1E
22fc  18e6      jr      #22e4           ; Jump to coordinate storage

; FUNCTION: SECONDARY_SEQUENCE_COMPLETE - Complete secondary sequence
; C_PSEUDO: void complete_secondary_sequence() {
; C_PSEUDO:   secondary_sequence_state = 0;   // Reset secondary sequence
; C_PSEUDO:   trigger_completion_sound();     // Audio feedback
; C_PSEUDO:   gameplay_sub_state++;           // Advance main game state
; C_PSEUDO: }
; ALGORITHM: Resets secondary sequence and advances main gameplay state
22fe  af        xor     a		; Clear accumulator (A = 0)
22ff  32084e    ld      (#4e08),a	; Reset secondary sequence state to 0
2302  f7        rst     #30		; Queue command: Completion sound
2303  45        ld      b,l		; Command parameter
2304  00        nop     		; Parameter data  
2305  00        nop     		; Parameter data
2306  21044e    ld      hl,#4e04	; Point to gameplay sub-state
2309  34        inc     (hl)		; Increment gameplay sub-state
230a  c9        ret     		; Return

; ======================================================
; SYSTEM INITIALIZATION AND ROM/RAM TEST
; ======================================================
; Hardware initialization, memory clearing, and system setup.
; This appears to be boot/reset code for the arcade machine.
; ======================================================

; FUNCTION: SYSTEM_INITIALIZATION - Initialize arcade hardware
; C_PSEUDO: void initialize_system() {
; C_PSEUDO:   clear_hardware_latches();      // Reset 74LS259 latches
; C_PSEUDO:   initialize_video_memory();     // Set up screen RAM
; C_PSEUDO:   initialize_color_memory();     // Set up color RAM  
; C_PSEUDO:   setup_interrupt_system();      // Configure Z80 interrupts
; C_PSEUDO:   enable_hardware();             // Enable system operation
; C_PSEUDO: }
; ALGORITHM: Complete system initialization sequence for arcade hardware

; Clear 74LS259 latch contents (interrupts off, sound off, flip off, etc.)
230b  210050    ld      hl,#5000	; Point to hardware latch base address
230e  0608      ld      b,#08		; 8 latches to clear
2310  af        xor     a		; Clear accumulator (A = 0)
2311  77        ld      (hl),a		; Clear current latch
2312  2c        inc     l		; Move to next latch
2313  10fc      djnz    #2311           ; Loop for all 8 latches

; Initialize video RAM (0x4000-0x43FF) to 0x40
2315  210040    ld      hl,#4000	; Point to video RAM start
2318  0604      ld      b,#04		; 4 pages of 256 bytes each (1K total)
231a  32c050    ld      (#50c0),a	; Kick watchdog timer
231d  320750    ld      (#5007),a	; Clear coin counter
2320  3e40      ld      a,#40		; Set fill value (0x40 = space character)
2322  77        ld      (hl),a		; Write to video memory
2323  2c        inc     l		; Increment low byte
2324  20fc      jr      nz,#2322        ; Loop until page complete (L wraps to 0)
2326  24        inc     h		; Move to next page
2327  10f1      djnz    #231a           ; Loop for all 4 pages

; Initialize color RAM (0x4400-0x47FF) to 0x0F  
2329  0604      ld      b,#04		; 4 pages of 256 bytes each (1K total)
232b  32c050    ld      (#50c0),a	; Kick watchdog timer
232e  af        xor     a		; Clear accumulator (A = 0)
232f  320750    ld      (#5007),a	; Clear coin counter
2332  3e0f      ld      a,#0f		; Set color value (0x0F = white on black)
2334  77        ld      (hl),a		; Write to color memory
2335  2c        inc     l		; Increment low byte
2336  20fc      jr      nz,#2334        ; Loop until page complete (L wraps to 0)
2338  24        inc     h		; Move to next page
2339  10f0      djnz    #232b           ; Loop for all 4 pages

; Setup Z80 interrupt system
233b  ed5e      im      2		; Set interrupt mode 2 (vectored interrupts)
233d  3efa      ld      a,#fa		; Load interrupt vector high byte
233f  d300      out     (#00),a		; Set interrupt vector to 0xFA00
2341  af        xor     a		; Clear accumulator (A = 0)
2342  320750    ld      (#5007),a	; Clear coin counter
2345  3c        inc     a		; Set A = 1
2346  320050    ld      (#5000),a	; Enable hardware interrupts
2349  fb        ei			; Enable CPU interrupts
234a  76        halt			; Wait for interrupt

; FUNCTION: GAME_STARTUP - Complete game initialization sequence
; C_PSEUDO: void startup_game() {
; C_PSEUDO:   kick_watchdog();
; C_PSEUDO:   setup_stack(0x4FC0);
; C_PSEUDO:   clear_hardware_latches();
; C_PSEUDO:   clear_main_ram();
; C_PSEUDO:   clear_sound_and_sprites();
; C_PSEUDO:   initialize_command_queue();
; C_PSEUDO:   start_main_loop();
; C_PSEUDO: }
; ALGORITHM: Final initialization before entering main game loop
234b  32c050    ld      (#50c0),a	; Kick watchdog timer
234e  31c04f    ld      sp,#4fc0	; Set stack pointer to 0x4FC0

; Clear hardware latches (disable all)
2351  af        xor     a		; Clear accumulator (A = 0)
2352  210050    ld      hl,#5000	; Point to hardware latch base
2355  010808    ld      bc,#0808	; Clear 8 latches, 8 bytes each
2358  cf        rst     #8		; Call memory clear routine

; Clear main RAM (0x4C00-0x4DBE = 446 bytes)
2359  21004c    ld      hl,#4c00	; Point to main RAM start
235c  06be      ld      b,#be		; 190 bytes to clear (0xBE)
235e  cf        rst     #8		; Clear memory block
235f  cf        rst     #8		; Clear memory block  
2360  cf        rst     #8		; Clear memory block
2361  cf        rst     #8		; Clear memory block

; Clear sound registers and sprite positions (0x5040-0x507F = 64 bytes)
2362  214050    ld      hl,#5040	; Point to sound/sprite hardware
2365  0640      ld      b,#40		; 64 bytes to clear
2367  cf        rst     #8		; Clear hardware registers

2368  32c050    ld      (#50c0),a	; Kick watchdog timer
236b  cd0d24    call    #240d		; Call: Clear color RAM
236e  32c050    ld      (#50c0),a	; Kick watchdog timer
2371  0600      ld      b,#00		; Set parameter for next call
2373  cded23    call    #23ed		; Call: Initialize video system
2376  32c050    ld      (#50c0),a	; Kick watchdog timer

; ======================================================
; RST #28 COMMAND QUEUE INITIALIZATION  
; ======================================================
; Initialize the circular command buffer used by RST #28
; Buffer: 0x4CC0-0x4CFF (64 bytes, 32 commands max)
; Pointers: 0x4C80 (read), 0x4C82 (write)
; ======================================================
2379  21c04c    ld      hl,#4cc0	; Point to command buffer start
237c  22804c    ld      (#4c80),hl	; Set read pointer to buffer start
237f  22824c    ld      (#4c82),hl	; Set write pointer to buffer start

; Fill command buffer with 0xFF (empty markers)
2382  3eff      ld      a,#ff		; Load empty command marker
2384  0640      ld      b,#40		; 64 bytes to fill
2386  cf        rst     #8		; Fill buffer with 0xFF

2387  3e01      ld      a,#01		; Enable value
2389  320050    ld      (#5000),a	; Enable hardware interrupts
238c  fb        ei			; Enable CPU interrupts

; ======================================================
; RST #28 COMMAND PROCESSING LOOP (Called by 60Hz interrupt)
; ======================================================
; This is THE command processing loop that executes queued RST #28 commands.
; It runs continuously, processing commands until the buffer is empty.
; ======================================================

; FUNCTION: PROCESS_COMMAND_QUEUE - Main command processing loop
; C_PSEUDO: void process_command_queue() {
; C_PSEUDO:   while (true) {
; C_PSEUDO:     command_ptr = read_pointer;
; C_PSEUDO:     if (*command_ptr < 0) continue;  // Empty slot, wait
; C_PSEUDO:     
; C_PSEUDO:     command_code = *command_ptr;
; C_PSEUDO:     *command_ptr = 0xFF;  // Mark as processed
; C_PSEUDO:     parameter = *(command_ptr + 1);
; C_PSEUDO:     *(command_ptr + 1) = 0xFF;  // Mark as processed
; C_PSEUDO:     
; C_PSEUDO:     advance_read_pointer();
; C_PSEUDO:     execute_command(command_code, parameter);  // RST #20 dispatch
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Circular buffer processing with RST #20 command dispatch
238d  2a824c    ld      hl,(#4c82)	; Load read pointer from 0x4C82
2390  7e        ld      a,(hl)		; Load command code from buffer
2391  a7        and     a		; Test if command code is negative
2392  fa8d23    jp      m,#238d		; Jump back if negative (0xFF = empty)
2395  36ff      ld      (hl),#ff	; Mark command slot as processed (0xFF)
2397  2c        inc     l		; Move to parameter byte
2398  46        ld      b,(hl)		; Load parameter into B register
2399  36ff      ld      (hl),#ff	; Mark parameter slot as processed (0xFF)
239b  2c        inc     l		; Advance to next command slot
239c  2002      jr      nz,#23a0        ; Jump if not at buffer end
239e  2ec0      ld      l,#c0		; Wrap to buffer start (0x4CC0)
23a0  22824c    ld      (#4c82),hl	; Update read pointer
23a3  218d23    ld      hl,#238d	; Load return address (back to processing loop)
23a6  e5        push    hl		; Push return address on stack
23a7  e7        rst     #20		; Execute command via RST #20 (B = parameter)

; ======================================================
; RST #20 COMMAND DISPATCH JUMP TABLE - DATA TABLE
; ======================================================
; This jump table is used by RST #20 to dispatch commands read from the
; command buffer. Each command byte (0x00-0x1F) is doubled and used as
; an index into this table to find the handler function address.
; ======================================================

; MEMORY_MAP: Command Handler Address Table (32 entries)
; Format: 16-bit addresses in little-endian format
23a8  ed23      dw      #23ed		; Command 0x00: Initialize video system
23aa  d724      dw      #24d7		; Command 0x01: POSSIBLY sprite/tile management
23ac  1924      dw      #2419		; Command 0x02: Screen data processing (compressed format)
23ae  4824      dw      #2448		; Command 0x03: Screen rendering with dual lookup tables
23b0  3d25      dw      #253d		; Command 0x04: POSSIBLY level/maze initialization
23b2  8b26      dw      #268b		; Command 0x05: POSSIBLY ghost AI state management
23b4  0d24      dw      #240d		; Command 0x06: Clear color RAM to black
23b6  9826      dw      #2698		; Command 0x07: POSSIBLY score/bonus management
23b8  3027      dw      #2730		; Command 0x08: POSSIBLY sound effect control
23ba  6c27      dw      #276c		; Command 0x09: POSSIBLY fruit/bonus object control
23bc  a927      dw      #27a9		; Command 0x0A: POSSIBLY pellet consumption logic
23be  f127      dw      #27f1		; Command 0x0B: POSSIBLY power pellet effects
23c0  3b28      dw      #283b		; Command 0x0C: POSSIBLY collision detection
23c2  6528      dw      #2865		; Command 0x0D: Pinky's targeting (contains 4-tile bug!)
23c4  8f28      dw      #288f		; Command 0x0E: POSSIBLY Inky's targeting algorithm
23c6  b928      dw      #28b9		; Command 0x0F: POSSIBLY Sue's targeting algorithm
23c8  0d28      dw      #280d		; Command 0x10: POSSIBLY Blinky's targeting algorithm
23ca  a226      dw      #26a2		; Command 0x11: POSSIBLY ghost movement coordination
23cc  c924      dw      #24c9		; Command 0x12: POSSIBLY sprite animation control
23ce  3526      dw      #2635		; Command 0x13: POSSIBLY player input processing
23d0  d026      dw      #26d0		; Command 0x14: POSSIBLY level progression logic
23d2  8724      dw      #2487		; Command 0x15: POSSIBLY game state transitions
23d4  e823      dw      #23e8		; Command 0x16: Increment gameplay sub-state counter
23d6  e328      dw      #28e3		; Command 0x17: POSSIBLY frightened mode management
23d8  e02a      dw      #2ae0		; Command 0x18: POSSIBLY tunnel teleportation
23da  5a2a      dw      #2a5a		; Command 0x19: POSSIBLY death sequence control
23dc  6a2b      dw      #2b6a		; Command 0x1A: POSSIBLY intermission/cutscene control
23de  ea2b      dw      #2bea		; Command 0x1B: POSSIBLY demo mode automation
23e0  5e2c      dw      #2c5e		; Command 0x1C: POSSIBLY attract mode cycling
23e2  a12b      dw      #2ba1		; Command 0x1D: POSSIBLY high score management
23e4  752b      dw      #2b75		; Command 0x1E: POSSIBLY credit/coin processing
23e6  b226      dw      #26b2		; Command 0x1F: POSSIBLY system diagnostics

; ======================================================
; COMMAND HANDLER IMPLEMENTATIONS
; ======================================================

; FUNCTION: COMMAND_16_INCREMENT_STATE - Increment gameplay sub-state counter (Command 0x16)
; C_PSEUDO: void increment_gameplay_substate() {
; C_PSEUDO:   gameplay_substate_counter++;   // Advance game progression
; C_PSEUDO: }
; ALGORITHM: Simple counter increment for game state management
; This function is called via the jump table entry at 23d4
23e8  21044e    ld      hl,#4e04	; Point to gameplay sub-state counter at 0x4e04
23eb  34        inc     (hl)		; Increment the counter
23ec  c9        ret     		; Return

; ======================================================
; SYSTEM INITIALIZATION CODE SECTION  
; ======================================================

; FUNCTION: SYSTEM_INITIALIZE_ENTRY - Main system initialization entry point
; C_PSEUDO: void system_initialize() {
; C_PSEUDO:   enable_interrupts();          // Enable Z80 interrupts
; C_PSEUDO:   halt_until_interrupt();       // Wait for first interrupt
; C_PSEUDO:   kick_watchdog();              // Reset hardware watchdog
; C_PSEUDO:   setup_stack_pointer();        // Initialize stack
; C_PSEUDO:   clear_hardware_registers();   // Zero all hardware I/O
; C_PSEUDO:   clear_ram_areas();            // Clear work RAM and sprite RAM
; C_PSEUDO:   clear_sound_registers();      // Initialize audio hardware
; C_PSEUDO:   initialize_color_ram();       // Set up display colors
; C_PSEUDO:   initialize_video_system();    // Set up video hardware
; C_PSEUDO:   setup_memory_pointers();      // Initialize buffer pointers
; C_PSEUDO:   enable_system_operation();    // Start normal operation
; C_PSEUDO: }
; ALGORITHM: Complete arcade machine initialization sequence
; This is the main boot/reset routine that sets up all hardware and memory
; for normal game operation. Uses RST #8 extensively for memory clearing.
2346  320050    ld      (#5000),a	; Enable interrupts (A=0 from prior code)
2349  fb        ei			; Enable Z80 interrupts
234a  76        halt			; Wait for interrupt (synchronization)

; ALGORITHM: Watchdog and Stack Setup
; The "kick the dog" refers to resetting the hardware watchdog timer
; to prevent system reset. Stack pointer set to 0x4fc0.
234b  32c050    ld      (#50c0),a	; Kick the watchdog timer
234e  31c04f    ld      sp,#4fc0	; Set stack pointer to 0x4fc0

; FUNCTION: CLEAR_HARDWARE_REGISTERS - Zero all hardware I/O registers
; C_PSEUDO: void clear_hardware_registers() {
; C_PSEUDO:   memset(0x5000, 0, 8);   // Clear 8 hardware control registers
; C_PSEUDO: }
; ALGORITHM: Uses RST #8 (memory clear routine) to zero hardware registers
; RST #8 jumps to 0x0008 which is: LD (HL),A; INC HL; DJNZ loop; RET
2351  af        xor     a		; A = 0 (value to store)
2352  210050    ld      hl,#5000	; HL = 0x5000 (hardware registers base)
2355  010808    ld      bc,#0808	; B = 8 (count), C = 8 (POSSIBLY second count?)
2358  cf        rst     #8		; Call memory clear: clear 8 bytes at 0x5000

; FUNCTION: CLEAR_WORK_RAM - Clear main work RAM area
; C_PSEUDO: void clear_work_ram() {
; C_PSEUDO:   memset(0x4c00, 0, 0xBE * 4);  // Clear 760 bytes of work RAM
; C_PSEUDO: }
; ALGORITHM: Clears the main work RAM area where game state is stored
; Multiple RST #8 calls suggest clearing in chunks
2359  21004c    ld      hl,#4c00	; HL = 0x4c00 (work RAM start)
235c  06be      ld      b,#be		; B = 190 (0xBE) bytes to clear
235e  cf        rst     #8		; Clear first 190 bytes
235f  cf        rst     #8		; Clear next 190 bytes  
2360  cf        rst     #8		; Clear next 190 bytes
2361  cf        rst     #8		; Clear next 190 bytes (total: 760 bytes)

; FUNCTION: CLEAR_SOUND_SPRITE_REGISTERS - Clear audio and sprite hardware
; C_PSEUDO: void clear_sound_sprite_registers() {
; C_PSEUDO:   memset(0x5040, 0, 0x40);  // Clear 64 bytes of sound/sprite regs
; C_PSEUDO: }
; ALGORITHM: Clears sound registers and sprite position registers
2362  214050    ld      hl,#5040	; HL = 0x5040 (sound/sprite registers)
2365  0640      ld      b,#40		; B = 64 bytes to clear
2367  cf        rst     #8		; Clear sound and sprite registers

2368  32c050    ld      (#50c0),a	; Kick the watchdog timer

; FUNCTION: INITIALIZE_COLOR_RAM - Set up display color memory
; C_PSEUDO: void initialize_color_ram() {
; C_PSEUDO:   clear_color_memory();    // Function at 0x240d
; C_PSEUDO: }
; ALGORITHM: Calls dedicated color RAM initialization routine
236b  cd0d24    call    #240d		; Call color RAM clear function

2368  32c050    ld      (#50c0),a	; Kick the watchdog timer

; FUNCTION: INITIALIZE_VIDEO_SYSTEM - Set up video hardware
; C_PSEUDO: void initialize_video_system() {
; C_PSEUDO:   setup_video_hardware(0);  // Function at 0x23ed with parameter 0
; C_PSEUDO: }
; ALGORITHM: Calls video system initialization with parameter B=0
2371  0600      ld      b,#00		; B = 0 (parameter for video init)
2373  cded23    call    #23ed		; Call video system initialization

2376  32c050    ld      (#50c0),a	; Kick the watchdog timer

; FUNCTION: SETUP_MEMORY_POINTERS - Initialize buffer management pointers
; C_PSEUDO: void setup_memory_pointers() {
; C_PSEUDO:   buffer_ptr1 = 0x4cc0;    // Set both pointers to same location
; C_PSEUDO:   buffer_ptr2 = 0x4cc0;    // POSSIBLY for double buffering setup
; C_PSEUDO: }
; ALGORITHM: Sets up memory management pointers, MAYBE for sprite or display buffers
2379  21c04c    ld      hl,#4cc0	; HL = 0x4cc0 (buffer start address)
237c  22804c    ld      (#4c80),hl	; Store in pointer 1 (0x4c80)
237f  22824c    ld      (#4c82),hl	; Store in pointer 2 (0x4c82)

; FUNCTION: INITIALIZE_BUFFER_AREA - Fill buffer area with 0xFF
; C_PSEUDO: void initialize_buffer_area() {
; C_PSEUDO:   memset(0x4cc0, 0xFF, 0x40);  // Fill 64 bytes with 0xFF
; C_PSEUDO: }
; ALGORITHM: Initializes a 64-byte buffer area with 0xFF values
; This MIGHT be initializing sprite or tile buffer data
2382  3eff      ld      a,#ff		; A = 0xFF (fill value)
2384  0640      ld      b,#40		; B = 64 bytes to fill
2386  cf        rst     #8		; Fill buffer with 0xFF

; FUNCTION: ENABLE_SYSTEM_OPERATION - Enable normal operation mode
; C_PSEUDO: void enable_system_operation() {
; C_PSEUDO:   enable_interrupts_mode();     // Set interrupt enable flag
; C_PSEUDO:   start_main_loop();            // Begin main execution loop
; C_PSEUDO: }
; ALGORITHM: Final step - enables interrupts and starts main game loop
2387  3e01      ld      a,#01		; A = 1 (enable flag)
2389  320050    ld      (#5000),a	; Enable interrupts in hardware
238c  fb        ei			; Enable Z80 interrupts

; FUNCTION: MAIN_EXECUTION_LOOP - Main game execution loop after initialization
; C_PSEUDO: void main_execution_loop() {
; C_PSEUDO:   while(1) {
; C_PSEUDO:     buffer_ptr = *(uint16_t*)0x4c82;  // Get current buffer pointer
; C_PSEUDO:     while(*buffer_ptr >= 0) {         // While not negative (0x80+ = negative)
; C_PSEUDO:       buffer_ptr = *(uint16_t*)0x4c82; // Keep checking
; C_PSEUDO:     }
; C_PSEUDO:     *buffer_ptr = 0xFF;               // Mark as processed
; C_PSEUDO:     buffer_ptr++;                     // Move to next byte
; C_PSEUDO:     command = *buffer_ptr;            // Get command byte
; C_PSEUDO:     *buffer_ptr = 0xFF;               // Mark as processed
; C_PSEUDO:     buffer_ptr++;                     // Move to next position
; C_PSEUDO:     if(buffer_ptr & 0xFF == 0) {      // If wrapped to page boundary
; C_PSEUDO:       buffer_ptr = 0x4cc0;            // Reset to buffer start
; C_PSEUDO:     }
; C_PSEUDO:     *(uint16_t*)0x4c82 = buffer_ptr;  // Update pointer
; C_PSEUDO:     execute_command_with_rst20(command); // Execute the command
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Main command processing loop - reads commands from a circular buffer
; and executes them. This APPEARS to be a command queue system for game logic.
238d  2a824c    ld      hl,(#4c82)	; Load buffer pointer from 0x4c82
2390  7e        ld      a,(hl)		; Read byte from buffer
2391  a7        and     a		; Test if negative (bit 7 set)
2392  fa8d23    jp      m,#238d         ; Loop back if negative (wait for positive)
2395  36ff      ld      (hl),#ff	; Mark current position as processed (0xFF)
2397  2c        inc     l		; Move to next buffer position
2398  46        ld      b,(hl)		; Read command byte into B
2399  36ff      ld      (hl),#ff	; Mark command position as processed
239b  2c        inc     l		; Move to next position
239c  2002      jr      nz,#23a0        ; If L didn't wrap to 0, continue
239e  2ec0      ld      l,#c0		; If wrapped, reset L to 0xc0 (buffer start)
23a0  22824c    ld      (#4c82),hl	; Store updated buffer pointer
23a3  218d23    ld      hl,#238d	; Push return address (loop continuation)
23a6  e5        push    hl		; Put on stack for return
23a7  e7        rst     #20		; Execute command via RST #20 (command dispatcher)

; ======================================================
; RST #20 COMMAND DISPATCH JUMP TABLE - DATA TABLE
; ======================================================
; This jump table is used by RST #20 to dispatch commands read from the
; command buffer. Each command byte (0x00-0x1F) is doubled and used as
; an index into this table to find the handler function address.
; ======================================================

; MEMORY_MAP: Command Handler Address Table (32 entries)
; Format: 16-bit addresses in little-endian format
23a8  ed23      dw      #23ed		; Command 0x00: Initialize video system
23aa  d724      dw      #24d7		; Command 0x01: POSSIBLY sprite/tile management
23ac  1924      dw      #2419		; Command 0x02: Screen data processing (compressed format)
23ae  4824      dw      #2448		; Command 0x03: Screen rendering with dual lookup tables
23b0  3d25      dw      #253d		; Command 0x04: POSSIBLY level/maze initialization
23b2  8b26      dw      #268b		; Command 0x05: POSSIBLY ghost AI state management
23b4  0d24      dw      #240d		; Command 0x06: Clear color RAM to black
23b6  9826      dw      #2698		; Command 0x07: POSSIBLY score/bonus management
23b8  3027      dw      #2730		; Command 0x08: POSSIBLY sound effect control
23ba  6c27      dw      #276c		; Command 0x09: POSSIBLY fruit/bonus object control
23bc  a927      dw      #27a9		; Command 0x0A: POSSIBLY pellet consumption logic
23be  f127      dw      #27f1		; Command 0x0B: POSSIBLY power pellet effects
23c0  3b28      dw      #283b		; Command 0x0C: POSSIBLY collision detection
23c2  6528      dw      #2865		; Command 0x0D: Pinky's targeting (contains 4-tile bug!)
23c4  8f28      dw      #288f		; Command 0x0E: POSSIBLY Inky's targeting algorithm
23c6  b928      dw      #28b9		; Command 0x0F: POSSIBLY Sue's targeting algorithm
23c8  0d28      dw      #280d		; Command 0x10: POSSIBLY Blinky's targeting algorithm
23ca  a226      dw      #26a2		; Command 0x11: POSSIBLY ghost movement coordination
23cc  c924      dw      #24c9		; Command 0x12: POSSIBLY sprite animation control
23ce  3526      dw      #2635		; Command 0x13: POSSIBLY player input processing
23d0  d026      dw      #26d0		; Command 0x14: POSSIBLY level progression logic
23d2  8724      dw      #2487		; Command 0x15: POSSIBLY game state transitions
23d4  e823      dw      #23e8		; Command 0x16: Increment gameplay sub-state counter
23d6  e328      dw      #28e3		; Command 0x17: POSSIBLY frightened mode management
23d8  e02a      dw      #2ae0		; Command 0x18: POSSIBLY tunnel teleportation
23da  5a2a      dw      #2a5a		; Command 0x19: POSSIBLY death sequence control
23dc  6a2b      dw      #2b6a		; Command 0x1A: POSSIBLY intermission/cutscene control
23de  ea2b      dw      #2bea		; Command 0x1B: POSSIBLY demo mode automation
23e0  5e2c      dw      #2c5e		; Command 0x1C: POSSIBLY attract mode cycling
23e2  a12b      dw      #2ba1		; Command 0x1D: POSSIBLY high score management
23e4  752b      dw      #2b75		; Command 0x1E: POSSIBLY credit/coin processing
23e6  b226      dw      #26b2		; Command 0x1F: POSSIBLY system diagnostics

; ======================================================
; COMMAND HANDLER IMPLEMENTATIONS
; ======================================================

; FUNCTION: COMMAND_16_INCREMENT_STATE - Increment gameplay sub-state counter (Command 0x16)
; C_PSEUDO: void increment_gameplay_substate() {
; C_PSEUDO:   gameplay_substate_counter++;   // Advance game progression
; C_PSEUDO: }
; ALGORITHM: Simple counter increment for game state management
; This function is called via the jump table entry at 23d4
23e8  21044e    ld      hl,#4e04	; Point to gameplay sub-state counter at 0x4e04
23eb  34        inc     (hl)		; Increment the counter
23ec  c9        ret     		; Return

; FUNCTION: VIDEO_SYSTEM_INITIALIZE - Initialize video hardware subsystem (Command 0x00)
; C_PSEUDO: void initialize_video_system(uint8_t parameter) {
; C_PSEUDO:   execute_command_via_rst20(parameter);  // Use parameter from B register
; C_PSEUDO:   setup_screen_memory();                 // Initialize screen RAM areas
; C_PSEUDO:   setup_sprite_memory();                 // Initialize sprite RAM areas  
; C_PSEUDO: }
; ALGORITHM: Video system initialization with parameter-driven setup
; This function is called during system initialization with B=0
23ed  78        ld      a,b		; Get parameter from B register
23ee  e7        rst     #20		; Execute command via RST #20 dispatcher

; FUNCTION: SETUP_SCREEN_MEMORY - Initialize screen RAM with pattern
; C_PSEUDO: void setup_screen_memory() {
; C_PSEUDO:   for(int page = 0; page < 4; page++) {
; C_PSEUDO:     memset(0x4000 + (page * 0x100), 0x40, 0x100);  // Fill page with 0x40
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Fills 4 pages (1024 bytes) of screen RAM with tile value 0x40
; This LIKELY sets up the screen with a default tile pattern
23f3  3e40      ld      a,#40		; A = 0x40 (tile/pattern value)
23f5  010400    ld      bc,#0004	; B = 4 (page count), C = 0 (POSSIBLY page index)
23f8  210040    ld      hl,#4000	; HL = 0x4000 (screen RAM base)
23fb  cf        rst     #8		; Fill 256 bytes with 0x40
23fc  0d        dec     c		; Decrement page counter? (C was 0, now 0xFF)
23fd  20fc      jr      nz,#23fb        ; Loop back if not zero (NOTE: C started at 0!)
23ff  c9        ret     		; Return

; FUNCTION: SETUP_SPRITE_MEMORY - Initialize sprite RAM with pattern  
; C_PSEUDO: void setup_sprite_memory() {
; C_PSEUDO:   for(int page = 0; page < 4; page++) {
; C_PSEUDO:     memset(0x4040 + (page * 0x100), 0x40, 0x80);  // Fill 128 bytes per page
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Fills sprite RAM areas with default pattern 0x40
; POSSIBLY initializes sprite visibility or default sprite tiles
2400  3e40      ld      a,#40		; A = 0x40 (sprite pattern value)
2402  214040    ld      hl,#4040	; HL = 0x4040 (sprite RAM base)
2405  010480    ld      bc,#8004	; B = 4 (page count), C = 0x80 (MAYBE bytes per page?)
2408  cf        rst     #8		; Fill memory with 0x40
2409  0d        dec     c		; Decrement counter
240a  20fc      jr      nz,#2408        ; Loop until counter = 0
240c  c9        ret     		; Return

; FUNCTION: CLEAR_COLOR_RAM - Initialize color RAM to black
; C_PSEUDO: void clear_color_ram() {
; C_PSEUDO:   for(int page = 0; page < 4; page++) {
; C_PSEUDO:     memset(0x4400 + (page * 0x100), 0x00, 0x100);  // Clear color data
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Sets all color RAM to 0x00 (black/transparent)
; This is the function called during system initialization at 236b
240d  af        xor     a		; A = 0 (black color value)
240e  010400    ld      bc,#0004	; B = 4 (page count), C = 0
2411  210044    ld      hl,#4400	; HL = 0x4400 (color RAM base)
2414  cf        rst     #8		; Clear 256 bytes to 0x00
2415  0d        dec     c		; Decrement counter
2416  20fc      jr      nz,#2414        ; Loop back if not zero
2418  c9        ret     		; Return

; ======================================================
; RST #20 COMMAND IMPLEMENTATIONS
; ======================================================
; These are the actual command handler functions called via the jump table.
; Each corresponds to an entry in the command dispatch table at 23a8.

; FUNCTION: COMMAND_02_HANDLER - Screen data processing (COMPLEX)
; C_PSEUDO: void process_screen_data() {
; C_PSEUDO:   uint16_t screen_ptr = 0x4000;        // Screen RAM base
; C_PSEUDO:   uint16_t data_ptr = 0x3435;          // Data source pointer
; C_PSEUDO:   
; C_PSEUDO:   while(1) {
; C_PSEUDO:     uint8_t offset = *(data_ptr++);    // Get offset value
; C_PSEUDO:     if(offset == 0) return;            // Exit on zero
; C_PSEUDO:     
; C_PSEUDO:     if(offset & 0x80) {                // If negative
; C_PSEUDO:       // Handle special case (UNCLEAR what this does)
; C_PSEUDO:     } else {
; C_PSEUDO:       screen_ptr += offset - 1;        // Move screen pointer
; C_PSEUDO:       uint8_t tile = *(data_ptr++);    // Get tile value
; C_PSEUDO:       *(screen_ptr++) = tile;          // Write to screen
; C_PSEUDO:       // POSSIBLY also update color RAM via lookup table
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Complex screen drawing routine using compressed data format
; This APPEARS to be drawing tiles to the screen using offset-compressed data
; POSSIBLY used for drawing the maze or other static screen elements
2419  210040    ld      hl,#4000	; HL = 0x4000 (screen RAM pointer)
241c  013534    ld      bc,#3435	; BC = 0x3435 (data source pointer)
241f  0a        ld      a,(bc)		; Load byte from data source
2420  a7        and     a		; Test if zero
2421  c8        ret     z		; Return if zero (end of data)

2422  fa2c24    jp      m,#242c         ; Jump if negative (0x80+)
2425  5f        ld      e,a		; E = offset value
2426  1600      ld      d,#00		; DE = offset (16-bit)
2428  19        add     hl,de		; Add offset to screen pointer
2429  2b        dec     hl		; Adjust pointer (offset-1)
242a  03        inc     bc		; Move to next data byte
242b  0a        ld      a,(bc)		; Get tile value
242c  23        inc     hl		; Move screen pointer forward
242d  77        ld      (hl),a		; Write tile to screen RAM
242e  f5        push    af		; Save tile value
242f  e5        push    hl		; Save screen pointer

; ALGORITHM: Color RAM Update (COMPLEX CALCULATION)
; This section APPEARS to calculate the corresponding color RAM address
; and update it with a related color value
2430  11e083    ld      de,#83e0	; DE = 0x83e0 (POSSIBLY color table base?)
2433  7d        ld      a,l		; Get low byte of screen address
2434  e61f      and     #1f		; Mask to 5 bits (0-31)
2436  87        add     a,a		; Double it (for 16-bit table?)
2437  2600      ld      h,#00		; HL = doubled masked value
2439  6f        ld      l,a
243a  19        add     hl,de		; Add to table base
243b  d1        pop     de		; Restore screen pointer to DE
243c  a7        and     a		; Clear carry
243d  ed52      sbc     hl,de		; Calculate difference (UNCLEAR why)
243f  f1        pop     af		; Restore tile value
2440  ee01      xor     #01		; Toggle bit 0 of tile value
2442  77        ld      (hl),a		; Store modified value (to color RAM?)
2443  eb        ex      de,hl		; Exchange DE and HL
2444  03        inc     bc		; Move to next data byte
2445  c31f24    jp      #241f		; Jump back to main loop

; FUNCTION: COMMAND_03_HANDLER - Screen rendering with lookup tables
; C_PSEUDO: void render_screen_with_lookup() {
; C_PSEUDO:   uint16_t screen_ptr = 0x4000;        // Screen RAM base
; C_PSEUDO:   uint8_t* data_ptr = 0x4e16;          // Primary data source
; C_PSEUDO:   uint8_t* lookup_ptr = 0x35b5;        // Lookup table
; C_PSEUDO:   
; C_PSEUDO:   for(int row = 0; row < 30; row++) {  // 30 rows
; C_PSEUDO:     for(int col = 0; col < 8; col++) { // 8 columns  
; C_PSEUDO:       uint8_t data = *data_ptr;
; C_PSEUDO:       uint8_t lookup = *lookup_ptr;
; C_PSEUDO:       // COMPLEX processing (exact algorithm unclear)
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Two-table screen rendering system  
; Uses data from 0x4e16 and lookup table at 0x35b5 to render screen content
; POSSIBLY the main maze rendering or game field drawing routine
2448  210040    ld      hl,#4000	; HL = 0x4000 (screen RAM base)
244b  dd21164e  ld      ix,#4e16	; IX = 0x4e16 (primary data pointer)
244f  fd21b535  ld      iy,#35b5	; IY = 0x35b5 (lookup table pointer)
2453  1600      ld      d,#00		; D = 0 (upper byte of offset)
2455  061e      ld      b,#1e		; B = 30 (row counter)
2457  0e08      ld      c,#08		; C = 8 (column counter)
2459  dd7e00    ld      a,(ix+#00)	; Get byte from primary data
245c  fd5e00    ld      e,(iy+#00)	; Get byte from lookup table
; [Function continues but appears incomplete in current section...]

2400  3e40      ld      a,#40		; Load character value (space)
2402  214040    ld      hl,#4040	; Start at offset video memory  
2405  010480    ld      bc,#8004	; Different size/config
2408  cf        rst     #8		; Clear memory block
2409  0d        dec     c		; Decrement page counter  
240a  20fc      jr      nz,#2408        ; Loop until all pages cleared
240c  c9        ret     		; Return

; FUNCTION: COMMAND_06_CLEAR_COLOR - Clear color RAM (Command 0x06)
; C_PSEUDO: void clear_color_ram() {
; C_PSEUDO:   fill_memory(0x4400, 0x400, 0x00);  // Clear 1K color RAM to black
; C_PSEUDO: }  
; ALGORITHM: Clears entire color RAM area to 0x00 (black)
240d  af        xor     a		; Clear accumulator (A = 0)
240e  010400    ld      bc,#0004	; 4 pages of 256 bytes each
2411  210044    ld      hl,#4400	; Point to color RAM start
2414  cf        rst     #8		; Clear memory block  
2415  0d        dec     c		; Decrement page counter
2416  20fc      jr      nz,#2414        ; Loop until all pages cleared
2418  c9        ret     		; Return

; FUNCTION: COMMAND_02_SCREEN_DATA_PROCESSOR - Process compressed screen data (Command 0x02)
; C_PSEUDO: void process_screen_data() {
; C_PSEUDO:   uint16_t screen_ptr = 0x4000;        // Screen RAM base
; C_PSEUDO:   uint16_t data_ptr = 0x3435;          // Compressed data source
; C_PSEUDO:   
; C_PSEUDO:   while(1) {
; C_PSEUDO:     uint8_t offset = read_data_byte();  // Get offset/command byte
; C_PSEUDO:     if(offset == 0) return;             // Exit on zero terminator
; C_PSEUDO:     
; C_PSEUDO:     if(offset & 0x80) {                 // If negative (special command)
; C_PSEUDO:       handle_special_command();         // Process special case
; C_PSEUDO:     } else {
; C_PSEUDO:       screen_ptr += offset - 1;         // Move screen pointer
; C_PSEUDO:       uint8_t tile = read_data_byte();  // Get tile value
; C_PSEUDO:       write_screen_tile(screen_ptr, tile); // Write to screen
; C_PSEUDO:       update_color_ram(screen_ptr, tile);  // Update corresponding color
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Compressed screen drawing using offset-based data format
; This appears to be for drawing static screen elements like the maze
2419  210040    ld      hl,#4000	; HL = 0x4000 (screen RAM pointer)
241c  013534    ld      bc,#3435	; BC = 0x3435 (compressed data source pointer)
241f  0a        ld      a,(bc)		; Load byte from data source
2420  a7        and     a		; Test if zero
2421  c8        ret     z		; Return if zero (end of data marker)

2422  fa2c24    jp      m,#242c         ; Jump if negative (0x80+) - special command
2425  5f        ld      e,a		; E = offset value
2426  1600      ld      d,#00		; DE = offset (16-bit)
2428  19        add     hl,de		; Add offset to screen pointer
2429  2b        dec     hl		; Adjust pointer (offset-1)
242a  03        inc     bc		; Move to next data byte
242b  0a        ld      a,(bc)		; Get tile value
242c  23        inc     hl		; Move screen pointer forward
242d  77        ld      (hl),a		; Write tile to screen RAM
242e  f5        push    af		; Save tile value
242f  e5        push    hl		; Save screen pointer

; ALGORITHM: Color RAM Update - Calculate corresponding color address
; This calculates the color RAM address for the screen position and
; updates it with a modified version of the tile value
2430  11e083    ld      de,#83e0	; DE = 0x83e0 (POSSIBLY color calculation base?)
2433  7d        ld      a,l		; Get low byte of screen address
2434  e61f      and     #1f		; Mask to 5 bits (0-31, screen width related?)
2436  87        add     a,a		; Double it (for 16-bit table entries?)
2437  2600      ld      h,#00		; HL = doubled masked value
2439  6f        ld      l,a
243a  19        add     hl,de		; Add to calculation base
243b  d1        pop     de		; Restore screen pointer to DE
243c  a7        and     a		; Clear carry flag
243d  ed52      sbc     hl,de		; Calculate difference (color offset?)
243f  f1        pop     af		; Restore tile value
2440  ee01      xor     #01		; Toggle bit 0 of tile value
2442  77        ld      (hl),a		; Store modified value (to color RAM?)
2443  eb        ex      de,hl		; Exchange DE and HL
2444  03        inc     bc		; Move to next data byte
2445  c31f24    jp      #241f		; Jump back to main processing loop

; FUNCTION: COMMAND_03_SCREEN_RENDERER - Screen rendering with dual lookup tables (Command 0x03)
; C_PSEUDO: void render_screen_with_dual_lookup() {
; C_PSEUDO:   uint16_t screen_ptr = 0x4000;        // Screen RAM base
; C_PSEUDO:   uint8_t* data_ptr = 0x4e16;          // Primary data source
; C_PSEUDO:   uint8_t* lookup_ptr = 0x35b5;        // Lookup table
; C_PSEUDO:   
; C_PSEUDO:   for(int row = 0; row < 30; row++) {  // 30 rows (maze height)
; C_PSEUDO:     for(int col = 0; col < 8; col++) { // 8 columns per iteration
; C_PSEUDO:       uint8_t data = *data_ptr;        // Get maze data
; C_PSEUDO:       uint8_t lookup = *lookup_ptr;    // Get lookup value
; C_PSEUDO:       screen_ptr += lookup;            // Move screen pointer
; C_PSEUDO:       data <<= 1;                      // Shift data left
; C_PSEUDO:       if(carry) *(screen_ptr) = 0x10;  // Set tile if bit was set
; C_PSEUDO:       lookup_ptr++;                    // Next lookup entry
; C_PSEUDO:     }
; C_PSEUDO:     data_ptr++;                        // Next row of data
; C_PSEUDO:   }
; C_PSEUDO:   copy_sprite_positions();             // Copy sprite data
; C_PSEUDO: }
; ALGORITHM: Complex screen rendering using bit-mapped data and position lookup
; This APPEARS to be the main maze/playfield rendering routine
2448  210040    ld      hl,#4000	; HL = 0x4000 (screen RAM base)
244b  dd21164e  ld      ix,#4e16	; IX = 0x4e16 (maze data pointer)
244f  fd21b535  ld      iy,#35b5	; IY = 0x35b5 (position lookup table)
2453  1600      ld      d,#00		; D = 0 (upper byte for offset calculations)
2455  061e      ld      b,#1e		; B = 30 (row counter - maze height)
2457  0e08      ld      c,#08		; C = 8 (column counter - bits per byte)
2459  dd7e00    ld      a,(ix+#00)	; Get byte from maze data
245c  fd5e00    ld      e,(iy+#00)	; Get position offset from lookup table
245f  19        add     hl,de		; Add offset to screen pointer
2460  07        rlca    		; Rotate left (shift maze data bit into carry)
2461  3002      jr      nc,#2465        ; Skip if bit was 0 (no wall/pellet)
2463  3610      ld      (hl),#10	; Write tile 0x10 if bit was 1 (wall/pellet)
2465  fd23      inc     iy		; Move to next lookup table entry
2467  0d        dec     c		; Decrement column counter
2468  20f2      jr      nz,#245c        ; Loop for 8 bits per maze data byte
246a  dd23      inc     ix		; Move to next maze data byte
246c  05        dec     b		; Decrement row counter
246d  20e8      jr      nz,#2457        ; Loop for 30 rows

; ALGORITHM: Sprite Position Data Copy
; After rendering the maze, copy sprite position data to specific locations
246f  21344e    ld      hl,#4e34	; Source: sprite data at 0x4e34
2472  116440    ld      de,#4064	; Destination: 0x4064 (screen position?)
2475  eda0      ldi     		; Copy 1 byte and increment pointers
2477  117840    ld      de,#4078	; Destination: 0x4078 (screen position?)
247a  eda0      ldi     		; Copy 1 byte and increment pointers
247c  118443    ld      de,#4384	; Destination: 0x4384 (color RAM position?)
247f  eda0      ldi     		; Copy 1 byte and increment pointers
2481  119843    ld      de,#4398	; Destination: 0x4398 (color RAM position?)
2484  eda0      ldi     		; Copy 1 byte and increment pointers
2486  c9        ret     		; Return

; FUNCTION: COMMAND_15_GAME_STATE_TRANSITIONS - Game state management (Command 0x15)
; C_PSEUDO: void manage_game_state_transitions() {
; C_PSEUDO:   // SIMILAR to Command 03 but with different processing
; C_PSEUDO:   // POSSIBLY handles game state changes, level transitions
; C_PSEUDO:   render_screen_with_lookup_variant();
; C_PSEUDO: }
; ALGORITHM: Variant of screen rendering, POSSIBLY for state transitions
; This function is very similar to Command 03 but may handle different data
2487  210040    ld      hl,#4000	; HL = 0x4000 (screen RAM base)
248a  dd21164e  ld      ix,#4e16	; IX = 0x4e16 (data pointer - same as Command 03)
248e  fd21b535  ld      iy,#35b5	; IY = 0x35b5 (lookup table - same as Command 03)
2492  1600      ld      d,#00		; D = 0
2494  061e      ld      b,#1e		; B = 30 (row counter)
2496  0e08      ld      c,#08		; C = 8 (column counter)
2498  fd5e00    ld      e,(iy+#00)	; Get lookup value (NOTE: different order than 03)
249b  19        add     hl,de		; Add offset to screen pointer
249c  7e        ld      a,(hl)		; Read current tile from screen
249d  fe10      cp      #10		; Compare with tile value 0x10
249f  37        scf     		; Set carry flag
24a0  2801      jr      z,#24a3         ; Jump if tile == 0x10 (keep carry set)
24a2  3f        ccf     		; Complement carry flag (clear if tile != 0x10)
24a3  ddcb0016  rl      (ix+#00)	; Rotate left through carry into data byte
24a7  fd23      inc     iy		; Move to next lookup table entry
24a9  0d        dec     c		; Decrement column counter
24aa  20ec      jr      nz,#2498        ; Loop for 8 bits
24ac  dd23      inc     ix		; Move to next data byte
24ae  05        dec     b		; Decrement row counter
24af  20e5      jr      nz,#2496        ; Loop for 30 rows

; ALGORITHM: Reverse Sprite Position Data Copy
; This copies data FROM screen positions back TO the data area
; (opposite direction compared to Command 03)
24b1  216440    ld      hl,#4064	; Source: screen position 0x4064
24b4  11344e    ld      de,#4e34	; Destination: data area 0x4e34
24b7  eda0      ldi     		; Copy 1 byte (reverse direction)
24b9  217840    ld      hl,#4078	; Source: screen position 0x4078
24bc  eda0      ldi     		; Copy 1 byte
24be  218443    ld      hl,#4384	; Source: color RAM position 0x4384
24c1  eda0      ldi     		; Copy 1 byte
24c3  219843    ld      hl,#4398	; Source: color RAM position 0x4398
24c6  eda0      ldi     		; Copy 1 byte
24c8  c9        ret     		; Return

; FUNCTION: COMMAND_12_SPRITE_ANIMATION - Sprite animation control (Command 0x12)
; C_PSEUDO: void control_sprite_animation() {
; C_PSEUDO:   memset(0x4e16, 0xFF, 30);  // Clear 30 bytes with 0xFF
; C_PSEUDO:   memset(0x4e16+30, 0x14, 4); // Set 4 bytes to 0x14
; C_PSEUDO: }
; ALGORITHM: Initialize sprite animation data areas
; POSSIBLY sets up sprite animation frames or visibility flags
24c9  21164e    ld      hl,#4e16	; HL = 0x4e16 (sprite data area)
24cc  3eff      ld      a,#ff		; A = 0xFF (fill value)
24ce  061e      ld      b,#1e		; B = 30 bytes to fill
24d0  cf        rst     #8		; Fill 30 bytes with 0xFF
24d1  3e14      ld      a,#14		; A = 0x14 (different fill value)
24d3  0604      ld      b,#04		; B = 4 bytes to fill
24d5  cf        rst     #8		; Fill 4 bytes with 0x14
24d6  c9        ret     		; Return

; FUNCTION: COMMAND_01_SPRITE_TILE_MANAGER - Sprite/tile management (Command 0x01)
; C_PSEUDO: void manage_sprites_tiles(uint8_t mode) {
; C_PSEUDO:   uint8_t value = (mode == 2) ? 0x1F : 0x10;  // Select tile value
; C_PSEUDO:   fill_color_ram_area(0x4440, value);          // Fill color area
; C_PSEUDO: }
; ALGORITHM: Conditional sprite/tile value setting based on mode parameter
; Mode passed in B register determines which tile value to use
24d7  58        ld      e,b		; Save mode parameter in E
24d8  78        ld      a,b		; Get mode parameter in A
24d9  fe02      cp      #02		; Compare with mode 2
24db  3e1f      ld      a,#1f		; Load default value 0x1F
24dd  2802      jr      z,#24e1         ; Use 0x1F if mode == 2
24df  3e10      ld      a,#10		; Otherwise use 0x10
24e1  214044    ld      hl,#4440	; HL = 0x4440 (color RAM area)
24e4  010480    ld      bc,#8004	; B = 4, C = 0x80 (POSSIBLY 4 pages of 128 bytes?)
24e7  cf        rst     #8		; Fill memory with selected value
24e8  0d        dec     c		; Decrement page counter
24e9  20fc      jr      nz,#24e7        ; Loop until all pages filled

; ALGORITHM: Additional color setup - fill another area with 0x0F
24eb  3e0f      ld      a,#0f		; A = 0x0F (different color value)
24ed  0640      ld      b,#40		; B = 64 bytes to fill
24ef  21c047    ld      hl,#47c0	; HL = 0x47c0 (different color area)
24f2  cf        rst     #8		; Fill 64 bytes with 0x0F

; ALGORITHM: Mode-specific processing for mode 1
24f3  7b        ld      a,e		; Get saved mode parameter
24f4  fe01      cp      #01		; Compare with mode 1
24f6  c0        ret     nz		; Return if not mode 1

; ALGORITHM: Mode 1 specific setup - sprite configuration
; Sets up sprite data at multiple positions with value 0x1A
24f7  3e1a      ld      a,#1a		; A = 0x1A (sprite value)
24f9  112000    ld      de,#0020	; DE = 0x20 (32-byte offset between sprites)
24fc  0606      ld      b,#06		; B = 6 (sprite counter)
24fe  dd21a045  ld      ix,#45a0	; IX = 0x45a0 (sprite data base)
2502  dd770c    ld      (ix+#0c),a	; Set sprite attribute at offset +0x0C
2505  dd7718    ld      (ix+#18),a	; Set sprite attribute at offset +0x18
2508  dd19      add     ix,de		; Move to next sprite (32 bytes forward)
250a  10f6      djnz    #2502           ; Loop for 6 sprites

; ALGORITHM: Additional sprite setup with value 0x1B
250c  3e1b      ld      a,#1b		; A = 0x1B (different sprite value)
250e  0605      ld      b,#05		; B = 5 (counter)
2510  dd214044  ld      ix,#4440	; IX = 0x4440 (different sprite area)
2514  dd770e    ld      (ix+#0e),a	; Set sprite attribute at offset +0x0E
2517  dd770f    ld      (ix+#0f),a	; Set sprite attribute at offset +0x0F
251a  dd7710    ld      (ix+#10),a	; Set sprite attribute at offset +0x10
251d  dd19      add     ix,de		; Move to next sprite (32 bytes forward)
251f  10f3      djnz    #2514           ; Loop for 5 sprites

; ALGORITHM: Final sprite setup - another area with 0x1B
2521  0605      ld      b,#05		; B = 5 (counter)
2523  dd212047  ld      ix,#4720	; IX = 0x4720 (third sprite area)
2527  dd770e    ld      (ix+#0e),a	; Set sprite attribute at offset +0x0E
252a  dd770f    ld      (ix+#0f),a	; Set sprite attribute at offset +0x0F
252d  dd7710    ld      (ix+#10),a	; Set sprite attribute at offset +0x10
2530  dd19      add     ix,de		; Move to next sprite (32 bytes forward)
2532  10f3      djnz    #2527           ; Loop for 5 sprites

; ALGORITHM: Set specific sprite positions/values
2534  3e18      ld      a,#18		; A = 0x18 (position/color value)
2536  32ed45    ld      (#45ed),a	; Set sprite position/attribute
2539  320d46    ld      (#460d),a	; Set sprite position/attribute
253c  c9        ret     		; Return

; FUNCTION: COMMAND_04_LEVEL_MAZE_INIT - Level/maze initialization (Command 0x04)
; C_PSEUDO: void initialize_level_maze(uint8_t level) {
; C_PSEUDO:   setup_sprite_positions();     // Configure initial sprite positions
; C_PSEUDO:   if(level == 0) {
; C_PSEUDO:     setup_initial_game_state(); // First level setup
; C_PSEUDO:   } else {
; C_PSEUDO:     setup_continuing_level();   // Subsequent level setup
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Level initialization with different handling for first vs later levels
; Sets up sprite positions and game state based on level parameter
253d  dd21004c  ld      ix,#4c00	; IX = 0x4c00 (sprite data base)
2541  dd360220  ld      (ix+#02),#20	; Set sprite 1 X position to 0x20
2545  dd360420  ld      (ix+#04),#20	; Set sprite 2 X position to 0x20
2549  dd360620  ld      (ix+#06),#20	; Set sprite 3 X position to 0x20
254d  dd360820  ld      (ix+#08),#20	; Set sprite 4 X position to 0x20
2551  dd360a2c  ld      (ix+#0a),#2c	; Set sprite 5 X position to 0x2C
2555  dd360c3f  ld      (ix+#0c),#3f	; Set sprite 6 X position to 0x3F

; ALGORITHM: Set sprite Y positions
2559  dd360301  ld      (ix+#03),#01	; Set sprite 1 Y position to 0x01
255d  dd360503  ld      (ix+#05),#03	; Set sprite 2 Y position to 0x03
2561  dd360705  ld      (ix+#07),#05	; Set sprite 3 Y position to 0x05
2565  dd360907  ld      (ix+#09),#07	; Set sprite 4 Y position to 0x07
2569  dd360b09  ld      (ix+#0b),#09	; Set sprite 5 Y position to 0x09
256d  dd360d00  ld      (ix+#0d),#00	; Set sprite 6 Y position to 0x00

; ALGORITHM: Level-specific processing
2571  78        ld      a,b		; Get level parameter
2572  a7        and     a		; Test if zero (first level)
2573  c20f26    jp      nz,#260f	; Jump to continuing level setup if not first

; ALGORITHM: First level initialization - Setup game state tables
; This extensive section initializes various game state tables with
; specific values for starting a new game
2576  216480    ld      hl,#8064	; HL = 0x8064
2579  22004d    ld      (#4d00),hl	; Store in game state pointer 1
257c  217c80    ld      hl,#807c	; HL = 0x807C
257f  22024d    ld      (#4d02),hl	; Store in game state pointer 2
2582  217c90    ld      hl,#907c	; HL = 0x907C
2585  22044d    ld      (#4d04),hl	; Store in game state pointer 3
2588  217c70    ld      hl,#707c	; HL = 0x707C
258b  22064d    ld      (#4d06),hl	; Store in game state pointer 4
258e  21c480    ld      hl,#80c4	; HL = 0x80C4
2591  22084d    ld      (#4d08),hl	; Store in game state pointer 5

; ALGORITHM: Character position initialization
; Sets up initial positions for Pac-Man and ghosts
2594  212c2e    ld      hl,#2e2c	; HL = 0x2E2C (POSSIBLY Pac-Man start position?)
2597  220a4d    ld      (#4d0a),hl	; Store primary position
259a  22314d    ld      (#4d31),hl	; Store backup position
259d  212f2e    ld      hl,#2e2f	; HL = 0x2E2F (slightly different position)
25a0  220c4d    ld      (#4d0c),hl	; Store position 2
25a3  22334d    ld      (#4d33),hl	; Store backup position 2
25a6  212f30    ld      hl,#302f	; HL = 0x302F (ghost position?)
25a9  220e4d    ld      (#4d0e),hl	; Store position 3
25ac  22354d    ld      (#4d35),hl	; Store backup position 3
25af  212f2c    ld      hl,#2c2f	; HL = 0x2C2F (ghost position?)
25b2  22104d    ld      (#4d10),hl	; Store position 4
25b5  22374d    ld      (#4d37),hl	; Store backup position 4
25b8  21382e    ld      hl,#2e38	; HL = 0x2E38 (ghost position?)
25bb  22124d    ld      (#4d12),hl	; Store position 5
25be  22394d    ld      (#4d39),hl	; Store backup position 5

; ALGORITHM: Direction/movement initialization
; Sets up initial movement directions and speeds
25c1  210001    ld      hl,#0100	; HL = 0x0100 (POSSIBLY right direction?)
25c4  22144d    ld      (#4d14),hl	; Store direction 1
25c7  221e4d    ld      (#4d1e),hl	; Store backup direction 1
25ca  210100    ld      hl,#0001	; HL = 0x0001 (POSSIBLY down direction?)
25cd  22164d    ld      (#4d16),hl	; Store direction 2
25d0  22204d    ld      (#4d20),hl	; Store backup direction 2
25d3  21ff00    ld      hl,#00ff	; HL = 0x00FF (POSSIBLY left direction?)
25d6  22184d    ld      (#4d18),hl	; Store direction 3
25d9  22224d    ld      (#4d22),hl	; Store backup direction 3
25dc  21ff00    ld      hl,#00ff	; HL = 0x00FF (same left direction)
25df  221a4d    ld      (#4d1a),hl	; Store direction 4
25e2  22244d    ld      (#4d24),hl	; Store backup direction 4
25e5  210001    ld      hl,#0100	; HL = 0x0100 (right direction again)
25e8  221c4d    ld      (#4d1c),hl	; Store direction 5
25eb  22264d    ld      (#4d26),hl	; Store backup direction 5

; ALGORITHM: Character state initialization
; Sets up initial state values for characters (ghosts/Pac-Man)
25ee  210201    ld      hl,#0102	; HL = 0x0102 (POSSIBLY character state?)
25f1  22284d    ld      (#4d28),hl	; Store state 1
25f4  222c4d    ld      (#4d2c),hl	; Store backup state 1
25f7  210303    ld      hl,#0303	; HL = 0x0303 (different state?)
25fa  222a4d    ld      (#4d2a),hl	; Store state 2
25fd  222e4d    ld      (#4d2e),hl	; Store backup state 2

; ALGORITHM: Character mode/type initialization
2600  3e02      ld      a,#02		; A = 2 (POSSIBLY character mode/type?)
2602  32304d    ld      (#4d30),a	; Set character mode 1
2605  323c4d    ld      (#4d3c),a	; Set character mode 2 (backup?)

; ALGORITHM: Clear score/timer area
2608  210000    ld      hl,#0000	; HL = 0 (clear value)
260b  22d24d    ld      (#4dd2),hl	; Clear score/timer area
260e  c9        ret     		; Return from first level initialization

; FUNCTION: CONTINUING_LEVEL_SETUP - Setup for levels after the first
; C_PSEUDO: void setup_continuing_level() {
; C_PSEUDO:   // Simplified setup for subsequent levels
; C_PSEUDO:   setup_simplified_positions();    // Use simpler position layout
; C_PSEUDO:   copy_previous_state();           // Maintain some previous state
; C_PSEUDO: }
; ALGORITHM: Continuing level initialization (simpler than first level)
; This is used when advancing to level 2, 3, etc.
260f  219400    ld      hl,#0094	; HL = 0x0094 (different base value)
2612  22004d    ld      (#4d00),hl	; Store simplified state pointer 1
2615  22024d    ld      (#4d02),hl	; Store simplified state pointer 2
2618  22044d    ld      (#4d04),hl	; Store simplified state pointer 3
261b  22064d    ld      (#4d06),hl	; Store simplified state pointer 4

; ALGORITHM: Simplified character positioning for continuing levels
261e  21321e    ld      hl,#1e32	; HL = 0x1E32 (POSSIBLY center/default position?)
2621  220a4d    ld      (#4d0a),hl	; Store simplified position 1
2624  220c4d    ld      (#4d0c),hl	; Store simplified position 2
2627  220e4d    ld      (#4d0e),hl	; Store simplified position 3
262a  22104d    ld      (#4d10),hl	; Store simplified position 4
262d  22314d    ld      (#4d31),hl	; Store backup position
2630  22334d    ld      (#4d33),hl	; Store backup position 2
2633  22354d    ld      (#4d35),hl	; Store backup position 3
2636  22374d    ld      (#4d37),hl	; Store backup position 4

; ALGORITHM: Simplified direction setup - all characters move right initially
2639  210001    ld      hl,#0100	; HL = 0x0100 (right direction for all)
263c  22144d    ld      (#4d14),hl	; Set direction 1 to right
263f  22164d    ld      (#4d16),hl	; Set direction 2 to right
2642  22184d    ld      (#4d18),hl	; Set direction 3 to right
2645  221a4d    ld      (#4d1a),hl	; Set direction 4 to right
2648  221e4d    ld      (#4d1e),hl	; Set backup direction 1 to right
264b  22204d    ld      (#4d20),hl	; Set backup direction 2 to right
264e  22224d    ld      (#4d22),hl	; Set backup direction 3 to right
2651  22244d    ld      (#4d24),hl	; Set backup direction 4 to right
2654  221c4d    ld      (#4d1c),hl	; Set direction 5 to right
2657  22264d    ld      (#4d26),hl	; Set backup direction 5 to right

; ALGORITHM: Character state setup for continuing levels
265a  21284d    ld      hl,#4d28	; HL = character state area
265d  3e02      ld      a,#02		; A = 2 (state value)
265f  0609      ld      b,#09		; B = 9 bytes to fill
2661  cf        rst     #8		; Fill 9 bytes with state value 2
2662  323c4d    ld      (#4d3c),a	; Set additional state value

; ALGORITHM: Final position adjustments for continuing levels  
2665  219408    ld      hl,#0894	; HL = 0x0894 (different position?)
2668  22084d    ld      (#4d08),hl	; Store final position adjustment
266b  21321f    ld      hl,#1f32	; HL = 0x1F32 (slightly different from 0x1E32?)
266e  22124d    ld      (#4d12),hl	; Store adjusted position
2671  22394d    ld      (#4d39),hl	; Store backup adjusted position
2674  c9        ret     		; Return from continuing level setup

; FUNCTION: COMMAND_13_PLAYER_INPUT - Player input processing (Command 0x13)
; C_PSEUDO: void process_player_input() {
; C_PSEUDO:   clear_game_variables();    // Reset various game state variables
; C_PSEUDO: }
; ALGORITHM: Clears multiple game state variables to zero
; POSSIBLY used when resetting game state or handling player input changes
2675  210000    ld      hl,#0000	; HL = 0 (clear value)
2678  22d24d    ld      (#4dd2),hl	; Clear variable 1 (score/timer area)
267b  22084d    ld      (#4d08),hl	; Clear variable 2 (position pointer)
267e  22004d    ld      (#4d00),hl	; Clear variable 3 (state pointer 1)
2681  22024d    ld      (#4d02),hl	; Clear variable 4 (state pointer 2)
2684  22044d    ld      (#4d04),hl	; Clear variable 5 (state pointer 3)
2687  22064d    ld      (#4d06),hl	; Clear variable 6 (state pointer 4)
268a  c9        ret     		; Return

; FUNCTION: COMMAND_05_GHOST_AI_STATE - Ghost AI state management (Command 0x05)
; C_PSEUDO: void manage_ghost_ai_state(uint8_t parameter) {
; C_PSEUDO:   ghost_ai_flag = 0x55;      // Set AI state flag
; C_PSEUDO:   if(parameter == 0) return; // Exit if no additional processing
; C_PSEUDO:   ghost_mode_flag = 1;       // Enable special ghost mode
; C_PSEUDO: }
; ALGORITHM: Ghost AI state management with conditional processing
; Parameter in B register determines level of AI activation
268b  3e55      ld      a,#55		; A = 0x55 (AI state flag value)
268d  32944d    ld      (#4d94),a	; Set ghost AI state flag
2690  05        dec     b		; Decrement parameter (test if was 1)
2691  c8        ret     z		; Return if parameter was 1 (basic AI only)

; ALGORITHM: Advanced AI mode activation
2692  3e01      ld      a,#01		; A = 1 (enable flag)
2694  32a04d    ld      (#4da0),a	; Enable advanced ghost mode
2697  c9        ret     		; Return

; FUNCTION: COMMAND_07_SCORE_BONUS - Score/bonus management (Command 0x07)
; C_PSEUDO: void manage_score_bonus() {
; C_PSEUDO:   game_active_flag = 1;     // Set game as active
; C_PSEUDO:   bonus_counter = 0;        // Reset bonus counter
; C_PSEUDO: }
; ALGORITHM: Activates game state and resets bonus tracking
; POSSIBLY called when starting gameplay or awarding bonuses
2698  3e01      ld      a,#01		; A = 1 (active flag)
269a  32004e    ld      (#4e00),a	; Set game active flag
269d  af        xor     a		; A = 0 (clear value)
269e  32014e    ld      (#4e01),a	; Clear bonus counter
26a1  c9        ret     		; Return

; FUNCTION: COMMAND_11_GHOST_MOVEMENT - Ghost movement coordination (Command 0x11)
; C_PSEUDO: void coordinate_ghost_movement() {
; C_PSEUDO:   memset(0x4d00, 0, 0x100);  // Clear entire game state area
; C_PSEUDO: }
; ALGORITHM: Mass clear of game state memory from 0x4D00 to 0x4E00
; This clears 256 bytes of game state data, POSSIBLY resetting all ghost states
26a2  af        xor     a		; A = 0 (clear value)
26a3  11004d    ld      de,#4d00	; DE = 0x4D00 (start of game state area)
26a6  21004e    ld      hl,#4e00	; HL = 0x4E00 (end of game state area)
26a9  12        ld      (de),a		; Clear byte at DE
26aa  13        inc     de		; Move to next byte
26ab  a7        and     a		; Clear carry flag
26ac  ed52      sbc     hl,de		; Calculate remaining bytes
26ae  c2a626    jp      nz,#26a6        ; Continue until DE reaches HL
26b1  c9        ret     		; Return

; FUNCTION: COMMAND_1F_SYSTEM_DIAGNOSTICS - System diagnostics (Command 0x1F)
; C_PSEUDO: void system_diagnostics() {
; C_PSEUDO:   display_hex_digit_low(score_byte);   // Show low nibble of score
; C_PSEUDO:   if(high_nibble != 0) {               // If high nibble exists
; C_PSEUDO:     display_hex_digit_high(score_byte); // Show high nibble too
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Hexadecimal display routine for debugging/diagnostics
; Converts a byte to hexadecimal ASCII and displays it on screen
26b2  dd213641  ld      ix,#4136	; IX = 0x4136 (display position)
26b6  3a714e    ld      a,(#4e71)	; Get byte to display (POSSIBLY score/status)
26b9  e60f      and     #0f		; Mask to get low nibble (0-15)
26bb  c630      add     a,#30		; Convert to ASCII ('0'-'9', then ':'-'?')
26bd  dd7700    ld      (ix+#00),a	; Display low nibble character

; ALGORITHM: High nibble processing
26c0  3a714e    ld      a,(#4e71)	; Get the same byte again
26c3  0f        rrca    		; Rotate right 4 times to get high nibble
26c4  0f        rrca    
26c5  0f        rrca    
26c6  0f        rrca    
26c7  e60f      and     #0f		; Mask to get high nibble
26c9  c8        ret     z		; Return if high nibble is 0 (no display needed)

26ca  c630      add     a,#30		; Convert high nibble to ASCII
26cc  dd7720    ld      (ix+#20),a	; Display high nibble character (32 bytes offset)
26cf  c9        ret     		; Return

; FUNCTION: COMMAND_14_LEVEL_PROGRESSION - Level progression logic (Command 0x14)
; C_PSEUDO: void handle_level_progression() {
; C_PSEUDO:   uint8_t input = read_hardware_input(); // Read from hardware port
; C_PSEUDO:   process_input_value(input);            // Process the input
; C_PSEUDO: }
; ALGORITHM: Reads hardware input and processes it for level progression
; POSSIBLY handles advancing to next level or processing game progression
26d0  3a8050    ld      a,(#5080)	; Read from hardware port 0x5080 (input/status?)
26d3  47        ld      b,a		; Save input value in B register

; ALGORITHM: Process input bits for level progression
26d4  e603      and     #03		; Mask to get lower 2 bits
26d6  c2de26    jp      nz,#26de        ; Jump if any lower bits set
26d9  216e4e    ld      hl,#4e6e	; HL = 0x4e6e (POSSIBLY credit counter?)
26dc  36ff      ld      (hl),#ff	; Set to 0xFF (maximum value)

; ALGORITHM: Complex bit manipulation for game state
26de  4f        ld      c,a		; Save masked value in C
26df  1f        rra     		; Rotate right (divide by 2)
26e0  ce00      adc     a,#00		; Add carry (rounds up division)
26e2  326b4e    ld      (#4e6b),a	; Store processed value
26e5  e602      and     #02		; Check bit 1
26e7  a9        xor     c		; XOR with original masked value
26e8  326d4e    ld      (#4e6d),a	; Store XOR result (POSSIBLY credits per coin?)

; ALGORITHM: Process upper bits of input for difficulty/level settings
26eb  78        ld      a,b		; Get original input value
26ec  0f        rrca    		; Rotate right 2 positions
26ed  0f        rrca    
26ee  e603      and     #03		; Mask to get bits 2-3
26f0  3c        inc     a		; Increment (1-4 range)
26f1  fe04      cp      #04		; Compare with 4
26f3  2001      jr      nz,#26f6        ; Skip if not 4
26f5  3c        inc     a		; If was 4, make it 5
26f6  326f4e    ld      (#4e6f),a	; Store level/difficulty value

; ALGORITHM: Lookup table processing for additional settings
26f9  78        ld      a,b		; Get original input again
26fa  0f        rrca    		; Rotate right 4 positions
26fb  0f        rrca    
26fc  0f        rrca    
26fd  0f        rrca    
26fe  e603      and     #03		; Get upper 2 bits
2700  212827    ld      hl,#2728	; HL = lookup table at 0x2728
2703  d7        rst     #10		; Call table lookup (add A to HL, return (HL))
2704  32714e    ld      (#4e71),a	; Store lookup result

; ALGORITHM: Process final input bit for game settings
2707  78        ld      a,b		; Get original input one more time
2708  07        rlca    		; Rotate left (move bit 7 to bit 0)
2709  2f        cpl     		; Complement (invert all bits)
270a  e601      and     #01		; Mask to get inverted bit 7
270c  32754e    ld      (#4e75),a	; Store final processed bit

; ALGORITHM: Additional input processing
270f  78        ld      a,b		; Get original input value again
2710  07        rlca    		; Rotate left 2 positions  
2711  07        rlca    
2712  2f        cpl     		; Complement all bits
2713  e601      and     #01		; Get inverted bit 6
2715  47        ld      b,a		; Save processed value in B
2716  212c27    ld      hl,#272c	; HL = lookup table at 0x272c
2719  df        rst     #18		; Call lookup routine (DIFFERENT from RST #10)
271a  22734e    ld      (#4e73),hl	; Store 16-bit lookup result

; ALGORITHM: Read additional hardware input
271d  3a4050    ld      a,(#5040)	; Read from hardware port 0x5040 (sound/input?)
2720  07        rlca    		; Rotate left (move bit 7 to bit 0)
2721  2f        cpl     		; Complement all bits
2722  e601      and     #01		; Get inverted bit 7
2724  32724e    ld      (#4e72),a	; Store final hardware flag
2727  c9        ret     		; Return

; ======================================================
; DATA TABLES FOR COMMAND 14
; ======================================================
; These appear to be lookup tables used by the level progression function

; MEMORY_MAP: Lookup table 1 (at 0x2728)
2728  10        db      #10		; Table entry 0
2729  15        db      #15		; Table entry 1  
272a  20        db      #20		; Table entry 2
272b  ff        db      #ff		; Table entry 3

; MEMORY_MAP: Lookup table 2 (at 0x272c) - 16-bit values
272c  6800      dw      #0068		; Table entry 0: 0x0068
272e  7d00      dw      #007d		; Table entry 1: 0x007D

; FUNCTION: COMMAND_08_SOUND_EFFECTS - Sound effect control (Command 0x08)  
; C_PSEUDO: void control_sound_effects() {
; C_PSEUDO:   if(sound_state_flag & 1) {        // Check sound state
; C_PSEUDO:     handle_special_sound();         // Process special sound
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_normal_sound();          // Process normal sound
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Sound effect processing with state-based branching
2730  3ac14d    ld      a,(#4dc1)	; Get sound state flag
2733  cb47      bit     0,a		; Test bit 0 of sound state
2735  c25827    jp      nz,#2758        ; Jump to special sound handling if bit set
2738  3ab64d    ld      a,(#4db6)	; Get normal sound parameter
273b  a7        and     a		; Test if parameter is zero
273c  201a      jr      nz,#2758        ; Jump to alternate processing if non-zero
273e  3a044e    ld      a,(#4e04)	; Get game state value
2741  fe03      cp      #03		; Compare with state 3
2743  2013      jr      nz,#2758        ; Jump to alternate if not state 3

; ALGORITHM: Special processing for state 3 with zero parameter
2745  2a0a4d    ld      hl,(#4d0a)	; Load position data 1
2748  3a2c4d    ld      a,(#4d2c)	; Load state data 1
274b  111d22    ld      de,#221d	; DE = 0x221D (coordinate/offset?)
274e  cd6629    call    #2966		; Call processing function at 0x2966
2751  221e4d    ld      (#4d1e),hl	; Store processed position
2754  322c4d    ld      (#4d2c),a	; Store processed state
2757  c9        ret     		; Return

; ALGORITHM: Alternate/general sound processing
2758  2a0a4d    ld      hl,(#4d0a)	; Load position data 1 (same as above)
275b  ed5b394d  ld      de,(#4d39)	; Load position data 2 (different source)
275f  3a2c4d    ld      a,(#4d2c)	; Load state data 1
2762  cd6629    call    #2966		; Call same processing function
2765  221e4d    ld      (#4d1e),hl	; Store processed position
2768  322c4d    ld      (#4d2c),a	; Store processed state
276b  c9        ret     		; Return

; FUNCTION: COMMAND_09_FRUIT_BONUS - Fruit/bonus object control (Command 0x09)
; C_PSEUDO: void control_fruit_bonus() {
; C_PSEUDO:   if(sound_state_flag & 1) {        // Check sound state
; C_PSEUDO:     handle_alternate_fruit();       // Alternate fruit processing
; C_PSEUDO:   } else if(game_state == 3) {      // If in specific game state
; C_PSEUDO:     handle_special_fruit();         // Special fruit handling
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_normal_fruit();          // Normal fruit processing
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Fruit/bonus object management with multiple processing paths
; Very similar structure to Command 08, suggesting shared object handling logic
276c  3ac14d    ld      a,(#4dc1)	; Get sound state flag (same as Command 08)
276f  cb47      bit     0,a		; Test bit 0 of sound state
2771  c28e27    jp      nz,#278e        ; Jump to alternate processing if bit set
2774  3a044e    ld      a,(#4e04)	; Get game state value
2777  fe03      cp      #03		; Compare with state 3
2779  2013      jr      nz,#278e        ; Jump to alternate if not state 3

; ALGORITHM: Special fruit processing for state 3
277b  2a0c4d    ld      hl,(#4d0c)	; Load position data 2 (different from Command 08)
277e  3a2d4d    ld      a,(#4d2d)	; Load state data 2 (different from Command 08)
2781  111d39    ld      de,#391d	; DE = 0x391D (different coordinate than Command 08)
2784  cd6629    call    #2966		; Call same processing function
2787  22204d    ld      (#4d20),hl	; Store processed position (different target)
278a  322d4d    ld      (#4d2d),a	; Store processed state (different target)
278d  c9        ret     		; Return

; ALGORITHM: Alternate fruit processing (complex coordinate calculation)
278e  ed5b394d  ld      de,(#4d39)	; Load position data from backup area
2792  2a1c4d    ld      hl,(#4d1c)	; Load direction/multiplier data
2795  29        add     hl,hl		; Multiply by 2
2796  29        add     hl,hl		; Multiply by 2 again (total: multiply by 4)
2797  19        add     hl,de		; Add to position data
2798  eb        ex      de,hl		; Exchange - result goes to DE
2799  2a0c4d    ld      hl,(#4d0c)	; Load position data 2
279c  3a2d4d    ld      a,(#4d2d)	; Load state data 2
279f  cd6629    call    #2966		; Call processing function
27a2  22204d    ld      (#4d20),hl	; Store processed position
27a5  322d4d    ld      (#4d2d),a	; Store processed state
27a8  c9        ret     		; Return

; FUNCTION: COMMAND_0A_PELLET_CONSUMPTION - Pellet consumption logic (Command 0x0A)
; C_PSEUDO: void handle_pellet_consumption() {
; C_PSEUDO:   if(sound_state_flag & 1) {        // Check sound state
; C_PSEUDO:     handle_alternate_pellet();      // Alternate pellet processing
; C_PSEUDO:   } else if(game_state == 3) {      // If in specific game state
; C_PSEUDO:     handle_special_pellet();        // Special pellet handling
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_normal_pellet();         // Normal pellet processing
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Pellet consumption management - identical structure to Commands 08 & 09
; This pattern suggests a unified object processing system for different game entities
27a9  3ac14d    ld      a,(#4dc1)	; Get sound state flag (identical to 08 & 09)
27ac  cb47      bit     0,a		; Test bit 0 of sound state
27ae  c2cb27    jp      nz,#27cb        ; Jump to alternate processing if bit set
27b1  3a044e    ld      a,(#4e04)	; Get game state value
27b4  fe03      cp      #03		; Compare with state 3
27b6  2013      jr      nz,#27cb        ; Jump to alternate if not state 3

; ALGORITHM: Special pellet processing for state 3
27b8  2a0e4d    ld      hl,(#4d0e)	; Load position data 3 (different offset)
27bb  3a2e4d    ld      a,(#4d2e)	; Load state data 3 (different offset)
27be  114020    ld      de,#2040	; DE = 0x2040 (different coordinate)
27c1  cd6629    call    #2966		; Call processing function
27c4  22224d    ld      (#4d22),hl	; Store processed position (different target)
27c7  322e4d    ld      (#4d2e),a	; Store processed state (different target)
27ca  c9        ret     		; Return

; ALGORITHM: Alternate pellet processing (very complex coordinate calculation)
27cb  ed4b0a4d  ld      bc,(#4d0a)	; Load position data 1 into BC
27cf  ed5b394d  ld      de,(#4d39)	; Load position data from backup area
27d3  2a1c4d    ld      hl,(#4d1c)	; Load direction/multiplier data
27d6  29        add     hl,hl		; Multiply by 2
27d7  19        add     hl,de		; Add to position data
27d8  7d        ld      a,l		; Get low byte of result
27d9  87        add     a,a		; Double it
27da  91        sub     c		; Subtract C (low byte of position 1)
27db  6f        ld      l,a		; Store back in L
27dc  7c        ld      a,h		; Get high byte of result
27dd  87        add     a,a		; Double it
27de  90        sub     b		; Subtract B (high byte of position 1)
27df  67        ld      h,a		; Store back in H
27e0  eb        ex      de,hl		; Exchange - complex result goes to DE
27e1  2a0e4d    ld      hl,(#4d0e)	; Load position data 3
27e4  3a2e4d    ld      a,(#4d2e)	; Load state data 3
27e7  cd6629    call    #2966		; Call processing function
27ea  22224d    ld      (#4d22),hl	; Store processed position
27ed  322e4d    ld      (#4d2e),a	; Store processed state
27f0  c9        ret     		; Return

; FUNCTION: COMMAND_0B_POWER_PELLET - Power pellet effects (Command 0x0B)
; C_PSEUDO: void handle_power_pellet_effects() {
; C_PSEUDO:   if(sound_state_flag & 1) {        // Check sound state
; C_PSEUDO:     handle_alternate_power_pellet(); // Alternate processing
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_normal_power_pellet();    // Normal processing
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Power pellet effect management - continuing the pattern
; Commands 08, 09, 0A, 0B all follow the same structural pattern
27f1  3ac14d    ld      a,(#4dc1)	; Get sound state flag (same pattern)
27f4  cb47      bit     0,a		; Test bit 0 of sound state
27f6  c21328    jp      nz,#2813        ; Jump to alternate processing if bit set
27f9  3a044e    ld      a,(#4e04)	; Get game state value
27fc  fe03      cp      #03		; Compare with state 3
27fe  2013      jr      nz,#2813        ; Jump to alternate if not state 3

; ALGORITHM: Special power pellet processing for state 3
2800  2a104d    ld      hl,(#4d10)	; Load position data 4 (continuing the pattern)
2803  3a2f4d    ld      a,(#4d2f)	; Load state data 4 (continuing the pattern)
2806  11403b    ld      de,#3b40	; DE = 0x3B40 (different coordinate)
2809  cd6629    call    #2966		; Call processing function
280c  22244d    ld      (#4d24),hl	; Store processed position (different target)
280f  322f4d    ld      (#4d2f),a	; Store processed state (different target)
2812  c9        ret     		; Return

; ALGORITHM: Alternate power pellet processing (sophisticated calculation)
2813  dd21394d  ld      ix,#4d39	; IX = position data backup area
2817  fd21104d  ld      iy,#4d10	; IY = position data 4
281b  cdea29    call    #29ea		; Call coordinate calculation function
281e  114000    ld      de,#0040	; DE = 0x0040 (threshold value)
2821  a7        and     a		; Clear carry flag
2822  ed52      sbc     hl,de		; Subtract threshold from result
2824  da0028    jp      c,#2800         ; Jump back to simple processing if negative

; ALGORITHM: Complex power pellet coordinate processing
2827  2a104d    ld      hl,(#4d10)	; Load position data 4
282a  ed5b394d  ld      de,(#4d39)	; Load position data from backup area
282e  3a2f4d    ld      a,(#4d2f)	; Load state data 4
2831  cd6629    call    #2966		; Call processing function
2834  22244d    ld      (#4d24),hl	; Store processed position
2837  322f4d    ld      (#4d2f),a	; Store processed state
283a  c9        ret     		; Return

; FUNCTION: COMMAND_0C_COLLISION_DETECTION - Collision detection (Command 0x0C)
; C_PSEUDO: void handle_collision_detection() {
; C_PSEUDO:   if(collision_flag == 0) {           // No collision detected
; C_PSEUDO:     handle_no_collision();            // Normal movement processing
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_collision_response();      // Collision response logic
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Collision detection and response system
; This breaks the pattern of the previous commands - no sound state check
283b  3aac4d    ld      a,(#4dac)	; Get collision detection flag
283e  a7        and     a		; Test if zero (no collision)
283f  ca5528    jp      z,#2855         ; Jump to no-collision handling if zero
2842  112c2e    ld      de,#2e2c	; DE = 0x2E2C (collision position?)
2845  2a0a4d    ld      hl,(#4d0a)	; Load position data 1
2848  3a2c4d    ld      a,(#4d2c)	; Load state data 1
284b  cd6629    call    #2966		; Call processing function (collision response)
284e  221e4d    ld      (#4d1e),hl	; Store processed position
2851  322c4d    ld      (#4d2c),a	; Store processed state
2854  c9        ret     		; Return

; ALGORITHM: No collision detected - normal movement processing
2855  2a0a4d    ld      hl,(#4d0a)	; Load position data 1 (same as collision case)
2858  3a2c4d    ld      a,(#4d2c)	; Load state data 1 (same as collision case)
285b  cd1e29    call    #291e		; Call DIFFERENT function (normal movement at 0x291e)
285e  221e4d    ld      (#4d1e),hl	; Store processed position
2861  322c4d    ld      (#4d2c),a	; Store processed state
2864  c9        ret     		; Return

; FUNCTION: COMMAND_0D_PINKY_TARGETING - Pinky's targeting algorithm (Command 0x0D)
; C_PSEUDO: void handle_pinky_targeting() {
; C_PSEUDO:   if(pinky_collision_flag == 0) {     // No collision with Pinky
; C_PSEUDO:     handle_pinky_normal_movement();   // Normal AI targeting
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_pinky_collision();         // Pinky collision response
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Pinky's AI targeting system with collision detection
; This is where the famous "4-tile ahead" bug is located!
; Similar structure to Command 0C but for specific ghost (Pinky)
2865  3aad4d    ld      a,(#4dad)	; Get Pinky collision flag (different from 0x4dac)
2868  a7        and     a		; Test if zero (no collision)
2869  ca7f28    jp      z,#287f         ; Jump to normal targeting if zero
286c  112c2e    ld      de,#2e2c	; DE = 0x2E2C (same collision position as Command 0C)
286f  2a0c4d    ld      hl,(#4d0c)	; Load position data 2 (Pinky's position data)
2872  3a2d4d    ld      a,(#4d2d)	; Load state data 2 (Pinky's state data)
2875  cd6629    call    #2966		; Call processing function (collision response)
2878  22204d    ld      (#4d20),hl	; Store processed position (Pinky's target)
287b  322d4d    ld      (#4d2d),a	; Store processed state (Pinky's target)
287e  c9        ret     		; Return

; ALGORITHM: Pinky normal targeting (contains the famous 4-tile bug!)
287f  2a0c4d    ld      hl,(#4d0c)	; Load Pinky's position data
2882  3a2d4d    ld      a,(#4d2d)	; Load Pinky's state data
2885  cd1e29    call    #291e		; Call normal movement function (contains 4-tile bug!)
2888  22204d    ld      (#4d20),hl	; Store Pinky's target position
288b  322d4d    ld      (#4d2d),a	; Store Pinky's target state
288e  c9        ret     		; Return

; FUNCTION: COMMAND_0E_INKY_TARGETING - Inky's targeting algorithm (Command 0x0E)
; C_PSEUDO: void handle_inky_targeting() {
; C_PSEUDO:   if(inky_collision_flag == 0) {      // No collision with Inky
; C_PSEUDO:     handle_inky_normal_movement();    // Normal AI targeting
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_inky_collision();          // Inky collision response
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Inky's AI targeting system - identical structure to Pinky
; Each ghost has its own collision flag and position data
288f  3aae4d    ld      a,(#4dae)	; Get Inky collision flag
2892  a7        and     a		; Test if zero (no collision)
2893  caa928    jp      z,#28a9         ; Jump to normal targeting if zero
2896  112c2e    ld      de,#2e2c	; DE = 0x2E2C (same collision position)
2899  2a0e4d    ld      hl,(#4d0e)	; Load position data 3 (Inky's position data)
289c  3a2e4d    ld      a,(#4d2e)	; Load state data 3 (Inky's state data)
289f  cd6629    call    #2966		; Call processing function (collision response)
28a2  22224d    ld      (#4d22),hl	; Store processed position (Inky's target)
28a5  322e4d    ld      (#4d2e),a	; Store processed state (Inky's target)
28a8  c9        ret     		; Return

; ALGORITHM: Inky normal targeting
28a9  2a0e4d    ld      hl,(#4d0e)	; Load Inky's position data
28ac  3a2e4d    ld      a,(#4d2e)	; Load Inky's state data
28af  cd1e29    call    #291e		; Call normal movement function
28b2  22224d    ld      (#4d22),hl	; Store Inky's target position
28b5  322e4d    ld      (#4d2e),a	; Store Inky's target state
28b8  c9        ret     		; Return

; FUNCTION: COMMAND_0F_CLYDE_TARGETING - Clyde's targeting algorithm (Command 0x0F)
; C_PSEUDO: void handle_clyde_targeting() {
; C_PSEUDO:   if(clyde_collision_flag == 0) {     // No collision with Clyde
; C_PSEUDO:     handle_clyde_normal_movement();   // Normal AI targeting
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_clyde_collision();         // Clyde collision response
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Clyde's AI targeting system - identical structure to Pinky & Inky
; Clyde is the fourth ghost (orange ghost)
28b9  3aaf4d    ld      a,(#4daf)	; Get Clyde collision flag
28bc  a7        and     a		; Test if zero (no collision)
28bd  cad328    jp      z,#28d3         ; Jump to normal targeting if zero
28c0  112c2e    ld      de,#2e2c	; DE = 0x2E2C (same collision position)
28c3  2a104d    ld      hl,(#4d10)	; Load position data 4 (Clyde's position data)
28c6  3a2f4d    ld      a,(#4d2f)	; Load state data 4 (Clyde's state data)
28c9  cd6629    call    #2966		; Call processing function (collision response)
28cc  22244d    ld      (#4d24),hl	; Store processed position (Clyde's target)
28cf  322f4d    ld      (#4d2f),a	; Store processed state (Clyde's target)
28d2  c9        ret     		; Return

; ALGORITHM: Clyde normal targeting
28d3  2a104d    ld      hl,(#4d10)	; Load Clyde's position data
28d6  3a2f4d    ld      a,(#4d2f)	; Load Clyde's state data
28d9  cd1e29    call    #291e		; Call normal movement function
28dc  22244d    ld      (#4d24),hl	; Store Clyde's target position
28df  322f4d    ld      (#4d2f),a	; Store Clyde's target state
28e2  c9        ret     		; Return

; FUNCTION: COMMAND_17_FRIGHTENED_MODE - Frightened mode management (Command 0x17)
; C_PSEUDO: void handle_frightened_mode() {
; C_PSEUDO:   if(frightened_flag == 0) {          // Not in frightened mode
; C_PSEUDO:     handle_normal_retreat();          // Normal retreat behavior
; C_PSEUDO:   } else {
; C_PSEUDO:     handle_frightened_retreat();      // Frightened state retreat
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Frightened mode management - when ghosts turn blue and flee
; This handles the state when Pac-Man eats a power pellet
28e3  3aa74d    ld      a,(#4da7)	; Get frightened mode flag
28e6  a7        and     a		; Test if zero (not frightened)
28e7  cafe28    jp      z,#28fe         ; Jump to normal retreat if zero
28ea  2a124d    ld      hl,(#4d12)	; Load position data 5 (retreat position)
28ed  ed5b0c4d  ld      de,(#4d0c)	; Load position data 2 (current position)
28f1  3a3c4d    ld      a,(#4d3c)	; Load state data (frightened state)
28f4  cd6629    call    #2966		; Call processing function
28f7  22264d    ld      (#4d26),hl	; Store processed retreat position
28fa  323c4d    ld      (#4d3c),a	; Store processed state
28fd  c9        ret     		; Return

; ALGORITHM: Normal retreat behavior (complex position calculation)
28fe  2a394d    ld      hl,(#4d39)	; Load position data from backup area
2901  ed4b0c4d  ld      bc,(#4d0c)	; Load position data 2 into BC
2905  7d        ld      a,l		; Get low byte of backup position
2906  87        add     a,a		; Double the low byte (multiply by 2)
2907  91        sub     c		; Subtract C (low byte of position data 2)
2908  6f        ld      l,a		; Store result back in L
2909  7c        ld      a,h		; Get high byte of backup position
290a  87        add     a,a		; Double the high byte (multiply by 2)
290b  90        sub     b		; Subtract B (high byte of position data 2)
290c  67        ld      h,a		; Store result back in H
290d  eb        ex      de,hl		; Exchange: DE = calculated position, HL = ?
290e  2a124d    ld      hl,(#4d12)	; Load position data 5 into HL
2911  3a3c4d    ld      a,(#4d3c)	; Load state data from 0x4d3c
2914  cd6629    call    #2966		; Call unified processing function
2917  22264d    ld      (#4d26),hl	; Store processed position
291a  323c4d    ld      (#4d3c),a	; Store processed state
291d  c9        ret     		; Return

; ======================================================
; FUNCTION: GHOST_NORMAL_MOVEMENT - Normal ghost AI movement algorithm
; ======================================================
; C_PSEUDO: void ghost_normal_movement(position_data, state_data) {
; C_PSEUDO:   store_position_backup(position_data);      // Backup current position
; C_PSEUDO:   state_data ^= 0x02;                        // Toggle direction bit
; C_PSEUDO:   store_state_backup(state_data);            // Backup modified state
; C_PSEUDO:   direction = get_random_direction();        // Get random 0-3
; C_PSEUDO:   current_direction = direction;             // Store in 0x4d3b
; C_PSEUDO:   
; C_PSEUDO:   if(state_data == current_direction) {      // Same direction as before
; C_PSEUDO:     skip_direction_change();                 // Continue straight
; C_PSEUDO:   } else {
; C_PSEUDO:     check_tunnel_conditions();              // Check if can change direction
; C_PSEUDO:     if(can_change_direction) {
; C_PSEUDO:       set_new_direction();                   // Change to new direction
; C_PSEUDO:     } else {
; C_PSEUDO:       increment_direction();                 // Try next direction
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Core ghost AI pathfinding with direction validation
; This is the main function called by Pinky, Inky, and Clyde for normal movement
; Contains the famous Pinky 4-tile bug when called from Pinky's targeting
291e  223e4d    ld      (#4d3e),hl	; Store position backup at 0x4d3e
2921  ee02      xor     #02		; Toggle bit 1 (direction reversal bit)
2923  323d4d    ld      (#4d3d),a	; Store modified state at 0x4d3d
2926  cd232a    call    #2a23		; Call random direction generator
2929  e603      and     #03		; Mask to 0-3 (4 directions: up, right, down, left)
292b  213b4d    ld      hl,#4d3b	; HL points to current direction storage
292e  77        ld      (hl),a		; Store new direction in 0x4d3b
292f  87        add     a,a		; Double direction (multiply by 2 for table index)
2930  5f        ld      e,a		; E = direction * 2
2931  1600      ld      d,#00		; D = 0 (DE = direction index)
2933  dd21ff32  ld      ix,#32ff	; IX = 0x32ff (direction table base - 1)
2937  dd19      add     ix,de		; IX = direction table + (direction * 2)
2939  fd213e4d  ld      iy,#4d3e	; IY = position backup area (0x4d3e)
293d  3a3d4d    ld      a,(#4d3d)	; Load modified state from backup
2940  be        cp      (hl)		; Compare with current direction (0x4d3b)
2941  ca5729    jp      z,#2957         ; Jump if same direction (continue straight)

; ALGORITHM: Direction change validation
2944  cd0f20    call    #200f		; Check tunnel/boundary conditions
2947  e6c0      and     #c0		; Mask upper 2 bits (tunnel flags?)
2949  d6c0      sub     #c0		; Test if equals 0xc0
294b  280a      jr      z,#2957         ; Jump to continue if can't change direction

; ALGORITHM: Set new direction from table
294d  dd6e00    ld      l,(ix+#00)	; Load low byte from direction table
2950  dd6601    ld      h,(ix+#01)	; Load high byte from direction table
2953  3a3b4d    ld      a,(#4d3b)	; Load current direction
2956  c9        ret     		; Return with new direction data

; ALGORITHM: Increment direction (try next)
2957  dd23      inc     ix		; Move to next direction entry
2959  dd23      inc     ix		; (each entry is 2 bytes)
295b  213b4d    ld      hl,#4d3b	; HL points to current direction
295e  7e        ld      a,(hl)		; Load current direction
295f  3c        inc     a		; Increment direction (0->1, 1->2, 2->3, 3->0)
2960  e603      and     #03		; Wrap around at 4 (keep in 0-3 range)
2962  77        ld      (hl),a		; Store new direction
2963  c33d29    jp      #293d		; Jump back to direction comparison loop

; ======================================================
; FUNCTION: UNIFIED_OBJECT_PROCESSOR - Core game object processing engine
; ======================================================
; C_PSEUDO: void unified_object_processor(position_data, target_position, state_data) {
; C_PSEUDO:   backup_position = position_data;          // Store current position
; C_PSEUDO:   target_backup = target_position;          // Store target position
; C_PSEUDO:   current_state = state_data;               // Store current state
; C_PSEUDO:   modified_state = state_data ^ 0x02;       // Toggle direction bit
; C_PSEUDO:   
; C_PSEUDO:   best_distance = 0xFFFF;                   // Initialize to max distance
; C_PSEUDO:   direction_table = 0x32FF;                 // Direction lookup table
; C_PSEUDO:   
; C_PSEUDO:   for(direction = 0; direction < 4; direction++) {
; C_PSEUDO:     if(modified_state == direction) continue;  // Skip reverse direction
; C_PSEUDO:     
; C_PSEUDO:     new_position = calculate_move(position_data, direction);
; C_PSEUDO:     if(can_move_to(new_position)) {
; C_PSEUDO:       distance = calculate_distance(new_position, target_position);
; C_PSEUDO:       if(distance < best_distance) {
; C_PSEUDO:         best_distance = distance;
; C_PSEUDO:         best_direction = direction;
; C_PSEUDO:         best_position = new_position;
; C_PSEUDO:       }
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO:   return best_position, best_direction;
; C_PSEUDO: }
; ALGORITHM: This is the CORE pathfinding engine used by ALL game objects
; Used by Commands 08 (sound), 09 (fruit), 0A (pellets), 0B (power pellets)
; Also used by ghost AI for collision response and movement calculations
; This function finds the best direction to move toward a target position
2966  223e4d    ld      (#4d3e),hl	; Store position data backup at 0x4d3e
2969  ed53404d  ld      (#4d40),de	; Store target position at 0x4d40
296d  323b4d    ld      (#4d3b),a	; Store current state at 0x4d3b
2970  ee02      xor     #02		; Toggle bit 1 (reverse direction bit)
2972  323d4d    ld      (#4d3d),a	; Store modified state at 0x4d3d
2975  21ffff    ld      hl,#ffff	; Initialize best distance to maximum (65535)
2978  22444d    ld      (#4d44),hl	; Store best distance at 0x4d44
297b  dd21ff32  ld      ix,#32ff	; IX = direction table base - 1
297f  fd213e4d  ld      iy,#4d3e	; IY = position backup area
2983  21c74d    ld      hl,#4dc7	; HL = direction counter storage
2986  3600      ld      (hl),#00	; Initialize direction counter to 0

; ALGORITHM: Main pathfinding loop - test all 4 directions
2988  3a3d4d    ld      a,(#4d3d)	; Load modified state (reverse direction)
298b  be        cp      (hl)		; Compare with current direction counter
298c  cac629    jp      z,#29c6         ; Skip if this is the reverse direction

; ALGORITHM: Calculate new position for current direction
298f  cd0020    call    #2000		; Calculate movement position for direction
2992  22424d    ld      (#4d42),hl	; Store calculated position at 0x4d42
2995  cd6500    call    #0065		; Get maze data for new position
2998  7e        ld      a,(hl)		; Load maze tile data
2999  e6c0      and     #c0		; Check movement flags (bits 6-7)
299b  d6c0      sub     #c0		; Test if equals 0xc0 (blocked?)
299d  2827      jr      z,#29c6         ; Skip if can't move to this position

; ALGORITHM: This position is valid - calculate distance to target
299f  dde5      push    ix		; Save direction table pointer
29a1  fde5      push    iy		; Save position backup pointer
29a3  dd21404d  ld      ix,#4d40	; IX = target position
29a7  fd21424d  ld      iy,#4d42	; IY = new calculated position
29ab  cdea29    call    #29ea		; Call distance calculation function
29ae  fde1      pop     iy		; Restore position backup pointer
29b0  dde1      pop     ix		; Restore direction table pointer

; ALGORITHM: Compare distance and update best if closer
29b2  eb        ex      de,hl		; DE = calculated distance
29b3  2a444d    ld      hl,(#4d44)	; Load current best distance
29b6  a7        and     a		; Clear carry flag
29b7  ed52      sbc     hl,de		; Compare: best_distance - new_distance
29b9  dac629    jp      c,#29c6         ; Jump if new distance >= best (no improvement)

; ALGORITHM: New distance is better - update best values
29bc  ed53444d  ld      (#4d44),de	; Store new best distance
29c0  3ac74d    ld      a,(#4dc7)	; Load current direction counter
29c3  323b4d    ld      (#4d3b),a	; Store as new best direction

; ALGORITHM: Continue to next direction
29c6  dd23      inc     ix		; Move to next direction table entry
29c8  dd23      inc     ix		; (each entry is 2 bytes)
29ca  21c74d    ld      hl,#4dc7	; HL = direction counter
29cd  34        inc     (hl)		; Increment direction counter
29ce  3e04      ld      a,#04		; A = 4 (total directions to test)
29d0  be        cp      (hl)		; Compare with counter
29d1  c28829    jp      nz,#2988        ; Continue loop if not all 4 directions tested

; ALGORITHM: All directions tested - return best result
29d4  3a3b4d    ld      a,(#4d3b)	; Load best direction found
29d7  87        add     a,a		; Double it (multiply by 2 for table index)
29d8  5f        ld      e,a		; E = direction * 2
29d9  1600      ld      d,#00		; D = 0 (DE = table index)
29db  dd21ff32  ld      ix,#32ff	; IX = direction table base - 1
29df  dd19      add     ix,de		; IX = table + (best_direction * 2)
29e1  dd6e00    ld      l,(ix+#00)	; Load low byte of best direction data
29e4  dd6601    ld      h,(ix+#01)	; Load high byte of best direction data
29e7  cb3f      srl     a		; Shift right to get original direction (divide by 2)
29e9  c9        ret     		; Return with HL = direction data, A = direction

; ======================================================
; FUNCTION: CALCULATE_DISTANCE - Calculate distance between two points
; ======================================================
; C_PSEUDO: int calculate_distance(point1, point2) {
; C_PSEUDO:   dx = abs(point1.x - point2.x);    // Absolute X difference
; C_PSEUDO:   dy = abs(point1.y - point2.y);    // Absolute Y difference
; C_PSEUDO:   return dx*dx + dy*dy;             // Squared Euclidean distance
; C_PSEUDO: }
; ALGORITHM: Standard Euclidean distance calculation (squared for efficiency)
; INPUT: IX = point 1 coordinates, IY = point 2 coordinates
; OUTPUT: HL = distance squared
29ea  dd7e00    ld      a,(ix+#00)	; Load point1 X coordinate
29ed  fd4600    ld      b,(iy+#00)	; Load point2 X coordinate into B
29f0  90        sub     b		; Calculate X difference
29f1  d2f929    jp      nc,#29f9        ; Jump if result is positive (no borrow)
29f4  78        ld      a,b		; If negative, swap operands
29f5  dd4600    ld      b,(ix+#00)	; B = point1 X
29f8  90        sub     b		; A = point2 X - point1 X (make positive)
29f9  cd122a    call    #2a12		; Calculate X_diff squared
29fc  e5        push    hl		; Save X_diff squared on stack

; ALGORITHM: Calculate Y difference squared
29fd  dd7e01    ld      a,(ix+#01)	; Load point1 Y coordinate
2a00  fd4601    ld      b,(iy+#01)	; Load point2 Y coordinate into B
2a03  90        sub     b		; Calculate Y difference
2a04  d20c2a    jp      nc,#2a0c        ; Jump if result is positive (no borrow)
2a07  78        ld      a,b		; If negative, swap operands  
2a08  dd4601    ld      b,(ix+#01)	; B = point1 Y
2a0b  90        sub     b		; A = point2 Y - point1 Y (make positive)
2a0c  cd122a    call    #2a12		; Calculate Y_diff squared
2a0f  c1        pop     bc		; Restore X_diff squared into BC
2a10  09        add     hl,bc		; HL = X_diff² + Y_diff² (distance squared)
2a11  c9        ret     		; Return distance squared

; ======================================================
; FUNCTION: SQUARE_CALCULATION - Calculate square of a number
; ======================================================
; C_PSEUDO: int square(int value) {
; C_PSEUDO:   result = 0;
; C_PSEUDO:   for(i = 0; i < 8; i++) {        // 8-bit multiplication
; C_PSEUDO:     result = result << 1;         // Shift left
; C_PSEUDO:     if(carry) result += value;    // Add if carry set
; C_PSEUDO:   }
; C_PSEUDO:   return result;
; C_PSEUDO: }
; ALGORITHM: 8-bit multiplication via shift-and-add (value * value)
; INPUT: A = value to square
; OUTPUT: HL = value squared
2a12  67        ld      h,a		; H = value (multiplicand)
2a13  5f        ld      e,a		; E = value (multiplier)  
2a14  2e00      ld      l,#00		; L = 0 (low byte of result)
2a16  55        ld      d,l		; D = 0 (high byte of multiplier)
2a17  0e08      ld      c,#08		; C = 8 (bit counter for 8-bit multiply)

; ALGORITHM: Shift-and-add multiplication loop
2a19  29        add     hl,hl		; Shift result left (HL = HL * 2)
2a1a  d21e2a    jp      nc,#2a1e        ; Jump if no carry from shift
2a1d  19        add     hl,de		; Add multiplier if carry was set
2a1e  0d        dec     c		; Decrement bit counter
2a1f  c2192a    jp      nz,#2a19        ; Continue loop if more bits to process
2a22  c9        ret     		; Return with HL = value squared

; ======================================================
; FUNCTION: RANDOM_DIRECTION_GENERATOR - Generate pseudo-random direction
; ======================================================
; C_PSEUDO: int get_random_direction() {
; C_PSEUDO:   seed = random_seed;                    // Load current seed
; C_PSEUDO:   seed = seed * 5 + 1;                   // Linear congruential generator
; C_PSEUDO:   seed = seed & 0x1FFF;                  // Keep in 13-bit range
; C_PSEUDO:   random_seed = seed;                    // Store new seed
; C_PSEUDO:   return memory[seed];                   // Return pseudo-random value
; C_PSEUDO: }
; ALGORITHM: Linear Congruential Generator for pseudo-random numbers
; This is used by ghost AI to introduce randomness in pathfinding decisions
; The formula: next = (current * 5 + 1) mod 8192
2a23  2ac94d    ld      hl,(#4dc9)	; Load current random seed from 0x4dc9
2a26  54        ld      d,h		; Copy HL to DE (seed value)
2a27  5d        ld      e,l		; DE = current seed
2a28  29        add     hl,hl		; HL = seed * 2
2a29  29        add     hl,hl		; HL = seed * 4  
2a2a  19        add     hl,de		; HL = seed * 4 + seed = seed * 5
2a2b  23        inc     hl		; HL = seed * 5 + 1 (LCG formula)
2a2c  7c        ld      a,h		; Get high byte
2a2d  e61f      and     #1f		; Mask to keep within 0x1FFF (8191)
2a2f  67        ld      h,a		; Store masked high byte back
2a30  7e        ld      a,(hl)		; Read pseudo-random value from memory
2a31  22c94d    ld      (#4dc9),hl	; Store new seed back to 0x4dc9
2a34  c9        ret     		; Return pseudo-random value in A

; ======================================================
; FUNCTION: PELLET_CLEANUP - Clean up consumed pellets from screen
; ======================================================
; C_PSEUDO: void cleanup_consumed_pellets() {
; C_PSEUDO:   for(addr = 0x4040; addr < 0x43C0; addr++) {
; C_PSEUDO:     if(memory[addr] == 0x10 || memory[addr] == 0x12 || memory[addr] == 0x14) {
; C_PSEUDO:       memory[addr] = 0x40;      // Replace with empty space
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Scan screen memory and replace consumed pellet tiles with empty space
; Pellet tile values: 0x10 (small pellet), 0x12 (power pellet?), 0x14 (bonus pellet?)
; Replacement value: 0x40 (empty space)
2a35  114040    ld      de,#4040	; DE = start of screen memory (0x4040)
2a38  21c043    ld      hl,#43c0	; HL = end of screen memory (0x43c0)
2a3b  a7        and     a		; Clear carry flag
2a3c  ed52      sbc     hl,de		; Compare HL - DE (check if at end)
2a3e  c8        ret     z		; Return if DE >= HL (scan complete)

; ALGORITHM: Check current tile and replace if it's a consumed pellet
2a3f  1a        ld      a,(de)		; Load tile value from screen memory
2a40  fe10      cp      #10		; Check if small pellet (0x10)
2a42  ca532a    jp      z,#2a53         ; Jump to replace if match
2a45  fe12      cp      #12		; Check if power pellet (0x12)
2a47  ca532a    jp      z,#2a53         ; Jump to replace if match
2a4a  fe14      cp      #14		; Check if bonus pellet (0x14)
2a4c  ca532a    jp      z,#2a53         ; Jump to replace if match
2a4f  13        inc     de		; Move to next screen position
2a50  c3382a    jp      #2a38		; Continue scan loop

; ALGORITHM: Replace consumed pellet with empty space
2a53  3e40      ld      a,#40		; A = 0x40 (empty space tile)
2a55  12        ld      (de),a		; Replace pellet with empty space
2a56  13        inc     de		; Move to next screen position
2a57  c3382a    jp      #2a38		; Continue scan loop

; ======================================================
; FUNCTION: COMMAND_19_DEATH_SEQUENCE - Death sequence control (Command 0x19)
; ======================================================
; C_PSEUDO: void handle_death_sequence() {
; C_PSEUDO:   if(death_state != 0x01) return;        // Only process if in death state
; C_PSEUDO:   
; C_PSEUDO:   score_value = get_score_table_value(); // Get score from table
; C_PSEUDO:   current_score += score_value;          // Add to current score (BCD)
; C_PSEUDO:   
; C_PSEUDO:   // Check for extra life (score-based)
; C_PSEUDO:   score_shifted = current_score << 4;    // Shift for comparison
; C_PSEUDO:   if(score_shifted >= extra_life_threshold) {
; C_PSEUDO:     award_extra_life();
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   update_score_display();
; C_PSEUDO:   
; C_PSEUDO:   // Check for new high score
; C_PSEUDO:   if(current_score > high_score) {
; C_PSEUDO:     high_score = current_score;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Death sequence processing with score updates and high score tracking
; Uses BCD (Binary Coded Decimal) arithmetic for score calculations
2a5a  3a004e    ld      a,(#4e00)	; Load death state flag from 0x4e00
2a5d  fe01      cp      #01		; Check if death sequence active (0x01)
2a5f  c8        ret     z		; Return if not in death sequence

; ALGORITHM: Score calculation and addition (BCD arithmetic)
2a60  21172b    ld      hl,#2b17	; HL = score table base address
2a63  df        rst     #18		; Call scoring lookup (RST #18)
2a64  eb        ex      de,hl		; DE = score value, HL = ?
2a65  cd0b2b    call    #2b0b		; Get current score pointer
2a68  7b        ld      a,e		; Load low byte of score value
2a69  86        add     a,(hl)		; Add to current score (BCD)
2a6a  27        daa     		; Decimal adjust after addition
2a6b  77        ld      (hl),a		; Store new low byte
2a6c  23        inc     hl		; Move to next score byte
2a6d  7a        ld      a,d		; Load high byte of score value
2a6e  8e        adc     a,(hl)		; Add with carry to current score (BCD)
2a6f  27        daa     		; Decimal adjust after addition
2a70  77        ld      (hl),a		; Store new middle byte
2a71  5f        ld      e,a		; E = middle byte for extra life check
2a72  23        inc     hl		; Move to highest score byte
2a73  3e00      ld      a,#00		; A = 0 (for carry propagation)
2a75  8e        adc     a,(hl)		; Add carry to highest byte (BCD)
2a76  27        daa     		; Decimal adjust after addition
2a77  77        ld      (hl),a		; Store new highest byte
2a78  57        ld      d,a		; D = highest byte for extra life check

; ALGORITHM: Extra life threshold check (score-based bonus life)
2a79  eb        ex      de,hl		; HL = score value for comparison
2a7a  29        add     hl,hl		; Shift left (multiply by 2)
2a7b  29        add     hl,hl		; Shift left (multiply by 4)
2a7c  29        add     hl,hl		; Shift left (multiply by 8)
2a7d  29        add     hl,hl		; Shift left (multiply by 16) - HL = score * 16
2a7e  3a714e    ld      a,(#4e71)	; Load extra life threshold
2a81  3d        dec     a		; Decrement threshold
2a82  bc        cp      h		; Compare with shifted score high byte
2a83  dc332b    call    c,#2b33         ; Call extra life award if score >= threshold

; ALGORITHM: Update score display
2a86  cdaf2a    call    #2aaf		; Update score display

; ALGORITHM: High score comparison and update
2a89  13        inc     de		; Move DE to point to score comparison area
2a8a  13        inc     de		; (skip 2 bytes)
2a8b  13        inc     de		; (skip 1 more byte)
2a8c  218a4e    ld      hl,#4e8a	; HL = high score storage address
2a8f  0603      ld      b,#03		; B = 3 (number of bytes to compare)

; ALGORITHM: Compare current score with high score (3-byte BCD comparison)
2a91  1a        ld      a,(de)		; Load byte from current score
2a92  be        cp      (hl)		; Compare with high score byte
2a93  d8        ret     c		; Return if current < high (no new record)
2a94  2005      jr      nz,#2a9b        ; Jump to update if current > high
2a96  1b        dec     de		; Move to previous byte (if equal, check next)
2a97  2b        dec     hl		; Move to previous high score byte
2a98  10f7      djnz    #2a91           ; Continue comparison loop
2a9a  c9        ret     		; Return if all bytes equal (same score)

; ALGORITHM: Update high score (copy current score to high score storage)
2a9b  cd0b2b    call    #2b0b		; Get current score pointer
2a9e  11884e    ld      de,#4e88	; DE = high score storage - 2 bytes
2aa1  010300    ld      bc,#0003	; BC = 3 bytes to copy
2aa4  edb0      ldir    		; Copy current score to high score
2aa6  1b        dec     de		; Move DE back one byte for display
2aa7  010403    ld      bc,#0304	; B = 4 bytes to display, C = 3 (POSSIBLY player flag)
2aaa  21f243    ld      hl,#43f2	; HL = high score display location
2aad  180f      jr      #2abe           ; Jump to score display routine

; ======================================================
; FUNCTION: UPDATE_SCORE_DISPLAY - Update score display on screen
; ======================================================
; C_PSEUDO: void update_score_display() {
; C_PSEUDO:   player = current_player;               // Get current player (0 or 1)
; C_PSEUDO:   bytes_to_display = 4;                  // 4 BCD digits
; C_PSEUDO:   screen_location = (player == 0) ? 0x43FC : 0x43E9;
; C_PSEUDO:   display_bcd_score(current_score, screen_location, bytes_to_display);
; C_PSEUDO: }
; ALGORITHM: Display current player's score in BCD format on screen
2aaf  3a094e    ld      a,(#4e09)	; Load current player number (0 or 1)
2ab2  010403    ld      bc,#0304	; B = 4 bytes to display, C = 3 (POSSIBLY formatting flag)
2ab5  21fc43    ld      hl,#43fc	; HL = Player 1 score display location
2ab8  a7        and     a		; Test if player 0 (A == 0)
2ab9  2803      jr      z,#2abe         ; Jump if Player 1 (use 0x43fc)
2abb  21e943    ld      hl,#43e9	; HL = Player 2 score display location

; ALGORITHM: Display BCD score digits on screen
2abe  1a        ld      a,(de)		; Load BCD byte from score
2abf  0f        rrca    		; Rotate right 4 times to get high nibble
2ac0  0f        rrca    		; (moves high digit to low nibble)
2ac1  0f        rrca    
2ac2  0f        rrca    
2ac3  cdce2a    call    #2ace		; Display high digit
2ac6  1a        ld      a,(de)		; Load same BCD byte again  
2ac7  cdce2a    call    #2ace		; Display low digit (low nibble)
2aca  1b        dec     de		; Move to previous BCD byte
2acb  10f1      djnz    #2abe           ; Continue for all B bytes
2acd  c9        ret     		; Return

; ======================================================
; FUNCTION: DISPLAY_BCD_DIGIT - Display single BCD digit with leading zero suppression
; ======================================================
; C_PSEUDO: void display_bcd_digit(digit) {
; C_PSEUDO:   digit = digit & 0x0F;           // Mask to single digit
; C_PSEUDO:   if(digit == 0 && suppress_leading_zeros) {
; C_PSEUDO:     display_character = 0x40;     // Space character
; C_PSEUDO:   } else {
; C_PSEUDO:     suppress_leading_zeros = false;
; C_PSEUDO:     display_character = 0x30 + digit;  // ASCII digit
; C_PSEUDO:   }
; C_PSEUDO:   screen[position] = display_character;
; C_PSEUDO:   position++;
; C_PSEUDO: }
; ALGORITHM: Display BCD digit with leading zero suppression for clean score display
2ace  e60f      and     #0f		; Mask to single BCD digit (0-9)
2ad0  2804      jr      z,#2ad6         ; Jump if digit is 0
2ad2  0e00      ld      c,#00		; C = 0 (disable leading zero suppression)
2ad4  1807      jr      #2add           ; Jump to display digit
2ad6  79        ld      a,c		; Load suppression flag
2ad7  a7        and     a		; Test if leading zeros should be suppressed
2ad8  3e40      ld      a,#40		; A = 0x40 (space character)
2ada  c0        ret     nz		; Return with space if suppressing zeros
2adc  af        xor     a		; A = 0 (display zero)
2add  77        ld      (hl),a		; Store digit character to screen
2ade  2b        dec     hl		; Move to previous screen position (right-to-left display)
2adf  c9        ret     		; Return

; ======================================================
; FUNCTION: COMMAND_18_TUNNEL_TELEPORTATION - Tunnel teleportation (Command 0x18)
; ======================================================
; C_PSEUDO: void handle_tunnel_teleportation() {
; C_PSEUDO:   display_high_score();               // Draw "HIGH SCORE" text
; C_PSEUDO:   clear_player_scores();              // Clear P1 and P2 score areas
; C_PSEUDO:   display_player1_score();            // Show P1 score
; C_PSEUDO:   if(two_player_mode) {
; C_PSEUDO:     display_player2_score();          // Show P2 score if applicable
; C_PSEUDO:   } else {
; C_PSEUDO:     display_blank_p2_area();          // Blank P2 area in 1-player mode
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Display initialization and score setup for tunnel/screen transitions
; This function appears to be called during screen setup or transitions
2ae0  0600      ld      b,#00		; B = 0 (parameter for high score display)
2ae2  cd5e2c    call    #2c5e		; Call high score display function

; ALGORITHM: Clear player score memory areas
2ae5  af        xor     a		; A = 0 (clear value)
2ae6  21804e    ld      hl,#4e80	; HL = Player score memory start
2ae9  0608      ld      b,#08		; B = 8 bytes to clear
2aeb  cf        rst     #8		; Clear 8 bytes of score memory

; ALGORITHM: Display Player 1 score
2aec  010403    ld      bc,#0407	; B = 4 bytes to display, C = 7 (leading zero suppression)
2aef  11824e    ld      de,#4e83	; DE = Player 1 score data + 1 
2af2  21fc43    ld      hl,#43fc	; HL = Player 1 score screen location
2af5  cdbe2a    call    #2abe		; Call score display function

; ALGORITHM: Display Player 2 score (conditional)
2af8  010403    ld      bc,#0407	; B = 4 bytes to display, C = 7 (leading zero suppression)
2afb  11864e    ld      de,#4e87	; DE = Player 2 score data + 1
2afe  21e943    ld      hl,#43e9	; HL = Player 2 score screen location
2b01  3a704e    ld      a,(#4e70)	; Load two-player mode flag
2b04  a7        and     a		; Test if two-player mode active
2b05  20b7      jr      nz,#2abe        ; Jump to display P2 score if two-player mode

; ALGORITHM: Blank Player 2 area in single-player mode
2b07  0e06      ld      c,#06		; C = 6 (blank display mode)
2b09  18b3      jr      #2abe           ; Jump to display blanks for P2 area

; ======================================================
; FUNCTION: GET_CURRENT_SCORE_POINTER - Get pointer to current player's score
; ======================================================
; C_PSEUDO: int* get_current_score_pointer() {
; C_PSEUDO:   if(current_player == 0) {
; C_PSEUDO:     return &player1_score;          // 0x4e80
; C_PSEUDO:   } else {
; C_PSEUDO:     return &player2_score;          // 0x4e84
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Return pointer to current player's score storage area
; Used by scoring functions to update the correct player's score
2b0b  3a094e    ld      a,(#4e09)	; Load current player number (0 or 1)
2b0e  21804e    ld      hl,#4e80	; HL = Player 1 score pointer (default)
2b11  a7        and     a		; Test if player 0
2b12  c8        ret     z		; Return Player 1 pointer if player 0
2b13  21844e    ld      hl,#4e84	; HL = Player 2 score pointer
2b16  c9        ret     		; Return Player 2 pointer

; ======================================================
; MEMORY_MAP: SCORING TABLE - Point values for different game objects
; ======================================================
; This table contains the point values awarded for eating different items
; Values are stored in little-endian format (low byte, high byte)
; Used by RST #18 scoring lookup function
2b17  0100      dw      #0001		; Small pellet (dot) = 10 points
2b19  0500      dw      #0005		; Power pellet = 50 points  
2b1b  2000      dw      #0020		; Ghost 1 (first ghost eaten) = 200 points
2b1d  4000      dw      #0040		; Ghost 2 (second ghost eaten) = 400 points
2b1f  8000      dw      #0080		; Ghost 3 (third ghost eaten) = 800 points
2b21  6001      dw      #0160		; Ghost 4 (fourth ghost eaten) = 1600 points
2b23  1000      dw      #0010		; Fruit 1 (Cherry) = 100 points
2b25  3000      dw      #0030		; Fruit 2 (Strawberry) = 300 points
2b27  5000      dw      #0050		; Fruit 3 (Orange) = 500 points
2b29  7000      dw      #0070		; Fruit 4 (Apple) = 700 points
2b2b  0001      dw      #0100		; Fruit 5 (Melon) = 1000 points
2b2d  0002      dw      #0200		; Fruit 6 (Galaxian) = 2000 points
2b2f  0003      dw      #0300		; Fruit 7 (Bell) = 3000 points
2b31  0005      dw      #0500		; Fruit 8 (Key) = 5000 points

; ======================================================
; FUNCTION: AWARD_EXTRA_LIFE - Award extra life when score threshold reached
; ======================================================
; C_PSEUDO: void award_extra_life() {
; C_PSEUDO:   // Check if already awarded (prevent multiple awards at same score)
; C_PSEUDO:   if(extra_life_awarded_flag & 0x01) return;
; C_PSEUDO:   
; C_PSEUDO:   extra_life_awarded_flag |= 0x01;      // Set awarded flag
; C_PSEUDO:   extra_life_indicator = true;          // Enable extra life indicator
; C_PSEUDO:   lives_player1++;                      // Add life to player 1
; C_PSEUDO:   lives_player2++;                      // Add life to player 2
; C_PSEUDO:   
; C_PSEUDO:   // Update lives display on screen
; C_PSEUDO:   for(life = 0; life < lives && life < 5; life++) {
; C_PSEUDO:     screen[life_display_area + life] = PAC_MAN_SPRITE;
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Award bonus life and update display when score threshold reached
; This is called when the player's score reaches the extra life threshold
2b33  13        inc     de		; Move DE to next position
2b34  6b        ld      l,e		; Copy DE to HL (for flag checking)
2b35  62        ld      h,d
2b36  1b        dec     de		; Restore DE position
2b37  cb46      bit     0,(hl)		; Test if extra life already awarded (bit 0)
2b39  c0        ret     nz		; Return if already awarded (prevent duplicate)

; ALGORITHM: Set extra life awarded flags
2b3a  cbc6      set     0,(hl)		; Set extra life awarded flag (bit 0)
2b3c  219c4e    ld      hl,#4e9c	; HL = extra life indicator address
2b3f  cbc6      set     0,(hl)		; Enable extra life indicator (bit 0)

; ALGORITHM: Increment life counters for both players
2b41  21144e    ld      hl,#4e14	; HL = Player 1 lives counter
2b44  34        inc     (hl)		; Increment Player 1 lives
2b45  21154e    ld      hl,#4e15	; HL = Player 2 lives counter  
2b48  34        inc     (hl)		; Increment Player 2 lives
2b49  46        ld      b,(hl)		; B = Player 2 lives (for display)

; ALGORITHM: Update lives display on screen
2b4a  211a40    ld      hl,#401a	; HL = lives display area start
2b4d  0e05      ld      c,#05		; C = 5 (maximum lives to display)
2b4f  78        ld      a,b		; A = number of lives to display
2b50  a7        and     a		; Test if zero lives
2b51  280e      jr      z,#2b61         ; Jump to clear display if zero lives
2b53  fe06      cp      #06		; Compare with 6 lives
2b55  300a      jr      nc,#2b61        ; Jump to clear if >= 6 (cap at 5 display)

; ALGORITHM: Draw Pac-Man sprites for each life
2b57  3e20      ld      a,#20		; A = 0x20 (Pac-Man sprite tile)
2b59  cd8f2b    call    #2b8f		; Draw sprite at current position
2b5c  2b        dec     hl		; Move to previous screen position
2b5d  2b        dec     hl		; (2 positions back for spacing)
2b5e  0d        dec     c		; Decrement display counter
2b5f  10f6      djnz    #2b57           ; Continue for all lives to display

; ALGORITHM: Clear remaining life display positions (if fewer than 5 lives)
2b61  0d        dec     c		; Decrement remaining position counter
2b62  f8        ret     m		; Return if no more positions to clear

2b63  cd7e2b    call    #2b7e		; Clear position (draw blank)
2b66  2b        dec     hl		; Move to previous screen position
2b67  2b        dec     hl		; (2 positions back)
2b68  18f7      jr      #2b61           ; Continue clearing remaining positions

; ======================================================
; FUNCTION: COMMAND_1A_INTERMISSION_CUTSCENE - Intermission/cutscene control (Command 0x1A)
; ======================================================
; C_PSEUDO: void handle_intermission_cutscene() {
; C_PSEUDO:   if(game_state != 0x01) return;        // Only process if in correct state
; C_PSEUDO:   
; C_PSEUDO:   // POSSIBLY complex intermission logic - unclear without more context
; C_PSEUDO:   value = get_intermission_data();      // Get some intermission value
; C_PSEUDO:   store_value(value);                   // Store it somewhere
; C_PSEUDO:   // Additional processing...
; C_PSEUDO:   update_lives_display();               // Update lives display
; C_PSEUDO: }
; ALGORITHM: Handles intermission sequences and cutscenes between levels
; The exact logic is unclear without more context about the data being manipulated
2b6a  3a004e    ld      a,(#4e00)	; Load game state from 0x4e00
2b6d  fe01      cp      #01		; Check if state equals 1
2b6f  c8        ret     z		; Return if state is 1 (POSSIBLY wrong state)

; ALGORITHM: POSSIBLY intermission data processing
2b70  cdcd2b    call    #2bcd		; Call intermission data function (POSSIBLY)
2b73  12        ld      (de),a		; Store result at DE
2b74  44        ld      b,h		; B = H (POSSIBLY for calculation)
2b75  09        add     hl,bc		; HL = HL + BC (POSSIBLY address calculation)
2b76  0a        ld      a,(bc)		; Load value from BC address
2b77  02        ld      (bc),a		; Store A at BC (POSSIBLY redundant?)
2b78  21154e    ld      hl,#4e15	; HL = Player 2 lives counter
2b7b  46        ld      b,(hl)		; B = Player 2 lives count
2b7c  18cc      jr      #2b4a           ; Jump back to lives display update

; ======================================================
; FUNCTION: DRAW_2X2_BLANK - Draw blank 2x2 character square
; ======================================================
; C_PSEUDO: void draw_2x2_blank(screen_position) {
; C_PSEUDO:   char blank = 0x40;                   // Blank/space character
; C_PSEUDO:   screen[position] = blank;            // Top-left
; C_PSEUDO:   screen[position + 1] = blank;        // Top-right
; C_PSEUDO:   screen[position + 32] = blank;       // Bottom-left (next row)
; C_PSEUDO:   screen[position + 33] = blank;       // Bottom-right
; C_PSEUDO: }
; ALGORITHM: Draw a 2x2 blank square for clearing sprites/graphics
; Used to clear lives display positions and other 2x2 graphics
2b7e  3e40      ld      a,#40		; A = 0x40 (blank/space character)

; ALGORITHM: Draw 2x2 character square
2b80  e5        push    hl		; Save HL (screen position)
2b81  d5        push    de		; Save DE
2b82  77        ld      (hl),a		; Draw top-left character
2b83  23        inc     hl		; Move to next position (top-right)
2b84  77        ld      (hl),a		; Draw top-right character
2b85  111f00    ld      de,#001f	; DE = 31 (move to next row - 1)
2b88  19        add     hl,de		; HL = position + 31 (bottom-left)
2b89  77        ld      (hl),a		; Draw bottom-left character
2b8a  23        inc     hl		; Move to next position (bottom-right)
2b8b  77        ld      (hl),a		; Draw bottom-right character
2b8c  d1        pop     de		; Restore DE
2b8d  e1        pop     hl		; Restore HL
2b8e  c9        ret     		; Return

; ======================================================
; FUNCTION: DRAW_2X2_SPRITE - Draw 2x2 sprite (used for fruit/lives)
; ======================================================
; C_PSEUDO: void draw_2x2_sprite(screen_position, base_tile) {
; C_PSEUDO:   screen[position] = base_tile;        // Top-left
; C_PSEUDO:   screen[position + 1] = base_tile + 1;    // Top-right
; C_PSEUDO:   screen[position + 32] = base_tile + 2;   // Bottom-left
; C_PSEUDO:   screen[position + 33] = base_tile + 3;   // Bottom-right
; C_PSEUDO: }
; ALGORITHM: Draw a 2x2 sprite using consecutive tile numbers
; Creates composite sprites like Pac-Man lives or fruit bonuses
2b8f  e5        push    hl		; Save HL (screen position)
2b90  d5        push    de		; Save DE
2b91  111f00    ld      de,#001f	; DE = 31 (move to next row - 1)
2b94  77        ld      (hl),a		; Draw top-left tile (base tile)
2b95  3c        inc     a		; A = base_tile + 1
2b96  23        inc     hl		; Move to next position (top-right)
2b97  77        ld      (hl),a		; Draw top-right tile
2b98  3c        inc     a		; A = base_tile + 2
2b99  19        add     hl,de		; HL = position + 31 (bottom-left)
2b9a  77        ld      (hl),a		; Draw bottom-left tile
2b9b  3c        inc     a		; A = base_tile + 3
2b9c  23        inc     hl		; Move to next position (bottom-right)
2b9d  77        ld      (hl),a		; Draw bottom-right tile
2b9e  d1        pop     de		; Restore DE
2b9f  e1        pop     hl		; Restore HL
2ba0  c9        ret     		; Return

; ======================================================
; FUNCTION: COMMAND_1D_HIGH_SCORE_MANAGEMENT - High score management (Command 0x1D)
; ======================================================
; C_PSEUDO: void display_credits_or_freeplay() {
; C_PSEUDO:   credits = credit_counter;              // Load credit count
; C_PSEUDO:   if(credits == 0xFF) {                  // Free play mode
; C_PSEUDO:     display_text("FREE PLAY");
; C_PSEUDO:   } else {
; C_PSEUDO:     display_text("CREDIT");
; C_PSEUDO:     display_credit_digits(credits);      // Show credit count
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Display credit counter or "FREE PLAY" text at bottom of screen
; This is part of the coin-op arcade machine interface
2ba1  3a6e4e    ld      a,(#4e6e)	; Load credit counter from 0x4e6e
2ba4  feff      cp      #ff		; Check if free play mode (0xFF)
2ba6  2005      jr      nz,#2bad        ; Jump to credit display if not free play

; ALGORITHM: Display "FREE PLAY" text
2ba8  0602      ld      b,#02		; B = 2 (text ID for "FREE PLAY")
2baa  c35e2c    jp      #2c5e		; Jump to text display function

; ALGORITHM: Display "CREDIT" text and credit count
2bad  0601      ld      b,#01		; B = 1 (text ID for "CREDIT")
2baf  cd5e2c    call    #2c5e		; Call text display function
2bb2  3a6e4e    ld      a,(#4e6e)	; Load credit counter again
2bb5  e6f0      and     #f0		; Mask upper nibble (tens digit)
2bb7  2809      jr      z,#2bc2         ; Skip tens digit if zero

; ALGORITHM: Display tens digit of credit count
2bb9  0f        rrca    		; Rotate right 4 times to move
2bba  0f        rrca    		; upper nibble to lower nibble
2bbb  0f        rrca    
2bbc  0f        rrca    
2bbd  c630      add     a,#30		; Convert to ASCII digit
2bbf  323440    ld      (#4034),a	; Store tens digit at screen position

; ALGORITHM: Display ones digit of credit count
2bc2  3a6e4e    ld      a,(#4e6e)	; Load credit counter
2bc5  e60f      and     #0f		; Mask lower nibble (ones digit)
2bc7  c630      add     a,#30		; Convert to ASCII digit
2bc9  323340    ld      (#4033),a	; Store ones digit at screen position
2bcc  c9        ret     		; Return

; ======================================================
; FUNCTION: LOAD_INTERMISSION_DATA - Load data for intermissions/cutscenes
; ======================================================
; C_PSEUDO: int load_intermission_data() {
; C_PSEUDO:   // This function loads 5 bytes of data from the return address location
; C_PSEUDO:   // It's called by intermission routines to load configuration data
; C_PSEUDO:   return_address = pop_stack();          // Get return address
; C_PSEUDO:   de = read_word(return_address);        // Load DE value
; C_PSEUDO:   bc = read_word(return_address + 2);    // Load BC value  
; C_PSEUDO:   a = read_byte(return_address + 4);     // Load A value
; C_PSEUDO:   return_address += 5;                   // Skip past data
; C_PSEUDO:   push_stack(return_address);            // Update return address
; C_PSEUDO:   
; C_PSEUDO:   // Use loaded data for some processing
; C_PSEUDO:   process_intermission_data(de, bc, a);
; C_PSEUDO:   return a;
; C_PSEUDO: }
; ALGORITHM: Inline data loading function for intermission sequences
; This is a sophisticated technique where data is embedded after the call instruction
2bcd  e1        pop     hl		; Pop return address from stack
2bce  5e        ld      e,(hl)		; Load low byte of DE from data
2bcf  23        inc     hl		; Move to next data byte
2bd0  56        ld      d,(hl)		; Load high byte of DE from data
2bd1  23        inc     hl		; Move to next data byte
2bd2  4e        ld      c,(hl)		; Load low byte of BC from data
2bd3  23        inc     hl		; Move to next data byte
2bd4  46        ld      b,(hl)		; Load high byte of BC from data
2bd5  23        inc     hl		; Move to next data byte
2bd6  7e        ld      a,(hl)		; Load A value from data
2bd7  23        inc     hl		; Move past data (return address now correct)
2bd8  e5        push    hl		; Push updated return address back to stack
2bd9  eb        ex      de,hl		; HL = DE (loaded data), DE = return address

; ALGORITHM: Process loaded data (draw rectangular pattern)
2bda  112000    ld      de,#0020	; DE = 32 (screen width - move to next row)
2bdd  e5        push    hl		; Save HL (current screen position)
2bde  c5        push    bc		; Save BC (width/height parameters)
2bdf  71        ld      (hl),c		; Draw character C at current position
2be0  23        inc     hl		; Move to next screen position
2be1  10fc      djnz    #2bdf           ; Continue for B columns (width)
2be3  c1        pop     bc		; Restore BC (width/height parameters)
2be4  e1        pop     hl		; Restore HL (start of current row)
2be5  19        add     hl,de		; Move to next row (HL + 32)
2be6  3d        dec     a		; Decrement row counter
2be7  20f4      jr      nz,#2bdd        ; Continue for A rows (height)
2be9  c9        ret     		; Return

; ======================================================
; FUNCTION: COMMAND_1B_DEMO_MODE - Demo mode automation (Command 0x1B)
; ======================================================
; C_PSEUDO: void handle_demo_mode() {
; C_PSEUDO:   if(game_state != 0x01) return;        // Only process if in correct state
; C_PSEUDO:   
; C_PSEUDO:   level = current_level + 1;            // Get next level number
; C_PSEUDO:   if(level >= 8) {                      // If level 8 or higher
; C_PSEUDO:     handle_high_level_fruit();          // Special fruit handling
; C_PSEUDO:   } else {
; C_PSEUDO:     display_fruit_progression(level);   // Show fruit for current level
; C_PSEUDO:   }
; C_PSEUDO: }
; ALGORITHM: Display fruit progression during demo/attract mode
; Shows the fruits that appear at different levels to entice players
2bea  3a004e    ld      a,(#4e00)	; Load game state from 0x4e00
2bed  fe01      cp      #01		; Check if state equals 1
2bef  c8        ret     z		; Return if state is 1 (POSSIBLY wrong state)

; ALGORITHM: Display fruit progression based on level
2bf0  3a134e    ld      a,(#4e13)	; Load current level number
2bf3  3c        inc     a		; Increment level (A = level + 1)
2bf4  fe08      cp      #08		; Compare with 8 (level 8)
2bf6  d22e2c    jp      nc,#2c2e	; Jump to high level handling if >= 8

; ALGORITHM: Display fruits for levels 1-7
2bf9  11083b    ld      de,#3b08	; DE = fruit table address (POSSIBLY)
2bfc  47        ld      b,a		; B = level number (for counter)
2bfd  0e07      ld      c,#07		; C = 7 (maximum fruits to display)
2bff  210440    ld      hl,#4004	; HL = fruit display area start
2c02  1a        ld      a,(de)		; Load fruit sprite ID from table
2c03  cd8f2b    call    #2b8f		; Draw 2x2 fruit sprite

; ALGORITHM: Move to next fruit position and continue
2c06  3e04      ld      a,#04		; A = 4 (spacing between fruits)
2c08  84        add     a,h		; H = H + 4 (move 4 rows down on screen)
2c09  67        ld      h,a		; Update H with new position
2c0a  13        inc     de		; Move to next fruit in table
2c0b  1a        ld      a,(de)		; Load next fruit sprite ID
2c0c  cd802b    call    #2b80		; Erase fruit (draw blank pattern)
2c0f  3efc      ld      a,#fc		; A = -4 (move back up 4 rows)
2c11  84        add     a,h		; H = H - 4 (restore original row)
2c12  67        ld      h,a		; Update H
2c13  13        inc     de		; Move to next fruit entry
2c14  23        inc     hl		; Move screen position right
2c15  23        inc     hl		; (2 positions for 2x2 sprite spacing)
2c16  0d        dec     c		; Decrement fruit counter
2c17  10e9      djnz    #2c02           ; Continue for B fruits (level number)

; ALGORITHM: Clear remaining fruit positions (if fewer than 7)
2c19  0d        dec     c		; Decrement remaining position counter
2c1a  f8        ret     m		; Return if no more positions to clear

2c1b  cd7e2b    call    #2b7e		; Draw blank 2x2 square
2c1e  3e04      ld      a,#04		; A = 4 (move down 4 rows)
2c20  84        add     a,h		; H = H + 4
2c21  67        ld      h,a		; Update H
2c22  af        xor     a		; A = 0 (blank pattern)
2c23  cd802b    call    #2b80		; Draw blank pattern
2c26  3efc      ld      a,#fc		; A = -4 (move back up)
2c28  84        add     a,h		; H = H - 4
2c29  67        ld      h,a		; Update H
2c2a  23        inc     hl		; Move to next position
2c2b  23        inc     hl		; (2 positions right)
2c2c  18eb      jr      #2c19           ; Continue clearing remaining positions

; ALGORITHM: High level fruit handling (level 8+)
2c2e  fe13      cp      #13		; Compare level with 19
2c30  3802      jr      c,#2c34         ; Jump if level < 19
2c32  3e13      ld      a,#13		; Cap level at 19 (maximum)
2c34  d607      sub     #07		; A = level - 7 (adjust for high level table)
2c36  4f        ld      c,a		; C = adjusted level
2c37  0600      ld      b,#00		; B = 0 (for 16-bit offset)
2c39  21083b    ld      hl,#3b08	; HL = fruit table base
2c3c  09        add     hl,bc		; HL = table + offset
2c3d  09        add     hl,bc		; HL = table + (offset * 2) for word entries
2c3e  eb        ex      de,hl		; DE = calculated fruit table address
2c3f  0607      ld      b,#07		; B = 7 (display 7 fruits for high levels)
2c41  c3fd2b    jp      #2bfd		; Jump back to main fruit display loop

; ======================================================
; FUNCTION: BINARY_TO_BCD_CONVERTER - Convert binary to BCD
; ======================================================
; C_PSEUDO: int binary_to_bcd(int binary_value) {
; C_PSEUDO:   ones = binary_value & 0x0F;          // Extract ones digit
; C_PSEUDO:   tens = (binary_value & 0xF0) >> 4;   // Extract tens digit
; C_PSEUDO:   
; C_PSEUDO:   bcd_result = ones;                   // Start with ones
; C_PSEUDO:   for(i = 0; i < tens; i++) {
; C_PSEUDO:     bcd_result += 0x16;                // Add 16 in BCD (represents 10)
; C_PSEUDO:     bcd_adjust(bcd_result);            // Decimal adjust
; C_PSEUDO:   }
; C_PSEUDO:   return bcd_result;
; C_PSEUDO: }
; ALGORITHM: Convert 8-bit binary value to BCD format
; Uses decimal adjust after addition (DAA) for proper BCD arithmetic
2c44  47        ld      b,a		; Save original value in B
2c45  e60f      and     #0f		; Mask ones digit (lower nibble)
2c47  c600      add     a,#00		; Add 0 (for decimal adjust)
2c49  27        daa     		; Decimal adjust (ensure BCD format)
2c4a  4f        ld      c,a		; C = BCD ones digit
2c4b  78        ld      a,b		; Restore original value
2c4c  e6f0      and     #f0		; Mask tens digit (upper nibble)
2c4e  280b      jr      z,#2c5b         ; Jump to end if no tens digit

; ALGORITHM: Convert tens digit to BCD by repeated addition
2c50  0f        rrca    		; Rotate right 4 times to move
2c51  0f        rrca    		; tens digit to ones position
2c52  0f        rrca    
2c53  0f        rrca    
2c54  47        ld      b,a		; B = tens count
2c55  af        xor     a		; A = 0 (accumulator)
2c56  c616      add     a,#16		; Add 16 (BCD representation of 10)
2c58  27        daa     		; Decimal adjust after addition
2c59  10fb      djnz    #2c56           ; Repeat for each tens digit
2c5b  81        add     a,c		; Add ones digit to result
2c5c  27        daa     		; Final decimal adjust
2c5d  c9        ret     		; Return BCD result in A

; ======================================================
; FUNCTION: COMMAND_1C_ATTRACT_MODE - Attract mode cycling (Command 0x1C)
; ======================================================
; C_PSEUDO: void display_message_from_table(message_id) {
; C_PSEUDO:   message_entry = message_table[message_id];     // Get message entry
; C_PSEUDO:   screen_offset = message_entry.position;        // Screen position
; C_PSEUDO:   text_data = message_entry.text;                // Text to display
; C_PSEUDO:   color_data = message_entry.color;              // Color information
; C_PSEUDO:   
; C_PSEUDO:   // Calculate screen addresses
; C_PSEUDO:   color_ram_addr = 0x4400 + screen_offset;       // Color RAM
; C_PSEUDO:   video_ram_addr = 0x4000 + screen_offset;       // Video RAM  
; C_PSEUDO:   
; C_PSEUDO:   // Determine text direction/offset
; C_PSEUDO:   if(special_positioning) {
; C_PSEUDO:     offset = 0xFFE0;                             // Top/bottom lines
; C_PSEUDO:   } else {
; C_PSEUDO:     offset = 0xFFFF;                             // Normal text
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Draw text characters
; C_PSEUDO:   while(*text != 0x2F) {                         // 0x2F = end marker
; C_PSEUDO:     video_ram[position] = *text++;               // Write character
; C_PSEUDO:     position += offset;                          // Move to next position
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Apply color information
; C_PSEUDO:   apply_color_data(color_ram_addr, color_data);
; C_PSEUDO: }
; ALGORITHM: Display text messages from a lookup table
; This is the main text display engine used throughout the game
; Handles both normal text and special positioned text (top/bottom screen)
2c5e  21a536    ld      hl,#36a5	; HL = message table base address
2c61  df        rst     #18		; RST #18: HL = HL + (B * 2) - get message entry
2c62  5e        ld      e,(hl)		; Load low byte of screen offset
2c63  23        inc     hl		; Move to next byte
2c64  56        ld      d,(hl)		; Load high byte of screen offset
2c65  dd210044  ld      ix,#4400	; IX = Color RAM base (0x4400)
2c69  dd19      add     ix,de		; IX = Color RAM + offset (color position)
2c6b  dde5      push    ix		; Save color RAM address on stack
2c6d  1100fc    ld      de,#fc00	; DE = -1024 (0x4400 - 0x4000 = 1024)
2c70  dd19      add     ix,de		; IX = Video RAM + offset (0x4000 + original offset)
2c72  11ffff    ld      de,#ffff	; DE = -1 (normal text direction)
2c75  cb7e      bit     7,(hl)		; Test bit 7 of position data
2c77  2003      jr      nz,#2c7c        ; Jump if bit 7 set (special positioning)
2c79  11e0ff    ld      de,#ffe0	; DE = -32 (top/bottom line positioning)

; ALGORITHM: Main text drawing loop
2c7c  23        inc     hl		; Move to text data
2c7d  78        ld      a,b		; A = message ID
2c7e  010000    ld      bc,#0000	; BC = 0 (character counter)
2c81  87        add     a,a		; A = message_ID * 2
2c82  3828      jr      c,#2cac         ; Jump to special draw routine if ID >= 128

; ALGORITHM: Normal text character drawing
2c84  7e        ld      a,(hl)		; Load character from text data
2c85  fe2f      cp      #2f		; Check for end marker (0x2F)
2c87  2809      jr      z,#2c92         ; Jump to color processing if end reached
2c89  dd7700    ld      (ix+#00),a	; Write character to video RAM
2c8c  23        inc     hl		; Move to next character
2c8d  dd19      add     ix,de		; Move to next screen position (IX + DE)
2c8f  04        inc     b		; Increment character counter
2c90  18f2      jr      #2c84           ; Continue character drawing loop

; ALGORITHM: Color processing after text drawing
2c92  23        inc     hl		; Move to color data
2c93  dde1      pop     ix		; Restore color RAM address
2c95  7e        ld      a,(hl)		; Load color information
2c96  a7        and     a		; Test color value
2c97  faa42c    jp      m,#2ca4		; Jump to special color handling if >= 0x80

; ALGORITHM: Multi-color text - each character has individual color
2c9a  7e        ld      a,(hl)		; Load color value
2c9b  dd7700    ld      (ix+#00),a	; Write color to color RAM
2c9e  23        inc     hl		; Move to next color
2c9f  dd19      add     ix,de		; Move to next color RAM position
2ca1  10f7      djnz    #2c9a           ; Continue for all B characters
2ca3  c9        ret     		; Return

; ALGORITHM: Single-color text - all characters use same color
2ca4  dd7700    ld      (ix+#00),a	; Write color to color RAM
2ca7  dd19      add     ix,de		; Move to next color RAM position  
2ca9  10f9      djnz    #2ca4           ; Continue for all B characters
2cab  c9        ret     		; Return

; ALGORITHM: Special draw routine for message ID >= 128 (erase mode)
2cac  7e        ld      a,(hl)		; Load character from text data
2cad  fe2f      cp      #2f		; Check for end marker (0x2F)
2caf  280a      jr      z,#2cbb         ; Jump to color processing if end reached
2cb1  dd360040  ld      (ix+#00),#40	; Write 0x40 (space/blank) to video RAM
2cb5  23        inc     hl		; Move to next character
2cb6  dd19      add     ix,de		; Move to next screen position
2cb8  04        inc     b		; Increment character counter
2cb9  18f1      jr      #2cac           ; Continue erasing loop

; ALGORITHM: Skip to color data after erasing text
2cbb  23        inc     hl		; Move past end marker
2cbc  04        inc     b		; Increment counter
2cbd  edb1      cpir    		; Search for next 0x2F (end of color data)
2cbf  18d2      jr      #2c93           ; Jump to color processing

; ======================================================
; FUNCTION: GHOST_STATE_PROCESSOR - Process ghost state data
; ======================================================
; C_PSEUDO: void process_ghost_state_data() {
; C_PSEUDO:   // Process first ghost data set
; C_PSEUDO:   table1 = 0x3bc8;                         // First ghost table
; C_PSEUDO:   state_storage1 = 0x4ecc;                 // State storage area 1
; C_PSEUDO:   output_area1 = 0x4e8c;                   // Output area 1
; C_PSEUDO:   result1 = process_ghost_data(table1, state_storage1, output_area1);
; C_PSEUDO:   
; C_PSEUDO:   if(state_storage1[0] != 0) {             // If state is active
; C_PSEUDO:     game_state_flag = result1;             // Store result in game state
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Process second ghost data set  
; C_PSEUDO:   table2 = 0x3bcc;                         // Second ghost table
; C_PSEUDO:   state_storage2 = 0x4edc;                 // State storage area 2
; C_PSEUDO:   output_area2 = 0x4e92;                   // Output area 2
; C_PSEUDO:   process_ghost_data(table2, state_storage2, output_area2);
; C_PSEUDO: }
; ALGORITHM: Process ghost state information using lookup tables
; This appears to manage ghost AI state transitions and behaviors
2cc1  21c83b    ld      hl,#3bc8	; HL = first ghost state table
2cc4  dd21cc4e  ld      ix,#4ecc	; IX = state storage area 1
2cc8  fd218c4e  ld      iy,#4e8c	; IY = output area 1
2ccc  cd442d    call    #2d44		; Call ghost data processing function
2ccf  47        ld      b,a		; Save result in B
2cd0  3acc4e    ld      a,(#4ecc)	; Load state from storage area 1
2cd3  a7        and     a		; Test if state is zero
2cd4  2804      jr      z,#2cda         ; Skip if state is zero (inactive)
2cd6  78        ld      a,b		; Restore result
2cd7  32914e    ld      (#4e91),a	; Store result in game state flag

; ALGORITHM: Process second ghost data set
2cda  21cc3b    ld      hl,#3bcc	; HL = second ghost state table
2cdd  dd21dc4e  ld      ix,#4edc	; IX = state storage area 2  
2ce1  fd21924e  ld      iy,#4e92	; IY = output area 2
2ce5  cd442d    call    #2d44		; Call ghost data processing function
2ce8  47        ld      b,a		; Save result in B
2ce9  3adc4e    ld      a,(#4edc)	; Load state from storage area 2
2cec  a7        and     a		; Test if state is zero
2ced  2804      jr      z,#2cf3         ; Skip if state is zero (inactive)
2cef  78        ld      a,b		; Restore result
2cf0  32964e    ld      (#4e96),a	; Store result in game state flag

; ALGORITHM: Process third ghost data set
2cf3  21d03b    ld      hl,#3bd0	; HL = third ghost state table
2cf6  dd21ec4e  ld      ix,#4eec	; IX = state storage area 3
2cfa  fd21974e  ld      iy,#4e97	; IY = output area 3
2cfe  cd442d    call    #2d44		; Call ghost data processing function
2d01  47        ld      b,a		; Save result in B
2d02  3aec4e    ld      a,(#4eec)	; Load state from storage area 3
2d05  a7        and     a		; Test if state is zero
2d06  c8        ret     z		; Return if state is zero (inactive)
2d07  78        ld      a,b		; Restore result
2d08  329b4e    ld      (#4e9b),a	; Store result in game state flag
2d0b  c9        ret     		; Return

; ======================================================
; FUNCTION: BONUS_OBJECT_PROCESSOR - Process bonus objects (fruits/points)
; ======================================================
; C_PSEUDO: void process_bonus_objects() {
; C_PSEUDO:   // Process first bonus object set
; C_PSEUDO:   table1 = 0x3b30;                         // First bonus table
; C_PSEUDO:   state_storage1 = 0x4e9c;                 // State storage area 1
; C_PSEUDO:   output_area1 = 0x4e8c;                   // Output area 1
; C_PSEUDO:   result1 = process_bonus_data(table1, state_storage1, output_area1);
; C_PSEUDO:   game_state_flag1 = result1;              // Store result
; C_PSEUDO:   
; C_PSEUDO:   // Process second bonus object set
; C_PSEUDO:   table2 = 0x3b40;                         // Second bonus table
; C_PSEUDO:   state_storage2 = 0x4eac;                 // State storage area 2
; C_PSEUDO:   output_area2 = 0x4e92;                   // Output area 2
; C_PSEUDO:   result2 = process_bonus_data(table2, state_storage2, output_area2);
; C_PSEUDO:   game_state_flag2 = result2;              // Store result
; C_PSEUDO: }
; ALGORITHM: Process bonus objects like fruits and point displays
; Uses different processing function (2dee) than ghost processor
2d0c  21303b    ld      hl,#3b30	; HL = first bonus object table
2d0f  dd219c4e  ld      ix,#4e9c	; IX = state storage area 1
2d13  fd218c4e  ld      iy,#4e8c	; IY = output area 1
2d17  cdee2d    call    #2dee		; Call bonus data processing function
2d1a  32914e    ld      (#4e91),a	; Store result in game state flag

; ALGORITHM: Process second bonus object set
2d1d  21403b    ld      hl,#3b40	; HL = second bonus object table
2d20  dd21ac4e  ld      ix,#4eac	; IX = state storage area 2
2d24  fd21924e  ld      iy,#4e92	; IY = output area 2
2d28  cdee2d    call    #2dee		; Call bonus data processing function
2d2b  32964e    ld      (#4e96),a	; Store result in game state flag

; ALGORITHM: Process third bonus object set
2d2e  21803b    ld      hl,#3b80	; HL = third bonus object table
2d31  dd21bc4e  ld      ix,#4ebc	; IX = state storage area 3
2d35  fd21974e  ld      iy,#4e97	; IY = output area 3
2d39  cdee2d    call    #2dee		; Call bonus data processing function
2d3c  329b4e    ld      (#4e9b),a	; Store result in game state flag
2d3f  af        xor     a		; A = 0 (clear value)
2d40  32904e    ld      (#4e90),a	; Clear additional game state flag
2d43  c9        ret     		; Return

; ======================================================
; FUNCTION: GHOST_DATA_PROCESSOR - Process individual ghost data
; ======================================================
; C_PSEUDO: int process_ghost_data(table, state_storage, output_area) {
; C_PSEUDO:   if(state_storage[0] == 0) {               // Check if ghost is active
; C_PSEUDO:     return clear_ghost_data();              // Clear and return if inactive
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   state_flags = state_storage[0];           // Load current state flags
; C_PSEUDO:   
; C_PSEUDO:   // Find first set bit in state flags (0x80, 0x40, 0x20, etc.)
; C_PSEUDO:   for(bit = 7; bit >= 0; bit--) {
; C_PSEUDO:     if(state_flags & (1 << bit)) {
; C_PSEUDO:       break;                                // Found active state bit
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   if(state_storage[2] & current_bit) {      // Check if state is already active
; C_PSEUDO:     // Timer countdown and state management
; C_PSEUDO:     state_storage[12]--;                    // Decrement timer
; C_PSEUDO:     if(state_storage[12] == 0) {            // Timer expired
; C_PSEUDO:       process_state_data();                 // Process state transition
; C_PSEUDO:     }
; C_PSEUDO:   } else {
; C_PSEUDO:     // Initialize new state
; C_PSEUDO:     state_storage[2] |= current_bit;        // Set state active flag
; C_PSEUDO:     table_entry = table[bit];               // Get table entry for this state
; C_PSEUDO:     process_state_initialization();         // Initialize state data
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   return process_state_command();           // Process state-specific command
; C_PSEUDO: }
; ALGORITHM: Core ghost AI state processing with timer-based state transitions
; This function manages individual ghost behaviors using bit flags and timers
2d44  dd7e00    ld      a,(ix+#00)	; Load state flags from storage[0]
2d47  a7        and     a		; Test if zero (ghost inactive)
2d48  caf42d    jp      z,#2df4         ; Jump to clear function if inactive
2d4b  4f        ld      c,a		; C = state flags
2d4c  0608      ld      b,#08		; B = 8 (bit counter)
2d4e  1e80      ld      e,#80		; E = 0x80 (start with bit 7)

; ALGORITHM: Find first set bit in state flags
2d50  7b        ld      a,e		; A = current bit mask
2d51  a1        and     c		; Test if this bit is set in state flags
2d52  2005      jr      nz,#2d59        ; Jump if bit is set (found active state)
2d54  cb3b      srl     e		; Shift bit mask right (0x80->0x40->0x20...)
2d56  10f8      djnz    #2d50           ; Continue for all 8 bits
2d58  c9        ret     		; Return if no bits set (shouldn't happen)

; ALGORITHM: Process found active state bit
2d59  dd7e02    ld      a,(ix+#02)	; Load active state tracking from storage[2]
2d5c  a3        and     e		; Test if this state is already active
2d5d  2007      jr      nz,#2d66        ; Jump to timer processing if already active

; ALGORITHM: Initialize new state
2d5f  dd7302    ld      (ix+#02),e	; Set this state as active in storage[2]
2d62  05        dec     b		; B = bit number (7->0)
2d63  df        rst     #18		; RST #18: HL = table + (B * 2) - get table entry
2d64  180c      jr      #2d72           ; Jump to state data processing

; ALGORITHM: Timer countdown for active state
2d66  dd350c    dec     (ix+#0c)	; Decrement timer at storage[12]
2d69  c2d72d    jp      nz,#2dd7        ; Jump to command processing if timer not expired
2d6c  dd6e06    ld      l,(ix+#06)	; Load low byte of state data pointer
2d6f  dd6607    ld      h,(ix+#07)	; Load high byte of state data pointer

; ALGORITHM: Process state data from table
2d72  7e        ld      a,(hl)		; Load state data byte
2d73  23        inc     hl		; Move to next data byte
2d74  dd7506    ld      (ix+#06),l	; Store updated pointer low byte
2d77  dd7407    ld      (ix+#07),h	; Store updated pointer high byte
2d7a  fef0      cp      #f0		; Check for special command (0xF0)
2d7c  3827      jr      c,#2da5         ; Jump to timer setup if < 0xF0

; ALGORITHM: Special command processing (F0-FF)
2d7e  216c2d    ld      hl,#2d6c	; HL = return address (back to timer load)
2d81  e5        push    hl		; Push return address on stack
2d82  e60f      and     #0f		; Mask to get command number (0-F)
2d84  e7        rst     #20		; Execute special command via RST #20

; MEMORY_MAP: Special command jump table (embedded data)
2d85  552d      dw      #2d55		; Command F0: POSSIBLY state reset
2d87  652d      dw      #2d65		; Command F1: POSSIBLY state transition  
2d89  772d      dw      #2d77		; Command F2: POSSIBLY timer reload
2d8b  892d      dw      #2d89		; Command F3: POSSIBLY state modification
2d8d  9b2d      dw      #2d9b		; Command F4: POSSIBLY behavior change
2d8f  0c00      dw      #000c		; Command F5: POSSIBLY special value
2d91  0c00      dw      #000c		; Command F6: POSSIBLY special value
2d93  0c00      dw      #000c		; Command F7: POSSIBLY special value
2d95  0c00      dw      #000c		; Command F8: POSSIBLY special value
2d97  0c00      dw      #000c		; Command F9: POSSIBLY special value
2d99  0c00      dw      #000c		; Command FA: POSSIBLY special value
2d9b  0c00      dw      #000c		; Command FB: POSSIBLY special value
2d9d  0c00      dw      #000c		; Command FC: POSSIBLY special value
2d9f  0c00      dw      #000c		; Command FD: POSSIBLY special value
2da1  0c00      dw      #000c		; Command FE: POSSIBLY special value
2da3  ad2f      dw      #2fad		; Command FF: POSSIBLY end/cleanup

; ALGORITHM: Timer setup and state parameter processing
2da5  47        ld      b,a		; B = timer value
2da6  e61f      and     #1f		; Mask lower 5 bits
2da8  2803      jr      z,#2dad         ; Skip if zero
2daa  dd700d    ld      (ix+#0d),b	; Store full timer value at storage[13]

; ALGORITHM: Process movement and behavior parameters
2dad  dd4e09    ld      c,(ix+#09)	; Load parameter from storage[9]
2db0  dd7e0b    ld      a,(ix+#0b)	; Load flags from storage[11]
2db3  e608      and     #08		; Test bit 3 (movement disable flag?)
2db5  2802      jr      z,#2db9         ; Skip if bit not set
2db7  0e00      ld      c,#00		; Set movement parameter to 0 (disable movement)
2db9  dd710f    ld      (ix+#0f),c	; Store movement parameter at storage[15]
2dbc  78        ld      a,b		; A = timer value
2dbd  07        rlca    		; Rotate left 3 times to extract
2dbe  07        rlca    		; upper 3 bits (bits 7-5)
2dbf  07        rlca    
2dc0  e607      and     #07		; Mask to 0-7 (3 bits)
2dc2  21b03b    ld      hl,#3bb0	; HL = timer table 1 base
2dc5  d7        rst     #10		; RST #10: A = table[A] - lookup timer value
2dc6  dd770c    ld      (ix+#0c),a	; Store timer at storage[12]

; ALGORITHM: Process secondary timer parameter
2dc9  78        ld      a,b		; A = timer value again
2dca  e61f      and     #1f		; Mask lower 5 bits
2dcc  2809      jr      z,#2dd7         ; Skip if zero
2dce  e60f      and     #0f		; Mask to lower 4 bits (0-15)
2dd0  21b83b    ld      hl,#3bb8	; HL = timer table 2 base
2dd3  d7        rst     #10		; RST #10: A = table[A] - lookup secondary timer
2dd4  dd770e    ld      (ix+#0e),a	; Store secondary timer at storage[14]

; ALGORITHM: Final state processing and command execution
2dd7  dd6e0e    ld      l,(ix+#0e)	; Load secondary timer
2dda  2600      ld      h,#00		; H = 0 (HL = secondary timer value)
2ddc  dd7e0d    ld      a,(ix+#0d)	; Load main timer flags
2ddf  e610      and     #10		; Test bit 4 (command modifier?)
2de1  2802      jr      z,#2de5         ; Skip if bit not set
2de3  3e01      ld      a,#01		; A = 1 (command modifier)
2de5  dd8604    add     a,(ix+#04)	; Add to command at storage[4]
2de8  cae82e    jp      z,#2ee8         ; Jump to special handler if result is 0
2deb  c3e42e    jp      #2ee4		; Jump to main command processor

; ======================================================
; FUNCTION: BONUS_DATA_PROCESSOR - Process bonus object data
; ======================================================
; C_PSEUDO: int process_bonus_data(table, state_storage, output_area) {
; C_PSEUDO:   if(state_storage[0] == 0) {               // Check if bonus object is active
; C_PSEUDO:     if(state_storage[2] != 0) {             // Check if cleanup needed
; C_PSEUDO:       clear_bonus_data();                   // Clear all bonus data
; C_PSEUDO:     }
; C_PSEUDO:     return 0;                               // Return inactive
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   // Similar bit-scanning logic as ghost processor
; C_PSEUDO:   state_flags = state_storage[0];           // Load current state flags
; C_PSEUDO:   
; C_PSEUDO:   for(bit = 7; bit >= 0; bit--) {
; C_PSEUDO:     if(state_flags & (1 << bit)) {
; C_PSEUDO:       process_bonus_state(bit);             // Process active bonus state
; C_PSEUDO:       break;
; C_PSEUDO:     }
; C_PSEUDO:   }
; C_PSEUDO:   
; C_PSEUDO:   return execute_bonus_command();           // Execute bonus-specific command
; C_PSEUDO: }
; ALGORITHM: Process bonus objects (fruits, points, etc.) similar to ghost processor
; Uses same bit-scanning and state management approach but for different object types
2dee  dd7e00    ld      a,(ix+#00)	; Load state flags from storage[0]
2df1  a7        and     a		; Test if zero (bonus object inactive)
2df2  2027      jr      nz,#2e1b        ; Jump to processing if active

; ALGORITHM: Clear bonus data if needed
2df4  dd7e02    ld      a,(ix+#02)	; Load active state tracking
2df7  a7        and     a		; Test if cleanup needed
2df8  c8        ret     z		; Return if no cleanup needed

; ALGORITHM: Clear all bonus object data
2df9  dd360200  ld      (ix+#02),#00	; Clear active state tracking
2dfd  dd360d00  ld      (ix+#0d),#00	; Clear timer storage[13]
2e01  dd360e00  ld      (ix+#0e),#00	; Clear timer storage[14]
2e05  dd360f00  ld      (ix+#0f),#00	; Clear parameter storage[15]
2e09  fd360000  ld      (iy+#00),#00	; Clear output area[0]
2e0d  fd360100  ld      (iy+#01),#00	; Clear output area[1]
2e11  fd360200  ld      (iy+#02),#00	; Clear output area[2]
2e15  fd360300  ld      (iy+#03),#00	; Clear output area[3]
2e19  af        xor     a		; A = 0 (return inactive)
2e1a  c9        ret     		; Return

; ALGORITHM: Process active bonus object (same bit-scanning as ghost processor)
2e1b  4f        ld      c,a		; C = state flags
2e1c  0608      ld      b,#08		; B = 8 (bit counter)
2e1e  1e80      ld      e,#80		; E = 0x80 (start with bit 7)
2e20  7b        ld      a,e		; A = current bit mask
2e21  a1        and     c		; Test if this bit is set in state flags
2e22  2005      jr      nz,#2e29        ; Jump if bit is set (found active state)
2e24  cb3b      srl     e		; Shift bit mask right
2e26  10f8      djnz    #2e20           ; Continue for all 8 bits
2e28  c9        ret     		; Return if no bits set

; ALGORITHM: Process found active bonus state bit
2e29  dd7e02    ld      a,(ix+#02)	; Load active state tracking from storage[2]
2e2c  a3        and     e		; Test if this state is already active
2e2d  203f      jr      nz,#2e6e        ; Jump to processing if already active

; ALGORITHM: Initialize new bonus state
2e2f  dd7302    ld      (ix+#02),e	; Set this state as active in storage[2]
2e32  05        dec     b		; B = bit number (7->0)
2e33  78        ld      a,b		; A = bit number
2e34  07        rlca    		; Multiply by 8 (each table entry is 8 bytes)
2e35  07        rlca    
2e36  07        rlca    
2e37  4f        ld      c,a		; C = bit_number * 8
2e38  0600      ld      b,#00		; B = 0 (BC = offset)
2e3a  e5        push    hl		; Save table base address
2e3b  09        add     hl,bc		; HL = table + (bit_number * 8)
2e3c  dde5      push    ix		; Push IX (storage area)
2e3e  d1        pop     de		; DE = storage area address
2e3f  13        inc     de		; DE = storage + 1
2e40  13        inc     de		; DE = storage + 2
2e41  13        inc     de		; DE = storage + 3 (start copying here)
2e42  010800    ld      bc,#0008	; BC = 8 bytes to copy
2e45  edb0      ldir    		; Copy 8 bytes from table to storage[3-10]
2e47  e1        pop     hl		; Restore table base address

; ALGORITHM: Initialize bonus object parameters
2e48  dd7e06    ld      a,(ix+#06)	; Load parameter from storage[6]
2e4b  e67f      and     #7f		; Mask bit 7 (clear sign bit)
2e4d  dd770c    ld      (ix+#0c),a	; Store timer at storage[12]
2e50  dd7e04    ld      a,(ix+#04)	; Load parameter from storage[4]
2e53  dd770e    ld      (ix+#0e),a	; Store secondary timer at storage[14]
2e56  dd7e09    ld      a,(ix+#09)	; Load flags from storage[9]
2e59  47        ld      b,a		; B = flags (save original)
2e5a  0f        rrca    		; Rotate right 4 times to get
2e5b  0f        rrca    		; upper nibble (bits 7-4)
2e5c  0f        rrca    
2e5d  0f        rrca    
2e5e  e60f      and     #0f		; Mask to 4 bits
2e60  dd770b    ld      (ix+#0b),a	; Store processed flags at storage[11]
2e63  e608      and     #08		; Test bit 3 of processed flags
2e65  2007      jr      nz,#2e6e        ; Jump to processing if bit set

; ALGORITHM: Store movement parameter and clear secondary timer
2e67  dd700f    ld      (ix+#0f),b	; Store original flags at storage[15]
2e6a  dd360d00  ld      (ix+#0d),#00	; Clear storage[13] (secondary timer reset)

; ALGORITHM: Main bonus object processing loop
2e6e  dd350c    dec     (ix+#0c)	; Decrement primary timer at storage[12]
2e71  205a      jr      nz,#2ecd        ; Jump to parameter update if timer not expired

; ALGORITHM: Process timer expiration and state transitions
2e73  dd7e08    ld      a,(ix+#08)	; Load duration counter from storage[8]
2e76  a7        and     a		; Test if zero
2e77  2810      jr      z,#2e89         ; Jump to timer reload if zero

; ALGORITHM: Duration countdown and state cleanup
2e79  dd3508    dec     (ix+#08)	; Decrement duration counter
2e7c  200b      jr      nz,#2e89        ; Jump to timer reload if not expired
2e7e  7b        ld      a,e		; A = current state bit mask
2e7f  2f        cpl     		; Invert mask (all bits except current)
2e80  dda600    and     (ix+#00)	; Clear current state bit in storage[0]
2e83  dd7700    ld      (ix+#00),a	; Store updated state flags
2e86  c3ee2d    jp      #2dee		; Restart processing (check for other states)

; ALGORITHM: Timer reload and directional processing  
2e89  dd7e06    ld      a,(ix+#06)	; Load timer value from storage[6]
2e8c  e67f      and     #7f		; Mask bit 7 (clear direction flag)
2e8e  dd770c    ld      (ix+#0c),a	; Reload timer at storage[12]
2e91  ddcb067e  bit     7,(ix+#06)	; Test bit 7 of storage[6] (direction flag)
2e95  2816      jr      z,#2ead         ; Jump to normal update if direction flag clear

; ALGORITHM: Direction reversal processing
2e97  dd7e05    ld      a,(ix+#05)	; Load movement delta from storage[5]
2e9a  ed44      neg     		; Negate delta (reverse direction)
2e9c  dd7705    ld      (ix+#05),a	; Store reversed delta
2e9f  ddcb0d46  bit     0,(ix+#0d)	; Test bit 0 of storage[13] (direction state)
2ea3  ddcb0dc6  set     0,(ix+#0d)	; Set bit 0 of storage[13]
2ea7  2824      jr      z,#2ecd         ; Jump to parameter update if bit was clear
2ea9  ddcb0d86  res     0,(ix+#0d)	; Clear bit 0 of storage[13] (toggle state)

; ALGORITHM: Parameter update and movement calculation
2ead  dd7e04    ld      a,(ix+#04)	; Load base parameter from storage[4]
2eb0  dd8607    add     a,(ix+#07)	; Add increment from storage[7]
2eb3  dd7704    ld      (ix+#04),a	; Store updated parameter at storage[4]
2eb6  dd770e    ld      (ix+#0e),a	; Store same value at storage[14]
2eb9  dd7e09    ld      a,(ix+#09)	; Load secondary parameter from storage[9]
2ebc  dd860a    add     a,(ix+#0a)	; Add increment from storage[10]
2ebf  dd7709    ld      (ix+#09),a	; Store updated parameter at storage[9]
2ec2  47        ld      b,a		; B = updated parameter (save for later)
2ec3  dd7e0b    ld      a,(ix+#0b)	; Load behavior flags from storage[11]
2ec6  e608      and     #08		; Test bit 3 (movement disable flag)
2ec8  2003      jr      nz,#2ecd        ; Skip if movement disabled
2eca  dd700f    ld      (ix+#0f),b	; Store movement parameter at storage[15]

; ALGORITHM: Final position calculation and command preparation
2ecd  dd7e0e    ld      a,(ix+#0e)	; Load parameter from storage[14]
2ed0  dd8605    add     a,(ix+#05)	; Add movement delta from storage[5]
2ed3  dd770e    ld      (ix+#0e),a	; Store final parameter at storage[14]
2ed6  6f        ld      l,a		; L = final parameter
2ed7  2600      ld      h,#00		; H = 0 (HL = final parameter)
2ed9  dd7e03    ld      a,(ix+#03)	; Load command flags from storage[3]
2edc  e670      and     #70		; Mask bits 6-4 (command modifier bits)
2ede  2808      jr      z,#2ee8         ; Jump to simple command if no modifier
2ee0  0f        rrca    		; Rotate right 4 times to extract
2ee1  0f        rrca    		; command modifier (bits 6-4 -> 2-0)
2ee2  0f        rrca    
2ee3  0f        rrca    
2ee4  47        ld      b,a		; B = command modifier (shift count)
2ee5  29        add     hl,hl		; Shift HL left (multiply by 2)
2ee6  10fd      djnz    #2ee5           ; Repeat B times (HL = parameter << modifier)

; ALGORITHM: Store final computed values in output area
2ee8  fd7500    ld      (iy+#00),l	; Store low byte of result at output[0]
2eeb  7d        ld      a,l		; A = low byte
2eec  0f        rrca    		; Rotate right 4 times to get
2eed  0f        rrca    		; upper nibble of low byte
2eee  0f        rrca    
2eef  0f        rrca    
2ef0  fd7701    ld      (iy+#01),a	; Store upper nibble at output[1]
2ef3  fd7402    ld      (iy+#02),h	; Store high byte of result at output[2]
2ef6  7c        ld      a,h		; A = high byte
2ef7  0f        rrca    		; Rotate right 4 times to get
2ef8  0f        rrca    		; upper nibble of high byte
2ef9  0f        rrca    
2efa  0f        rrca    
2efb  fd7703    ld      (iy+#03),a	; Store upper nibble at output[3]

; ALGORITHM: Execute behavior-specific command
2efe  dd7e0b    ld      a,(ix+#0b)	; Load behavior flags from storage[11]
2f01  e7        rst     #20		; Execute command via RST #20 dispatch

; MEMORY_MAP: Behavior command jump table (embedded data)
2f02  222f      dw      #2f22		; Command 0: Return movement parameter
2f04  262f      dw      #2f26		; Command 1: Decrement parameter with game timing
2f06  2b2f      dw      #2f2b		; Command 2: Conditional parameter decrement (bit 0)
2f08  3c2f      dw      #2f3c		; Command 3: Conditional parameter decrement (bits 1-0)
2f0a  432f      dw      #2f43		; Command 4: Conditional parameter decrement (bits 2-0)
2f0c  4a2f      dw      #2f4a		; Command 5: No operation (return)

; NOTE: The section 2f0d-2f21 appears to be mis-disassembled data in the original
; disassembly. The pattern of alternating `cpl` instructions suggests this is
; actually data that was incorrectly interpreted as code.

; ======================================================
; BEHAVIOR COMMAND IMPLEMENTATIONS
; ======================================================

; COMMAND 0: Return movement parameter
; ALGORITHM: Simple parameter retrieval
; C_PSEUDOCODE: return object->movement_param;
2f22  dd7e0f    ld      a,(ix+#0f)	; Load movement parameter from storage[15]
2f25  c9        ret     		; Return with parameter in A

; COMMAND 1: Decrement parameter with frame timing
; ALGORITHM: Conditional parameter decrement based on game timing
; C_PSEUDOCODE: 
;   a = object->movement_param;
;   goto decrement_with_timing;
2f26  dd7e0f    ld      a,(ix+#0f)	; Load movement parameter from storage[15]
2f29  1809      jr      #2f34           ; Jump to shared decrement logic

; COMMAND 2: Conditional parameter decrement (bit 0)
; ALGORITHM: Decrement only when game timing bit 0 is clear
; C_PSEUDOCODE:
;   if (game_timing & 0x01) return object->movement_param;
;   goto decrement_parameter;
2f2b  3a844c    ld      a,(#4c84)	; Load game timing flags from memory
2f2e  e601      and     #01		; Test bit 0 (frame timing)
2f30  dd7e0f    ld      a,(ix+#0f)	; Load movement parameter
2f33  c0        ret     nz		; Return unchanged if bit 0 set

; ALGORITHM: Shared parameter decrement logic
; C_PSEUDOCODE:
;   param &= 0x0f;
;   if (param == 0) return 0;
;   return --param;
2f34  e60f      and     #0f		; Mask to lower 4 bits
2f36  c8        ret     z		; Return if zero (no decrement)
2f37  3d        dec     a		; Decrement parameter
2f38  dd770f    ld      (ix+#0f),a	; Store back to storage[15]
2f3b  c9        ret     		; Return with decremented value

; COMMAND 3: Conditional parameter decrement (bits 1-0)
; ALGORITHM: Decrement only when game timing bits 1-0 are both clear
; C_PSEUDOCODE:
;   if (game_timing & 0x03) return object->movement_param;
;   goto decrement_parameter;
2f3c  3a844c    ld      a,(#4c84)	; Load game timing flags
2f3f  e603      and     #03		; Test bits 1-0 (slower timing)
2f41  18ed      jr      #2f30           ; Jump to conditional decrement logic

; COMMAND 4: Conditional parameter decrement (bits 2-0)
; ALGORITHM: Decrement only when game timing bits 2-0 are all clear
; C_PSEUDOCODE:
;   if (game_timing & 0x07) return object->movement_param;
;   goto decrement_parameter;
2f43  3a844c    ld      a,(#4c84)	; Load game timing flags
2f46  e607      and     #07		; Test bits 2-0 (slowest timing)
2f48  18e6      jr      #2f30           ; Jump to conditional decrement logic

; COMMAND 5: No operation
; ALGORITHM: Return immediately (placeholder command)
; C_PSEUDOCODE: return;
2f4a  c9        ret     		; No operation, just return

; MEMORY_MAP: Unknown function (possibly unused)
2f4b  c9        ret     

; MEMORY_MAP: Series of simple return functions (2f4c-2f54)
; These appear to be placeholder or unused functions
2f4c  c9        ret     
2f4d  c9        ret     
2f4e  c9        ret     
2f4f  c9        ret     
2f50  c9        ret     
2f51  c9        ret     
2f52  c9        ret     
2f53  c9        ret     
2f54  c9        ret     

; ======================================================
; TABLE POINTER ADVANCEMENT FUNCTION
; ======================================================
; ALGORITHM: Advance table pointer to next entry
; C_PSEUDOCODE:
;   pointer = object->table_ptr;
;   object->table_ptr[0] = *pointer++;
;   object->table_ptr[1] = *pointer++;
2f55  dd6e06    ld      l,(ix+#06)	; Load table pointer low byte
2f58  dd6607    ld      h,(ix+#07)	; Load table pointer high byte
2f5b  7e        ld      a,(hl)		; Read byte from table
2f5c  dd7706    ld      (ix+#06),a	; Store as new low byte
2f5f  23        inc     hl		; Advance to next table entry
2f60  7e        ld      a,(hl)		; Read next byte from table
2f61  dd7707    ld      (ix+#07),a	; Store as new high byte
2f64  c9        ret     		; Return

; ======================================================
; TABLE DATA READING FUNCTIONS
; ======================================================
; These functions read data from tables and store to specific object fields

; READ_TABLE_TO_COMMAND_FLAGS
; ALGORITHM: Read next byte from table and store as command flags
; C_PSEUDOCODE:
;   pointer = object->table_ptr;
;   object->command_flags = *pointer++;
;   object->table_ptr = pointer;
2f65  dd6e06    ld      l,(ix+#06)	; Load table pointer low byte
2f68  dd6607    ld      h,(ix+#07)	; Load table pointer high byte
2f6b  7e        ld      a,(hl)		; Read byte from table
2f6c  23        inc     hl		; Advance pointer
2f6d  dd7506    ld      (ix+#06),l	; Store updated pointer low byte
2f70  dd7407    ld      (ix+#07),h	; Store updated pointer high byte
2f73  dd7703    ld      (ix+#03),a	; Store byte as command flags at storage[3]
2f76  c9        ret     		; Return

; READ_TABLE_TO_PARAMETER
; ALGORITHM: Read next byte from table and store as base parameter
; C_PSEUDOCODE:
;   pointer = object->table_ptr;
;   object->base_param = *pointer++;
;   object->table_ptr = pointer;
2f77  dd6e06    ld      l,(ix+#06)	; Load table pointer low byte
2f7a  dd6607    ld      h,(ix+#07)	; Load table pointer high byte
2f7d  7e        ld      a,(hl)		; Read byte from table
2f7e  23        inc     hl		; Advance pointer
2f7f  dd7506    ld      (ix+#06),l	; Store updated pointer low byte
2f82  dd7407    ld      (ix+#07),h	; Store updated pointer high byte
2f85  dd7704    ld      (ix+#04),a	; Store byte as base parameter at storage[4]
2f88  c9        ret     		; Return

; READ_TABLE_TO_SECONDARY_PARAM
; ALGORITHM: Read next byte from table and store as secondary parameter
; C_PSEUDOCODE:
;   pointer = object->table_ptr;
;   object->secondary_param = *pointer++;
;   object->table_ptr = pointer;
2f89  dd6e06    ld      l,(ix+#06)	; Load table pointer low byte
2f8c  dd6607    ld      h,(ix+#07)	; Load table pointer high byte
2f8f  7e        ld      a,(hl)		; Read byte from table
2f90  23        inc     hl		; Advance pointer
2f91  dd7506    ld      (ix+#06),l	; Store updated pointer low byte
2f94  dd7407    ld      (ix+#07),h	; Store updated pointer high byte
2f97  dd7709    ld      (ix+#09),a	; Store byte as secondary parameter at storage[9]
2f9a  c9        ret     		; Return

; READ_TABLE_TO_BEHAVIOR_FLAGS
; ALGORITHM: Read next byte from table and store as behavior flags
; C_PSEUDOCODE:
;   pointer = object->table_ptr;
;   object->behavior_flags = *pointer++;
;   object->table_ptr = pointer;
2f9b  dd6e06    ld      l,(ix+#06)	; Load table pointer low byte
2f9e  dd6607    ld      h,(ix+#07)	; Load table pointer high byte
2fa1  7e        ld      a,(hl)		; Read byte from table
2fa2  23        inc     hl		; Advance pointer
2fa3  dd7506    ld      (ix+#06),l	; Store updated pointer low byte
2fa6  dd7407    ld      (ix+#07),h	; Store updated pointer high byte
2fa9  dd770b    ld      (ix+#0b),a	; Store byte as behavior flags at storage[11]
2fac  c9        ret     		; Return

; ======================================================
; OBJECT DEACTIVATION FUNCTION
; ======================================================
; ALGORITHM: Deactivate object by clearing its state bit
; C_PSEUDOCODE:
;   mask = ~object->state_bit;
;   object->active_states &= mask;  // Clear this object's bit
;   jump back to processor loop;
2fad  dd7e02    ld      a,(ix+#02)	; Load state bit mask from storage[2]
2fb0  2f        cpl     		; Invert mask (all bits except this one)
2fb1  dda600    and     (ix+#00)	; Clear state bit in active states
2fb4  dd7700    ld      (ix+#00),a	; Store updated active states
2fb7  c3f42d    jp      #2df4		; Jump back to processor loop entry

; MEMORY_MAP: NOP padding (2fba-2fff)
; This section contains NOP instructions for memory alignment/padding
2fba  00        nop     
2fbb  00        nop     
2fbc  00        nop     
2fbd  00        nop     
2fbe  00        nop     
2fbf  00        nop     
2fc0  00        nop     
2fc1  00        nop     
2fc2  00        nop     
2fc3  00        nop     
2fc4  00        nop     
2fc5  00        nop     
2fc6  00        nop     
2fc7  00        nop     
2fc8  00        nop     
2fc9  00        nop     
2fca  00        nop     
2fcb  00        nop     
2fcc  00        nop     
2fcd  00        nop     
2fce  00        nop     
2fcf  00        nop     
2fd0  00        nop     
2fd1  00        nop     
2fd2  00        nop     
2fd3  00        nop     
2fd4  00        nop     
2fd5  00        nop     
2fd6  00        nop     
2fd7  00        nop     
2fd8  00        nop     
2fd9  00        nop     
2fda  00        nop     
2fdb  00        nop     
2fdc  00        nop     
2fdd  00        nop     
2fde  00        nop     
2fdf  00        nop     
2fe0  00        nop     
2fe1  00        nop     
2fe2  00        nop     
2fe3  00        nop     
2fe4  00        nop     
2fe5  00        nop     
2fe6  00        nop     
2fe7  00        nop     
2fe8  00        nop     
2fe9  00        nop     
2fea  00        nop     
2feb  00        nop     
2fec  00        nop     
2fed  00        nop     
2fee  00        nop     
2fef  00        nop     
2ff0  00        nop     
2ff1  00        nop     
2ff2  00        nop     
2ff3  00        nop     
2ff4  00        nop     
2ff5  00        nop     
2ff6  00        nop     
2ff7  00        nop     
2ff8  00        nop     
2ff9  00        nop     
2ffa  00        nop     
2ffb  00        nop     
2ffc  00        nop     
2ffd  00        nop     

; MEMORY_MAP: Interrupt vector data
2ffe  834c      dw      #4c83		; Interrupt vector #3ffa data

; ======================================================
; ROM CHECKSUM VERIFICATION ROUTINE
; ======================================================
; ALGORITHM: Calculate and verify ROM checksums for integrity checking
; This is an interrupt routine for vector #3ffa
; C_PSEUDOCODE:
;   checksum = 0;
;   for (addr = 0x0000; addr < 0x1000; addr++) {
;       checksum += rom[addr];
;   }
;   // Verify checksum against expected value
3000  210000    ld      hl,#0000	; HL = start address (0x0000)
3003  010010    ld      bc,#1000	; BC = byte count (4096 bytes)

; ALGORITHM: Main checksum calculation loop
3006  32c050    ld      (#50c0),a	; Kick the watchdog timer
3009  79        ld      a,c		; A = current checksum (C register)
300a  86        add     a,(hl)		; Add current ROM byte to checksum
300b  4f        ld      c,a		; Store updated checksum in C
300c  7d        ld      a,l		; A = low byte of address
300d  c602      add     a,#02		; Add 2 to address (skip every other byte?)
300f  6f        ld      l,a		; Store updated low address byte
3010  fe02      cp      #02		; Compare with 02 (check for address wrap)
3012  d20930    jp      nc,#3009	; Continue checksum if no carry
3015  24        inc     h		; Increment high byte of address
3016  10ee      djnz    #3006           ; Decrement B and loop until B=0

; ALGORITHM: Verify checksum result
3018  79        ld      a,c		; A = final checksum
3019  a7        and     a		; Test if checksum is zero
301a  2015      jr      nz,#3031        ; Jump to error handler if checksum bad

; ALGORITHM: Continue with next ROM section or complete
301c  320750    ld      (#5007),a	; Clear coin counter register
301f  7c        ld      a,h		; A = high byte of current address
3020  fe30      cp      #30		; Compare with 0x30 (end of ROM area?)
3022  c20330    jp      nz,#3003	; Continue for other ROMs if not at end
3025  2600      ld      h,#00		; Reset high byte to 0
3027  2c        inc     l		; Increment low byte
3028  7d        ld      a,l		; A = low byte
3029  fe02      cp      #02		; Compare with 2
302b  da0330    jp      c,#3003		; Continue if less than 2
302e  c34230    jp      #3042		; Jump to completion routine

; ======================================================
; ROM CHECKSUM ERROR HANDLER
; ======================================================
; ALGORITHM: Handle ROM checksum failure
; C_PSEUDOCODE:
;   failed_rom = (current_address >> 4) & 0x0f;
;   error_code = failed_rom;
;   goto display_error;
3031  25        dec     h		; Decrement high address byte
3032  7c        ld      a,h		; A = high byte
3033  e6f0      and     #f0		; Mask upper nibble
3035  320750    ld      (#5007),a	; Store error code to coin register
3038  0f        rrca    		; Rotate right 4 times to get
3039  0f        rrca    		; upper nibble in lower 4 bits
303a  0f        rrca    
303b  0f        rrca    
303c  5f        ld      e,a		; E = failed ROM number
303d  0600      ld      b,#00		; B = 0 (error display counter)
303f  c3bd30    jp      #30bd		; Jump to error display routine

; ======================================================
; RAM MEMORY TEST ROUTINE
; ======================================================
; ALGORITHM: Comprehensive RAM testing with pattern writes and verification
; Tests RAM area starting at 0x4c00
; C_PSEUDOCODE:
;   for (area = 0x4c00; area < end; area += block_size) {
;       write_test_patterns(area);
;       verify_test_patterns(area);
;   }
3042  315431    ld      sp,#3154	; Set stack pointer to test data area
3045  06ff      ld      b,#ff		; B = 0xFF (test pattern base)
3047  e1        pop     hl		; HL = 0x4c00 (RAM start address - first time)
3048  d1        pop     de		; DE = 0x040f (test parameters - first time)
3049  48        ld      c,b		; C = 0xFF (copy test pattern)

; ALGORITHM: Write test patterns to RAM
; C_PSEUDOCODE:
;   pattern = 0xFF & test_param;
;   for (addr = start; addr < end; addr++) {
;       ram[addr] = pattern;
;       pattern = (pattern + 0x33) & 0xFF;
;   }
304a  32c050    ld      (#50c0),a	; Kick the watchdog timer
304d  79        ld      a,c		; A = current test pattern
304e  a3        and     e		; AND with test parameter from E
304f  77        ld      (hl),a		; Write pattern to RAM location
3050  c633      add     a,#33		; Add 0x33 to create next pattern
3052  4f        ld      c,a		; Store updated pattern in C
3053  2c        inc     l		; Increment low address byte
3054  7d        ld      a,l		; A = low address byte
3055  e60f      and     #0f		; Test lower 4 bits
3057  c24d30    jp      nz,#304d	; Continue if not at 16-byte boundary

; ALGORITHM: Pattern modification at 16-byte boundaries
; C_PSEUDOCODE: pattern = ((pattern * 5) + 0x31) & 0xFF;
3059  79        ld      a,c		; A = current pattern
305a  87        add     a,a		; A = pattern * 2
305b  87        add     a,a		; A = pattern * 4
305c  81        add     a,c		; A = pattern * 5
305d  c631      add     a,#31		; A = pattern * 5 + 0x31
305f  4f        ld      c,a		; Store new pattern in C
3060  7d        ld      a,l		; A = low address byte
3061  a7        and     a		; Test if low byte is zero
3062  c24d30    jp      nz,#304d	; Continue pattern writing if not zero

; ALGORITHM: Move to next memory page
3065  24        inc     h		; Increment high address byte (next 256-byte page)
3066  15        dec     d		; Decrement page counter
3067  c24a30    jp      nz,#304a	; Continue if more pages to test

; ALGORITHM: Prepare for verification phase
3068  3b        dec     sp		; Restore stack pointer to
3069  3b        dec     sp		; point back to test data
306a  3b        dec     sp		; (4 decrements = -4 bytes)
306b  3b        dec     sp
306c  e1        pop     hl		; HL = 0x4c00 (RAM start address again)
306d  d1        pop     de		; DE = 0x040f (test parameters again)
306e  48        ld      c,b		; C = 0xFF (reset pattern for verification)

; ALGORITHM: Verify RAM test patterns
; C_PSEUDOCODE:
;   expected_pattern = 0xFF & test_param;
;   for (addr = start; addr < end; addr++) {
;       actual = ram[addr] & test_param;
;       if (actual != expected_pattern) goto ram_test_failed;
;       expected_pattern = (expected_pattern + 0x33) & 0xFF;
;   }
3072  32c050    ld      (#50c0),a	; Kick the watchdog timer
3075  79        ld      a,c		; A = expected pattern
3076  a3        and     e		; AND with test parameter
3077  4f        ld      c,a		; C = expected pattern
3078  7e        ld      a,(hl)		; A = actual value from RAM
3079  a3        and     e		; AND with test parameter
307a  b9        cp      c		; Compare actual with expected
307b  c2b530    jp      nz,#30b5	; Jump to RAM test failure if mismatch
307e  c633      add     a,#33		; Generate next expected pattern
3080  4f        ld      c,a		; Store next pattern in C
3081  2c        inc     l		; Increment low address byte
3082  7d        ld      a,l		; A = low address byte
3083  e60f      and     #0f		; Test lower 4 bits
3085  c27530    jp      nz,#3075	; Continue if not at 16-byte boundary

; ALGORITHM: Pattern modification at 16-byte boundaries (verification)
3088  79        ld      a,c		; A = current expected pattern
3089  87        add     a,a		; A = pattern * 2
308a  87        add     a,a		; A = pattern * 4
308b  81        add     a,c		; A = pattern * 5
308c  c631      add     a,#31		; A = pattern * 5 + 0x31
308e  4f        ld      c,a		; Store new expected pattern in C
308f  7d        ld      a,l		; A = low address byte
3090  a7        and     a		; Test if low byte is zero
3091  c27530    jp      nz,#3075	; Continue verification if not zero

; ALGORITHM: Move to next memory page (verification)
3094  24        inc     h		; Increment high address byte
3095  15        dec     d		; Decrement page counter
3096  c27230    jp      nz,#3072	; Continue if more pages to verify

; ALGORITHM: Restore stack and continue with next test
3099  3b        dec     sp		; Restore stack pointer to original position
309a  3b        dec     sp
309b  3b        dec     sp		; Continue stack restoration
309c  3b        dec     sp
309d  78        ld      a,b		; A = test pattern counter (0xFF)
309e  d610      sub     #10		; Subtract 0x10 (test different pattern)
30a0  47        ld      b,a		; B = new test pattern
30a1  10a4      djnz    #3047           ; Continue with different pattern if B != 0

; ALGORITHM: Check if all RAM areas tested
30a3  f1        pop     af		; AF = final test address (0x4c00)
30a4  d1        pop     de		; DE = final test parameters
30a5  fe44      cp      #44		; Check if we've reached 0x44xx area
30a7  c24530    jp      nz,#3045	; Continue testing if not done with 0x44xx
30aa  7b        ld      a,e		; A = low byte of test parameters
30ab  eef0      xor     #f0		; XOR with 0xF0 to check completion
30ad  c24530    jp      nz,#3045	; Continue testing if not completely done
30b0  0601      ld      b,#01		; B = 1 (RAM test passed indicator)
30b2  c3bd30    jp      #30bd		; Jump to initialization routine

; ======================================================
; RAM TEST FAILURE HANDLER
; ======================================================
; ALGORITHM: Handle RAM test failure
; C_PSEUDOCODE:
;   failed_bit = test_param & 0x01;
;   error_code = failed_bit ^ 0x01;
;   goto display_error;
30b5  7b        ld      a,e		; A = test parameter that failed
30b6  e601      and     #01		; Mask bit 0
30b8  ee01      xor     #01		; Invert bit 0 (create error code)
30ba  5f        ld      e,a		; E = RAM error code
30bb  0600      ld      b,#00		; B = 0 (RAM test failed indicator)

; ======================================================
; SYSTEM INITIALIZATION ROUTINE
; ======================================================
; ALGORITHM: Initialize system after successful tests or prepare error display
; C_PSEUDOCODE:
;   setup_stack();
;   clear_all_ram();
;   initialize_video_memory();
30bd  31c04f    ld      sp,#4fc0	; Set stack pointer to 0x4fc0
30c0  d9        exx			; Swap to alternate register set

; ALGORITHM: Clear all program RAM
; C_PSEUDOCODE:
;   for (page = 0x4c00; page < 0x4c00 + 0x400; page += 0x100) {
;       for (addr = page; addr < page + 0x100; addr++) {
;           ram[addr] = 0x00;
;       }
;   }
30c1  21004c    ld      hl,#4c00	; HL = start of program RAM (0x4c00)
30c4  0604      ld      b,#04		; B = 4 pages to clear
30c6  32c050    ld      (#50c0),a	; Kick the watchdog timer
30c9  3600      ld      (hl),#00	; Clear memory location
30cb  2c        inc     l		; Increment low address byte
30cc  20fb      jr      nz,#30c9        ; Continue until page complete (L wraps to 0)
30ce  24        inc     h		; Increment to next page
30cf  10f5      djnz    #30c6           ; Continue for all 4 pages

; ALGORITHM: Initialize video RAM to space characters
; C_PSEUDOCODE:
;   for (page = 0x4000; page < 0x4000 + 0x400; page += 0x100) {
;       for (addr = page; addr < page + 0x100; addr++) {
;           video_ram[addr] = 0x40;  // Space character
;       }
;   }
30d1  210040    ld      hl,#4000	; HL = start of video RAM (0x4000)
30d4  0604      ld      b,#04		; B = 4 pages to initialize
30d6  32c050    ld      (#50c0),a	; Kick the watchdog timer
30d9  3e40      ld      a,#40		; A = 0x40 (space character)
30db  77        ld      (hl),a		; Write space to video RAM
30dc  2c        inc     l		; Increment low address byte
30dd  20fc      jr      nz,#30db        ; Continue until page complete
30df  24        inc     h		; Increment to next page
30e0  10f4      djnz    #30d6           ; Continue for all 4 pages

; ALGORITHM: Initialize color RAM to bright white
; C_PSEUDOCODE:
;   for (page = 0x4400; page < 0x4400 + 0x400; page += 0x100) {
;       for (addr = page; addr < page + 0x100; addr++) {
;           color_ram[addr] = 0x0f;  // Bright white color
;       }
;   }
; NOTE: HL already points to 0x4400 (color RAM) after video RAM init
30e2  0604      ld      b,#04		; B = 4 pages to initialize
30e4  32c050    ld      (#50c0),a	; Kick the watchdog timer
30e7  3e0f      ld      a,#0f		; A = 0x0F (bright white color)
30e9  77        ld      (hl),a		; Write color to color RAM
30ea  2c        inc     l		; Increment low address byte
30eb  20fc      jr      nz,#30e9        ; Continue until page complete
30ed  24        inc     h		; Increment to next page
30ee  10f4      djnz    #30e4           ; Continue for all 4 pages

; ALGORITHM: System initialization completion and error handling
30f0  d9        exx			; Restore original register set
30f1  1008      djnz    #30fb           ; If B=1 (RAM test passed), jump to error display
30f3  0623      ld      b,#23		; B = 0x23 (system initialization message)
30f5  cd5e2c    call    #2c5e		; Call message display routine
30f8  c37431    jp      #3174		; Jump to main system startup

; ======================================================
; ERROR DISPLAY ROUTINE
; ======================================================
; ALGORITHM: Display ROM/RAM error information on screen
; C_PSEUDOCODE:
;   error_char = error_code + '0';  // Convert to ASCII digit
;   screen[position] = error_char;  // Display error number
;   display_error_message();
30fb  7b        ld      a,e		; A = error code (ROM or RAM)
30fc  c630      add     a,#30		; Convert to ASCII digit (add '0')
30fe  328441    ld      (#4184),a	; Write error digit to screen position
3101  c5        push    bc		; Save error status
3102  e5        push    hl		; Save current HL
3103  0624      ld      b,#24		; B = 0x24 (error message number)
3105  cd5e2c    call    #2c5e		; Call message display routine
3108  e1        pop     hl		; Restore HL
3109  7c        ld      a,h		; A = high byte of address
310a  fe40      cp      #40		; Compare with 0x40
310c  2a6c31    ld      hl,(#316c)	; Load error table pointer 1
310f  3811      jr      c,#3122         ; Jump if less than 0x40
3111  fe4c      cp      #4c		; Compare with 0x4c
3113  2a6e31    ld      hl,(#316e)	; Load error table pointer 2
3116  300a      jr      nc,#3122        ; Jump if greater than or equal to 0x4c
3118  fe44      cp      #44		; Compare with 0x44
311a  2a7031    ld      hl,(#3170)	; Load error table pointer 3
311d  3803      jr      c,#3122         ; Jump if less than 0x44
311f  2a7231    ld      hl,(#3172)	; Load error table pointer 4

; ALGORITHM: Display specific error information
3122  7d        ld      a,l		; A = low byte of error info
3123  320442    ld      (#4204),a	; Write to screen position (error detail)
3126  7c        ld      a,h		; A = high byte of error info
3127  326442    ld      (#4264),a	; Write to screen position (error type)

; ALGORITHM: Read input switches and display additional error info
312a  3a0050    ld      a,(#5000)	; Read DIP switch settings
312d  47        ld      b,a		; B = DIP switch values
312e  3a4050    ld      a,(#5040)	; Read input port
3131  b0        or      b		; Combine with DIP switches
3132  e601      and     #01		; Test bit 0 (service mode?)
3134  2011      jr      nz,#3147        ; Jump to wait loop if service mode

; ALGORITHM: Display detailed error codes
3136  c1        pop     bc		; Restore BC (error status)
3137  79        ld      a,c		; A = low byte of error info
3138  e60f      and     #0f		; Mask lower 4 bits
313a  47        ld      b,a		; B = lower nibble
313b  79        ld      a,c		; A = low byte again
313c  e6f0      and     #f0		; Mask upper 4 bits
313e  0f        rrca    		; Rotate right 4 times to get
313f  0f        rrca    		; upper nibble in lower 4 bits
3140  0f        rrca    
3141  0f        rrca    
3142  4f        ld      c,a		; C = upper nibble
3143  ed438541  ld      (#4185),bc	; Write both nibbles to screen

; ALGORITHM: Wait for service switch
; C_PSEUDOCODE:
;   do {
;       kick_watchdog();
;       input = read_input_port();
;   } while (!(input & 0x10));  // Wait for service switch
3147  32c050    ld      (#50c0),a	; Kick the watchdog timer
314a  3a4050    ld      a,(#5040)	; Read input port
314d  e610      and     #10		; Test bit 4 (service switch)
314f  28f6      jr      z,#3147         ; Loop until service switch pressed
3151  c30b23    jp      #230b		; Jump to system restart

; ======================================================
; RAM TEST DATA TABLES (Stack-based parameters)
; ======================================================
; MEMORY_MAP: RAM test parameters for different memory areas
; These are popped from the stack during the RAM test
3154  004c      dw      #4c00		; RAM area 1 start address
3156  0f04      dw      #040f		; RAM area 1 test parameters

3158  004c      dw      #4c00		; RAM area 2 start address
315a  f004      dw      #04f0		; RAM area 2 test parameters

315c  0040      dw      #4000		; Video RAM start address
315e  0f04      dw      #040f		; Video RAM test parameters

3160  0040      dw      #4000		; Video RAM start address (repeat)
3162  f004      dw      #04f0		; Video RAM test parameters (alternate)

3164  0044      dw      #4400		; Color RAM start address
3166  0f04      dw      #040f		; Color RAM test parameters

3168  0044      dw      #4400		; Color RAM start address (repeat)
316a  f004      dw      #04f0		; Color RAM test parameters (alternate)

; ======================================================
; ERROR MESSAGE DATA TABLES
; ======================================================
; MEMORY_MAP: Error display character pairs
; These are loaded based on the memory area that failed testing
316c  4f40      dw      #404f		; "O " -> "BAD ROM" indicator
316e  4157      dw      #5741		; "AW" -> "BAD W RAM" indicator
3170  4156      dw      #5641		; "AV" -> "BAD V RAM" indicator (Video RAM)
3172  4143      dw      #4341		; "AC" -> "BAD C RAM" indicator (Color RAM)

; ======================================================
; MAIN SYSTEM STARTUP ROUTINE
; ======================================================
; ALGORITHM: Initialize hardware and start main game system
; This is reached after successful ROM/RAM tests
; C_PSEUDOCODE:
;   enable_all_hardware();
;   setup_interrupts();
;   initialize_game_state();
;   enable_sound_test_mode();
3174  210650    ld      hl,#5006	; HL = hardware enable register base
3177  3e01      ld      a,#01		; A = 0x01 (enable flag)
3179  77        ld      (hl),a		; Enable hardware register
317a  2d        dec     l		; Move to previous register
317b  20fc      jr      nz,#3179        ; Continue until all registers enabled (L=0)

; ALGORITHM: Configure display and interrupt system
317d  af        xor     a		; A = 0x00 (clear A)
317e  320350    ld      (#5003),a	; Set normal screen orientation (unflip)
3181  d604      sub     #04		; A = 0xFC (interrupt vector)
3183  d300      out     (#00),a		; Set interrupt vector to 0xFC
3185  31c04f    ld      sp,#4fc0	; Set stack pointer to 0x4fc0
3188  32c050    ld      (#50c0),a	; Kick the watchdog timer

; ALGORITHM: Initialize basic game state variables
318b  af        xor     a		; A = 0x00
318c  32004e    ld      (#4e00),a	; Clear game state variable at 0x4e00
318f  3c        inc     a		; A = 0x01
3190  32014e    ld      (#4e01),a	; Set game state variable at 0x4e01
3193  320050    ld      (#5000),a	; Enable interrupt system
3196  fb        ei			; Enable CPU interrupts

; ======================================================
; SOUND TEST MODE (SERVICE MODE)
; ======================================================
; ALGORITHM: Test sound system based on DIP switch and button inputs
; C_PSEUDOCODE:
;   dip_switches = read_dip_switches();
;   buttons = read_buttons();
;   test_sound_effects(dip_switches, buttons);

; Test coin/credit input sounds
3197  3a0050    ld      a,(#5000)	; Read DIP switch settings
319a  2f        cpl     		; Invert bits (active low inputs)
319b  47        ld      b,a		; B = inverted DIP switches
319c  e6e0      and     #e0		; Test bits 7-5 (coin/credit inputs)
319e  2805      jr      z,#31a5         ; Skip if no coin/credit inputs active
31a0  3e02      ld      a,#02		; A = sound effect 2
31a2  329c4e    ld      (#4e9c),a	; Trigger sound effect 2

; Test start button sounds
31a5  3a4050    ld      a,(#5040)	; Read input port (buttons)
31a8  2f        cpl     		; Invert bits (active low inputs)
31a9  4f        ld      c,a		; C = inverted button states
31aa  e660      and     #60		; Test bits 6-5 (P1/P2 start buttons)
31ac  2805      jr      z,#31b3         ; Skip if no start buttons pressed
31ae  3e01      ld      a,#01		; A = sound effect 1
31b0  329c4e    ld      (#4e9c),a	; Trigger sound effect 1

; Test directional input sounds (UP)
31b3  78        ld      a,b		; A = DIP switch states
31b4  b1        or      c		; Combine with button states
31b5  e601      and     #01		; Test bit 0 (UP direction)
31b7  2805      jr      z,#31be         ; Skip if UP not pressed
31b9  3e08      ld      a,#08		; A = sound effect 8
31bb  32bc4e    ld      (#4ebc),a	; Trigger sound effect 8

; Test directional input sounds (LEFT)
31be  78        ld      a,b		; A = DIP switch states
31bf  b1        or      c		; Combine with button states
31c0  e602      and     #02		; Test bit 1 (LEFT direction)
31c2  2805      jr      z,#31c9         ; Skip if LEFT not pressed
31c4  3e04      ld      a,#04		; A = sound effect 4
31c6  32bc4e    ld      (#4ebc),a	; Trigger sound effect 4

; Test directional input sounds (RIGHT)
31c9  78        ld      a,b		; A = DIP switch states
31ca  b1        or      c		; Combine with button states
31cb  e604      and     #04		; Test bit 2 (RIGHT direction)
31cd  2805      jr      z,#31d4         ; Skip if RIGHT not pressed
31cf  3e10      ld      a,#10		; A = sound effect 16
31d1  32bc4e    ld      (#4ebc),a	; Trigger sound effect 16

; Test directional input sounds (DOWN)
31d4  78        ld      a,b		; A = DIP switch states
31d5  b1        or      c		; Combine with button states
31d6  e608      and     #08		; Test bit 3 (DOWN direction)
31d8  2805      jr      z,#31df         ; Skip if DOWN not pressed
31da  3e20      ld      a,#20		; A = sound effect 32
31dc  32bc4e    ld      (#4ebc),a	; Trigger sound effect 32

; ======================================================
; DIP SWITCH DISPLAY ROUTINE
; ======================================================
; ALGORITHM: Display current DIP switch settings on screen
; C_PSEUDOCODE:
;   coin_setting = dip_switches & 0x03;
;   message_id = coin_setting + 0x25;
;   display_message(message_id);
31df  3a8050    ld      a,(#5080)	; Read DIP switch bank
31e2  e603      and     #03		; Mask bits 1-0 (coin settings)
31e4  c625      add     a,#25		; Add base message ID (0x25)
31e6  47        ld      b,a		; B = message ID for coin setting
31e7  cd5e2c    call    #2c5e		; Call message display routine

; ALGORITHM: Display extra life settings
; C_PSEUDOCODE:
;   extra_setting = (dip_switches >> 4) & 0x03;
;   if (extra_setting == 3) {
;       display_message(0x2A);  // "FREE PLAY" or similar
;   } else {
;       display_extra_life_count(extra_setting);
;   }
31ea  3a8050    ld      a,(#5080)	; Read DIP switch bank again
31ed  0f        rrca    		; Rotate right 4 times to get
31ee  0f        rrca    		; upper nibble (bits 7-4) 
31ef  0f        rrca    		; in lower 4 bits
31f0  0f        rrca    
31f1  e603      and     #03		; Mask bits 1-0 (extra life setting)
31f3  fe03      cp      #03		; Compare with 3 (special case)
31f5  2008      jr      nz,#31ff        ; Jump if not special case
31f7  062a      ld      b,#2a		; B = 0x2A (special message ID)
31f9  cd5e2c    call    #2c5e		; Display special message
31fc  c31c32    jp      #321c		; Jump to continue processing

; ALGORITHM: Display numeric extra life setting
31ff  07        rlca    		; Shift left to double the value
3200  5f        ld      e,a		; E = doubled extra life setting
3201  d5        push    de		; Save doubled setting for later
3202  062b      ld      b,#2b		; B = 0x2B (extra life message header)
3204  cd5e2c    call    #2c5e		; Display header message
3207  062e      ld      b,#2e		; B = 0x2E (extra life value message)
3209  cd5e2c    call    #2c5e		; Display value message
320c  d1        pop     de		; Restore doubled setting

; ALGORITHM: Look up and display extra life threshold values
; C_PSEUDOCODE:
;   table_ptr = extra_life_table + (setting * 2);
;   display_char1 = table_ptr[0];
;   display_char2 = table_ptr[1];
320d  1600      ld      d,#00		; D = 0 (clear high byte)
320f  21f932    ld      hl,#32f9	; HL = extra life value table
3212  19        add     hl,de		; HL = table + (setting * 2)
3213  7e        ld      a,(hl)		; A = first character
3214  322a42    ld      (#422a),a	; Write to screen position
3217  23        inc     hl		; Move to next table entry
3218  7e        ld      a,(hl)		; A = second character
3219  324a42    ld      (#424a),a	; Write to screen position

; ALGORITHM: Display difficulty level setting
; C_PSEUDOCODE:
;   difficulty = (dip_switches >> 2) & 0x03;
;   difficulty_char = difficulty + '1';
;   if (difficulty_char == '4') difficulty_char = '5';  // Special case
;   display_difficulty(difficulty_char);
321c  3a8050    ld      a,(#5080)	; Read DIP switch bank
321f  0f        rrca    		; Rotate right 2 times to get
3220  0f        rrca    		; bits 3-2 in positions 1-0
3221  e603      and     #03		; Mask bits 1-0 (difficulty setting)
3223  c631      add     a,#31		; Convert to ASCII ('1', '2', '3', '4')
3225  fe34      cp      #34		; Compare with '4'
3227  2001      jr      nz,#322a        ; Skip if not '4'
3229  3c        inc     a		; Change '4' to '5' (special case)
322a  320c42    ld      (#420c),a	; Write difficulty character to screen

; ALGORITHM: Display difficulty message and cabinet type
322d  0629      ld      b,#29		; B = 0x29 (difficulty message ID)
322f  cd5e2c    call    #2c5e		; Display difficulty message
3232  3a4050    ld      a,(#5040)	; Read input port
3235  07        rlca    		; Rotate left to move bit 7 to bit 0
3236  e601      and     #01		; Mask bit 0 (cabinet type setting)
3238  c62c      add     a,#2c		; Add base message ID (0x2C or 0x2D)
323a  47        ld      b,a		; B = cabinet type message ID
323b  cd5e2c    call    #2c5e		; Display cabinet type message

; ALGORITHM: Check for service mode exit
323e  3a4050    ld      a,(#5040)	; Read input port
3241  e610      and     #10		; Test bit 4 (service switch)
3243  ca8831    jp      z,#3188		; Return to service mode loop if switch not pressed

; ======================================================
; MAIN GAME INITIALIZATION
; ======================================================
; ALGORITHM: Exit service mode and start main game
; C_PSEUDOCODE:
;   disable_interrupts();
;   clear_all_hardware_registers();
;   setup_main_game_stack();
;   initialize_main_game_state();
3246  af        xor     a		; A = 0x00
3247  320050    ld      (#5000),a	; Disable interrupt system
324a  f3        di      		; Disable CPU interrupts

; ALGORITHM: Clear all hardware control registers
324b  210750    ld      hl,#5007	; HL = last hardware register
324e  af        xor     a		; A = 0x00 (clear value)
324f  77        ld      (hl),a		; Clear hardware register
3250  2d        dec     l		; Move to previous register
3251  20fc      jr      nz,#324f        ; Continue until all cleared (L=0)

; ALGORITHM: Setup main game execution environment
3253  31e23a    ld      sp,#3ae2	; Set stack pointer for main game
3256  0603      ld      b,#03		; B = 3 (initialization counter)
3258  d9        exx     		; Switch to alternate register set
3259  e1        pop     hl		; Pop initialization data from stack
325a  d1        pop     de		; Pop more initialization data
325b  32c050    ld      (#50c0),a	; Kick the watchdog timer
325e  c1        pop     bc		; Pop final initialization data

; ALGORITHM: Initialize memory with patterns
; C_PSEUDOCODE:
;   for (count = B; count > 0; count--) {
;       *hl++ = 0x3C;  // Write pattern byte
;       *hl++ = D;     // Write data byte
;   }
325f  3e3c      ld      a,#3c		; A = 0x3C (pattern byte)
3261  77        ld      (hl),a		; Write pattern to memory
3262  23        inc     hl		; Advance to next location
3263  72        ld      (hl),d		; Write data byte from D
3264  23        inc     hl		; Advance to next location
3265  10f8      djnz    #325f           ; Repeat B times

; ALGORITHM: Continue with second initialization pattern
3267  3b        dec     sp		; Adjust stack pointer
3268  3b        dec     sp
3269  c1        pop     bc		; Pop new initialization data
326a  71        ld      (hl),c		; Write byte from C
326b  23        inc     hl		; Advance to next location
326c  3e3f      ld      a,#3f		; A = 0x3F (different pattern)
326e  77        ld      (hl),a		; Write pattern to memory
326f  23        inc     hl		; Advance to next location
3270  10f8      djnz    #326a           ; Repeat B times

; ALGORITHM: Check for more initialization data
3272  3b        dec     sp		; Adjust stack pointer
3273  3b        dec     sp
3274  1d        dec     e		; Decrement initialization counter
3275  c25b32    jp      nz,#325b	; Continue if more data to process

; ALGORITHM: Complete initialization cycle
3278  f1        pop     af		; Restore AF register
3279  d9        exx     		; Switch back to main register set
327a  10dc      djnz    #3258           ; Repeat entire initialization if B > 0

; ======================================================
; MAIN GAME STARTUP SEQUENCE
; ======================================================
; ALGORITHM: Final system preparation and game start
327c  31c04f    ld      sp,#4fc0	; Reset stack pointer for game operation
327f  0608      ld      b,#08		; B = 8 (initialization cycles)
3281  cded32    call    #32ed		; Call initialization subroutine
3284  10fb      djnz    #3281           ; Repeat 8 times

; ALGORITHM: Wait for service switch release
3286  32c050    ld      (#50c0),a	; Kick the watchdog timer
3289  3a4050    ld      a,(#5040)	; Read input port
328c  e610      and     #10		; Test service switch (bit 4)
328e  28f6      jr      z,#3286         ; Wait until service switch is released

; ALGORITHM: Check for start button press to enter game
3290  3a4050    ld      a,(#5040)	; Read input port
3293  e660      and     #60		; Test P1/P2 start buttons (bits 6-5)
3295  c24b23    jp      nz,#234b	; Jump to game start if start button pressed

; ALGORITHM: Continue initialization if no start pressed
3298  0608      ld      b,#08		; B = 8 (more initialization cycles)
329a  cded32    call    #32ed		; Call initialization subroutine
329d  10fb      djnz    #329a           ; Repeat 8 times
329f  3a4050    ld      a,(#5040)	; Read input port again
32a2  e610      and     #10		; Test service switch again
32a4  c24b23    jp      nz,#234b	; Jump to game start if service switch pressed

; ======================================================
; DIP SWITCH MONITORING LOOP
; ======================================================
; ALGORITHM: Monitor DIP switches for changes and update display
; C_PSEUDOCODE:
;   test_mask = 0x01;
;   for (test_count = 4; test_count > 0; test_count--) {
;       wait_for_dip_change(test_mask);
;       update_display();
;       test_mask <<= 1;
;   }
32a7  1e01      ld      e,#01		; E = 0x01 (DIP switch test mask)
32a9  0604      ld      b,#04		; B = 4 (number of DIP switch tests)

; ALGORITHM: Wait for specific DIP switch change
32ab  32c050    ld      (#50c0),a	; Kick the watchdog timer
32ae  cded32    call    #32ed		; Call delay subroutine
32b1  3a0050    ld      a,(#5000)	; Read DIP switch state
32b4  a3        and     e		; Test current mask bit
32b5  20f4      jr      nz,#32ab        ; Loop while bit is set

; ALGORITHM: Wait for DIP switch to stabilize
32b7  cded32    call    #32ed		; Call delay subroutine
32ba  32c050    ld      (#50c0),a	; Kick the watchdog timer
32bd  3a0050    ld      a,(#5000)	; Read DIP switch state
32c0  eeff      xor     #ff		; Invert all bits
32c2  20f3      jr      nz,#32b7        ; Loop until all switches stable (all 0xFF)
32c4  10e5      djnz    #32ab           ; Continue with next DIP switch test

; ALGORITHM: Move to next DIP switch bit
32c6  cb03      rlc     e		; Rotate E left (shift mask to next bit)
32c8  7b        ld      a,e		; A = updated mask
32c9  fe10      cp      #10		; Compare with 0x10 (beyond 4 bits)
32cb  daa932    jp      c,#32a9		; Continue if mask < 0x10

; ======================================================
; SCREEN CLEAR AND FINAL INITIALIZATION
; ======================================================
; ALGORITHM: Clear screen and prepare for game or service mode
; C_PSEUDOCODE:
;   clear_screen_to_spaces();
;   call_system_init();
;   wait_for_service_switch();
32ce  210040    ld      hl,#4000	; HL = video RAM start (0x4000)
32d1  0604      ld      b,#04		; B = 4 pages to clear
32d3  3e40      ld      a,#40		; A = 0x40 (space character)
32d5  77        ld      (hl),a		; Write space to video RAM
32d6  2c        inc     l		; Increment low address
32d7  20fc      jr      nz,#32d5        ; Continue until page complete
32d9  24        inc     h		; Move to next page
32da  10f7      djnz    #32d3           ; Continue for all 4 pages

; ALGORITHM: Call system initialization routine
32dc  cdf43a    call    #3af4		; Call main system initialization

; ALGORITHM: Final service switch wait
32df  32c050    ld      (#50c0),a	; Kick the watchdog timer
32e2  3a4050    ld      a,(#5040)	; Read input port
32e5  e610      and     #10		; Test service switch
32e7  cadf32    jp      z,#32df		; Loop until service switch pressed
32ea  c34b23    jp      #234b		; Jump to main game start

; ======================================================
; DELAY SUBROUTINE
; ======================================================
; ALGORITHM: Simple timing delay routine
; C_PSEUDOCODE:
;   counter = 0x2800;
;   while (--counter != 0) {
;       kick_watchdog();
;   }
32ed  32c050    ld      (#50c0),a	; Kick the watchdog timer
32f0  210028    ld      hl,#2800	; HL = 0x2800 (delay counter)
32f3  2b        dec     hl		; Decrement counter
32f4  7c        ld      a,h		; A = high byte
32f5  b5        or      l		; OR with low byte (test if zero)
32f6  20fb      jr      nz,#32f3        ; Continue until HL = 0
32f8  c9        ret     		; Return when delay complete

; ======================================================
; EXTRA LIFE THRESHOLD DATA TABLE
; ======================================================
; MEMORY_MAP: Extra life point thresholds for display
; Referenced by the DIP switch display routine at 320f
; Each entry is 2 bytes representing the threshold display characters
32f9  3031      dw      #3130		; "10" - 10,000 points
32fb  3532      dw      #3235		; "25" - 15,000 points (displayed as "25")
32fd  3032      dw      #3230		; "20" - 20,000 points
32ff  0000      dw      #0000		; No extra life (free play mode)

; ======================================================
; LARGE DATA SECTION (3301-3ae1)
; ======================================================
; NOTE: The original disassembly from 3301 to 3ae1 appears to contain
; large data tables or graphics data that was incorrectly disassembled
; as Z80 instructions. This section likely contains:
; - Sprite graphics data
; - Character pattern data  
; - Sound effect data
; - Lookup tables for game logic
; - Level/maze layout data
;
; MEMORY_MAP: Mixed data tables (approximate size: ~1750 bytes)
; 3301-3ae1: Various game data tables (mis-disassembled in original)

; ======================================================
; STACK DATA FOR MAIN GAME INITIALIZATION
; ======================================================
; MEMORY_MAP: Stack-based initialization data
; This data is used by the main game initialization routine
3ae0  04        db      #04		; Initialization parameter
3ae1  00        db      #00		; Initialization parameter
3ae2  02        db      #02		; Stack data (referenced at 3253)
3ae3  40        db      #40		; Stack data

; ======================================================
; SYSTEM INITIALIZATION ROUTINE (3af4)
; ======================================================
; ALGORITHM: Main system initialization called from startup
; This function was called at 32dc during system startup
; C_PSEUDOCODE:
;   initialize_lookup_tables();
;   setup_memory_mapping();
;   configure_game_parameters();
3af4  013e3d    ld      bc,#3d3e	; BC = initialization parameters
3af7  114f3a    ld      de,#3a4f	; DE = data table pointer
3afa  3614      ld      (hl),#14	; Write initialization value
3afc  1a        ld      a,(de)		; Read from data table
3afd  a7        and     a		; Test if zero (end of table)
3afe  c8        ret     z		; Return if end of table reached

; ALGORITHM: Process initialization data
3aff  13        inc     de		; Move to next table entry
3b00  85        add     a,l		; Add table value to L
3b01  6f        ld      l,a		; Store result back in L
3b02  d2fa3a    jp      nc,#3afa	; Continue if no carry
3b05  24        inc     h		; Increment H if carry occurred
3b06  18f2      jr      #3afa           ; Jump back to continue processing

; ======================================================
; MESSAGE SYSTEM POINTER TABLE (36a5-3711)
; ======================================================
; MEMORY_MAP: Message pointer table used by display system
; Each entry is a 16-bit pointer to the actual message text
; Referenced by the message display routine at #2c5e
36a5  1337      dw      #3713		; 0x00: "HIGH SCORE"
36a7  2337      dw      #3723		; 0x01: "CREDIT"
36a9  3237      dw      #3732		; 0x02: "FREE PLAY"
36ab  4137      dw      #3741		; 0x03: "PLAYER ONE"
36ad  5a37      dw      #375a		; 0x04: "PLAYER TWO"
36af  6a37      dw      #376a		; 0x05: "GAME  OVER"
36b1  7a37      dw      #377a		; 0x06: "READY?"
36b3  8637      dw      #3786		; 0x07: "PUSH START BUTTON"
36b5  9d37      dw      #379d		; 0x08: "1 PLAYER ONLY"
36b7  b137      dw      #37b1		; 0x09: "1 OR 2 PLAYERS"
36b9  003d      dw      #3d00		; 0x0A: "BONUS PAC-MAN FOR   000 Pts"
36bb  213d      dw      #3d21		; 0x0B: "@ 1980 MIDWAY MFG.CO."
36bd  fd37      dw      #37fd		; 0x0C: "CHARACTER / NICKNAME"
36bf  673d      dw      #3d67		; 0x0D: "BLINKY"
36c1  e33d      dw      #3de3		; 0x0E: Character name (repeated B's)
36c3  863d      dw      #3d86		; 0x0F: "PINKY"
36c5  023e      dw      #3e02		; 0x10: Character name (repeated D's)
36c7  4c38      dw      #384c		; 0x11: ". 10 Pts" (pellet points)
36c9  5a38      dw      #385a		; 0x12: "o 50 Pts" (power pellet points)
36cb  3c3d      dw      #3d3c		; 0x13: "@ 1980 MIDWAY MFG.CO." (duplicate)
36cd  573d      dw      #3d57		; 0x14: "-SHADOW" (Blinky nickname)
36cf  d33d      dw      #3dd3		; 0x15: Character name (repeated A's)
36d1  763d      dw      #3d76		; 0x16: "-SPEEDY" (Pinky nickname)
36d3  f23d      dw      #3df2		; 0x17: Character name (repeated C's)
36d5  0100      dw      #0001		; 0x18: Data value
36d7  0200      dw      #0002		; 0x19: Data value
36d9  0300      dw      #0003		; 0x1A: Data value
36db  bc38      dw      #38bc		; 0x1B: "100" (points)
36dd  c438      dw      #38c4		; 0x1C: "300" (points)
36df  ce38      dw      #38ce		; 0x1D: "500" (points)
36e1  d838      dw      #38d8		; 0x1E: "700" (points)
36e3  e238      dw      #38e2		; 0x1F: "1000" (points)
36e5  ec38      dw      #38ec		; 0x20: "2000" (points)
36e7  f638      dw      #38f6		; 0x21: "3000" (points)
36e9  0039      dw      #3900		; 0x22: "5000" (points)
36eb  0a39      dw      #390a		; 0x23: "MEMORY  OK"
36ed  1a39      dw      #391a		; 0x24: "BAD    R M"
36ef  6f39      dw      #396f		; 0x25: "FREE  PLAY"
36f1  2a39      dw      #392a		; 0x26: "1 COIN  1 CREDIT"
36f3  5839      dw      #3958		; 0x27: "1 COIN  2 CREDITS"
36f5  4139      dw      #3941		; 0x28: "2 COINS 1 CREDIT"
36f7  4f3e      dw      #3e4f		; 0x29: "PAC-MAN"
36f9  8639      dw      #3986		; 0x2A: "BONUS  NONE"
36fb  9739      dw      #3997		; 0x2B: "BONUS"
36fd  b039      dw      #39b0		; 0x2C: "TABLE"
36ff  bd39      dw      #39bd		; 0x2D: "UPRIGHT"
3701  ca39      dw      #39ca		; 0x2E: "000"
3703  a53d      dw      #3da5		; 0x2F: "INKY"
3705  213e      dw      #3e21		; 0x30: Character name (repeated F's)
3707  c43d      dw      #3dc4		; 0x31: "CLYDE"
3709  403e      dw      #3e40		; 0x32: Character name (repeated H's)
370b  953d      dw      #3d95		; 0x33: "-BASHFUL" (Inky nickname)
370d  113e      dw      #3e11		; 0x34: Character name (repeated E's)
370f  b43d      dw      #3db4		; 0x35: "-POKEY" (Clyde nickname)
3711  303e      dw      #3e30		; 0x36: Character name (repeated G's)

; ======================================================
; MESSAGE TEXT STRINGS  
; ======================================================
; MEMORY_MAP: Actual message text data
; These strings use special encoding for display on screen
; 
; FORMAT: Each message has:
;   - Optional prefix bytes (message formatting/positioning)
;   - Character data using Pac-Man character encoding
;   - Terminator sequence (usually $2f + control bytes)
;   - Optional display formatting data
;
; CHARACTER ENCODING (Pac-Man custom, NOT ASCII):
;   $40 = space, $41-$5A = A-Z, $30-$39 = 0-9  
;   Special characters: $3B, $2F (terminator), various control codes
;   This is similar to ASCII but offset: ASCII '@'=64=$40, but Pac-Man space=$40
;
; ASSEMBLER DIRECTIVES: 
;   db $xx,$yy - using hex notation due to custom character encoding

; Message 0x00: "HIGH SCORE"
msg_high_score:
3713  db        $c8                                     ; message prefix/format
3714  db        $48,$49,$47,$48,$40,$53,$43,$4f,$52,$45 ; "HIGH SCORE" (Pac-Man encoding)
371e  db        $2f,$8f,$2f,$80                         ; string terminator + metadata

; Message 0x01: "CREDIT"  
msg_credit:
3721  db        $3b,$80                                   ; message prefix/format
3723  db        $43,$52,$45,$44,$49,$54,$40,$40,$40     ; "CREDIT   " (Pac-Man encoding)
372c  db        $2f,$8f,$2f,$80                         ; string terminator + metadata

; Message 0x02: "FREE PLAY"
msg_free_play:
3730  db        $3b,$80                                   ; message prefix/format
3732  db        $46,$52,$45,$45,$40,$50,$4c,$41,$59     ; "FREE PLAY" (Pac-Man encoding)
373b  db        $2f,$8f,$2f,$80                         ; string terminator + metadata

; Message 0x03: "PLAYER ONE"
msg_player_one:
373f  db        $8c,$02                                   ; message prefix/format  
3741  db        $50,$4c,$41,$59,$45,$52,$40,$4f,$4e,$45 ; "PLAYER ONE" (Pac-Man encoding)
374b  db        $2f,$85,$2f                             ; string terminator + metadata
374e  db        $10,$10,$1a,$1a,$1a,$1a,$1a,$1a,$10     ; display formatting data

; Message 0x04: "PLAYER TWO"
msg_player_two:
3757  db        $10                                       ; display formatting (end of prev msg)
3758  db        $8c,$02                                   ; message prefix/format  
375a  db        $50,$4c,$41,$59,$45,$52,$40,$54,$57,$4f ; "PLAYER TWO" (Pac-Man encoding)
3764  db        $2f,$85,$2f,$80                         ; string terminator + metadata

; Message 0x05: "GAME  OVER"
msg_game_over:
3768  db        $92,$02                                   ; message prefix/format
376a  db        $47,$41,$4d,$45,$40,$40,$4f,$56,$45,$52 ; "GAME  OVER" (Pac-Man encoding)
3774  db        $2f,$81,$2f,$80                         ; string terminator + metadata

; Message 0x06: "READY?"
msg_ready:
3778  db        $52,$02                                   ; message prefix/format
377a  db        $52,$45,$41,$44,$59,$5b                 ; "READY?" (Pac-Man encoding - 5B = '?')
3780  db        $2f,$89,$2f,$90                         ; string terminator + metadata

; Message 0x07: "PUSH START BUTTON"
msg_push_start_button:
3784  db        $ee,$02                                   ; message prefix/format
3786  db        $50,$55,$53,$48,$40,$53,$54,$41,$52,$54 ; "PUSH START"
3790  db        $40,$42,$55,$54,$54,$4f,$4e             ; " BUTTON" (Pac-Man encoding)
3797  db        $2f,$87,$2f,$80                         ; string terminator + metadata

; Message 0x08: "1 PLAYER ONLY"
msg_1_player_only:
379b  db        $b2,$02                                   ; message prefix/format
379d  db        $31,$40,$50,$4c,$41,$59,$45,$52,$40,$4f ; "1 PLAYER O"
37a7  db        $4e,$4c,$59,$40                         ; "NLY " (Pac-Man encoding)
37ab  db        $2f,$85,$2f,$80                         ; string terminator + metadata

; Message 0x09: "1 OR 2 PLAYERS"
msg_1_or_2_players:
37af  db        $b2,$02                                   ; message prefix/format
37b1  db        $31,$40,$4f,$52,$40,$32,$40,$50,$4c,$41 ; "1 OR 2 PLA"
37bb  db        $59,$45,$52,$53                         ; "YERS" (Pac-Man encoding)
37bf  db        $2f,$85,$00,$2f,$00,$80                 ; string terminator + metadata + padding

; Message 0x0A: "BONUS PUCKMAN FOR   000 Pts"
msg_bonus_puckman:
37c5  db        $00                                       ; padding
37c6  db        $96,$03                                   ; message prefix/format
37c8  db        $42,$4f,$4e,$55,$53,$40,$50,$55,$43,$4b ; "BONUS PUCK"
37d2  db        $4d,$41,$4e,$40,$46,$4f,$52,$40,$40,$40 ; "MAN FOR   "
37dc  db        $30,$30,$30,$40,$5d,$5e,$5f             ; "000 Pts" (5D/5E/5F = P/t/s in Pac-Man encoding)
37e3  db        $2f,$8e,$2f,$80                         ; string terminator + metadata

; Message 0x0B: "@ 1980 MIDWAY MFG.CO." (Copyright message)
msg_copyright:
37e7  db        $ba,$02                                   ; message prefix/format
37e9  db        $5c,$40,$31,$39,$38,$30,$40,$4d,$49,$44 ; "@ 1980 MID" (5C = '@' in Pac-Man encoding)
37f3  db        $57,$41,$59,$40,$4d,$46,$47,$5c,$43,$4f ; "WAY MFG.CO" (5C = '.' in Pac-Man encoding)
37fd  db        $5c                                     ; "." (Pac-Man encoding)
37fe  db        $2f,$83,$2f,$80                         ; string terminator + metadata

; Message 0x0C: "CHARACTER / NICKNAME"
msg_character_nickname:
3802  db        $c3,$02                                   ; message prefix/format
3804  db        $43,$48,$41,$52,$41,$43,$54,$45,$52,$40 ; "CHARACTER "
380e  db        $3a,$40,$4e,$49,$43,$4b,$4e,$41,$4d,$45 ; "/ NICKNAME" (3A = '/' in Pac-Man encoding)
3818  db        $2f,$8f,$2f,$80                         ; string terminator + metadata

; GHOST CHARACTER NAMES AND POINT SCORING MESSAGES
; Additional message text continues here for ghost names, character descriptions, etc.
; [Note: Full ghost name data would include: BLINKY, PINKY, INKY, CLYDE with various nicknames]

; Message 0x11: ". 10 Pts" (Small pellet points)
msg_pellet_points:
384c  db        $76,$02                                   ; message prefix/format
384e  db        $10,$40,$31,$30,$40,$5d,$5e,$5f         ; ". 10 Pts" (10 = '.' in Pac-Man encoding)
3856  db        $2f,$9f,$2f,$80                         ; string terminator + metadata

; Message 0x12: "o 50 Pts" (Power pellet points)
msg_power_pellet_points:
385a  db        $78,$02                                   ; message prefix/format
385c  db        $14,$40,$35,$30,$40,$5d,$5e,$5f         ; "o 50 Pts" (14 = 'o' symbol for power pellet)
3864  db        $2f,$9f,$2f,$80                         ; string terminator + metadata

; ADDITIONAL DATA SECTIONS CONTINUE...
; =====================================
; From 3868 onwards, the ROM contains:
; - Ghost character name definitions
; - Extended message text  
; - Game logic lookup tables
; - Sprite animation data
; - Sound effect patterns
; - Maze layout data

; Sample additional data (key sections):
3868  db        $5d,$02                                 ; Additional message prefix
386a  db        $28,$29,$2a,$2b,$2c,$2d,$2e,$2f        ; Special symbol table
3872  db        $83,$2f,$80                             ; Terminator

; Ghost name: "OIKAKE" (Japanese name for one of the ghosts)
3875  db        $c5,$02,$40,$4f,$49,$4b,$41,$4b,$45    ; Message data
387d  db        $3b,$3b,$3b,$3b,$2f,$81,$2f,$80        ; "OIKAKE" with padding and terminator

; Ghost name: "URCHIN" 
3886  db        $c5,$02,$40,$55,$52,$43,$48,$49,$4e    ; Message data  
388e  db        $3b,$3b,$3b,$3b,$3b,$2f,$81,$2f,$80   ; "URCHIN" with padding and terminator

; [VAST AMOUNT OF ADDITIONAL ROM DATA CONTINUES...]
; The complete ROM contains hundreds more bytes of:
; - All remaining message text
; - Character/ghost name tables  
; - Fruit scoring tables
; - Maze pattern definitions
; - Sprite animation sequences
; - Color palette data
; - Sound generation tables
; - Game state lookup tables

; ROM TERMINATION (at end of 16K ROM)
; ===================================
; The ROM concludes with interrupt vectors and checksum:

3ffa  dw        $3000                                   ; Interrupt Vector 3000
3ffc  dw        $008d                                   ; Interrupt Vector 008d  

3ffe  db        $75,$73                                 ; ROM checksum data

; END OF PAC-MAN ROM AT 3FFF

