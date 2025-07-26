# Commander X16 Emulator MCP Keyboard Text Guide

## Overview

The Commander X16 emulator's MCP (Model Context Protocol) server provides a powerful `send_keyboard` tool that allows sending text input to the emulator with macro support, timing control, and multiple input modes. This guide focuses on the **ASCII mode** (the default), which provides the most natural text input experience.

## Basic Usage

### Simple Text Input

```json
{
  "text": "hello world"
}
```

**Key Behavior in ASCII Mode:**
- Lowercase letters are automatically converted to uppercase (Commodore convention)
- Text is queued with 10ms delay between characters (100 characters/second)
- Special characters are handled appropriately for the X16 system

### Text with Special Keys

Use backticks (`) to insert special keys and macros:

```json
{
  "text": "hello`ENTER`world`F1`"
}
```

## Macro System

### Function Keys
- `F1`, `F2`, `F3`, `F4`, `F5`, `F6`, `F7`, `F8`, `F9`, `F10`, `F11`, `F12`

### Navigation Keys
- `UP`, `DOWN`, `LEFT`, `RIGHT` - Cursor movement
- `HOME`, `END` - Line navigation
- `PAGEUP`, `PAGEDOWN` - Page navigation
- `INSERT`, `DELETE` - Text editing

### Control Keys
- `ENTER` or `RETURN` - Enter key
- `TAB` - Tab key
- `BACKSPACE` - Backspace
- `ESCAPE` - Escape key
- `SPACE` - Space character

### Modifier Keys
- `LSHIFT`, `RSHIFT` - Left/Right Shift
- `LCTRL`, `RCTRL` - Left/Right Control
- `LALT`, `RALT` - Left/Right Alt
- `CAPSLOCK` - Caps Lock

## Escape Sequences

Standard escape sequences are supported:

- `\n` - Newline (converted to ENTER)
- `\r` - Carriage return (converted to ENTER)
- `\t` - Tab character
- `\b` - Backspace

Example:
```json
{
  "text": "line 1\nline 2\ttabbed text"
}
```

## Timing Control with Pauses

### Pause Syntax
- `_500` - Pause for 500 milliseconds
- `_1.5` - Pause for 1.5 seconds (1500 milliseconds)

### Examples

```json
{
  "text": "hello`_500`world`_1.5`done"
}
```

This will:
1. Type "hello"
2. Pause for 500ms
3. Type "world"
4. Pause for 1.5 seconds
5. Type "done"

### Practical Use Cases

**Menu Navigation:**
```json
{
  "text": "`F1``_200``DOWN``DOWN``ENTER`"
}
```

**Program Loading:**
```json
{
  "text": "LOAD\"GAME.PRG\",8`ENTER``_2000`RUN`ENTER`"
}
```

**Interactive Input:**
```json
{
  "text": "What is your name?`ENTER``_1000`John Doe`ENTER`"
}
```

## PETSCII Support

While ASCII mode is the default, you can access PETSCII characters using macros:

### Colors
- `RED`, `BLUE`, `GREEN`, `YELLOW`, `CYAN`, `PURPLE`, `WHITE`, `BLACK`
- `LRED`, `LBLU`, `LGRN` (light variants)
- `GRY1`, `GRY2`, `GRY3` (gray shades)

### Symbols
- `HEART`, `DIAMOND`, `CLUB`, `SPADE` - Card suits
- `STAR`, `BALL`, `CIRCLE`, `CROSS` - Basic symbols
- `PI`, `POUND`, `UPARROW`, `LEFTARROW` - Special characters

### Box Drawing
- `HLINE`, `VLINE` - Horizontal/vertical lines
- `ULCORNER`, `URCORNER`, `LLCORNER`, `LRCORNER` - Corners
- `CROSS4` - Four-way intersection
- `TEE_UP`, `TEE_DOWN`, `TEE_LEFT`, `TEE_RIGHT` - T-junctions

### Screen Control
- `CLR` - Clear screen
- `HOME` - Cursor home
- `RVS_ON`, `RVS_OFF` - Reverse video on/off
- `INST`, `DEL` - Insert/delete

### Example with PETSCII
```json
{
  "text": "`CLR``RED`HELLO `BLUE`WORLD`WHITE``HEART``HEART``HEART`"
}
```

## Advanced Features

### Raw Keycodes
Use `K` prefix for direct X16 keyboard scan codes:
```json
{
  "text": "`K112`"  // F1 key (scan code 112)
}
```

### Single Key Events
For individual key presses/releases:
```json
{
  "key": "ENTER",
  "pressed": true
}
```

### Mode Selection
Explicitly specify ASCII mode (though it's the default):
```json
{
  "text": "hello world",
  "mode": "ascii"
}
```

## Timing and Performance

### Queue System
- Text is queued with 10ms intervals between characters
- Queue can hold up to 4096 characters
- System prevents buffer overflow by checking available space

### Timing Calculations
- Base rate: 100 characters/second (10ms per character)
- Pauses add to total execution time
- Queue processing is automatic and non-blocking

### Example Response
```json
{
  "status": "success",
  "message": "Text queued for emulator",
  "text": "hello`_500`world",
  "characters": 10,
  "estimated_time_ms": 600,
  "estimated_time_seconds": 0.6,
  "typing_rate_ms_per_char": 10,
  "queue_info": {
    "size_before": 0,
    "size_after": 10,
    "total_queue_time_ms": 100,
    "total_queue_time_seconds": 0.1
  }
}
```

## Best Practices

### 1. Natural Text Entry
```json
{
  "text": "10 PRINT \"HELLO WORLD\"`ENTER`20 GOTO 10`ENTER`RUN`ENTER`"
}
```

### 2. Menu Navigation
```json
{
  "text": "`F1``_100``DOWN``DOWN``ENTER`"
}
```

### 3. Game Input
```json
{
  "text": "`SPACE``_50``LEFT``LEFT``_50``SPACE`"
}
```

### 4. File Operations
```json
{
  "text": "LOAD\"$\",8`ENTER``_2000`"
}
```

### 5. Error Recovery
Always include appropriate pauses for system response:
```json
{
  "text": "LOAD\"PROGRAM.PRG\",8`ENTER``_3000`RUN`ENTER`"
}
```

## Error Handling

### Common Issues
- **Buffer Full**: Queue has reached 4096 character limit
- **Invalid Macro**: Unknown macro name in backticks
- **Timing Issues**: Commands sent too quickly without pauses

### Success Response
```json
{
  "status": "success",
  "message": "Text queued for emulator"
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Failed to queue text - buffer may be full"
}
```

## Integration Examples

### Basic BASIC Programming
```json
{
  "text": "10 FOR I=1 TO 10`ENTER`20 PRINT I`ENTER`30 NEXT I`ENTER`RUN`ENTER`"
}
```

### Interactive Session
```json
{
  "text": "PRINT \"WHAT IS YOUR NAME?\"`ENTER``_1000`INPUT N$`ENTER``_500`PRINT \"HELLO \";N$`ENTER`"
}
```

### Game Loading Sequence
```json
{
  "text": "`CLR`LOADING GAME...`ENTER``_1000`LOAD\"GAME.PRG\",8`ENTER``_5000`RUN`ENTER`"
}
```

This comprehensive system provides natural text input with precise timing control, making it ideal for automated testing, demonstration scripts, and interactive emulator control.
