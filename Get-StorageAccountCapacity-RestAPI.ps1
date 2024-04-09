#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                # 
#   Version 1.0                                                             #
#                                                                           #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#############################################################################

# Set the time zone to Eastern Standard Time (EST) and calculate the dates
$est = [System.TimeZoneInfo]::FindSystemTimeZoneById("Eastern Standard Time")
$today = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), $est.Id)

$startTime = $today.AddDays(-7).ToString("yyyy-MM-ddT00:00:00Z")
$endTime = $today.ToString("yyyy-MM-ddT00:00:00Z")

$accessToken = az account get-access-token --resource https://management.usgovcloudapi.net --query accessToken -o tsv

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Use the correct API version
$apiVersion = "2021-05-01"
$subscriptionId = "88b99cc4-b96b-4d65-a9e0-924273ba9b34"

# Fetch all storage accounts in the subscription
$storageAccountsUri = "https://management.usgovcloudapi.net/subscriptions/$subscriptionId/providers/Microsoft.Storage/storageAccounts?api-version=$apiVersion"
$storageAccounts = Invoke-RestMethod -Uri $storageAccountsUri -Method Get -Headers $headers

# Now, iterate through storage accounts to fetch metrics
foreach ($account in $storageAccounts.value) {
    $resourceId = $account.id
    # Construct the metrics API URL for each storage account with the dynamically calculated timespan and valid metric names
    $metricsUri = "https://management.usgovcloudapi.net$resourceId/providers/microsoft.insights/metrics?timespan=$startTime/$endTime&interval=PT1H&metricnames=UsedCapacity,Transactions&aggregation=average,total&api-version=$apiVersion"
    $metrics = Invoke-RestMethod -Uri $metricsUri -Method Get -Headers $headers

    # Process the $metrics as needed
}

