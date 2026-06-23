#!/bin/bash

set -e

# html-preview: Open HTML content or file in the default browser
# Usage: /html-preview <file-path-or-html-content>

if [ -z "$1" ]; then
  echo "Error: Please provide an HTML file path or HTML content"
  echo "Usage: /html-preview <file-path-or-html-content>"
  exit 1
fi

INPUT="$1"
TEMP_DIR="/tmp/claude-html-preview"
mkdir -p "$TEMP_DIR"

# Check if input is a file path
if [ -f "$INPUT" ]; then
  FILE_PATH="$INPUT"
  echo "Opening HTML file: $FILE_PATH"
else
  # Treat as HTML content - create temp file
  FILE_PATH="$TEMP_DIR/preview_$(date +%s).html"
  echo "$INPUT" > "$FILE_PATH"
  echo "Opening HTML preview from generated file"
fi

# Detect OS and open in default browser
case "$(uname -s)" in
  Darwin)
    # macOS
    open "$FILE_PATH"
    ;;
  Linux)
    # Linux
    if command -v xdg-open &> /dev/null; then
      xdg-open "$FILE_PATH"
    elif command -v gnome-open &> /dev/null; then
      gnome-open "$FILE_PATH"
    else
      echo "Error: Could not find browser opener on Linux"
      exit 1
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    # Windows
    start "$FILE_PATH"
    ;;
  *)
    echo "Error: Unsupported operating system"
    exit 1
    ;;
esac

echo "✓ HTML preview opened in browser"
echo "File: $FILE_PATH"
