#!/usr/bin/env bash
# Build firmware and copy .hex to Curiosity Nano (CURIOSITY volume).
# The board programs automatically when the file is copied.
# Usage: from repo root: ./tools/flash_curiosity.sh   or   bash tools/flash_curiosity.sh

set -e
cd "$(dirname "$0")/.."
HEX="firmware_sam/dist/default/production/firmware_sam.production.hex"
VOL="/Volumes/CURIOSITY"

echo "Building firmware..."
make -C firmware_sam

if [[ ! -d "$VOL" ]]; then
  echo "CURIOSITY volume not found. Plug in the Curiosity Nano (USB) and run this script again."
  exit 1
fi

echo "Copying $HEX to $VOL ..."
cp -X "$HEX" "$VOL/" 2>/dev/null || cp "$HEX" "$VOL/"
echo "Done. The board will program automatically (watch the status LED)."
