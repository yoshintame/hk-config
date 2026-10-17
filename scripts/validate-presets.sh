#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
for preset in pkl/presets/*.pkl test/*.pkl; do
  HK_FILE="$preset" hk validate
done
