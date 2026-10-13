#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
for preset in base.pkl ts.pkl test/consumer.pkl; do
  HK_FILE="$preset" hk validate
done
