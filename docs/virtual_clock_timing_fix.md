# Virtual Clock Timing Fix for Keyboard Processor

## Problem

The MCP keyboard processor was using `SDL_GetTicks()` for timing, which is system time and can be affected by:
- Framerate drops
- Emulator pauses
- System performance issues
- Host system clock changes

This caused keyboard input to drop keys or have inconsistent timing when the emulator experienced performance issues.

## Solution

Modified the keyboard processor to use the emulator's virtual clock time instead of system time. The virtual clock is based on the 6502 CPU clock ticks (`clockticks6502`) which runs at the emulated CPU frequency.

## Changes Made

### 1. Added Virtual Clock Function

```cpp
static uint32_t get_virtual_clock_ms() {
    // Convert CPU ticks to milliseconds
    // clockticks6502 is in CPU cycles, MHZ is in MHz
    // Formula: (clockticks6502 / (MHZ * 1000000)) * 1000 = clockticks6502 / (MHZ * 1000)
    return clockticks6502 / (MHZ * 1000);
}
```

### 2. Added External References

```cpp
extern "C" {
    // Virtual clock timing from emulator
    extern uint32_t clockticks6502;
    extern uint8_t MHZ;
}
```

### 3. Updated Timing Calls

Replaced `SDL_GetTicks()` calls with `get_virtual_clock_ms()` in:
- `process_input_event_queues()` - Main timing loop
- `submit_input_queue()` - Queue initialization

## Benefits

1. **Consistent Timing**: Keyboard input timing is now tied to the emulated CPU clock, not system performance
2. **Pause-Safe**: When the emulator is paused, the virtual clock stops, so keyboard timing is preserved
3. **Framerate Independent**: Keyboard timing is unaffected by video framerate drops
4. **Accurate Emulation**: Timing now matches the actual 6502 clock rate (8 MHz by default)

## Technical Details

- The virtual clock is calculated from `clockticks6502` which accumulates CPU cycles
- `MHZ` is the emulated CPU frequency (8 MHz by default, configurable via `-mhz` option)
- Time conversion: `milliseconds = clockticks6502 / (MHZ * 1000)`
- This ensures keyboard timing scales correctly with different CPU speeds

## Testing

The fix has been compiled successfully and is ready for testing. To verify:

1. Start the emulator with MCP server enabled
2. Send keyboard input via MCP
3. Test during various conditions:
   - Normal operation
   - Emulator pause/unpause
   - High CPU load scenarios
   - Different `-mhz` settings

## Backward Compatibility

This change is fully backward compatible:
- All existing MCP keyboard functionality remains unchanged
- No changes to the MCP protocol or API
- Legacy keyboard functions continue to work as before
