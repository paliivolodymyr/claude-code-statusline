#!/bin/bash
# Run statusline.sh against all bundled fixtures.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/../statusline.sh"

fail=0
for fixture in "$DIR"/*.json; do
    echo "── $(basename "$fixture") ─────────────────────────────"
    if ! "$SCRIPT" < "$fixture"; then
        echo "FAILED (non-zero exit)"
        fail=1
    fi
    echo ""
done

echo "── empty stdin ─────────────────────────────"
printf '%s\n' "$(printf '' | "$SCRIPT")"
echo ""

[ "$fail" -eq 0 ] && echo "All fixtures rendered OK." || { echo "Some fixtures failed."; exit 1; }
