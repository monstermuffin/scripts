#!/bin/bash
MACHINE_FILE="machines.txt"

# Log file
LOG_FILE="sumo.log"

# read -p "Enter SSH username: " SSH_USER
SSH_USER="XXXXX"
read -sp "Enter SSH password: " SSH_PASS
echo ""

ACCESSID="XXXXX"
ACCESSKEY="XXXXX"

UNINSTALL_CMD="sudo /usr/bin/alienvault-agent.sh uninstall"
BASE_INSTALL_CMD="sudo /tmp/./SumoCollector.sh -q -Vsumo.accessid=$ACCESSID -Vsumo.accesskey=$ACCESSKEY"
DRY_RUN_CHECK_CMD="rpm -q osqueryd"
START_COLLECTOR_CMD="sudo service collector start"
CHECK_COLLECTOR_CMD="systemctl is-active collector"

echo "Perform dry run? (y/n, default: y): "
read -r DRY_RUN
DRY_RUN=${DRY_RUN:-y}

SSH_COMMAND="sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no -l $SSH_USER"

while IFS= read -r machine; do
    if [[ -n "$machine" ]]; then
        echo "============================" | tee -a "$LOG_FILE"
        echo "Processing machine: $machine" | tee -a "$LOG_FILE"
        echo "============================" | tee -a "$LOG_FILE"

        {
        echo "Checking if collector service is already running on $machine..." | tee -a "$LOG_FILE"
        COLLECTOR_STATUS=$($SSH_COMMAND $machine "$CHECK_COLLECTOR_CMD" 2>&1)
        echo "Collector status: $COLLECTOR_STATUS" | tee -a "$LOG_FILE"
        if echo "$COLLECTOR_STATUS" | grep -q "active"; then
            echo "Sumo Logic collector service is already running on $machine. Skipping installation." | tee -a "$LOG_FILE"
            continue
        fi
        echo "Checking for osqueryd package on $machine..." | tee -a "$LOG_FILE"
        if ! $SSH_COMMAND $machine "$DRY_RUN_CHECK_CMD" 2>&1 | tee -a "$LOG_FILE"; then
            echo "osqueryd package not found on $machine." | tee -a "$LOG_FILE"
            if [[ $DRY_RUN != "y" ]]; then
                echo "osqueryd would be removed in actual run." | tee -a "$LOG_FILE"
            fi
        else
            echo "osqueryd package found on $machine." | tee -a "$LOG_FILE"
        fi

        if [[ $DRY_RUN != "y" ]]; then
            echo "Uninstalling old application on $machine..." | tee -a "$LOG_FILE"
            UNINSTALL_OUTPUT=$($SSH_COMMAND $machine "$UNINSTALL_CMD" 2>&1)
            echo "$UNINSTALL_OUTPUT" | tee -a "$LOG_FILE"
            HOSTNAME=$($SSH_COMMAND $machine "hostname" 2>&1)
            echo "Hostname of the machine: $HOSTNAME" | tee -a "$LOG_FILE"
            INSTALL_CMD="$BASE_INSTALL_CMD -Vcollector.name=$HOSTNAME"
            echo "Transferring installation files to $machine..." | tee -a "$LOG_FILE"
            TRANSFER_OUTPUT=$(sshpass -p $SSH_PASS scp ./SumoCollector.sh $SSH_USER@$machine:/tmp/ 2>&1)
            echo "$TRANSFER_OUTPUT" | tee -a "$LOG_FILE"
            echo "Installing new collector on $machine..." | tee -a "$LOG_FILE"
            INSTALL_OUTPUT=$($SSH_COMMAND $machine "$INSTALL_CMD" 2>&1)
            echo "$INSTALL_OUTPUT" | tee -a "$LOG_FILE"

            echo "Starting collector service on $machine..." | tee -a "$LOG_FILE"
            START_OUTPUT=$($SSH_COMMAND $machine "$START_COLLECTOR_CMD" 2>&1)
            echo "$START_OUTPUT" | tee -a "$LOG_FILE"

            echo "Processing for $machine complete." | tee -a "$LOG_FILE"
        fi
        } < /dev/null

        echo "Finished processing $machine." | tee -a "$LOG_FILE"
    fi
done < "$MACHINE_FILE"

echo "All machines processed." | tee -a "$LOG_FILE"
