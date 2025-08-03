# X16 Assembly Template - Working Configuration

This document provides the complete, tested configuration for creating working assembly programs for the Commander X16 emulator with ASM logging support.

## Required Files

### 1. Configuration File: `simple.cfg`

```
MEMORY {
    ZP:     start = $0002, size = $001A, type = rw, define = yes;
    LOADADDR: start = $0801, size = $0002, file = %O;
    HEADER: start = $0803, size = $000C, file = %O;
    MAIN:   start = $080F, size = $8FF1, file = %O;
}

SEGMENTS {
    LOADADDR: load = LOADADDR, type = ro;
    EXEHDR:   load = HEADER,   type = ro;
    CODE:     load = MAIN,     type = ro;
    RODATA:   load = MAIN,     type = ro;
    DATA:     load = MAIN,     type = rw;
    BSS:      load = MAIN,     type = bss, define = yes;
    ZEROPAGE: load = ZP,       type = zp;
}
```

### 2. Assembly Template: `template.asm`

```assembly
; ------------------------------------------------------------
; X16 Assembly Program Template
; Uses simple.cfg segments for proper compilation
; Includes ASM logging system support
; ------------------------------------------------------------

; Assembly logging memory addresses
ASM_LOG_PARAM1     = $9F60
ASM_LOG_PARAM2     = $9F61
ASM_LOG_INFO       = $9F62

; Load address segment
.segment "LOADADDR"
    .word $0801         ; load address

; BASIC stub header
.segment "EXEHDR"
    .word $080B         ; next line address
    .word 2024          ; line number
    .byte $9E           ; SYS token
    .byte "2061"        ; address string (2061 = $080D)
    .byte $00           ; end of line
    .word $0000         ; end of program

; Main code
.segment "CODE"
start:
    ; Your program code goes here
    
    ; Example: Change border color to show program is running
    lda #$0F            ; bright white border
    sta $D020           ; VIC-II border color register
    
    ; Example: ASM logging
    lda #42             ; some value to log
    sta ASM_LOG_PARAM1
    lda #3              ; message ID 3 from logging.def
    sta ASM_LOG_INFO
    
    ; Example: Change border to green when done
    lda #$05            ; green
    sta $D020
    
    ; End with infinite loop
infinite_loop:
    jmp infinite_loop

; Variables go in BSS segment
.segment "BSS"
counter: .res 1
```

### 3. Logging Definitions: `logging.def`

```json
{
  "info": {
    "1": "System initialized",
    "2": "Loading data from address %3",
    "3": "Player position: X=%1, Y=%2",
    "4": "Score updated to %3",
    "5": "Level %1 completed"
  },
  "warning": {
    "1": "Low memory warning: %1 bytes remaining",
    "2": "Invalid input detected: %1",
    "3": "Collision detected at %1, %2"
  },
  "error": {
    "1": "Memory allocation failed",
    "2": "Invalid address access: %3",
    "3": "System error code %1"
  }
}
```

## Build Process

### Single Command Build
```bash
ca65 your_program.asm -o your_program.o && ld65 -C simple.cfg your_program.o -o your_program.prg
```

### Step-by-Step Build
```bash
# Assemble
ca65 your_program.asm -o your_program.o

# Link
ld65 -C simple.cfg your_program.o -o your_program.prg
```

## Testing in Emulator

### Using MCP Tools
```bash
# Start emulator with program
start_emulator --program your_program.prg --auto_run true

# Or load into running emulator
load_program --path your_program.prg --auto_run true
```

### Manual Loading
```
LOAD"your_program.prg",8,1:RUN
```

## ASM Logging System

### Memory Addresses
- `$9F60` - Parameter 1 (ASM_LOG_PARAM1)
- `$9F61` - Parameter 2 (ASM_LOG_PARAM2)  
- `$9F62` - Message ID trigger (ASM_LOG_INFO)

### Usage Example
```assembly
; Set parameters
lda #42
sta ASM_LOG_PARAM1
lda #100
sta ASM_LOG_PARAM2

; Trigger log message (ID 3 = "Player position: X=%1, Y=%2")
lda #3
sta ASM_LOG_INFO
```

### Log Output
Messages appear in emulator logs as:
```
ASM INFO: Player position: X=$2A, Y=$64
```

## Key Segment Structure

1. **LOADADDR**: Contains the load address ($0801)
2. **EXEHDR**: BASIC stub that calls your assembly code
3. **CODE**: Your main program code
4. **BSS**: Uninitialized variables
5. **RODATA**: Read-only data
6. **DATA**: Initialized variables
7. **ZEROPAGE**: Zero page variables

## Memory Layout

- **$0801**: Load address (BASIC program start)
- **$0803-$080E**: BASIC stub
- **$080F**: Start of your assembly code
- **$9F60-$9F62**: ASM logging registers

## Troubleshooting

### Common Issues
1. **Segment not found**: Make sure you're using `simple.cfg`, not `test.cfg`
2. **Program doesn't run**: Check BASIC stub addresses match your code location
3. **No logging output**: Verify `logging.def` exists in project root
4. **Load errors**: Ensure .prg file was created successfully

### Verification Steps
1. Check .prg file exists and has reasonable size (>40 bytes)
2. Look for "LOADING FROM $0801 TO $xxxx" message in emulator
3. Check emulator logs for ASM logging messages
4. Verify border color changes if using visual indicators

## Working Example

The `test_working.asm` file demonstrates a complete working program that:
- Changes border color to white
- Logs 10 messages with incrementing counter
- Changes border to green when complete
- Ends in infinite loop

This template has been tested and confirmed working with the X16 emulator and MCP logging system.
