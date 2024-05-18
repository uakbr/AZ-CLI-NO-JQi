#!/bin/bash
# src/report.sh
CHECKPOINT_DIR="checkpoints"
# Function to log messages
function log() {
 local message=$1
 local level=$2
 timestamp=$(date +"%Y-%m-%d %H:%M:%S")
 echo "[$timestamp] [$level] $message" >> scan.log
}
# Function to generate the final report
function generateReport() {
 local findings=("$@")
 local report_file="azure_security_report_$(date +%Y%m%d_%H%M%S).json"
 local report_path="/app/output/$report_file"
 # Create the output directory if it doesn't exist
 mkdir -p /app/output
 # Generate the report JSON
 local report=$(cat <<EOF
{
 "timestamp": "$(date +%Y-%m-%d_%H:%M:%S)",
 "findings": [
 $(printf '%s\n' "${findings[@]}" | sed 's/$/,/' | sed '$ s/,$//')
 ]
}
EOF
)
 # Write the report to a file
 if echo "$report" > "$report_path"; then
 log "Report generated successfully at $report_path" "INFO"
 echo "$report_path"
 else
 log "Error generating report at $report_path" "ERROR"
 echo "Error generating report. Please check the logs for more details."
 return 1
 fi
}
# Function to save checkpoint data to SQLite database
function saveCheckpoint() {
 local sub_index=$1
 local data="${DATA[@]}"
 local findings="${FINDINGS[@]}"
 # Save checkpoint data to SQLite database
 if sqlite3 checkpoint.db "REPLACE INTO checkpoints (subscription_index, data, findings) VALUES ($sub_index, '$data', '$findings')"; then
 log "Checkpoint saved successfully for subscription index $sub_index" "INFO"
 else
 log "Error saving checkpoint for subscription index $sub_index" "ERROR"
 fi
}
# Function to load checkpoint data from SQLite database
function loadCheckpoint() {
 local sub_index=$1
 # Load checkpoint data from SQLite database
 local checkpoint=$(sqlite3 checkpoint.db "SELECT data, findings FROM checkpoints WHERE subscription_index = $sub_index")
 if [[ -n "$checkpoint" ]]; then
 log "Checkpoint loaded successfully for subscription index $sub_index" "INFO"
 IFS='|' read -r data findings <<< "$checkpoint"
 DATA=($data)
 FINDINGS=($findings)
 return 0
 else
 log "No checkpoint found for subscription index $sub_index" "INFO"
 return 1
 fi
}
# Function to remove checkpoint data from SQLite database
function removeCheckpoint() {
 local sub_index=$1
 # Remove checkpoint data from SQLite database
 if sqlite3 checkpoint.db "DELETE FROM checkpoints WHERE subscription_index = $sub_index"; then
 log "Checkpoint removed successfully for subscription index $sub_index" "INFO"
 else
 log "Error removing checkpoint for subscription index $sub_index" "ERROR"
 fi
}