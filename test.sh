#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/genid.sh"

testid() {
    local TOTAL_IDS=1000
    local PARALLEL=5
    local OUTPUT_FILE="output_ids.txt"

    rm -f "$OUTPUT_FILE" id_counter.txt lockfile.lock

    seq "$TOTAL_IDS" | xargs -n1 -P"$PARALLEL" bash -c 'genid >> output_ids.txt' _
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    testid "$@"
fi
