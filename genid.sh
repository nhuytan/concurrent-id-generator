set -euo pipefail

genid() {
    local ID_FILE="id_counter.txt"
    local LOCK_FILE="lockfile.lock"
    local fb=200
    local width=5

    # Open the lockfile on fd 200
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
    [ ! -f "$ID_FILE" ] && echo 0 > "$ID_FILE"

    # Read, increment and write back to counter file
    local id=$(<"$ID_FILE")
    id=$((id + 1))
    echo "$id" > "$ID_FILE"

    # Release lock & close FD
    flock -u "$fd"
    exec {fd}>&-
    
    printf "%05d\n" "$id"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    genid
fi
