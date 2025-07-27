# MCP Keyboard Text Command Guide - ASCII Mode

## Overview

The `send_keyboard` MCP tool with `text` parameter provides comprehensive text input capabilities for the Commander X16 emulator. This guide covers ASCII mode usage (the default mode).

## Basic Usage

```json
{
  "text": "your text here"
}
```

### With Custom Typing Rate

```json
{
  "text": "your text here",
  "typing_rate": 50
}
```

**Parameters:**
- `text` (required): The text to type
- `typing_rate` (optional): Milliseconds per character (default: 30ms, minimum: 30ms enforced for reliability)

## ASCII Mode Characteristics

- **Default Mode**: ASCII is the default mode when no mode is specified
- **Case Handling**: Lowercase letters are automatically converted to uppercase (X16 default)
- **Character Mapping**: Direct ASCII to X16 keyboard mapping
- **Shift Support**: Automatic SHIFT key handling for special characters

## Text Input Examples

### Simple Text
```json
{
  "text": "HELLO WORLD"
}
```
Result: Types "HELLO WORLD" on screen

### Mixed Case (Auto-Converted)
```json
{
  "text": "Hello World"
}
```
Result: Types "HELLO WORLD" (converted to uppercase)

### Numbers and Basic Punctuation
```json
{
  "text": "123 ABC, TEST."
}
```
Result: Types numbers, letters, comma, and period

## Special Characters (Require SHIFT)

The following characters automatically trigger SHIFT key presses:

- `!` (SHIFT + 1)
- `@` (SHIFT + 2) 
- `#` (SHIFT + 3)
- `$` (SHIFT + 4)
- `%` (SHIFT + 5)
- `^` (SHIFT + 6)
- `&` (SHIFT + 7)
- `*` (SHIFT + 8)
- `(` (SHIFT + 9)
- `)` (SHIFT + 0)
- `"` (SHIFT + APOSTROPHE) - **Now Working Correctly!**

### Example with Special Characters
```json
{
  "text": "PRINT \"HELLO!\" @ $100"
}
```
Result: Properly handles quotes, exclamation, at-sign, and dollar sign

## Macro System

Use backticks (`) to delimit macros within text:

### Special Keys
- `\`ENTER\`` - Enter/Return key
- `\`TAB\`` - Tab key
- `\`SPACE\`` - Space key
- `\`BACKSPACE\`` or `\`BS\`` - Backspace
- `\`DELETE\`` or `\`DEL\`` - Delete key
- `\`ESCAPE\`` or `\`ESC\`` - Escape key

### Navigation Keys
- `\`UP\`` - Up arrow
- `\`DOWN\`` - Down arrow  
- `\`LEFT\`` - Left arrow
- `\`RIGHT\`` - Right arrow
- `\`HOME\`` - Home key
- `\`END\`` - End key
- `\`CLR\`` - Clear screen (SHIFT + HOME)

### Function Keys
- `\`F1\`` through `\`F8\`` - Function keys

### Timing Macros
- `\`_500\`` - Wait 500 milliseconds
- `\`_1.5\`` - Wait 1.5 seconds
- `\`_2000\`` - Wait 2 seconds
- Any numeric value: `\`_750\``, `\`_0.25\``, etc.

## Complete Examples

### BASIC Program Entry
```json
{
  "text": "`CLR`10 PRINT \"HELLO WORLD\"`ENTER`20 GOTO 10`ENTER`RUN`ENTER`"
}
```

### Timed Input Sequence
```json
{
  "text": "A`_500`B`_500`C`_1000`DONE`ENTER`"
}
```

### Complex Command with Quotes
```json
{
  "text": "LOAD \"GAME.PRG\",8`ENTER`"
}
```

## PETSCII Color Codes

Access PETSCII colors using CTRL combinations:

- `\`BLACK\`` - CTRL + 2
- `\`WHITE\`` - CTRL + 9  
- `\`RED\`` - CTRL + 3
- `\`CYAN\`` - CTRL + 4
- `\`PURPLE\`` - CTRL + 5
- `\`GREEN\`` - CTRL + 6
- `\`BLUE\`` - CTRL + 7
- `\`YELLOW\`` - CTRL + 8

### Example with Colors
```json
{
  "text": "`RED`HELLO `BLUE`WORLD`WHITE`"
}
```

## PETSCII Symbols

Card suit symbols using SHIFT combinations:

- `\`HEART\`` - SHIFT + S
- `\`SPADE\`` - SHIFT + A
- `\`CLUB\`` - SHIFT + X  
- `\`DIAMOND\`` - SHIFT + Z

## Technical Details

### Character Processing
- **Lookup Table**: O(1) character mapping for performance
- **State Tracking**: Automatic SHIFT/CTRL key state management
- **Queue System**: Event-based processing with proper timing
- **Error Handling**: Graceful handling of unmapped characters

### Timing Algorithm
- **Base Rate**: 30ms per character (optimized for reliability)
- **Key Events**: 2ms minimum delay between key events
- **Release Timing**: 5ms delay for key release events
- **Macro Timing**: Custom delays via `_XXX` macros

### Queue Processing
- **Event Types**: KEYBOARD, JOYSTICK, WAIT
- **Sequential Processing**: Events processed in order
- **Memory Management**: Automatic cleanup of completed queues
- **State Persistence**: Modifier key states maintained across events

## Best Practices

1. **Use Macros**: Leverage `\`CLR\``, `\`ENTER\`` for cleaner code
2. **Timing Control**: Add delays with `\`_500\`` for visual effects
3. **Quote Handling**: Double quotes now work correctly in strings
4. **Error Recovery**: Invalid characters are skipped, not errored
5. **Performance**: Direct character lookup provides fast processing

## Troubleshooting

### Common Issues
- **Missing Quotes**: Ensure proper escaping in JSON: `\"`
- **Timing Too Fast**: Add `\`_XXX\`` delays between commands
- **Case Issues**: Remember ASCII mode converts to uppercase
- **Macro Syntax**: Use backticks, not other quote types

### Debug Information
The system provides detailed logging:
- Character mapping status
- Event queue processing
- Timing calculations
- Error conditions

## Integration Examples

### Python
```python
keyboard_input = {
    "text": "`CLR`PRINT \"HELLO\"`ENTER`"
}
```

### JavaScript  
```javascript
const keyboardInput = {
    text: "`CLR`PRINT \"HELLO\"`ENTER`"
};
```

### cURL
```bash
curl -X POST http://localhost:9090/keyboard \
  -H "Content-Type: application/json" \
  -d '{"text": "`CLR`PRINT \"HELLO\"`ENTER`"}'
```

## Summary

Your simplified keyboard processor now provides:

✅ **Reliable Text Input** - All ASCII characters work correctly  
✅ **Quote Support** - Double quotes function properly in strings  
✅ **Macro System** - Full macro support with timing control  
✅ **PETSCII Integration** - Colors and symbols available  
✅ **Performance** - Optimized character lookup and processing  
✅ **Error Handling** - Graceful handling of edge cases  

The system is now ready for production use with comprehensive text input capabilities for the Commander X16 emulator.
