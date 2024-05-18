#!/bin/bash
# bin/scanner.sh

# Import functions from other scripts
source ../src/auth.sh
source ../src/collect.sh
source ../src/analyze.sh
source ../src/report.sh

# Define supported resource types
resource_types=(
  "Microsoft.ApiManagement/service"
  "Microsoft.Compute/virtualMachines/extensions"
  "Microsoft.Network/networkWatchers/connectionMonitors"
  "Microsoft.Insights/scheduledQueryRules"
  "Microsoft.HybridCompute/machines"
  "Microsoft.Cdn/cdnWebApplicationFirewallPolicies"
  "Microsoft.ResourceGraph/queries"
  "Microsoft.Network/expressRouteCircuits"
  "Microsoft.Network/vpnGateways"
  "Microsoft.Network/virtualNetworkGateways"
  "Microsoft.Resources/templateSpecs/versions"
  "Microsoft.DataLakeStore/accounts"
  "Microsoft.AnalysisServices/servers"
  "Microsoft.Network/frontdoorWebApplicationFirewallPolicies"
  "Microsoft.Network/firewallPolicies"
  "Microsoft.Network/loadBalancers"
  "Microsoft.Network/localNetworkGateways"
  "Microsoft.CognitiveServices/accounts"
  "Microsoft.Search/searchServices"
  "Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies"
  "Microsoft.Network/azureFirewalls"
  "Microsoft.Network/applicationGateways"
  "Microsoft.Network/privateEndpoints"
  "Microsoft.ContainerRegistry/registries"
  "Microsoft.Network/vpnSites"
  "Microsoft.ContainerService/managedClusters"
  "Microsoft.Web/sites/slots"
  "Microsoft.Network/routeTables"
  "Microsoft.DocumentDB/databaseAccounts"
  "Microsoft.Web/sites"
  "Microsoft.Network/publicIPAddresses"
  "Microsoft.KeyVault/vaults"
  "Microsoft.Network/networkSecurityGroups"
  "Microsoft.Network/virtualNetworks"
  "Microsoft.Storage/storageAccounts"
  "Microsoft.Network/networkInterfaces"
  "Microsoft.Network/natGateways"
  "Microsoft.Network/networkIntentPolicies"
  "Microsoft.Network/virtualHubs"
  "Microsoft.Network/applicationSecurityGroups"
  "Microsoft.Network/bastionHosts"
  "Microsoft.Network/ddosProtectionPlans"
  "Microsoft.Network/connections"
  "Microsoft.DevCenter/networkConnections"
  "Microsoft.Network/dnsResolvers/outboundEndpoints"
  "Microsoft.Network/dnsForwardingRulesets"
  "Microsoft.Network/virtualWans"
  "Microsoft.Network/serviceEndpointPolicies"
  "Microsoft.Network/expressRouteGateways"
  "Microsoft.Network/dnsResolvers"
  "Microsoft.Network/dnsResolvers/inboundEndpoints"
  "Microsoft.Network/publicIPPrefixes"
  "Microsoft.Network/ipGroups"
  "Microsoft.Network/networkManagers"
)

# Define checkpoint frequency
CHECKPOINT_FREQUENCY=5

# Define timeout duration and maximum number of retries
TIMEOUT_DURATION=60
MAX_RETRIES=3

# Define progress bar function
function progress_bar() {
  local current=$1
  local total=$2
  local resource_type=$3
  local total_resource_types=$4
  local bar_width=50
  local progress=$((current * bar_width / total))
  local percentage=$((current * 100 / total))
  printf "Progress: [%-${bar_width}s] %d%% - Resource Type: %s (%d/%d)\r" "$(printf '#%.0s' $(seq 1 $progress))" $percentage "$resource_type" $current $total_resource_types
}

# Function to initialize the SQLite database
function initializeDatabase() {
  sqlite3 checkpoint.db <<EOF
CREATE TABLE IF NOT EXISTS checkpoints (
  subscription_index INTEGER PRIMARY KEY,
  data TEXT,
  findings TEXT
);
EOF
}

# Function to save checkpoint data to SQLite database
function saveCheckpoint() {
  local sub_index=$1
  local data="${DATA[@]}"
  local findings="${FINDINGS[@]}"

  sqlite3 checkpoint.db <<EOF
REPLACE INTO checkpoints (subscription_index, data, findings)
VALUES ($sub_index, '$data', '$findings');
EOF
}

