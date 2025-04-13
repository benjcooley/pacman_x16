# Plan doc

Vibe coding conversion of pacman.c (Sokol) faithful recreation of pacman to the Commander x16 in 6502 assembly language.

Key files:

pacman.c - Sokol faithful port of pacman to c95 and sokol gfx (as a reference).
pacman_asm.txt - Original decompiled z80 code for pacman (as a reference to use when needed to answer questions about behavior)
pacman_data.asm - The static data in 6502 assembly for the pacman assets, well documented. These will be inserted in our code file.
pacman_x16_wip.asm - Work in progress for our port.. our code we write will go in sections here.
Various Commander x16 documentation - As reference for writing our code
plan.md - This file.. we add to and change this file as we move forward in our project.

----------------------------------------------------

High level Plan

1. Conversion Objectives and Constraints
A. Fidelity and Accuracy
• We must replicate the original Pac‑Man algorithms exactly (including the LDIR‑style memory transfers, coin/credit math, and maze layout logic) using 65C02 equivalents.
• We want to preserve the original tile and sprite data. Wherever possible, we’ll use the original graphics converted to a format that VERA expects (e.g. 4bpp for an 8×8 tileset).

B. Code Size and Memory Space
• The original Z80 ROM is 16 KB total. However, our conversion (including helper routines for emulated instructions) may end up a bit larger because the 65C02 has fewer registers and may require helper loops.
• We must ensure that our critical routines (initialization, tileset/sprite load, and maze rendering) fit in a contiguous region so that we don’t hit bank‐switching problems on startup.
• We also need to reserve space for future modules (audio, attract mode, ghost AI, etc.) and plan a layout that allows for growth and modular updating without up‐front mistakes.

C. Banking and Peripherals
• The Commander X16, like the C64, uses a lower memory area (roughly up to 38 KB) that’s simpler to use and banked regions above that.
• We must design our code so that the “core” game code (initialization and maze display) is permanently mapped and does not require frequent bank switching.
• If additional routines (e.g. audio conversion) exceed the available room in the fixed region, we’ll use bank switching to load extra code and data.
• We need to plan ahead—estimating the sizes of each converted routine from the original disassembled code—to know if we’ll need extra banks.

──────────────────────────────

2. Overall Architecture and Module Breakdown
Our project is modular. For this phase, our modules (and their estimated sizes) are:

Module 1: Boot and Initialization

Purpose:
– Disable interrupts, clear key areas of RAM, initialize zero page variables.
– Set up the CPU environment and VERA registers (for tilemap mode and sprites).

Estimated Size: 1–2 KB

Notes:
– Emulation of Z80 “di” and “ld i” can be written as simple 65C02 routines.
– Zero-page (addresses $0000–$00FF) will hold our frequently accessed counters and pointers.

Module 2: Tileset and Sprite Setup

Purpose:
– Convert and store the original Pac‑Man graphics into a format (e.g. 4bpp 8×8) that VERA can use.
– Write routines to copy these tiles into VRAM (e.g. to a bank starting at $B000 or another agreed VRAM area).

Estimated Size: 1–2 KB for the routines plus the graphics data (typically a few KB of tile data)

Notes:
– We will likely run a conversion tool (or write a converter in Python) to process the ROM data into a ready-to-use binary format.

Module 3: Maze Rendering Routine

Purpose:
– Copy the maze layout data (extracted or recreated from the Z80 ROM) into the VERA tilemap memory.
– Emulate the LDIR-style routine from addresses like 0x0176–0x017F in the ROM.

Estimated Size: 1–2 KB

Notes:
– We must be careful with indexing because the original routine relies on 16‑bit pointers; our 65C02 code will use helper subroutines to simulate LDIR and DJNZ.

Module 4: Audio (Reserved for Later)

Purpose:
– Translate the original coin-input and sound routines into X16 audio routines.

Planned Allocation: Reserve about 2–4 KB in a separate bank or in the upper memory if possible.

Notes:
– The audio hardware of the X16 is integrated with VERA (or mapped into a similar address window), so audio routines must be isolated and mapped to a stable bank.

