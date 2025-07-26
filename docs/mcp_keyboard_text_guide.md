# MCP Keyboard Text Input Guide

## Overview
This guide provides complete documentation for using the `send_keyboard` tool's `text` parameter in ASCII mode (the default mode).

## Basic Usage

### ASCII Mode (Default)
- **Lowercase conversion**: All lowercase letters are automatically converted to uppercase
- **Example**: `"hello world"` becomes `"HELLO WORLD"`

### Escape Sequences
Standard escape sequences are supported:
- `\t` - TAB key
- `\n` - ENTER key

### Backtick Macros
Use backticks to insert special keys and commands:

#### Common Keys
- `ENTER` - Enter/Return key
- `F1`, `F2`, `F3`, etc. - Function keys
- `UP`, `DOWN`, `LEFT`, `RIGHT` - Arrow keys
- `HOME` - Home key
- `CLR` - Clear screen key

#### Commodore-Specific Keys
Following Commodore documentation conventions:
- `CRSR UP` - Cursor up
- `CRSR DOWN` - Cursor down
- `INST DEL` - Insert/Delete key

#### Timing Controls
Pauses can be inserted for timing control:
- `_500` - Pause for 500 milliseconds
- `_1.5` - Pause for 1.5 seconds
- **Rule**: Integer values = milliseconds, decimal values = seconds

## PETSCII Mode Examples
When using `mode: "petscii"`, additional symbols are available:

### Colors
- `RED` - Red text color
- `BLUE` - Blue text color

### Symbols
- `HEART` - Heart symbol
- `SPADE` - Spade symbol

## Complete Examples

### Basic Text Input
```json
{
  "text": "hello world"
}
```
Result: Types "HELLO WORLD"

### Text with Enter
```json
{
  "text": "hello`ENTER`world"
}
```
Result: Types "HELLO", presses Enter, then types "WORLD"

### Text with Timing
```json
{
  "text": "loading`_1.5`complete"
}
```
Result: Types "LOADING", waits 1.5 seconds, then types "COMPLETE"

### Using Escape Sequences
```json
{
  "text": "line1\nline2\tindented"
}
```
Result: Types "LINE1", presses Enter, types "LINE2", presses Tab, types "INDENTED"

### PETSCII Mode with Colors
```json
{
  "text": "`RED`error message`BLUE`info text",
  "mode": "petscii"
}
```
Result: Types "ERROR MESSAGE" in red, then "INFO TEXT" in blue

## Key Points for LLMs

1. **Case Conversion**: In ASCII mode, lowercase automatically becomes uppercase
2. **Timing Units**: `_500` = 500ms, `_1.5` = 1.5 seconds
3. **Backtick Syntax**: Use backticks for special keys: `ENTER`, `F1`, etc.
4. **Escape Sequences**: `\t` and `\n` work as expected
5. **Commodore Keys**: Use official names like `CRSR UP`, `INST DEL`
6. **PETSCII Mode**: Enables colors and special symbols

## Mode Reference

| Mode | Description | Case Conversion | Special Features |
|------|-------------|----------------|------------------|
| `ascii` | Default mode | Lowercase → Uppercase | Standard keys only |
| `petscii` | Commodore PETSCII | Varies | Colors, symbols |
| `screen` | Screen codes | Varies | Direct screen codes |

This guide ensures LLMs can effectively use the keyboard input functionality with proper timing, key sequences, and mode-specific features.
