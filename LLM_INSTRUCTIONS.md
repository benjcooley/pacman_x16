# LLM Instructions for X16 Emulator Output Analysis

## Overview
This document provides instructions for AI/LLM systems to analyze Commander X16 emulator output during development.

## Quick Start for LLMs

### 1. Running Programs with Visual Capture
Use these commands to run programs and capture their output:

```bash
# Run with AI development tool (includes screenshots + GIF)
python3 tools/ai_dev_tool.py 10

# Run with Makefile GIF recording
make run-gif GAME=pacman
```

### 2. Viewing Emulator Output
After running either command above, you'll see output like:

```
🎬 GIF RECORDING EXPORTED:
   📁 File: pacman_recording_20250724_231542.gif
   📏 Size: 1032192 bytes
   🤖 LLM VIEWING INSTRUCTIONS:
      Use: browser_action -> launch -> file:///Users/benjamincooley/projects/pacman_x16/pacman_recording_20250724_231542.gif
      This shows exactly what the emulator displayed during execution
```

### 3. LLM Analysis Steps
1. **Copy the file:// URL** from the output
2. **Use browser_action tool**:
   ```
   browser_action -> launch -> file:///full/path/to/recording.gif
   ```
3. **Analyze what you see** in the emulator output
4. **Describe the visual behavior** (colors, movement, crashes, etc.)

## Example Analysis Workflow

```
1. Run: python3 tools/ai_dev_tool.py 5
2. Look for: "🤖 LLM VIEWING INSTRUCTIONS"
3. Copy the file:// URL
4. Use: browser_action -> launch -> [URL]
5. Analyze the GIF/PNG content
6. Report findings and suggest fixes
```

## What to Look For

### ✅ Success Indicators
- Program loads and runs without crashing
- Expected visual elements appear
- Colors and graphics render correctly
- No error messages in emulator

### ❌ Problem Indicators
- "OUT OF MEMORY ERROR" messages
- Emulator crashes or exits early
- Black screen or no visual output
- Incorrect colors or graphics
- Garbled display

## File Locations

- **GIF Recordings**: Project root (e.g., `pacman_recording_*.gif`)
- **Screenshots**: `dev_screenshots/` directory
- **Session Logs**: `dev_logs/` directory

## Development Tools

- `python3 tools/ai_dev_tool.py [seconds]` - Full diagnostic with GIF + screenshots
- `make run-gif GAME=name` - Simple GIF recording
- `make run GAME=name` - Basic run without recording

## Notes for LLMs

- Always use the exact file:// URL provided in the tool output
- GIF files show the complete emulator session from start to finish
- Screenshots capture specific moments in time
- The X16 emulator has a distinctive blue boot screen - this is normal
- Programs that work correctly will show the boot sequence followed by program execution
