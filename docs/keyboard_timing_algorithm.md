# Keyboard Timing Algorithm for X16 Emulator MCP

## Overview

This document describes the keyboard timing algorithm used in the X16 emulator's MCP (Model Context Protocol) keyboard input system. The algorithm ensures consistent typing rates while handling complex character sequences that require modifier keys.

## Core Principles

### Target Typing Rate
- **10ms per character** - This is the target time from the start of one character to the start of the next character
- Maintains consistent typing speed regardless of character complexity

### Event Types
Each key action generates two events:
1. **Key Down** - When a key is pressed
2. **Key Up** - When a key is released (1ms after key down)

### Timing Strategy
The algorithm uses **adaptive delays** to maintain the 10ms per character rate:
- Track time used by all events for each character
- Calculate remaining time needed to reach 10ms target
- Apply remaining time as delay before next character starts

## Algorithm Details

### Basic Character (e.g., 'A')
```
Character 'A':
1. A key down - 0ms delay (first character) or calculated delay
2. A key up - 1ms delay
Total time used: 1ms (only counting events after the initial down)
Next character delay: 10ms - 1ms = 9ms
```

### Shifted Character (e.g., '"')
```
Character '"':
1. SHIFT down - 0ms delay (first character) or calculated delay  
2. ' key down - 1ms delay
3. ' key up - 1ms delay
4. SHIFT up - 1ms delay
Total time used: 3ms (events after initial SHIFT down)
Next character delay: 10ms - 3ms = 7ms
```

### First Character Rule
The first character in any input string always starts immediately (0ms delay) regardless of previous timing calculations.

## Implementation Algorithm

### Step 1: Initialize
```cpp
uint32_t next_char_delay = 0;  // First character has no delay
bool is_first_character = true;
```

### Step 2: For Each Character
```cpp
for (each character in input) {
    uint32_t char_time_used = 0;
    bool is_first_event_for_char = true;
    
    // Handle modifier keys (SHIFT, CTRL)
    if (needs_shift && !shift_down) {
        uint32_t delay = is_first_event_for_char ? next_char_delay : 1;
        queue->add_event(SHIFT_DOWN, delay);
        if (!is_first_event_for_char) char_time_used += 1;
        is_first_event_for_char = false;
        shift_down = true;
    }
    
    // Main key down
    uint32_t delay = is_first_event_for_char ? next_char_delay : 1;
    queue->add_event(KEY_DOWN, delay);
    if (!is_first_event_for_char) char_time_used += 1;
    is_first_event_for_char = false;
    
    // Main key up
    queue->add_event(KEY_UP, 1);
    char_time_used += 1;
    
    // Release modifier keys if needed
    if (needs_shift && shift_down && next_char_doesnt_need_shift) {
        queue->add_event(SHIFT_UP, 1);
        char_time_used += 1;
        shift_down = false;
    }
    
    // Calculate delay for next character
    next_char_delay = TARGET_CHAR_RATE_MS - char_time_used;
    if (next_char_delay < 0) next_char_delay = 0;  // Safety check
}
```

### Step 3: Cleanup
```cpp
// Release any remaining modifier keys
if (shift_down) {
    queue->add_event(SHIFT_UP, 1);
}
if (ctrl_down) {
    queue->add_event(CTRL_UP, 1);
}
```

## Examples

### Example 1: "AB"
```
Character 'A' (first):
- A down: 0ms delay (first character)
- A up: 1ms delay
- Time used: 1ms
- Next delay: 10ms - 1ms = 9ms

Character 'B':
- B down: 9ms delay
- B up: 1ms delay
- Total time from A start: 0 + 1 + 9 + 1 = 11ms
- Effective rate: 10ms between character starts
```

### Example 2: 'A"' (A followed by quote)
```
Character 'A' (first):
- A down: 0ms delay
- A up: 1ms delay  
- Time used: 1ms
- Next delay: 9ms

Character '"':
- SHIFT down: 9ms delay
- ' down: 1ms delay
- ' up: 1ms delay
- SHIFT up: 1ms delay
- Time used: 3ms (after initial SHIFT down)
- Next delay: 10ms - 3ms = 7ms
```

### Example 3: "AA" (repeated character)
```
Character 'A' (first):
- A down: 0ms delay
- A up: 1ms delay
- Time used: 1ms
- Next delay: 9ms

Character 'A' (second):
- A down: 9ms delay
- A up: 1ms delay
- Time used: 1ms
- Next delay: 9ms
```

## Constants

```cpp
#define KEY_EVENT_DELAY_MS  1   // Standard delay for each key event
#define TARGET_CHAR_RATE_MS 10  // Target time per character (10ms typing rate)
```

## Benefits

1. **Consistent Typing Speed**: Maintains 10ms per character regardless of complexity
2. **Natural Feel**: Mimics human typing patterns with proper key press/release timing
3. **Modifier Key Handling**: Properly manages SHIFT, CTRL states across characters
4. **Predictable Timing**: Easy to calculate total typing time for any string
5. **Flexible**: Can handle any combination of characters and modifiers

## Edge Cases

### Minimum Delay Protection
If a character requires more than 10ms of events, the next character delay becomes 0ms to prevent negative delays.

### Modifier State Management
The algorithm tracks modifier key states across characters to avoid unnecessary press/release cycles.

### Escape Sequences
Special sequences like `\n` (newline) and `\t` (tab) are handled as single characters with their own timing calculations.

## Testing

To verify the algorithm:
1. Measure time between character start events
2. Should be consistently 10ms ± timing precision
3. Total string time should be: `(character_count - 1) * 10ms + last_character_time`

Example: "HELLO" (5 characters)
- Expected time: 4 * 10ms + ~1ms = ~41ms total
- Character starts at: 0ms, 10ms, 20ms, 30ms, 40ms
