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

#Create empty array to store customobjects for output
$ObjArray = @()
# Get all subscriptions and iterate over them
Get-AzSubscription | ForEach-Object {
    # Set context to current subscription
    Set-AzContext -Subscription $_.Name
    $currentSub = $_.Name
 
    # Get all Resource Groups in the current subscription and iterate over them
    Get-AzResourceGroup | ForEach-Object {
        $currentRG = $_.ResourceGroupName
 
        # Get all Storage Accounts in the current Resource Group and iterate over them
        Get-AzStorageAccount -ResourceGroupName $currentRG | ForEach-Object {
            $storageAccount = $_.StorageAccountName
            $currentSAID = $_.Id
 
            # Get UsedCapacity metric for the current Storage Account
            $usedCapacity = (Get-AzMetric -ResourceId $currentSAID -MetricName "UsedCapacity").Data
            [int]$usedCapacityInMB = $usedCapacity.Average / 1024 / 1024
 
            # Create a custom object for each storage account with its details
            $thisObj = [PSCustomObject]@{
                StorageAccount = $storageAccount
                UsedCapacityMB = $usedCapacityInMB
                ResourceGroup  = $currentRG
                Subscription   = $currentSub
            }
        #Add custom object to Array    
        $ObjArray += $thisObj
        }
    }
}
#Output array of custom objects to CSV
$ObjArray| Export-Csv -Path ".\storageAccountsUsedCapacity.csv" -NoTypeInformation -Force