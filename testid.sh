#!/usr/bin/env bash
set -euo pipefail
set +m 

source "$(dirname "$0")/genid.sh"

# ----------------------------
# testid() — exercise genid() under concurrency and validate
# ----------------------------
testid() {
    local TOTAL_IDS=1000
    local PARALLEL=10
    local VERBOSE=0
    local TMP_DIR="tmp"
    local RESULT_DIR="result"

    mkdir -p "$TMP_DIR" "$RESULT_DIR"

    local OUTPUT_FILE="$TMP_DIR/output_ids.txt"
    local EXPECTED_FILE="$TMP_DIR/expected_ids.txt"
    local SORTED_FILE="$RESULT_DIR/sorted_ids.txt"
    local GAP_FILE="$RESULT_DIR/gap_report.txt"
    local COUNTER_FILE="$TMP_DIR/id_counter.txt"
    local LOCK_FILE="$TMP_DIR/id_lockfile.lock"

    # Parse CLI args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose) VERBOSE=1; shift ;;
            -p|--total-ids) TOTAL_IDS="$2"; shift 2 ;;
            [0-9]*) PARALLEL="$1"; shift ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
    done

    echo "Generating $TOTAL_IDS IDs with $PARALLEL parallel processes..."

    rm -f "$OUTPUT_FILE" "$EXPECTED_FILE" "$SORTED_FILE" "$GAP_FILE" "$COUNTER_FILE" "$LOCK_FILE"

    # Prepare expected ID sequence
    seq -f "%05g" 1 "$TOTAL_IDS" > "$EXPECTED_FILE"

    # Export context for genid
    export ID_FILE="$COUNTER_FILE"
    export LOCK_FILE="$LOCK_FILE"
    export VERBOSE="$VERBOSE"

    # Run in parallel with tee + grep for verbose screen output
    seq "$TOTAL_IDS" \
      | xargs -n1 -P"$PARALLEL" bash -c 'genid' _ \
      | tee "$OUTPUT_FILE" \
      | grep -E '^PID' || true

    # Validate result
    sort "$OUTPUT_FILE" > "$SORTED_FILE"
    echo -e "\nValidation Results:"

    local actual_count
    actual_count=$(wc -l < "$SORTED_FILE")
    if [ "$actual_count" -ne "$TOTAL_IDS" ]; then
        echo "ERROR: Expected $TOTAL_IDS IDs, got $actual_count"
        return 1
    fi

    local dup
    dup=$(uniq -d "$SORTED_FILE" || true)
    if [ -n "$dup" ]; then
        echo "ERROR: Duplicate IDs found:"
        echo "$dup" | head -n 5
        return 1
    else
        echo "No duplicate IDs"
    fi

    if ! diff -w "$EXPECTED_FILE" "$SORTED_FILE" > "$GAP_FILE"; then
        echo "ERROR: Gaps detected in ID sequence:"
        head -n5 "$GAP_FILE"
        echo "...(see $GAP_FILE for full details)"
        return 1
    else
        echo "No gaps in ID sequence"
    fi

    echo -e "\nTest completed successfully!"
}

# Run testid if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    testid "$@"
fi
