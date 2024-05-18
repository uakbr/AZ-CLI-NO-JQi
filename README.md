# Azure Security Scanner

The Azure Security Scanner is a bash script that scans Azure subscriptions for potential security issues across various Azure resources. It utilizes the Azure CLI (az) to collect resource data, analyze it for security misconfigurations, and generate a comprehensive report of the findings.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Supported Resource Types](#supported-resource-types)
- [Script Structure](#script-structure)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

## Overview

The Azure Security Scanner is designed to help Azure administrators and security professionals assess the security posture of their Azure environment. It scans multiple Azure subscriptions and collects data for a wide range of Azure resource types. The script then analyzes the collected data to identify potential security misconfigurations and generates a detailed report of the findings.

The script is built using bash scripting and relies on the Azure CLI (az) for authentication and data collection. It follows a modular structure, with separate files for different functionalities such as authentication, data collection, analysis, and reporting.

## Prerequisites

Before running the Azure Security Scanner, ensure that you have the following prerequisites:

- Azure CLI (az) installed on your system. You can install it by following the official documentation: [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Bash shell environment (e.g., Linux, macOS, Windows Subsystem for Linux)
- Access to the Azure subscriptions you want to scan, with appropriate permissions to read resource data.

## Installation

1. Clone the repository or download the script files to your local machine.

2. Ensure that the script files have execute permissions. You can set the permissions using the following command:

   ```bash
   chmod +x bin/scanner.sh src/*.sh
   ```

## Usage

To run the Azure Security Scanner, follow these steps:

1. Open a terminal or command prompt.

2. Navigate to the directory where the script files are located.

3. Run the `scanner.sh` script with the desired options:

   ```bash
   ./bin/scanner.sh [options]
   ```

   Available options:
   - `-s, --subscriptions`: Comma-separated list of subscription IDs to scan. If not provided, the script will prompt for subscription selection.
   - `-o, --output`: Output directory for the generated report. Default is `/app/output`.
   - `-a, --auth-method`: Authentication method to use. Supported values are `browser` (default), `device-code`, `interactive`, and `service-principal`.

   Example:
   ```bash
   ./bin/scanner.sh -s subscription1_id,subscription2_id -o /path/to/output -a device-code
   ```

4. The script will authenticate with Azure using the specified authentication method. If prompted, follow the authentication instructions.

5. The script will start scanning the selected subscriptions and collect resource data. Progress will be displayed in the console.

6. Once the scan is complete, the script will analyze the collected data and generate a report in JSON format. The report will be saved in the specified output directory.

7. Review the generated report for any identified security misconfigurations or potential issues.

## Configuration

The Azure Security Scanner provides some configuration options that you can modify according to your requirements:

- `CHECKPOINT_FREQUENCY`: Determines the frequency at which the script saves checkpoints during the scan. Default is 5.
- `TIMEOUT_DURATION`: Specifies the timeout duration in seconds for each data collection operation. Default is 60 seconds.
- `MAX_RETRIES`: Defines the maximum number of retries for failed data collection operations. Default is 3.

You can modify these configuration options in the `bin/scanner.sh` file.

## Supported Resource Types

The Azure Security Scanner supports scanning the following Azure resource types:

- `Microsoft.ApiManagement/service`
- `Microsoft.Compute/virtualMachines/extensions`
- `Microsoft.Network/networkWatchers/connectionMonitors`
- `Microsoft.Insights/scheduledQueryRules`
- `Microsoft.HybridCompute/machines`
- `Microsoft.Cdn/cdnWebApplicationFirewallPolicies`
- `Microsoft.ResourceGraph/queries`
- `Microsoft.Network/expressRouteCircuits`
- `Microsoft.Network/vpnGateways`
- `Microsoft.Network/virtualNetworkGateways`
- `Microsoft.Resources/templateSpecs/versions`
- `Microsoft.DataLakeStore/accounts`
- `Microsoft.AnalysisServices/servers`
- `Microsoft.Network/frontdoorWebApplicationFirewallPolicies`
- `Microsoft.Network/firewallPolicies`
- `Microsoft.Network/loadBalancers`
- `Microsoft.Network/localNetworkGateways`
- `Microsoft.CognitiveServices/accounts`
- `Microsoft.Search/searchServices`
- `Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies`
- `Microsoft.Network/azureFirewalls`
- `Microsoft.Network/applicationGateways`
- `Microsoft.Network/privateEndpoints`
- `Microsoft.ContainerRegistry/registries`
- `Microsoft.Network/vpnSites`
- `Microsoft.ContainerService/managedClusters`
- `Microsoft.Web/sites/slots`
- `Microsoft.Network/routeTables`
- `Microsoft.DocumentDB/databaseAccounts`
- `Microsoft.Web/sites`
- `Microsoft.Network/publicIPAddresses`
- `Microsoft.KeyVault/vaults`
- `Microsoft.Network/networkSecurityGroups`
- `Microsoft.Network/virtualNetworks`
- `Microsoft.Storage/storageAccounts`
- `Microsoft.Network/networkInterfaces`
- `Microsoft.Network/natGateways`
- `Microsoft.Network/networkIntentPolicies`
- `Microsoft.Network/virtualHubs`
- `Microsoft.Network/applicationSecurityGroups`
- `Microsoft.Network/bastionHosts`
- `Microsoft.Network/ddosProtectionPlans`
- `Microsoft.Network/connections`
- `Microsoft.DevCenter/networkConnections`
- `Microsoft.Network/dnsResolvers/outboundEndpoints`
- `Microsoft.Network/dnsForwardingRulesets`
- `Microsoft.Network/virtualWans`
- `Microsoft.Network/serviceEndpointPolicies`
- `Microsoft.Network/expressRouteGateways`
- `Microsoft.Network/dnsResolvers`
- `Microsoft.Network/dnsResolvers/inboundEndpoints`
- `Microsoft.Network/publicIPPrefixes`
- `Microsoft.Network/ipGroups`
- `Microsoft.Network/networkManagers`

The script collects relevant data for each resource type and performs specific security checks based on the resource properties.

## Script Structure

The Azure Security Scanner consists of the following script files:

- `bin/scanner.sh`: The main script file that orchestrates the scanning process. It handles command-line arguments, authentication, subscription selection, and coordinates the data collection, analysis, and reporting.

- `src/auth.sh`: Contains functions related to Azure authentication, such as logging in using different authentication methods and selecting subscriptions to scan.

- `src/collect.sh`: Defines functions for collecting resource data for each supported resource type. It uses the Azure CLI (az) to retrieve resource properties and handles retries and timeouts.

- `src/analyze.sh`: Implements functions for analyzing the collected resource data and identifying potential security misconfigurations. It performs specific checks based on resource types and their properties.

- `src/report.sh`: Generates the final security report in JSON format. It consolidates the findings from the analysis phase and saves the report to the specified output directory.

The script uses a modular approach, separating different functionalities into separate files for better organization and maintainability.

## Customization

If you want to customize the Azure Security Scanner or extend its functionality, you can modify the script files according to your needs. Here are a few possible customization options:

- Add support for additional resource types: If you want to scan resource types that are not currently supported, you can add new functions in the `src/collect.sh` and `src/analyze.sh` files to handle data collection and analysis for those resource types.

- Modify security checks: You can update the analysis functions in the `src/analyze.sh` file to perform different security checks based on your specific requirements. You can add, remove, or modify the checks as needed.

- Customize the report format: If you prefer a different report format or want to include additional information, you can modify the `generateReport` function in the `src/report.sh` file to generate the report in your desired format.

- Integrate with other tools: You can extend the script to integrate with other security tools or platforms. For example, you can send the generated report to a centralized security monitoring system or trigger automated remediation actions based on the findings.

When making customizations, ensure that you test the script thoroughly to verify that the changes work as expected and do not introduce any errors or performance issues.

## Troubleshooting

If you encounter any issues while running the Azure Security Scanner, consider the following troubleshooting steps:

- Verify that you have the required prerequisites installed, including the Azure CLI (az) and a compatible bash shell environment.

- Ensure that you have the necessary permissions to access the Azure subscriptions you want to scan. Check your Azure role assignments and verify that you have sufficient privileges to read resource data.

- If the script fails during the authentication process, double-check your credentials and ensure that you are using the correct authentication method. If using service principal authentication, verify that the service principal has the required permissions.

- If the script encounters errors during data collection or analysis, review the error messages in the console output or log files. The script logs detailed error messages that can help in identifying the cause of the issue.

- If the script is taking longer than expected to complete, you can adjust the `TIMEOUT_DURATION` and `MAX_RETRIES` configuration options to handle slower network connections or resource responses.

- If you encounter any other issues or have questions, please refer to the script's documentation or reach out to the script maintainer for assistance.

Remember to regularly update the Azure CLI (az) to ensure you have the latest features and bug fixes.
