
#!/usr/bin/env bash
set -euo pipefail
set +m  # Disable job control for Colab compatibility

# Source the library (adjust the path as needed)
source "$(dirname "$0")/genid.sh"

# ----------------------------
# testid() — exercise genid() under concurrency and validate
# ----------------------------
testid() {
    local TOTAL_IDS=1000
    local PARALLEL=10
    local VERBOSE=0  # Initialize VERBOSE to avoid unbound variable
    local OUTPUT_FILE="output_ids.txt"
    local EXPECTED_FILE="expected_ids.txt"
    local SORTED_FILE="sorted_ids.txt"
    local GAP_FILE="gap_report.txt"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            [0-9]*)
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    PARALLEL="$1"
                else
                    echo "Error: parallel_processes must be a positive integer, got '$1'" >&2
                    echo "Usage: $0 [-v|--verbose] [parallel_processes]" >&2
                    echo "  -v, --verbose: Print IDs to console during generation" >&2
                    echo "  parallel_processes: Number of parallel processes (default: 10)" >&2
                    return 1
                fi
                shift
                ;;
            *)
                echo "Error: unknown option '$1'" >&2
                echo "Usage: $0 [-v|--verbose] [parallel_processes]" >&2
                echo "  -v, --verbose: Print IDs to console during generation" >&2
                echo "  parallel_processes: Number of parallel processes (default: 10)" >&2
                return 1
                ;;
        esac
    done

    echo "Generating $TOTAL_IDS IDs with $PARALLEL parallel processes..."

    # Clean up previous runs
    rm -f "$OUTPUT_FILE" "$EXPECTED_FILE" "$SORTED_FILE" "$GAP_FILE" \
          id_counter.txt id_lockfile.lock

    # Prepare expected sequence
    seq -f "%05g" 1 "$TOTAL_IDS" > "$EXPECTED_FILE"

    # Run genid in parallel
    export -f genid
    if [ "$VERBOSE" -eq 1 ]; then
        seq "$TOTAL_IDS" \
          | xargs -n1 -P"$PARALLEL" bash -c 'genid | tee -a '"$OUTPUT_FILE"'' _
    else
        seq "$TOTAL_IDS" \
          | xargs -n1 -P"$PARALLEL" bash -c 'genid >> '"$OUTPUT_FILE"'' _
    fi

    # Validate
    sort "$OUTPUT_FILE" > "$SORTED_FILE"
    echo -e "\nValidation Results:"

    # 1) Count check
    local actual_count
    actual_count=$(wc -l < "$SORTED_FILE")
    if [ "$actual_count" -ne "$TOTAL_IDS" ]; then
        echo "ERROR: Expected $TOTAL_IDS IDs, got $actual_count" >&2
        return 1
    fi

    # 2) Duplicates
    if dup=$(uniq -d "$SORTED_FILE"); then
        if [ -n "$dup" ]; then
            echo "ERROR: Duplicate IDs found:" >&2
            echo "$dup" | head -n5 >&2
            return 1
        else
            echo "✓ No duplicate IDs"
        fi
    fi

    # 3) Gaps
    if ! diff -w "$EXPECTED_FILE" "$SORTED_FILE" > "$GAP_FILE"; then
        echo "ERROR: Gaps detected in ID sequence:" >&2
        head -n5 "$GAP_FILE" >&2
        echo "...(see $GAP_FILE for full details)" >&2
        return 1
    else
        echo "✓ No gaps in ID sequence"
    fi

    echo -e "\nTest completed successfully!"
}

# If run directly, invoke testid()
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    testid "$@"
fi
