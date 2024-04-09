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

