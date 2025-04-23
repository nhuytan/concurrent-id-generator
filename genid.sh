#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# genid() — generate a unique, zero‑padded ID
# ----------------------------
genid() {
    local ID_FILE="id_counter.txt"
    local LOCK_FILE="id_lockfile.lock"
    local fd=200
    local width=5

    # Open (and create) the lockfile on fd 200
    exec {fd}>"$LOCK_FILE" || {
        echo "Error: cannot open lock file '$LOCK_FILE'" >&2
        return 1
    }
    # Acquire exclusive lock
    flock -x "$fd" || {
        echo "Error: cannot acquire lock on '$LOCK_FILE'" >&2
        exec {fd}>&-
        return 1
    }

    # Initialize counter if missing
    [ ! -s "$ID_FILE" ] && echo "0" > "$ID_FILE"

    # Read, validate, increment, and write back
    local id
    id=$(<"$ID_FILE")
    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "Error: invalid counter value '$id'" >&2
        flock -u "$fd"
        exec {fd}>&-
        return 1
    fi
    id=$((id + 1))
    echo "$id" > "$ID_FILE" || {
        echo "Error: failed to write counter to '$ID_FILE'" >&2
        flock -u "$fd"
        exec {fd}>&-
        return 1
    }

    # Release lock & close FD
    flock -u "$fd"
    exec {fd}>&-

    # Print zero padded ID
    printf "%0${width}d\n" "$id"
}

# If someone sources this file, export the function too
export -f genid
