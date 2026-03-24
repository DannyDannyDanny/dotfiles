#!/usr/bin/env bash
set -euo pipefail

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title char count
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Text to count" }

# Documentation:
# @raycast.description counts chars in selected text
# @raycast.author DannyDannyDanny
# @raycast.authorURL https://raycast.com/DannyDannyDanny

printf '%s' "${1:-}" | wc -c | awk '{ print $1 }'
