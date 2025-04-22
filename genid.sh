genid() {
    local ID_FILE="id_counter.txt"
    [ ! -f "$ID_FILE" ] && echo 0 > "$ID_FILE"
    local id=$(<"$ID_FILE")
    id=$((id + 1))
    echo "$id" > "$ID_FILE"
    printf "%05d\n" "$id"
}