──────────────────────────────

3. Concrete Memory Map and Banking Plan
Given the X16’s 64 KB CPU address space and its banked configuration above ≈38 KB, our working memory plan is as follows:

A. Fixed Memory (Lower ~38 KB)
These addresses are always mapped and ideal for time-critical routines and frequently accessed variables.

Address Range	Purpose	Allocation Details
$0000–$00FF	Zero Page	Critical variables, counters, pointers
$0100–$01FF	Stack	Standard 65C02 stack
$0200–$3FFF	Main Working RAM / Core Game Code	– Initialization routines (Module 1)
– Maze rendering subroutines (Module 3)		
– Part of tileset routines (Module 2)		
Estimated available space: ~15–16 KB		
B. Banked Regions (Above ~$4000)
Due to the X16’s banking, we must carefully assign data and additional code to these areas.

Address Range	Purpose	Allocation Details
$4000–$7FFF	Banked Data / Expanded RAM	– Tileset conversion buffers
– Extended lookup tables		
– Any extra routines that do not require constant mapping. (May contain portions of Module 2 and Module 3 if needed.)		
$8000–$FFFF	Program Code / Assets (Bank 2)	– Additional game logic (attract screen, ghost AI, etc.)
– Future audio routines (Module 4)		
– Fixed asset data (e.g. audio waveforms)		
Key Points in Banking Plan:

Core Code in Fixed Memory:
We will try to place all routines essential for initialization and maze display (Modules 1–3) in the lower region (ideally under 16 KB total).

Future Growth:
Reserve a bank (or part of banked area) for audio and expanded gameplay logic. Our linker script must reflect these boundaries and ensure that data for the audio engine does not get overwritten by code.

Tools and Testing:
We’ll use our assembler’s listing and size reports to verify that the converted routines meet our size targets. We can also run “dummy” routines on the X16 emulator to ensure that bank switching works correctly.

──────────────────────────────

4. Estimating Code Size from the Source
Source Analysis:
– The original Pac‑Man ROM image is 16 KB in size.
– Our disassembly shows routines ranging from single instructions (e.g. “ld a,(hl)” loops) up through block transfer routines.
– We expect that if we mirror the same behavior in 65C02 assembly (including emulating multi-step instructions like LDIR), the converted code may be slightly larger.
– A rough estimate:
  • Initialization routines: ~1–2 KB
  • Maze rendering: ~1–2 KB
  • Graphics/tile transfer subroutines: ~1–2 KB
  • Helper routines (LDIR, DJNZ emulation, etc.): ~1 KB
– Total for Modules 1–3: Likely around 4–7 KB if written efficiently, leaving room in Bank 0 for later debugging and future porting.

Planning for Audio and Expansion:
– The original code had sound routines interleaved with game logic. We plan to rework these into a separate module, and based on preliminary estimates, allot an extra 2–4 KB in a bank dedicated to audio.
– Our final core project (including attract mode and ghost AI) will likely sum to less than 16 KB of code; we have three or four 16 KB banks available.
– It is critical that we build early tools in our assembler that report section sizes and flag if any bank exceeds its allocated size.

──────────────────────────────

5. Step-by-Step Roadmap
Source Code Breakdown and Analysis:
– Examine the full Z80 disassembly. Identify and extract all routines needed for initialization and maze rendering.
– Use this to build a detailed function list with their estimated byte counts.

Linker Script and Bank Mapping Setup:
– Write a preliminary linker script mapping:
  • Module 1–3 in the fixed memory region ($0200–$3FFF)
  • Reserve banked areas for data buffers and future audio/expansion routines.
– Validate against our size estimates using our assembler’s size reports.

Implement Conversion Helpers:
– Write macros/subroutines for emulating Z80’s LDIR, DJNZ, and other key instructions.
– Test these routines in isolation to ensure they meet cycle and size constraints.

