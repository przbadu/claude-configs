#!/bin/bash
# Reads the last assistant message from the transcript and speaks it aloud

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

TRANSCRIPT_PATH=$(jq -r '.transcript_path')

# Wait for the transcript to be flushed with the final message
sleep 1

RAW=$(
  tac "$TRANSCRIPT_PATH" |
  jq -r 'select(.type == "assistant") |
    .message.content[] | select(.type == "text") | .text' 2>/dev/null |
  head -1
)

# Clean up: strip code blocks, inline code, paths, CLI flags, URLs,
# markdown syntax, and other non-speech-friendly content, then limit to 50 words
SUMMARY=$(
  echo "$RAW" |
  sed 's/```[^`]*```//g' |               # remove fenced code blocks
  sed 's/`[^`]*`//g' |                    # remove inline code
  sed 's|https\?://[^ ]*||g' |           # remove URLs
  sed 's|[^ ]*[/\\][^ ]*||g' |           # remove file paths
  sed 's/ --\?[a-zA-Z_-]*//g' |          # remove CLI flags
  sed 's/[*#>`~_|{}()\[\]]//g' |         # remove markdown/special chars
  tr '\n' ' ' |                           # collapse to single line
  sed 's/  */ /g; s/^ *//; s/ *$//' |    # normalize whitespace
  awk '{for(i=1;i<=NF && i<=50;i++) printf "%s ", $i; print ""}' |
  sed 's/ *$//'
)

if [ -n "$SUMMARY" ]; then
  say "$SUMMARY"
else
  say "Task completed"
fi
