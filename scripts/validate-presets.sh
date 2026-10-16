#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
for preset in *.pkl test/*.pkl; do
  case "$preset" in
    hk.pkl | builtins.pkl) continue ;;
  esac
  HK_FILE="$preset" hk validate
done
