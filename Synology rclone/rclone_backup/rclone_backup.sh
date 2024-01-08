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
        # Split the patterns using commas as a delimiter
        IFS=',' read -ra ADDR <<< "$patterns"
        for i in "${ADDR[@]}"; do
            result+=("$flag=\"$i\"") # Enclose each pattern in double quotes
        done
    fi

    echo "${result[@]}"
}

# Ensure log file and directory exist
ensure_logfile_exists() {
    local logfile=$1
    local logdir

    logdir=$(dirname "$logfile")

    # Create log directory if it doesn't exist
    if [ ! -d "$logdir" ]; then
        mkdir -p "$logdir"
    fi

    # Create log file if it doesn't exist
    if [ ! -f "$logfile" ]; then
        touch "$logfile"
    fi
}

# Ensure the log file and directory exist
ensure_logfile_exists "$LOGFILE"

# Process patterns
readarray -t EXCLUDE_FLAGS < <(convert_to_rclone_flags "$EXCLUDE_PATTERNS" "--exclude")
readarray -t INCLUDE_FLAGS < <(convert_to_rclone_flags "$INCLUDE_PATTERNS" "--include")
readarray -t EXCLUDE_IF_PRESENT_FLAGS < <(convert_to_rclone_flags "$EXCLUDE_IF_PRESENT" "--exclude-if-present")

# Check if BWLIMIT is set and format it for rclone
[ -n "$BWLIMIT" ] && BWLIMIT="--bwlimit=$BWLIMIT"

# Check if VERBOSE is true and set verbose flag
[ "$VERBOSE" = true ] && VERBOSE_FLAG="-v"

# Check if DRY_RUN is true and set dry-run flag
[ "$DRY_RUN" = true ] && DRY_RUN_FLAG="--dry-run"

# Add --progress flag if running interactively (terminal is attached to standard input)
if [ -t 0 ]; then
    PROGRESS_FLAG="--progress"
else
    PROGRESS_FLAG=""
fi

# Art for logs and start/end messages
ART="_.~"~._.~"~._.~"~._.~"~._"
START="$ART Rclone Copy Job started at $(date "+%d.%m.%Y %T") $ART"
END="$ART Rclone Copy Job ended at $(date "+%d.%m.%Y %T") $ART"

# Function to join array elements into a string
join_by() {
    local IFS="$1"
    shift
    echo "$*"
}

# Loop through each local directory and perform the operation
for LOCALDIR in "${local_dirs_array[@]}"; do
    echo "Starting $OPERATION_MODE for $LOCALDIR" | tee -a $LOGFILE

    # Construct rclone command with conditional inclusion of flags
    RCLONE_CMD="rclone $OPERATION_MODE \"$LOCALDIR\" \"$REMOTEDIR\" --log-level=$LOGLEVEL --log-file=$LOGFILE --transfers=$TRANSFER_LIMIT $BWLIMIT $CUSTOM_FLAGS $PROGRESS_FLAG --retries=$RETRIES --retries-sleep=${RETRY_DELAY}s --checkers=$CHECKERS $VERBOSE_FLAG $DRY_RUN_FLAG"

    # Append include and exclude flags if they are not empty
    if [ ${#INCLUDE_FLAGS[@]} -ne 0 ]; then
        RCLONE_CMD+=" $(join_by ' ' "${INCLUDE_FLAGS[@]}")"
    fi

    if [ ${#EXCLUDE_FLAGS[@]} -ne 0 ]; then
        RCLONE_CMD+=" $(join_by ' ' "${EXCLUDE_FLAGS[@]}")"
    fi

    if [ ${#EXCLUDE_IF_PRESENT_FLAGS[@]} -ne 0 ]; then
        RCLONE_CMD+=" $(join_by ' ' "${EXCLUDE_IF_PRESENT_FLAGS[@]}")"
    fi

    eval $RCLONE_CMD
    STATUS=$?

    if [ $STATUS -ne 0 ]; then
        echo "Rclone $OPERATION_MODE encountered an error for $LOCALDIR. Check the log file for details." | tee -a $LOGFILE
    fi

    echo "Completed $OPERATION_MODE for $LOCALDIR" | tee -a $LOGFILE
done

echo "All specified directories have been processed." | tee -a $LOGFILE
