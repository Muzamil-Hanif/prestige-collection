#!/usr/bin/env bash
# Auto-format a Dart file after it is written/edited.
file="${1:-}"
if [[ "$file" == *.dart && -f "$file" ]]; then
  dart format "$file" --line-length 80 2>/dev/null && echo "formatted: $file"
fi