# Function to load checkpoint data from SQLite database
function loadCheckpoint() {
  local sub_index=$1
  local checkpoint=$(sqlite3 checkpoint.db "SELECT data, findings FROM checkpoints WHERE subscription_index = $sub_index;")

  if [[ -n "$checkpoint" ]]; then
    IFS='|' read -r data findings <<< "$checkpoint"
    DATA=($data)
    FINDINGS=($findings)
    return 0
  else
    return 1
  fi
}

# Function to remove checkpoint data from SQLite database
function removeCheckpoint() {
  local sub_index=$1
  sqlite3 checkpoint.db "DELETE FROM checkpoints WHERE subscription_index = $sub_index;"
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -s|--subscriptions) subscriptions="$2"; shift ;;
    -o|--output) output_path="$2"; shift ;;
    -a|--auth-method) auth_method="$2"; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Default to browser authentication if no method is provided
auth_method=${auth_method:-browser}

# Login to Azure
azLogin "$auth_method"

# Check login status
if ! az account show >/dev/null 2>&1; then
  echo "Failed to login to Azure. Please check your credentials and try again."
  exit 1
fi

# Get selected subscriptions
if [[ -n "$subscriptions" ]]; then
  IFS=',' read -r -a subscription_ids <<< "$subscriptions"
else
  mapfile -t subscription_ids < <(getSubscriptions | awk '{print $1}')
  mapfile -t subscription_names < <(getSubscriptions | awk '{print $2}')
fi

# Initialize data and findings arrays
DATA=()
FINDINGS=()

# Initialize errors array
errors=()

# Get total number of resource types
total_resource_types=${#resource_types[@]}

# Initialize the SQLite database
initializeDatabase

# Loop through selected subscriptions
total_subs=${#subscription_ids[@]}
for ((sub_index=0; sub_index<total_subs; sub_index++)); do
  sub_id=${subscription_ids[$sub_index]}
  sub_name=${subscription_names[$sub_index]}
  
  echo "Scanning subscription $((sub_index+1)) of $total_subs: $sub_name (ID: $sub_id)"
  
  # Set active subscription
  setActiveSubscription "$sub_id" "$sub_name"
  
  # Load checkpoint if exists
  if loadCheckpoint $sub_index; then
    echo "Resuming scan from checkpoint for subscription $sub_name (ID: $sub_id)"
  else
    DATA=()
    FINDINGS=()
  fi
  
  # Loop through supported resource types
  total_resources=${#resource_types[@]}
  for ((res_index=0; res_index<total_resources; res_index++)); do
    resource_type=${resource_types[$res_index]}
    echo "Collecting data for resource type: $resource_type"
    progress_bar $((res_index+1)) $total_resources "$resource_type" $total_resource_types
    
    # Call the respective data collection function based on resource type and append results to data array
    for ((retry=1; retry<=MAX_RETRIES; retry++)); do
      timeout $TIMEOUT_DURATION bash -c "resource_data=\$(collect_\"${resource_type//\//_}\" 2>/dev/null)"
      if [[ $? -eq 0 ]]; then
        DATA+=("$resource_data")
        break
      else
        echo "Error collecting data for resource type: $resource_type. Retry $retry/$MAX_RETRIES."
        sleep $((retry * 2))
      fi
    done
    
    # Save checkpoint if checkpoint frequency is reached
    if [[ $(( (res_index+1) % "$CHECKPOINT_FREQUENCY" )) -eq 0 ]]; then
      saveCheckpoint $sub_index
    fi
  done
  
  # Analyze collected data for the current subscription
  analyzed_findings=$(analyzeData "${DATA[@]}")
  FINDINGS+=("$analyzed_findings")
  
  # Check for analysis errors
  if [[ $? -ne 0 ]]; then
    echo "Error analyzing data for subscription $sub_name (ID: $sub_id). Please check the error log for more details."
    errors+=("Error analyzing data for subscription $sub_name (ID: $sub_id)")
  fi
  
  # Save checkpoint after processing the subscription
  saveCheckpoint $sub_index
  
  # Remove checkpoint after processing the subscription
  removeCheckpoint $sub_index
done

# Generate report
report_path=$(generateReport "${FINDINGS[@]}")

# Check for report generation errors
if [[ $? -ne 0 ]]; then
  echo "Error generating report. Please check the error log for more details."
  errors+=("Error generating report")
fi

echo "Report generated at: $report_path"

# Handle errors
if [[ ${#errors[@]} -gt 0 ]]; then
  echo "The following errors occurred during the scan:"
  printf '- %s\n' "${errors[@]}"
  echo "Please check the error log for more details."
  exit 1
fi

echo "Scan completed successfully."
exit 0