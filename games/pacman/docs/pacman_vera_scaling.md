# Pacman VERA Scaling Configuration for Commander X16

## Overview
This document captures the optimal VERA scaling values discovered for Pacman development on the Commander X16.

## VERA Scaling System
- **Base Address**: $9F2A (horizontal), $9F2B (vertical)
- **Normal Scaling**: 128 = 1x scaling baseline
- **Scale Up**: Values < 128 = larger display
- **Scale Down**: Values > 128 = smaller display

## Optimal Pacman Scaling Values

### Primary Mode: 80x80 (Recommended)
```asm
LDA #80          ; Clean, even scaling
STA $9F2A        ; VERA_DC_HSCALE (40746)
STA $9F2B        ; VERA_DC_VSCALE (40747)
```
- **Benefits**: Clean, crisp graphics with even scaling
- **Layout**: Centered display, traditional Pacman layout
- **Scaling Factor**: ~1.60x larger than normal

### Alternative Mode: 70x70 (Score Layout)
```asm
LDA #70          ; Larger scaling for score-on-right layout
STA $9F2A        ; VERA_DC_HSCALE (40746)
STA $9F2B        ; VERA_DC_VSCALE (40747)
```
- **Benefits**: More space for score display on right side
- **Layout**: Game area with dedicated score region
- **Scaling Factor**: ~1.83x larger than normal

### Special Mode: 75x75 (Exact Pacman Size)
```asm
LDA #75          ; Exact original Pacman dimensions
STA $9F2A        ; VERA_DC_HSCALE (40746)
STA $9F2B        ; VERA_DC_VSCALE (40747)
```
- **Benefits**: Exactly 35 lines on screen (original Pacman size)
- **Layout**: Authentic arcade dimensions
- **Scaling Factor**: ~1.71x larger than normal

## Implementation Notes

### Assembly Template
```asm
; Pacman VERA Scaling Setup
start:
    ; Set optimal scaling (choose one)
    lda #80          ; or #70 or #75
    sta $9F2A        ; VERA_DC_HSCALE
    sta $9F2B        ; VERA_DC_VSCALE
    
    ; Continue with game initialization...
```

### Compilation
```bash
cl65 -C simple.cfg -o pacman.prg pacman.asm
```

### Testing Values Explored
- 128x128: Normal size (baseline)
- 192x192: Too small
- 255x255: Very small
- 64x64: Too large
- 52x52: Large but usable
- 91x52: Rectangular (tested)
- 70x70: Good for score layout
- 75x75: Exact Pacman size (35 lines)
- 76x76: Clean scaling
- 80x80: **Optimal** - clean and centered

## Recommendations

1. **Default**: Use 80x80 for new Pacman implementations
2. **Alternative**: Use 70x70 when score display needs more space
3. **Authentic**: Use 75x75 for exact original arcade dimensions

## Files
- `test_pacman_final.asm`: Working implementation with 80x80 scaling
- `simple.cfg`: Configuration file for compilation
- This document: Complete scaling reference

## Future Development
The VERA scaling system is now fully understood and documented. These values provide the foundation for all future Pacman development on the Commander X16.