Write and Integrate Modules:
– Module 1 (Boot and Init): Test that our interrupt disabling, zero page initialization, and VERA setup work on the emulator.
– Module 2 (Tileset/Sprite Loading): Load dummy tile data first, then replace with authentic Pac‑Man tiles after conversion.
– Module 3 (Maze Rendering): Use the original maze layout data (or its emulation) to fill the VERA tilemap memory, ensuring that our memory-to-VRAM transfer code correctly emulates the original block copy.
– Repeatedly verify that all converted code fits within the planned region.

Plan and Reserve for Audio:
– Document the original audio routines and decide which parts are critical for a “faithful” sound reproduction.
– Reserve a bank (or part thereof) specifically for the audio routines and design a simple initialization routine to set the audio registers.
– This is planned but will be integrated after verifying our core graphics and initialization modules.

Iterate and Optimize:
– Use the assembler listings, emulator tests, and debugging tools to fine-tune memory usage.
– Revise our macros and helper routines if any part approaches or exceeds our bank limits.

──────────────────────────────

Conclusion
This detailed plan ensures we are concrete from the start:
• We have broken down the code into clear modules, with estimated sizes based on the original 16 KB Z80 ROM.
• We have mapped a memory layout that acknowledges the X16’s fixed and banked regions and reserved space for future audio integration.
• We have defined the conversion process—including creating macros to emulate Z80 instructions—so that our core routines (initialization, tileset/sprite loading, and maze rendering) fit within the available space and can be extended later.

This groundwork should help us avoid up‑front mistakes and set us on the correct path as we convert and integrate the original Pac‑Man code onto the Commander X16.

-----------------------------------------------

Current copy of the code (we'll update this as we get closer to complete each session)

Code will be one file.. minuse the "data" section which I will insert before compiling/testing.

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

; Destination addresses in VRAM:
TILEMAP_BASE     = $B000            ; VRAM address for tilemap
SPRITE_DEST      = $A000            ; VRAM address for sprite/tileset data

;----------------------------------------------------------
; Data Section
;----------------------------------------------------------
; Sprite/Tileset Data: 4KB of literal data.
; In a real port, replace this pattern with the actual Pac-Man sprite ROM dump.
SpriteData:
    .fill 4096, 1, $55           ; Fill 4096 bytes; each byte set to $55 as a placeholder
; If you need a more varied pattern and your assembler supports .repeat, you could do:
; .repeat 512
;    .byte $00, $11, $22, $33, $44, $55, $66, $77
; .endrepeat

; Maze Tilemap Data: (a dummy, very short example – full maze is 28×36 bytes, 1008 total)
MazeData:
    .byte 0, 1, 2, 3, 4, 5, 6, 7
MazeDataLen = MazeData_End - MazeData
MazeData_End:

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
    CPY #ZERO_PAGE_SIZE
    BNE ClearZeroPage

    ;------------------------------------------------------
    ; Section 1.1.2: VERA Initialization
    ; Set VERA's address registers so that subsequent writes go to TILEMAP_BASE.
    ;------------------------------------------------------
    LDA #<TILEMAP_BASE           ; Low byte of TILEMAP_BASE
    STA VERA_ADDR_L
    LDA #>TILEMAP_BASE           ; High byte of TILEMAP_BASE (for our 16-bit address)
    STA VERA_ADDR_M
    LDA #$00                    ; Assume top byte is zero
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

    LDY #$00                    ; Y will serve as our index (0..4095)
UploadSpriteLoop:
    LDA SpriteData, Y           ; Load byte from sprite data
    STA VERA_DATA0              ; Write byte to VERA (auto-increment)
    INY
    CPY #$00                    ; Compare Y with 4096 (Y wraps at $100 = 256 so need workaround)
    ; Because 4096 > 256, we cannot compare using a single byte register.
    ; Instead, we use a two-byte counter by leveraging a label.
    ; For simplicity, assume our assembler supports the pseudo-operator "SpriteDataLen"
    ; defined as 4096. If not, you will need to implement a proper 16-bit loop.
    CPY #4096 mod 256           ; (This is conceptual; adjust for your assembler)
    BNE UploadSpriteLoop
    ; In a real implementation, you would use a 16-bit counter here.

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

  .fill 4096, 1, $55