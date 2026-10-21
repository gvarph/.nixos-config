#!/usr/bin/env bash
# Lists files/folders in the downloads tree that are newer than the most
# recently-linked file currently in the audiobooks library. This is the
# self-contained way to find "the newest audiobook torrents" without
# depending on anything remembered from a prior conversation.
#
# Usage: find_new_audiobooks.sh
# Output: one candidate path per line, newest-reference-relative, with the
#         usual non-audiobook junk already filtered out. Still eyeball the
#         list yourself -- this is a first pass, not a guarantee every line
#         is really an audiobook (see SKILL.md "What this script does NOT do").

set -euo pipefail

DOWNLOADS="/tank/media/downloads"
AUDIOBOOKS="/tank/media/audiobooks"

# The most recently modified file anywhere in the library is our watermark.
# `head -1` closing the pipe early trips `pipefail` (SIGPIPE on the writer
# side) even though we got the line we wanted -- the `|| true` keeps that
# from killing the script under `set -e`.
REFERENCE=$(find "$AUDIOBOOKS" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2- || true)

if [[ -z "$REFERENCE" ]]; then
  echo "Could not determine a reference file under $AUDIOBOOKS -- is the library empty or unmounted?" >&2
  exit 1
fi

echo "# Using reference (most recently linked file): $REFERENCE" >&2

find "$DOWNLOADS" -maxdepth 3 -newer "$REFERENCE" \
  -not -path "$DOWNLOADS" \
  -not -path "*/slskd/*" \
  -not -path "*/incomplete/*" \
  -not -name ".*" \
  -not -name "*.jpg" -not -name "*.jpeg" -not -name "*.png" \
  -not -name "*.nfo" -not -name "*.txt" -not -name "*.key" \
  -not -name "*.idx" -not -name "*.sub" -not -name "*.srt" \
  -not -name "*.cue" -not -name "*.zip" -not -name "*.json" \
  -not -name "*.epub" \
  -not -name "*.mkv" -not -name "*.mp4" \
  2>/dev/null | sort
