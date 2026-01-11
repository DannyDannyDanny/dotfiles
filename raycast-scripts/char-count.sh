#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title char count
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Placeholder" }

# Documentation:
# @raycast.description counts chars in selected text
# @raycast.author DannyDannyDanny
# @raycast.authorURL https://raycast.com/DannyDannyDanny

echo -n "$1" | wc -c
