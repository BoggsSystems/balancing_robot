#!/usr/bin/env bash
# Open macOS Dictation settings and show how to use voice input (e.g. in Cursor).
# Usage: ./tools/run_voice_input_mac.sh

echo "Opening Keyboard / Dictation settings..."
# Open Keyboard preferences (Dictation is under Keyboard > Text Input on recent macOS)
open "x-apple.systempreferences:com.apple.preference.keyboard" 2>/dev/null || \
open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension" 2>/dev/null || \
open -a "System Settings" 2>/dev/null

echo ""
echo "=== Voice input on Mac ==="
echo "1. In System Settings, go to: Keyboard → Text Input (or Dictation)"
echo "2. Turn ON Dictation and choose a shortcut (e.g. Press Fn key twice)."
echo "3. To use in Cursor: click in the chat box, then press Fn Fn (or your shortcut) and speak."
echo ""
echo "Shortcut: Press the Function (Fn) key twice to start/stop dictation."
echo ""
