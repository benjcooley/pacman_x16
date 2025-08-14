## Pac-Man X16 Test Plan

### Boot and ROM Placement
- [ ] Verify linker config (`tests/simple.cfg`) start address and BASIC entry are correct
- [ ] Smoke test with 16-byte PRG (write to `$9F20`, `RTS`) using same cfg in x16emu

### Emulator Run Target
- [ ] Run the game via emulator: `x16emu -prg bin/pacman.prg -run -scale 2 -quality 2 -debug`
- [ ] If `x16emu` missing, build `emulator/` or use an existing binary

### Bring-up Modes (compile-time switch)
- [ ] `init-only`: call `x16_init`; screen remains stable/black
- [ ] `clear-screen`: run `clear_screen`; empty grid/white color visible
- [ ] `draw-maze`: run `draw_pacman_maze`; maze renders fully
- [ ] `draw-ui`: render score/hiscore/status fruits rows at (8,2)/(20,2)
- [ ] `draw-sprites`: place Pac + 1 ghost sprite at known tiles; visible
- [ ] `move-sprite`: move Pac slowly; smooth updates, no tearing
- [ ] `queue-only`: seed `CMD_01` and drain; UI updates, no movement
- [ ] `full-loop (no input)`: run ~10s; siren fades in; no crashes

### Logging Fallback (no MCP)
- [ ] Add tiny RAM ring buffer logger (256 entries): per-frame `tick_lo`, Pac tile, Blinky tile/dir/state, queue count
- [ ] Dump via emulator monitor `m <addr>` on hang; keep `ENABLE_QUEUE_TRACE` minimal (1 byte per dequeued cmd + frame terminator)

### Deterministic Baseline
- [ ] Fix RNG seed; disable demo/attract
- [ ] Run 1200 frames, no input; produce golden minimal log (or per-frame checksum)

### Early Gameplay Checks (no input)
- [ ] `dots_remaining` starts at 244; maze dots visible
- [ ] Dot/fruit queue drain occurs before collision checks each frame
- [ ] Scatter/Chase schedule logs phase; reversals only on phase flips
- [ ] House release: Pinky timer starts; Inky/Clyde dot-limits set (30/60); `global_dot_active=1`

### Input Sanity
- [ ] Space toggles `paused_flag`; pause halts updates while VSYNC continues

### Frightened Mode
- [ ] Extract ROM-accurate per-level frightened durations; update `level_fright_ticks`
- [ ] Blink starts in last 1s; palette swaps verified
- [ ] Frightened speed masks for Pac/ghosts match intended behavior

### Scatter/Chase Schedule
- [ ] Reconfirm phase schedule boundaries across levels
- [ ] Reversals only on phase flips and fright start/end; exclude house/leave/eyes

### Ghost House Releases
- [ ] Finalize Inky/Clyde dot-limit tables per level; Pinky timed release verified
- [ ] Global dot credit behavior correct (only one ghost credited per dot)

### Ghost AI Targeting
- [ ] Pinky 4-ahead quirk present (with known bug parity)
- [ ] Inky vector target (Pac + Blinky offset) matches
- [ ] Clyde distance rule (scatter when too close) enforced

### Collisions
- [ ] Collision threshold tuned (`COLLISION_THRESH_PLUS1`) to match expected hits
- [ ] Ghost-eaten window while frightened correct; Pac death timing correct

### Tunnel and Speed Rules
- [ ] Tunnel speed masks for Pac and ghosts match expectations; non-tunnel unaffected
- [ ] Elroy applies only in normal state; thresholds correct

### Power Pellets
- [ ] Ghost-eaten chain scores (200/400/800/1600) and popups show at correct positions/durations
- [ ] Eyes return/reset timing and speed verified

### Fruit
- [ ] Spawn thresholds (first/second) per level correct
- [ ] Despawn timer duration correct; pickup increments score; status fruit row updates

### Command Queue Parity (Gameplay)
- [ ] Enqueue AI helpers at ROM callpoints: 0x08..0x0B (avoid), 0x0C..0x0F (scatter)
- [ ] Localized drain applies helper effects before target/choose_move
- [ ] Non-gameplay RST #28 (attract/test) intentionally out of scope for now

### Regression Testing
- [ ] Establish golden per-frame checksum/log for 1200-frame no-input baseline
- [ ] Simple diff script flags first mismatching frame; expand that frame’s queue and entities for debugging








