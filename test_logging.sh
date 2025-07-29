#!/bin/bash
cd emulator
echo "Starting X16 emulator with assembly logging test..."
./x16emu -prg ../test_asm_logging.prg -run &
EMULATOR_PID=$!
sleep 3
kill $EMULATOR_PID 2>/dev/null
echo "Test completed."
