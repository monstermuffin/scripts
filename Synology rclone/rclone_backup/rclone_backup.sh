#!/bin/bash

# Get the directory where the script is running
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Configuration file path
CONFIG_FILE="$SCRIPT_DIR/config"

# Load configuration if file exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Convert LOCALDIRS into an array
IFS=',' read -r -a local_dirs_array <<< "$LOCALDIRS"

# Convert comma-separated list into rclone flags
convert_to_rclone_flags() {
    local patterns="$1"
    local flag="$2"
    local result=()

    if [ -n "$patterns" ]; then
        IFS=',' read -ra ADDR <<< "$patterns"
        for i in "${ADDR[@]}"; do
            result+=("$flag=\"$i\"")
        done
    fi

    echo "${result[@]}"
}

# Function to join array elements into a string
join_by() {
    local IFS="$1"; shift
    echo "$*"
}

# Ensure log file and directory exist
ensure_logfile_exists() {
    local logfile=$1
    local logdir=$(dirname "$logfile")

    [ ! -d "$logdir" ] && mkdir -p "$logdir"
    [ ! -f "$logfile" ] && touch "$logfile"
}

ensure_logfile_exists "$LOGFILE"

readarray -t EXCLUDE_FLAGS < <(convert_to_rclone_flags "$EXCLUDE_PATTERNS" "--exclude")
readarray -t INCLUDE_FLAGS < <(convert_to_rclone_flags "$INCLUDE_PATTERNS" "--include")
readarray -t EXCLUDE_IF_PRESENT_FLAGS < <(convert_to_rclone_flags "$EXCLUDE_IF_PRESENT" "--exclude-if-present")

# Art for logs
ART="_.~"~._.~"~._.~"~._.~"~._"
echo "$ART Rclone Copy Job started at $(date "+%d.%m.%Y %T") $ART" | tee -a $LOGFILE

# Determine progress flag
PROGRESS_FLAG=""
if [ -t 0 ]; then
    PROGRESS_FLAG="--progress"
fi

# Loop through each local directory and perform the operation
for LOCALDIR in "${local_dirs_array[@]}"; do
    echo "Starting $OPERATION_MODE for $LOCALDIR" | tee -a $LOGFILE

    RCLONE_CMD="rclone $OPERATION_MODE \"$LOCALDIR\" \"$REMOTEDIR\" --log-level=$LOGLEVEL --log-file=$LOGFILE --transfers=$TRANSFER_LIMIT ${BWLIMIT:+--bwlimit=$BWLIMIT} ${CUSTOM_FLAGS} $PROGRESS_FLAG --retries=$RETRIES --retries-sleep=${RETRY_DELAY}s --checkers=$CHECKERS ${DRY_RUN:+--dry-run}"

    [[ ${#INCLUDE_FLAGS[@]} -ne 0 ]] && RCLONE_CMD+=" $(join_by ' ' "${INCLUDE_FLAGS[@]}")"
    [[ ${#EXCLUDE_FLAGS[@]} -ne 0 ]] && RCLONE_CMD+=" $(join_by ' ' "${EXCLUDE_FLAGS[@]}")"
    [[ ${#EXCLUDE_IF_PRESENT_FLAGS[@]} -ne 0 ]] && RCLONE_CMD+=" $(join_by ' ' "${EXCLUDE_IF_PRESENT_FLAGS[@]}")"

    eval $RCLONE_CMD
    STATUS=$?

    if [ $STATUS -ne 0 ]; then
        echo "Rclone $OPERATION_MODE encountered an error for $LOCALDIR. Check the log file for details." | tee -a $LOGFILE
    fi

    echo "Completed $OPERATION_MODE for $LOCALDIR" | tee -a $LOGFILE
done

echo "$ART Rclone Copy Job ended at $(date "+%d.%m.%Y %T") $ART" | tee -a $LOGFILE