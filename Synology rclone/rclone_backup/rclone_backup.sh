#!/bin/bash

# Configuration file path
CONFIG_FILE="rclone_backup_config"

# Load configuration / Warn
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Convert comma-separated list into rclone flags
convert_to_rclone_flags() {
    local patterns=$1
    local flag=$2
    local result=""

    IFS=',' read -ra ADDR <<< "$patterns"
    for i in "${ADDR[@]}"; do
        result+="$flag $i "
    done

    echo $result
}

# Process patterns
EXCLUDE_FLAGS=$(convert_to_rclone_flags "$EXCLUDE_PATTERNS" "--exclude")
INCLUDE_FLAGS=$(convert_to_rclone_flags "$INCLUDE_PATTERN" "--include")
EXCLUDE_IF_PRESENT_FLAGS=$(convert_to_rclone_flags "$EXCLUDE_IF_PRESENT" "--exclude-if-present")

# Check if BWLIMIT is set and format it for rclone
[ -n "$BWLIMIT" ] && BWLIMIT="--bwlimit=$BWLIMIT"

# Check if VERBOSE is true and set verbose flag
[ "$VERBOSE" = true ] && VERBOSE_FLAG="-v"

# Check if DRY_RUN is true and set dry-run flag
[ "$DRY_RUN" = true ] && DRY_RUN_FLAG="--dry-run"

# Add --progress flag if running interactively
if [ -t 0 ]; then
    PROGRESS_FLAG="--progress"
else
    PROGRESS_FLAG=""
fi

# Art for logs
ART="_.~"~._.~"~._.~"~._.~"~._"

# Date & Time
START="$ART Rclone Copy Job started at $(date "+%d.%m.%Y %T") $ART"
END="$ART Rclone Copy Job ended at $(date "+%d.%m.%Y %T") $ART"

# Rclone Copy Script
echo $START | tee -a $LOGFILE
rclone copy $LOCALDIR $REMOTEDIR --log-level=$LOGLEVEL --log-file=$LOGFILE \
    $INCLUDE_FLAGS $EXCLUDE_FLAGS $EXCLUDE_IF_PRESENT_FLAGS \
    --transfers=$TRANSFER_LIMIT $BWLIMIT $CUSTOM_FLAGS $PROGRESS_FLAG \
    --retries=$RETRIES --retries-sleep=${RETRY_DELAY}s \
    --checkers=$CHECKERS $VERBOSE_FLAG $DRY_RUN_FLAG
STATUS=$?
echo $END | tee -a $LOGFILE

if [ $STATUS -ne 0 ]; then
    echo "Rclone operation encountered an error. Check the log file." | tee -a $LOGFILE
    exit $STATUS
fi

exit 0